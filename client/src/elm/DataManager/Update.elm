port module DataManager.Update exposing (subscriptions, update)

import App.Model exposing (SubModelReturn)
import Backend.HealthCenter.Encoder
import Backend.Measurement.Encoder
import Backend.Nurse.Encoder
import Backend.Person.Encoder
import Backend.PmtctParticipant.Encoder
import Backend.Relationship.Encoder
import DataManager.Decoder exposing (decodeDownloadSyncResponseAuthority, decodeDownloadSyncResponseGeneral)
import DataManager.Encoder
import DataManager.Model exposing (BackendAuthorityEntity(..), BackendGeneralEntity(..), DownloadPhotos(..), IndexDbQueryType(..), IndexDbQueryTypeResult(..), Model, Msg(..), SyncStatus(..), emptyRevisionIdPerAuthority)
import DataManager.Utils exposing (getSyncSpeedForSubscriptions)
import Device.Encoder
import Device.Model exposing (Device)
import Editable
import Error.Utils exposing (decodeError, maybeHttpError, noError)
import Gizra.NominalDate exposing (NominalDate)
import HttpBuilder exposing (withExpectJson, withJsonBody, withQueryParams)
import Json.Decode exposing (Value, decodeValue)
import Json.Encode
import List.Zipper as Zipper
import RemoteData
import Restful.Endpoint exposing (fromEntityUuid)
import Time
import Utils.WebData


update : NominalDate -> Device -> Msg -> Model -> SubModelReturn Model Msg
update currentDate device msg model =
    let
        noChange =
            SubModelReturn model Cmd.none noError []

        returnDetermineSyncStatus =
            SubModelReturn
                (DataManager.Utils.determineSyncStatus model)
                Cmd.none
                noError
                []

        -- @todo: Move has hardcoded in flags, or keep here?
        dbVersion =
            9
    in
    case msg of
        BackendAuthorityFetch ->
            case model.syncStatus of
                SyncDownloadAuthority webData ->
                    if RemoteData.isLoading webData then
                        -- We are already loading.
                        noChange

                    else
                        case model.revisionIdPerAuthorityZipper of
                            Nothing ->
                                -- No zipper, means not subscribed yet to any
                                -- authority. `determineSyncStatus` will take care of
                                -- rotating if we're not on automatic sync.
                                returnDetermineSyncStatus

                            Just zipper ->
                                if RemoteData.isLoading webData then
                                    -- We are already loading.
                                    noChange

                                else
                                    let
                                        currentZipper =
                                            Zipper.current zipper

                                        cmd =
                                            HttpBuilder.get (device.backendUrl ++ "/api/sync/" ++ currentZipper.uuid)
                                                |> withQueryParams
                                                    [ ( "access_token", device.accessToken )
                                                    , ( "db_version", String.fromInt dbVersion )
                                                    , ( "base_revision", String.fromInt currentZipper.revisionId )
                                                    ]
                                                |> withExpectJson decodeDownloadSyncResponseAuthority
                                                |> HttpBuilder.send (RemoteData.fromResult >> BackendAuthorityFetchHandle zipper)
                                    in
                                    SubModelReturn
                                        { model | syncStatus = SyncDownloadAuthority RemoteData.Loading }
                                        cmd
                                        noError
                                        []

                _ ->
                    returnDetermineSyncStatus

        BackendAuthorityFetchHandle zipper webData ->
            let
                currentZipper =
                    Zipper.current zipper

                cmd =
                    case RemoteData.toMaybe webData of
                        Just data ->
                            let
                                dataToSend =
                                    data.entities
                                        |> List.foldl
                                            (\entity accum ->
                                                let
                                                    doEncode uuid vid val =
                                                        Json.Encode.object
                                                            [ ( "uuid", Json.Encode.string uuid )
                                                            , ( "entity", val )
                                                            , ( "vid", Json.Encode.int vid )
                                                            ]
                                                            |> Json.Encode.encode 0
                                                in
                                                case entity of
                                                    BackendAuthorityAttendance uuid vid entity_ ->
                                                        doEncode uuid vid (Json.Encode.object <| Backend.Measurement.Encoder.encodeAttendance entity_)
                                                            :: accum

                                                    BackendAuthorityPhoto uuid vid entity_ ->
                                                        doEncode uuid vid (Json.Encode.object <| Backend.Measurement.Encoder.encodePhoto entity_)
                                                            :: accum

                                                    BackendAuthorityWeight uuid vid entity_ ->
                                                        doEncode uuid vid (Json.Encode.object <| Backend.Measurement.Encoder.encodeWeight entity_)
                                                            :: accum

                                                    BackendAuthorityEntityUnknown _ _ ->
                                                        -- Filter out the unknown entities.
                                                        accum
                                            )
                                            []
                                        |> List.reverse
                            in
                            sendSyncedDataToIndexDb { table = "Authority", data = dataToSend }

                        Nothing ->
                            Cmd.none

                deferredPhotosCmd =
                    -- Prepare a list of the photos, so we could grab them in a later
                    -- time.
                    case RemoteData.toMaybe webData of
                        Just data ->
                            let
                                dataToSend =
                                    data.entities
                                        |> List.foldl
                                            (\entity accum ->
                                                case DataManager.Utils.getPhotoFromBackendAuthorityEntity entity of
                                                    Just photoUrl ->
                                                        let
                                                            entityIdentifier =
                                                                DataManager.Utils.getBackendAuthorityEntityIdentifier entity
                                                        in
                                                        (Json.Encode.object
                                                            [ ( "uuid", Json.Encode.string entityIdentifier.uuid )
                                                            , ( "photo", Json.Encode.string photoUrl )
                                                            , ( "attempts", Json.Encode.int 0 )
                                                            , ( "vid", Json.Encode.int entityIdentifier.revision )
                                                            ]
                                                            |> Json.Encode.encode 0
                                                        )
                                                            :: accum

                                                    Nothing ->
                                                        accum
                                            )
                                            []
                                        |> List.reverse
                            in
                            if List.isEmpty dataToSend then
                                Cmd.none

                            else
                                sendSyncedDataToIndexDb { table = "DeferredPhotos", data = dataToSend }

                        Nothing ->
                            Cmd.none

                lastFetchedRevisionId =
                    case RemoteData.toMaybe webData of
                        Just data ->
                            -- Get the last item.
                            data.entities
                                |> List.reverse
                                |> List.head
                                |> Maybe.map
                                    (\entity ->
                                        case entity of
                                            BackendAuthorityAttendance _ vid _ ->
                                                vid

                                            BackendAuthorityPhoto _ vid _ ->
                                                vid

                                            BackendAuthorityWeight _ vid _ ->
                                                vid

                                            BackendAuthorityEntityUnknown _ vid ->
                                                vid
                                    )
                                |> Maybe.withDefault currentZipper.revisionId

                        Nothing ->
                            currentZipper.revisionId

                zipperUpdated =
                    Zipper.mapCurrent (\old -> { old | revisionId = lastFetchedRevisionId }) zipper

                modelWithSyncStatus =
                    DataManager.Utils.determineSyncStatus
                        { model
                            | syncStatus = SyncDownloadAuthority webData
                            , revisionIdPerAuthorityZipper = Just zipperUpdated
                        }
            in
            SubModelReturn
                modelWithSyncStatus
                (Cmd.batch
                    [ cmd
                    , deferredPhotosCmd

                    -- Send to JS the updated revision ID. We send the entire
                    -- list.
                    , sendRevisionIdPerAuthority (Zipper.toList zipperUpdated)
                    ]
                )
                (maybeHttpError webData "Backend.DataManager.Update" "BackendAuthorityFetchHandle")
                []

        BackendFetchMain ->
            case model.syncStatus of
                SyncIdle ->
                    returnDetermineSyncStatus

                SyncUploadPhotoGeneral _ ->
                    update
                        currentDate
                        device
                        BackendPhotoUploadGeneral
                        model

                SyncUploadGeneral _ ->
                    update
                        currentDate
                        device
                        FetchFromIndexDbUploadGeneral
                        model

                SyncDownloadGeneral _ ->
                    update
                        currentDate
                        device
                        BackendGeneralFetch
                        model

                SyncDownloadAuthority _ ->
                    update
                        currentDate
                        device
                        BackendAuthorityFetch
                        model

                SyncDownloadPhotos _ ->
                    update
                        currentDate
                        device
                        FetchFromIndexDbDeferredPhoto
                        model

        RevisionIdAuthorityAdd uuid ->
            -- Add a new authority to Local storage.
            let
                uuidAsString =
                    fromEntityUuid uuid

                revisionIdPerAuthorityZipper =
                    case model.revisionIdPerAuthorityZipper of
                        Just zipper ->
                            zipper
                                |> Zipper.toList
                                -- Before adding, lets remove the same UUID, so in case it's already
                                -- we won't have duplicates.
                                |> List.filter (\row -> row.uuid /= uuidAsString)
                                |> (\list -> emptyRevisionIdPerAuthority uuidAsString :: list)
                                |> Zipper.fromList

                        Nothing ->
                            [ emptyRevisionIdPerAuthority uuidAsString ]
                                |> Zipper.fromList

                cmd =
                    case revisionIdPerAuthorityZipper of
                        Just zipper ->
                            sendRevisionIdPerAuthority (Zipper.toList zipper)

                        Nothing ->
                            Cmd.none
            in
            SubModelReturn
                { model | revisionIdPerAuthorityZipper = revisionIdPerAuthorityZipper }
                cmd
                noError
                []

        RevisionIdAuthorityRemove uuid ->
            -- Remove authority from Local storage.
            let
                uuidAsString =
                    fromEntityUuid uuid

                revisionIdPerAuthorityZipper =
                    case model.revisionIdPerAuthorityZipper of
                        Just zipper ->
                            zipper
                                |> Zipper.toList
                                |> List.filter (\row -> row.uuid /= uuidAsString)
                                |> Zipper.fromList

                        Nothing ->
                            -- We don't seem to have a zipper, so we cannot add
                            -- it.
                            Nothing

                cmd =
                    case revisionIdPerAuthorityZipper of
                        Just zipper ->
                            sendRevisionIdPerAuthority (Zipper.toList zipper)

                        Nothing ->
                            Cmd.none
            in
            SubModelReturn
                { model | revisionIdPerAuthorityZipper = revisionIdPerAuthorityZipper }
                cmd
                noError
                []

        BackendGeneralFetch ->
            case model.syncStatus of
                SyncDownloadGeneral webData ->
                    if RemoteData.isLoading webData then
                        -- We are already loading.
                        noChange

                    else
                        let
                            cmd =
                                HttpBuilder.get (device.backendUrl ++ "/api/sync")
                                    |> withQueryParams
                                        [ ( "access_token", device.accessToken )
                                        , ( "db_version", String.fromInt dbVersion )
                                        , ( "base_revision", String.fromInt model.lastFetchedRevisionIdGeneral )
                                        ]
                                    |> withExpectJson decodeDownloadSyncResponseGeneral
                                    |> HttpBuilder.send (RemoteData.fromResult >> BackendGeneralFetchHandle)
                        in
                        SubModelReturn
                            { model | syncStatus = SyncDownloadGeneral RemoteData.Loading }
                            cmd
                            noError
                            []

                _ ->
                    SubModelReturn
                        (DataManager.Utils.determineSyncStatus model)
                        Cmd.none
                        noError
                        []

        BackendGeneralFetchHandle webData ->
            let
                cmd =
                    case RemoteData.toMaybe webData of
                        Just data ->
                            let
                                dataToSend =
                                    data.entities
                                        |> List.foldl
                                            (\entity accum ->
                                                let
                                                    doEncode uuid vid val =
                                                        Json.Encode.object
                                                            [ ( "uuid", Json.Encode.string uuid )
                                                            , ( "entity", val )
                                                            , ( "vid", Json.Encode.int vid )
                                                            ]
                                                            |> Json.Encode.encode 0
                                                in
                                                case entity of
                                                    BackendGeneralCatchmentArea uuid vid entity_ ->
                                                        doEncode uuid vid (Backend.HealthCenter.Encoder.encodeCatchmentArea entity_)
                                                            :: accum

                                                    BackendGeneralHealthCenter uuid vid entity_ ->
                                                        doEncode uuid vid (Backend.HealthCenter.Encoder.encodeHealthCenter entity_)
                                                            :: accum

                                                    BackendGeneralNurse uuid vid entity_ ->
                                                        doEncode uuid vid (Json.Encode.object <| Backend.Nurse.Encoder.encodeNurse entity_)
                                                            :: accum

                                                    BackendGeneralPerson uuid vid entity_ ->
                                                        doEncode uuid vid (Json.Encode.object <| Backend.Person.Encoder.encodePerson entity_)
                                                            :: accum

                                                    BackendGeneralPmtctParticipant uuid vid entity_ ->
                                                        doEncode uuid vid (Backend.PmtctParticipant.Encoder.encodePmtctParticipant entity_)
                                                            :: accum

                                                    BackendGeneralRelationship uuid vid entity_ ->
                                                        doEncode uuid vid (Backend.Relationship.Encoder.encodeRelationship entity_)
                                                            :: accum

                                                    BackendGeneralEntityUnknown _ _ ->
                                                        -- Filter out the unknown entities.
                                                        accum
                                            )
                                            []
                                        |> List.reverse
                            in
                            if List.isEmpty dataToSend then
                                Cmd.none

                            else
                                sendSyncedDataToIndexDb { table = "General", data = dataToSend }

                        Nothing ->
                            Cmd.none

                -- We have successfully downloaded the entities, so
                -- we can delete them fom the `nodeChanges` table.
                -- We will do it, by their localId.
                deleteLocalIdsCmd =
                    case RemoteData.toMaybe webData of
                        Just data ->
                            let
                                localIds =
                                    List.map
                                        (\entity ->
                                            let
                                                identifier =
                                                    DataManager.Utils.getBackendGeneralEntityIdentifier entity
                                            in
                                            identifier.uuid
                                        )
                                        data.entities
                            in
                            if List.isEmpty localIds then
                                Cmd.none

                            else
                                sendLocalIdsForDelete { type_ = "General", uuid = localIds }

                        _ ->
                            Cmd.none

                lastFetchedRevisionIdGeneral =
                    case RemoteData.toMaybe webData of
                        Just data ->
                            -- Get the last item.
                            data.entities
                                |> List.reverse
                                |> List.head
                                |> Maybe.map
                                    (\entity ->
                                        case entity of
                                            BackendGeneralCatchmentArea _ vid _ ->
                                                vid

                                            BackendGeneralHealthCenter _ vid _ ->
                                                vid

                                            BackendGeneralNurse _ vid _ ->
                                                vid

                                            BackendGeneralPerson _ vid _ ->
                                                vid

                                            BackendGeneralPmtctParticipant _ vid _ ->
                                                vid

                                            BackendGeneralRelationship _ vid _ ->
                                                vid

                                            BackendGeneralEntityUnknown _ vid ->
                                                vid
                                    )
                                |> Maybe.withDefault model.lastFetchedRevisionIdGeneral

                        Nothing ->
                            model.lastFetchedRevisionIdGeneral

                deferredPhotosCmd =
                    -- Prepare a list of the photos, so we could grab them in a later
                    -- time.
                    case RemoteData.toMaybe webData of
                        Just data ->
                            let
                                dataToSend =
                                    data.entities
                                        |> List.foldl
                                            (\entity accum ->
                                                case entity of
                                                    BackendGeneralPerson uuid vid entity_ ->
                                                        case entity_.avatarUrl of
                                                            Nothing ->
                                                                -- No photo.
                                                                accum

                                                            Just avatarUrl ->
                                                                let
                                                                    encodedPhoto =
                                                                        [ ( "photo", Json.Encode.string avatarUrl ) ]

                                                                    encodedEntityWithAttempt =
                                                                        ( "attempts", Json.Encode.int 0 ) :: encodedPhoto
                                                                in
                                                                -- We don't need all the info, so we just keep what we need.
                                                                (Json.Encode.object
                                                                    [ ( "uuid", Json.Encode.string uuid )
                                                                    , ( "entity", Json.Encode.object encodedEntityWithAttempt )
                                                                    , ( "vid", Json.Encode.int vid )
                                                                    ]
                                                                    |> Json.Encode.encode 0
                                                                )
                                                                    :: accum

                                                    _ ->
                                                        -- Not a photo.
                                                        accum
                                            )
                                            []
                                        |> List.reverse
                            in
                            if List.isEmpty dataToSend then
                                Cmd.none

                            else
                                sendSyncedDataToIndexDb { table = "DeferredPhotos", data = dataToSend }

                        _ ->
                            Cmd.none

                modelWithSyncStatus =
                    DataManager.Utils.determineSyncStatus { model | syncStatus = SyncDownloadGeneral webData }
            in
            SubModelReturn
                { modelWithSyncStatus | lastFetchedRevisionIdGeneral = lastFetchedRevisionIdGeneral }
                (Cmd.batch
                    [ cmd
                    , deferredPhotosCmd
                    , deleteLocalIdsCmd
                    , sendLastFetchedRevisionIdGeneral lastFetchedRevisionIdGeneral
                    ]
                )
                (maybeHttpError webData "Backend.DataManager.Update" "BackendGeneralFetchHandle")
                []

        SetLastFetchedRevisionIdAuthority zipper revisionId ->
            let
                zipperUpdated =
                    Zipper.mapCurrent (\old -> { old | revisionId = revisionId }) zipper
            in
            SubModelReturn
                { model | revisionIdPerAuthorityZipper = Just zipperUpdated }
                Cmd.none
                noError
                []

        SetLastFetchedRevisionIdGeneral revisionId ->
            SubModelReturn
                { model | lastFetchedRevisionIdGeneral = revisionId }
                Cmd.none
                noError
                []

        SetSyncStatusRotateAutomatic status ->
            SubModelReturn
                { model | syncCycle = status }
                Cmd.none
                noError
                []

        FetchFromIndexDbDeferredPhoto ->
            -- Get a deferred photo from IndexDB.
            case model.syncStatus of
                SyncDownloadPhotos DownloadPhotosNone ->
                    noChange

                SyncDownloadPhotos (DownloadPhotosBatch record) ->
                    if RemoteData.isLoading record.indexDbRemoteData || RemoteData.isLoading record.backendRemoteData then
                        -- We are already loading.
                        noChange

                    else
                        let
                            recordUpdated =
                                { record
                                    | indexDbRemoteData = RemoteData.Loading
                                    , backendRemoteData = RemoteData.NotAsked
                                }
                        in
                        update
                            currentDate
                            device
                            (QueryIndexDb IndexDbQueryDeferredPhoto)
                            { model | syncStatus = SyncDownloadPhotos (DownloadPhotosBatch recordUpdated) }

                SyncDownloadPhotos (DownloadPhotosAll record) ->
                    if RemoteData.isLoading record.indexDbRemoteData || RemoteData.isLoading record.backendRemoteData then
                        -- We are already loading.
                        noChange

                    else
                        let
                            recordUpdated =
                                { record
                                    | indexDbRemoteData = RemoteData.Loading
                                    , backendRemoteData = RemoteData.NotAsked
                                }
                        in
                        update
                            currentDate
                            device
                            (QueryIndexDb IndexDbQueryDeferredPhoto)
                            { model | syncStatus = SyncDownloadPhotos (DownloadPhotosAll recordUpdated) }

                _ ->
                    noChange

        FetchFromIndexDbUploadGeneral ->
            -- Get a entities for upload from IndexDB.
            case model.syncStatus of
                SyncUploadGeneral record ->
                    if RemoteData.isLoading record.indexDbRemoteData || RemoteData.isLoading record.backendRemoteData then
                        -- We are already loading.
                        noChange

                    else
                        let
                            recordUpdated =
                                { record
                                    | indexDbRemoteData = RemoteData.Loading
                                    , backendRemoteData = RemoteData.NotAsked
                                }
                        in
                        update
                            currentDate
                            device
                            (QueryIndexDb IndexDbQueryUploadGeneral)
                            { model | syncStatus = SyncUploadGeneral recordUpdated }

                _ ->
                    noChange

        BackendPhotoUploadGeneral ->
            case model.syncStatus of
                SyncUploadPhotoGeneral webData ->
                    if RemoteData.isLoading webData then
                        noChange

                    else
                        update
                            currentDate
                            device
                            (QueryIndexDb IndexDbQueryUploadPhotoGeneral)
                            { model | syncStatus = SyncUploadPhotoGeneral RemoteData.Loading }

                _ ->
                    noChange

        BackendUploadGeneral Nothing ->
            let
                syncStatus =
                    -- There are no deferred photos matching the query.
                    case model.syncStatus of
                        SyncUploadGeneral record ->
                            SyncUploadGeneral { record | indexDbRemoteData = RemoteData.Success Nothing }

                        _ ->
                            model.syncStatus
            in
            SubModelReturn
                (DataManager.Utils.determineSyncStatus { model | syncStatus = syncStatus })
                Cmd.none
                noError
                []

        BackendUploadGeneral (Just result) ->
            case model.syncStatus of
                SyncUploadGeneral record ->
                    if RemoteData.isLoading record.backendRemoteData then
                        -- We are already POSTing to the backend.
                        noChange

                    else
                        let
                            recordUpdated =
                                { record
                                    | backendRemoteData =
                                        if List.isEmpty result.entities then
                                            -- There were no entities for upload.
                                            RemoteData.NotAsked

                                        else
                                            RemoteData.Loading
                                    , indexDbRemoteData = RemoteData.Success (Just result)
                                }

                            modelUpdated =
                                { model | syncStatus = SyncUploadGeneral recordUpdated }

                            cmd =
                                if List.isEmpty result.entities then
                                    -- There were no entities for upload.
                                    Cmd.none

                                else
                                    HttpBuilder.post (device.backendUrl ++ "/api/sync")
                                        |> withQueryParams
                                            [ ( "access_token", device.accessToken )
                                            , ( "db_version", String.fromInt dbVersion )
                                            ]
                                        |> withJsonBody (Json.Encode.object <| DataManager.Encoder.encodeIndexDbQueryUploadGeneralResultRecord result)
                                        -- We don't need to decode anything, as we just want to have
                                        -- the browser download it.
                                        |> HttpBuilder.send (RemoteData.fromResult >> BackendUploadGeneralHandle result)
                        in
                        SubModelReturn
                            (DataManager.Utils.determineSyncStatus modelUpdated)
                            cmd
                            noError
                            []

                _ ->
                    noChange

        BackendUploadGeneralHandle result webData ->
            case model.syncStatus of
                SyncUploadGeneral record ->
                    case webData of
                        RemoteData.Failure error ->
                            let
                                syncStatus =
                                    SyncUploadGeneral { record | backendRemoteData = RemoteData.Failure error }
                            in
                            SubModelReturn
                                (DataManager.Utils.determineSyncStatus { model | syncStatus = syncStatus })
                                Cmd.none
                                (maybeHttpError webData "Backend.DataManager.Update" "BackendUploadGeneralHandle")
                                []

                        RemoteData.Success _ ->
                            let
                                syncStatus =
                                    SyncUploadGeneral { record | backendRemoteData = RemoteData.Success () }

                                -- We have successfully uploaded the entities, so
                                -- we can mark them as `isSynced`.
                                cmd =
                                    let
                                        localIds =
                                            List.map
                                                (\( entity, _ ) ->
                                                    let
                                                        identifier =
                                                            DataManager.Utils.getBackendGeneralEntityIdentifier entity
                                                    in
                                                    identifier.revision
                                                )
                                                result.entities
                                    in
                                    sendLocalIdsForMarkAsUploaded { type_ = "General", localId = localIds }
                            in
                            SubModelReturn
                                (DataManager.Utils.determineSyncStatus { model | syncStatus = syncStatus })
                                cmd
                                noError
                                []

                        _ ->
                            -- Satisfy the compiler.
                            noChange

                _ ->
                    noChange

        BackendUploadPhotoGeneralHandle remoteData ->
            -- Uploading of photos happened through JS, since it involves working
            -- with file blobs. This handler however is for post upload attempt
            -- (success or not), to set RemoteData accordingly.
            case model.syncStatus of
                SyncUploadPhotoGeneral _ ->
                    SubModelReturn
                        (DataManager.Utils.determineSyncStatus { model | syncStatus = SyncUploadPhotoGeneral remoteData })
                        Cmd.none
                        noError
                        []

                _ ->
                    noChange

        BackendDeferredPhotoFetch Nothing ->
            let
                syncStatus =
                    -- There are no deferred photos matching the query.
                    case model.syncStatus of
                        SyncDownloadPhotos (DownloadPhotosBatch record) ->
                            SyncDownloadPhotos (DownloadPhotosBatch { record | indexDbRemoteData = RemoteData.Success Nothing })

                        SyncDownloadPhotos (DownloadPhotosAll record) ->
                            SyncDownloadPhotos (DownloadPhotosAll { record | indexDbRemoteData = RemoteData.Success Nothing })

                        _ ->
                            model.syncStatus
            in
            SubModelReturn
                (DataManager.Utils.determineSyncStatus { model | syncStatus = syncStatus })
                Cmd.none
                noError
                []

        BackendDeferredPhotoFetch (Just result) ->
            let
                isLoading =
                    case model.syncStatus of
                        SyncDownloadPhotos (DownloadPhotosBatch record) ->
                            RemoteData.isLoading record.backendRemoteData

                        SyncDownloadPhotos (DownloadPhotosAll record) ->
                            RemoteData.isLoading record.backendRemoteData

                        _ ->
                            False
            in
            if isLoading then
                noChange

            else
                let
                    syncStatus =
                        case model.syncStatus of
                            SyncDownloadPhotos (DownloadPhotosBatch record) ->
                                let
                                    recordUpdated =
                                        { record
                                            | backendRemoteData = RemoteData.Loading
                                            , indexDbRemoteData = RemoteData.Success (Just result)
                                        }
                                in
                                SyncDownloadPhotos (DownloadPhotosBatch recordUpdated)

                            SyncDownloadPhotos (DownloadPhotosAll record) ->
                                let
                                    recordUpdated =
                                        { record
                                            | backendRemoteData = RemoteData.Loading
                                            , indexDbRemoteData = RemoteData.Success (Just result)
                                        }
                                in
                                SyncDownloadPhotos (DownloadPhotosAll recordUpdated)

                            _ ->
                                model.syncStatus

                    modelUpdated =
                        { model | syncStatus = syncStatus }

                    cmd =
                        -- As the image is captured with the image token (`itok`), we
                        -- don't use `withQueryParams` to add the access token, as it will
                        -- result with something like this:
                        -- image-1234.jpg?itok=[image-token]?access_token=[access-token]
                        -- Instead, we manually add the access token with a `&`.
                        HttpBuilder.get (result.photo ++ "&" ++ "access_token=" ++ device.accessToken)
                            -- We don't need to decode anything, as we just want to have
                            -- the browser download it.
                            |> HttpBuilder.send (RemoteData.fromResult >> BackendDeferredPhotoFetchHandle result)
                in
                SubModelReturn
                    (DataManager.Utils.determineSyncStatus modelUpdated)
                    cmd
                    noError
                    []

        BackendDeferredPhotoFetchHandle result webData ->
            case webData of
                RemoteData.Failure error ->
                    if Utils.WebData.isNetworkError error then
                        -- We're offline, so this doesn't qualify as an attempt.
                        noChange

                    else
                        let
                            syncStatus =
                                case model.syncStatus of
                                    SyncDownloadPhotos (DownloadPhotosBatch deferredPhoto) ->
                                        let
                                            deferredPhotoUpdated =
                                                { deferredPhoto
                                                  -- Reduce the batch counter.
                                                    | batchCounter = deferredPhoto.batchCounter - 1
                                                    , backendRemoteData = RemoteData.Failure error
                                                }
                                        in
                                        SyncDownloadPhotos (DownloadPhotosBatch deferredPhotoUpdated)

                                    SyncDownloadPhotos (DownloadPhotosAll deferredPhoto) ->
                                        let
                                            deferredPhotoUpdated =
                                                { deferredPhoto | backendRemoteData = RemoteData.Failure error }
                                        in
                                        SyncDownloadPhotos (DownloadPhotosAll deferredPhotoUpdated)

                                    _ ->
                                        model.syncStatus
                        in
                        update
                            currentDate
                            device
                            (QueryIndexDb <| IndexDbQueryUpdateDeferredPhotoAttempts result)
                            { model | syncStatus = syncStatus }

                RemoteData.Success queryResult ->
                    let
                        syncStatus =
                            case model.syncStatus of
                                SyncDownloadPhotos (DownloadPhotosBatch deferredPhoto) ->
                                    let
                                        deferredPhotoUpdated =
                                            { deferredPhoto
                                              -- Reduce the batch counter.
                                                | batchCounter = deferredPhoto.batchCounter - 1
                                                , backendRemoteData = RemoteData.Success queryResult
                                            }
                                    in
                                    SyncDownloadPhotos (DownloadPhotosBatch deferredPhotoUpdated)

                                SyncDownloadPhotos (DownloadPhotosAll deferredPhoto) ->
                                    let
                                        deferredPhotoUpdated =
                                            { deferredPhoto | backendRemoteData = RemoteData.Success queryResult }
                                    in
                                    SyncDownloadPhotos (DownloadPhotosAll deferredPhotoUpdated)

                                _ ->
                                    model.syncStatus
                    in
                    -- We've fetched the image, so we can remove the record from
                    -- `deferredPhotos` table.
                    update
                        currentDate
                        device
                        (QueryIndexDb <| IndexDbQueryRemoveDeferredPhotoAttempts result.uuid)
                        { model | syncStatus = syncStatus }

                _ ->
                    -- Satisfy the compiler.
                    noChange

        QueryIndexDb indexDbQueryType ->
            let
                record =
                    case indexDbQueryType of
                        IndexDbQueryUploadPhotoGeneral ->
                            let
                                -- Send the device info so on JS, we'd know how
                                -- to contact the backend.
                                encodedData =
                                    Device.Encoder.encode device
                                        |> Json.Encode.encode 0
                            in
                            { queryType = "IndexDbQueryUploadPhotoGeneral"
                            , data = Just encodedData
                            }

                        IndexDbQueryUploadGeneral ->
                            { queryType = "IndexDbQueryUploadGeneral"
                            , data = Nothing
                            }

                        IndexDbQueryDeferredPhoto ->
                            { queryType = "IndexDbQueryDeferredPhoto"
                            , data = Nothing
                            }

                        IndexDbQueryRemoveDeferredPhotoAttempts uuid ->
                            { queryType = "IndexDbQueryRemoveDeferredPhotoAttempts"
                            , data = Just uuid
                            }

                        IndexDbQueryUpdateDeferredPhotoAttempts record_ ->
                            let
                                -- Increment the number of attempts.
                                encodedData =
                                    Json.Encode.object
                                        [ ( "uuid", Json.Encode.string record_.uuid )
                                        , ( "attempts", Json.Encode.int (record_.attempts + 1) )
                                        ]
                                        |> Json.Encode.encode 0
                            in
                            { queryType = "IndexDbQueryUpdateDeferredPhotoAttempts"
                            , data = Just encodedData
                            }
            in
            SubModelReturn
                model
                (askFromIndexDb record)
                noError
                []

        QueryIndexDbHandle val ->
            case decodeValue DataManager.Decoder.decodeIndexDbQueryTypeResult val of
                Ok indexDbQueryTypeResult ->
                    case indexDbQueryTypeResult of
                        IndexDbQueryUploadPhotoGeneralResult remoteData ->
                            update
                                currentDate
                                device
                                (BackendUploadPhotoGeneralHandle remoteData)
                                model

                        IndexDbQueryUploadGeneralResult result ->
                            update
                                currentDate
                                device
                                (BackendUploadGeneral result)
                                model

                        IndexDbQueryDeferredPhotoResult result ->
                            update
                                currentDate
                                device
                                (BackendDeferredPhotoFetch result)
                                model

                Err error ->
                    SubModelReturn
                        model
                        Cmd.none
                        (decodeError "Backend.DataManager.Update" "FetchFromIndexDbHandle" error)
                        []

        ResetSettings ->
            let
                syncSpeed =
                    { idle = 10000
                    , cycle = 50
                    , offline = 3000
                    }
            in
            SubModelReturn
                { model | syncSpeed = Editable.ReadOnly syncSpeed }
                (sendSyncSpeed syncSpeed)
                noError
                []

        SaveSettings ->
            let
                syncSpeed =
                    Editable.value model.syncSpeed

                -- Safe guard against to0 low values.
                syncSpeedUpdated =
                    { syncSpeed
                        | idle =
                            if syncSpeed.idle < 3000 then
                                3000

                            else
                                syncSpeed.idle
                        , cycle =
                            if syncSpeed.cycle < 50 then
                                50

                            else
                                syncSpeed.cycle
                        , offline =
                            if syncSpeed.offline < 1000 then
                                1000

                            else
                                syncSpeed.offline
                    }
            in
            SubModelReturn
                { model | syncSpeed = Editable.ReadOnly syncSpeedUpdated }
                (sendSyncSpeed syncSpeedUpdated)
                noError
                []

        SetSyncSpeedIdle str ->
            case String.toInt str of
                Just val ->
                    let
                        syncSpeed =
                            model.syncSpeed
                                |> Editable.edit
                                |> Editable.map (\old -> { old | idle = val })
                    in
                    SubModelReturn
                        { model | syncSpeed = syncSpeed }
                        Cmd.none
                        noError
                        []

                _ ->
                    noChange

        SetSyncSpeedCycle str ->
            case String.toInt str of
                Just val ->
                    let
                        syncSpeed =
                            model.syncSpeed
                                |> Editable.edit
                                |> Editable.map (\old -> { old | cycle = val })
                    in
                    SubModelReturn
                        { model | syncSpeed = syncSpeed }
                        Cmd.none
                        noError
                        []

                _ ->
                    noChange

        SetSyncSpeedOffline str ->
            case String.toInt str of
                Just val ->
                    let
                        syncSpeed =
                            model.syncSpeed
                                |> Editable.edit
                                |> Editable.map (\old -> { old | offline = val })
                    in
                    SubModelReturn
                        { model | syncSpeed = syncSpeed }
                        Cmd.none
                        noError
                        []

                _ ->
                    noChange


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every (getSyncSpeedForSubscriptions model) (\_ -> BackendFetchMain)
        , getFromIndexDb QueryIndexDbHandle
        ]


{-| Send to JS data we have synced, e.g. `person`, `health center`, etc.
-}
port sendSyncedDataToIndexDb : { table : String, data : List String } -> Cmd msg


{-| Send to JS the last revision ID used to download General.
-}
port sendLastFetchedRevisionIdGeneral : Int -> Cmd msg


{-| Send to JS a list with the last revision ID used to download Authority,
along with their UUID.
-}
port sendRevisionIdPerAuthority : List { uuid : String, revisionId : Int } -> Cmd msg


{-| Send to JS a list of local ID that were uploaded.

The `type_` can be `General` or `Authority`.

-}
port sendLocalIdsForMarkAsUploaded : { type_ : String, localId : List Int } -> Cmd msd


{-| Send to JS a uuid list of local changes that can be deleted.
This is done after they are uploaded to the backend, and re-downloaded.

The `type_` can be `General` or `Authority`.

-}
port sendLocalIdsForDelete : { type_ : String, uuid : List String } -> Cmd msd


{-| Send to JS model.syncSpeed
-}
port sendSyncSpeed : { idle : Int, cycle : Int, offline : Int } -> Cmd msd


{-| Ask JS to send us data from IndexDB. We send the query type, and in case
we have some related data (e.g. the child ID to query), we send it as-well.
-}
port askFromIndexDb : { queryType : String, data : Maybe String } -> Cmd msg


{-| Get data requested from IndexDB.

For now we don't care who asked for the data, we just fill it in where
needed.

-}
port getFromIndexDb : (Value -> msg) -> Sub msg
