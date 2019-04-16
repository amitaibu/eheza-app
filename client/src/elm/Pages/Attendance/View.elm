module Pages.Attendance.View exposing (view)

{-| This shows the page where we can record which mothers are in attendance
at a session.

<https://github.com/Gizra/ihangane/issues/409>

-}

import Activity.Utils exposing (motherIsCheckedIn)
import Backend.Entities exposing (..)
import Backend.Mother.Model exposing (Mother)
import Backend.Session.Model exposing (EditableSession)
import Backend.Session.Utils exposing (getChildren, getMotherMeasurementData)
import EveryDictList
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Pages.Attendance.Model exposing (..)
import Pages.Page exposing (Page(..), SessionPage(..), UserPage(..))
import Pages.Utils exposing (matchFilter, matchMotherAndHerChildren, normalizeFilter, viewNameFilter)
import Translate exposing (Language, translate)
import Utils.Html exposing (thumbnailImage)


view : Language -> ( SessionId, EditableSession ) -> Model -> Html Msg
view language ( sessionId, session ) model =
    let
        filter =
            normalizeFilter model.filter

        matches =
            if String.isEmpty filter then
                \_ _ ->
                    -- No input entered, so show all values.
                    True

            else
                matchMotherAndHerChildren filter session.offlineSession

        mothers =
            if EveryDictList.isEmpty session.offlineSession.mothers then
                [ div
                    [ class "ui message warning" ]
                    [ text <| translate language Translate.ThisGroupHasNoMothers ]
                ]

            else
                let
                    matching =
                        EveryDictList.filter matches session.offlineSession.mothers
                in
                if EveryDictList.isEmpty matching then
                    [ span [] [ text <| translate language Translate.NoMatchesFound ] ]

                else
                    matching
                        |> EveryDictList.map (viewMother session)
                        |> EveryDictList.values
    in
    div [ class "wrap wrap-alt-2 page-attendance" ]
        [ div
            [ class "ui basic head segment" ]
            [ h1
                [ class "ui header" ]
                [ text <| translate language Translate.Attendance ]
            , a
                [ class "link-back"
                , Just session.offlineSession.session.clinicId
                    |> ClinicsPage
                    |> UserPage
                    |> SetActivePage
                    |> onClick
                ]
                [ span [ class "icon-back" ] []
                , span [] []
                ]
            , ul [ class "links-head" ]
                [ li
                    [ class "active" ]
                    [ a [] [ span [ class "icon-completed" ] [] ] ]
                , li
                    [ onClick <| SetActivePage <| UserPage <| SessionPage sessionId ParticipantsPage ]
                    [ a [] [ span [ class "icon-mother" ] [] ] ]
                , li
                    [ onClick <| SetActivePage <| UserPage <| SessionPage sessionId ActivitiesPage ]
                    [ a [] [ span [ class "icon-measurements" ] [] ] ]
                ]
            ]
        , div
            [ class "ui full blue segment" ]
            [ div
                [ class "full content" ]
                [ div [ class "wrap-list" ]
                    [ h3
                        [ class "ui header" ]
                        [ text <| translate language Translate.CheckIn ]
                    , p [] [ text <| translate language Translate.ClickTheCheckMark ]
                    , viewNameFilter language model.filter SetFilter
                    , div [ class "ui middle aligned divided list" ] mothers
                    ]
                ]
            ]
        ]


viewMother : EditableSession -> MotherId -> Mother -> Html Msg
viewMother session motherId mother =
    let
        attendanceId =
            getMotherMeasurementData motherId session
                |> (.current >> .attendance)
                |> Maybe.map Tuple.first

        checkIn =
            if motherIsCheckedIn motherId session then
                a
                    [ class "link-checked-in"
                    , onClick <| SetCheckedIn attendanceId motherId False
                    ]
                    [ span [ class "icon-checked-in" ] [] ]

            else
                a
                    [ class "link-check-in"
                    , onClick <| SetCheckedIn attendanceId motherId True
                    ]
                    [ span [ class "icon-check-in" ] [] ]

        children =
            getChildren motherId session.offlineSession
                |> List.map (\( _, child ) -> text child.name)
                |> List.intersperse (text ", ")
    in
    div
        [ class "item" ]
        [ thumbnailImage "mother ui avatar image" mother.avatarUrl mother.name 110 110
        , div
            [ class "content" ]
            [ div [ class "header" ] [ text mother.name ]
            , div [ class "description" ] children
            ]
        , checkIn
        ]
