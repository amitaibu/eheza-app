module DataManager.View exposing (view)

import AssocList as Dict
import Backend.Entities exposing (HealthCenterId)
import Backend.HealthCenter.Model exposing (HealthCenter)
import Backend.Model exposing (ModelIndexedDb)
import DataManager.Model
    exposing
        ( BackendAuthorityEntity(..)
        , BackendGeneralEntity(..)
        , DownloadPhotos(..)
        , DownloadPhotosBatchRec
        , DownloadSyncResponse
        , Model
        , Msg(..)
        , RevisionIdPerAuthorityZipper
        , SyncStatus(..)
        )
import Gizra.Html exposing (emptyNode)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onCheck, onClick)
import Json.Encode
import List.Extra
import List.Zipper as Zipper
import Maybe.Extra exposing (isJust)
import RemoteData exposing (WebData)
import Restful.Endpoint exposing (fromEntityUuid, toEntityUuid)
import Translate exposing (Language, translate)
import Url
import Utils.Html exposing (spinner)
import Utils.WebData


view : Language -> ModelIndexedDb -> Model -> Html Msg
view language db model =
    let
        htmlContent =
            details [ property "open" (Json.Encode.bool True) ]
                [ summary [] [ text "Sync Status" ]
                , viewSyncStatusControl model

                -- button [ onClick <| DataManager.Model.FetchFromIndexDb DataManager.Model.IndexDbQueryHealthCenters ] [ text "Fetch Health Centers" ]
                , div [] [ text <| "Sync status: " ++ Debug.toString model.syncStatus ]
                , case model.syncStatus of
                    SyncDownloadGeneral webData ->
                        viewSyncDownloadGeneral language model webData

                    SyncDownloadAuthority webData ->
                        viewSyncDownloadAuthority language db model webData

                    SyncDownloadPhotos (DownloadPhotosBatch deferredPhoto) ->
                        viewDownloadPhotosBatch language model deferredPhoto

                    _ ->
                        emptyNode
                ]
    in
    div []
        [ viewHealthCentersForSync language db model
        , pre [ class "ui segment sync-status" ] [ htmlContent ]
        ]


viewSyncStatusControl : Model -> Html Msg
viewSyncStatusControl model =
    div []
        [ input
            [ type_ "checkbox"
            , checked model.syncStatusRotateAutomatic
            , onCheck SetSyncStatusRotateAutomatic
            ]
            []
        , label [] [ text "Automatic Sync status control" ]
        ]


viewSyncDownloadGeneral : Language -> Model -> WebData (DownloadSyncResponse BackendGeneralEntity) -> Html Msg
viewSyncDownloadGeneral language model webData =
    div []
        [ div [] [ text <| "Fetch from General from revision ID " ++ String.fromInt model.lastFetchedRevisionIdGeneral ]
        , button [ onClick <| DataManager.Model.SetLastFetchedRevisionIdGeneral 0 ] [ text "Reset revision ID to 0" ]
        , div [] [ text "HTTP requests:" ]
        , case webData of
            RemoteData.Success data ->
                div []
                    [ div [] [ text <| String.fromInt data.revisionCount ++ " items left to download" ]
                    , if List.isEmpty data.entities then
                        div [] [ text "No content fetched in last HTTP request" ]

                      else
                        ol [] (List.map (viewGeneralEntity language) data.entities)
                    ]

            RemoteData.Failure error ->
                text <| Debug.toString error

            RemoteData.Loading ->
                spinner

            RemoteData.NotAsked ->
                emptyNode
        ]


viewGeneralEntity : Language -> BackendGeneralEntity -> Html msg
viewGeneralEntity language backendGeneralEntity =
    li []
        [ case backendGeneralEntity of
            BackendGeneralCatchmentArea _ _ entity ->
                text <| "Catchment area (" ++ entity.name ++ ")"

            BackendGeneralHealthCenter _ _ entity ->
                text <| "Health Center (" ++ entity.name ++ ")"

            BackendGeneralNurse _ _ entity ->
                text <| "Nurse " ++ entity.name

            BackendGeneralPerson _ _ entity ->
                text <| "Person (" ++ entity.name ++ ")"

            BackendGeneralPmtctParticipant _ _ entity ->
                text <| "Pmtct Participant for child ID (" ++ fromEntityUuid entity.child ++ ")"

            BackendGeneralRelationship _ _ entity ->
                text <| "Relationship for person ID (" ++ fromEntityUuid entity.person ++ ")"

            BackendGeneralEntityUnknown type_ _ ->
                text <| type_ ++ " (we still don't decode it)"
        ]


viewSyncDownloadAuthority : Language -> ModelIndexedDb -> Model -> WebData (DownloadSyncResponse BackendAuthorityEntity) -> Html Msg
viewSyncDownloadAuthority language db model webData =
    case model.revisionIdPerAuthorityZipper of
        Nothing ->
            emptyNode

        Just zipper ->
            let
                currentZipper =
                    Zipper.current zipper

                getAuthorityName uuid =
                    db.healthCenters
                        |> RemoteData.toMaybe
                        |> Maybe.andThen (\healthCenters -> Dict.get (toEntityUuid uuid) healthCenters)
                        |> Maybe.map (\healthCenter -> healthCenter.name)
                        |> Maybe.withDefault uuid

                authoritiesListHtml =
                    Zipper.toList zipper
                        |> List.map
                            (\row ->
                                if row.uuid == currentZipper.uuid then
                                    li [ class "active" ] [ text <| getAuthorityName row.uuid ++ " (from revision ID " ++ String.fromInt row.revisionId ++ ")" ]

                                else
                                    li [] [ text <| getAuthorityName row.uuid ]
                            )
            in
            div []
                [ div [] [ text <| "Fetch from Authority" ]
                , ol [] authoritiesListHtml
                , button [ onClick <| DataManager.Model.SetLastFetchedRevisionIdAuthority zipper 0 ] [ text "Reset revision ID to 0" ]
                , case webData of
                    RemoteData.Success data ->
                        div []
                            [ div [] [ text <| String.fromInt data.revisionCount ++ " items left to download" ]
                            , if List.isEmpty data.entities then
                                div [] [ text "No content fetched in last HTTP request" ]

                              else
                                div []
                                    [ div [] [ text <| "Here is the content we've fetched in the last HTTP request:" ]
                                    , ol [] (List.map viewAuthorityEntity data.entities)
                                    ]
                            ]

                    RemoteData.Failure error ->
                        text <| Debug.toString error

                    RemoteData.Loading ->
                        spinner

                    RemoteData.NotAsked ->
                        emptyNode
                ]


viewAuthorityEntity : BackendAuthorityEntity -> Html msg
viewAuthorityEntity backendAuthorityEntity =
    li []
        [ case backendAuthorityEntity of
            BackendAuthorityAttendance _ _ entity ->
                text <| "Attendance for person ID" ++ fromEntityUuid entity.participantId

            BackendAuthorityPhoto _ _ entity ->
                text <| "Photo for person ID" ++ fromEntityUuid entity.participantId

            BackendAuthorityWeight _ _ entity ->
                text <| "Weight for person ID" ++ fromEntityUuid entity.participantId

            BackendAuthorityEntityUnknown type_ _ ->
                text <| type_ ++ " (we still don't decode it)"
        ]


viewDownloadPhotosBatch : Language -> Model -> DownloadPhotosBatchRec -> Html Msg
viewDownloadPhotosBatch language model deferredPhoto =
    case deferredPhoto.indexDbRemoteData of
        RemoteData.Success (Just result) ->
            let
                fileName =
                    result.photo
                        |> Url.fromString
                        |> Maybe.andThen
                            (\url ->
                                url.path
                                    |> String.split "/"
                                    |> List.Extra.last
                            )
                        |> Maybe.withDefault ""

                attempt =
                    result.attempts + 1

                attemptString =
                    case attempt of
                        1 ->
                            "1st"

                        2 ->
                            "2nd"

                        3 ->
                            "3rd"

                        _ ->
                            String.fromInt attempt ++ "th"
            in
            div []
                [ text <| "Photos batch download (" ++ String.fromInt (deferredPhoto.batchCounter + 1) ++ " out of " ++ String.fromInt deferredPhoto.batchSize ++ ")"
                , div []
                    [ text <| attemptString ++ " attempt to download "
                    , a [ href result.photo, target "_blank" ] [ text fileName ]
                    ]
                ]

        _ ->
            emptyNode


{-| Show a list of Authorities that allow syncing from.
-}
viewHealthCentersForSync : Language -> ModelIndexedDb -> Model -> Html Msg
viewHealthCentersForSync language db model =
    let
        -- The Health centers that are synced.
        selectedHealthCentersUuid =
            case model.revisionIdPerAuthorityZipper of
                Just zipper ->
                    Zipper.toList zipper
                        |> List.map (\row -> row.uuid)

                Nothing ->
                    []
    in
    case db.healthCenters of
        RemoteData.Success healthCenters ->
            if Dict.isEmpty healthCenters then
                div [ class "segment ui health-center" ] [ text "No health centers synced yet" ]

            else
                div
                    [ class "segment ui health-center" ]
                    [ details [ property "open" (Json.Encode.bool False) ]
                        [ summary [] [ text "Health Centers" ]
                        , ul []
                            (List.map
                                (\( healthCenterId, healthCenter ) ->
                                    let
                                        isSynced =
                                            List.Extra.find (\selectedUuid -> selectedUuid == fromEntityUuid healthCenterId) selectedHealthCentersUuid
                                                |> isJust
                                    in
                                    viewHealthCenter language ( healthCenterId, healthCenter ) isSynced
                                )
                                (Dict.toList healthCenters)
                            )
                        ]
                    ]

        RemoteData.Failure error ->
            Utils.WebData.viewError language error

        RemoteData.Loading ->
            spinner

        RemoteData.NotAsked ->
            emptyNode


viewHealthCenter : Language -> ( HealthCenterId, HealthCenter ) -> Bool -> Html Msg
viewHealthCenter language ( healthCenterId, healthCenter ) isSynced =
    let
        ( syncLabel, syncMsg ) =
            if isSynced then
                ( "Remove from Sync list", RevisionIdAuthorityRemove healthCenterId )

            else
                ( "Add to Sync list", RevisionIdAuthorityAdd healthCenterId )
    in
    li []
        [ text <| healthCenter.name
        , button [ onClick syncMsg ] [ text syncLabel ]
        ]
