module Pages.Clinics.View exposing (view)

{-| The purpose of this page is to show a list of clinics, allowing the
user to click on clinics the user is assigned to, to see the sessions which are
available for data-entry.
-}

import App.Model exposing (Msg(..), MsgLoggedIn(..))
import AssocList as Dict exposing (Dict)
import Backend.Clinic.Model exposing (Clinic)
import Backend.Entities exposing (..)
import Backend.Model exposing (ModelIndexedDb, MsgIndexedDb(..))
import Backend.Nurse.Model exposing (Nurse)
import Backend.Nurse.Utils exposing (assignedToClinic)
import Backend.Session.Model exposing (Session)
import Backend.SyncData.Model exposing (SyncData)
import Gizra.Html exposing (emptyNode)
import Gizra.NominalDate exposing (NominalDate, formatYYYYMMDD)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Pages.Page exposing (Page(..), SessionPage(..), UserPage(..))
import Pages.PageNotFound.View
import RemoteData exposing (RemoteData(..), WebData)
import Translate exposing (Language, translate)
import Utils.WebData exposing (viewError, viewWebData)


{-| If `selectedClinic` is Just, we'll show a page for that clinic. If not,
we'll show a list of clinics.

For now, at least, we don't really need our own `Msg` type, so we're just using
the big one.

-}
view : Language -> NominalDate -> Nurse -> Maybe ClinicId -> ModelIndexedDb -> Html Msg
view language currentDate user selectedClinic db =
    case selectedClinic of
        Just clinicId ->
            viewClinic language currentDate user clinicId db

        Nothing ->
            viewClinicList language user db


viewClinicList : Language -> Nurse -> ModelIndexedDb -> Html Msg
viewClinicList language user db =
    let
        content =
            viewWebData language
                (viewLoadedClinicList language user)
                identity
                (RemoteData.append db.clinics db.syncData)
    in
    div [ class "wrap wrap-alt-2" ]
        [ div
            [ class "ui basic head segment" ]
            [ h1 [ class "ui header" ]
                [ text <| translate language Translate.Groups ]
            , a
                [ class "link-back"
                , onClick <| SetActivePage PinCodePage
                ]
                [ span [ class "icon-back" ] []
                , span [] []
                ]
            ]
        , div
            [ class "ui basic segment" ]
            [ content ]
        ]


{-| This is the "inner" view function ... we get here if all the data was
actually available.

We only show clinics for the health centers that we are syncing. In principle,
we could show something about the sync status here ... might want to know how
up-to-date things are.

-}
viewLoadedClinicList : Language -> Nurse -> ( Dict ClinicId Clinic, Dict HealthCenterId SyncData ) -> Html Msg
viewLoadedClinicList language user ( clinics, sync ) =
    let
        title =
            p
                [ class "centered" ]
                [ text <| translate language Translate.SelectYourGroup
                , text ":"
                ]

        synced =
            clinics
                |> Dict.filter (\_ clinic -> Dict.member clinic.healthCenterId sync)
                |> Dict.toList
                |> List.sortBy (Tuple.second >> .name)
                |> Dict.fromList

        clinicView =
            synced
                |> Dict.toList
                |> List.map (viewClinicButton user)

        message =
            if Dict.isEmpty synced then
                div
                    [ class "ui message warning" ]
                    [ div [ class "header" ] [ text <| translate language Translate.NoGroupsFound ]
                    , text <| translate language Translate.HaveYouSynced
                    ]

            else
                emptyNode
    in
    div []
        [ title
        , div [] clinicView
        , message
        ]


viewClinicButton : Nurse -> ( ClinicId, Clinic ) -> Html Msg
viewClinicButton user ( clinicId, clinic ) =
    let
        classAttr =
            if assignedToClinic clinicId user then
                class "ui fluid primary button"

            else
                class "ui fluid primary dark disabled button"
    in
    button
        [ classAttr
        , onClick <| SetActivePage <| UserPage <| ClinicsPage <| Just clinicId
        ]
        [ text clinic.name ]


{-| View a specific clinic.
-}
viewClinic : Language -> NominalDate -> Nurse -> ClinicId -> ModelIndexedDb -> Html Msg
viewClinic language currentDate nurse clinicId db =
    let
        clinic =
            RemoteData.map (Dict.get clinicId) db.clinics

        sessions =
            db.sessionsByClinic
                |> Dict.get clinicId
                |> Maybe.withDefault NotAsked
    in
    viewWebData language
        (viewLoadedClinic language currentDate nurse clinicId)
        identity
        (RemoteData.append clinic sessions)


viewLoadedClinic : Language -> NominalDate -> Nurse -> ClinicId -> ( Maybe Clinic, Dict SessionId Session ) -> Html Msg
viewLoadedClinic language currentDate nurse clinicId ( clinic, sessions ) =
    case clinic of
        Just clinic_ ->
            div
                [ class "wrap wrap-alt-2" ]
                (viewFoundClinic language currentDate nurse clinicId clinic_ sessions)

        Nothing ->
            Pages.PageNotFound.View.viewPage language
                (SetActivePage <| UserPage <| ClinicsPage Nothing)
                (UserPage <| ClinicsPage <| Just clinicId)


{-| We show recent and upcoming sessions, with a link to dive into the session
if it is open. (That is, the dates are correct and it's not explicitly closed).
We'll show anything which was scheduled to start or end within the last week
or the next week.
-}
viewFoundClinic : Language -> NominalDate -> Nurse -> ClinicId -> Clinic -> Dict SessionId Session -> List (Html Msg)
viewFoundClinic language currentDate nurse clinicId clinic sessions =
    let
        daysToShow =
            7

        recentAndUpcomingSessions =
            sessions
                -- @todo
                -- Implement `delta`
                -- |> Dict.filter
                --     (\_ session ->
                --         let
                --             deltaToEndDate =
                --                 delta session.scheduledDate.end currentDate
                --
                --             deltaToStartDate =
                --                 delta session.scheduledDate.start currentDate
                --         in
                --         -- Ends last week or next week
                --         (abs deltaToEndDate.days <= daysToShow)
                --             || -- Starts last week or next week
                --                (abs deltaToStartDate.days <= daysToShow)
                --             || -- Is between start and end date
                --                (deltaToStartDate.days <= 0 && deltaToEndDate.days >= 0)
                --     )
                |> Dict.map (viewSession language currentDate)
                |> Dict.values

        content =
            if assignedToClinic clinicId nurse then
                [ h1 [] [ text <| translate language Translate.RecentAndUpcomingGroupEncounters ]
                , table
                    [ class "ui table session-list" ]
                    [ thead []
                        [ tr []
                            [ th [] [ text <| translate language Translate.StartDate ]
                            , th [] [ text <| translate language Translate.EndDate ]
                            , th [] [ text <| translate language Translate.Closed ]
                            ]
                        ]
                    , tbody [] recentAndUpcomingSessions
                    ]
                ]

            else
                [ div [ class "ui message error" ]
                    [ text <| translate language Translate.GroupUnauthorized ]
                ]
    in
    [ div
        [ class "ui basic head segment" ]
        [ h1
            [ class "ui header" ]
            [ text clinic.name ]
        , a
            [ class "link-back"
            , onClick <| SetActivePage <| UserPage <| ClinicsPage Nothing
            ]
            [ span [ class "icon-back" ] []
            , span [] []
            ]
        ]
    , div [ class "ui basic segment" ] content
    ]


viewSession : Language -> NominalDate -> SessionId -> Session -> Html Msg
viewSession language currentDate sessionId session =
    let
        enableLink =
            -- @todo
            -- Implement `delta`
            -- ((delta session.scheduledDate.start currentDate).days <= 0)
            --     && ((delta session.scheduledDate.end currentDate).days >= 0)
            not session.closed

        link =
            button
                [ classList
                    [ ( "ui button small", True )
                    , ( "disabled", not enableLink )
                    ]
                , SessionPage sessionId AttendancePage
                    |> UserPage
                    |> SetActivePage
                    |> onClick
                ]
                [ text <| translate language Translate.Attendance ]

        closed =
            if session.closed then
                [ i [ class "check icon" ] [] ]

            else
                []
    in
    tr []
        [ td [] [ text <| formatYYYYMMDD session.scheduledDate.start ]
        , td [] [ text <| formatYYYYMMDD session.scheduledDate.end ]
        , td [] closed
        , td [] [ link ]
        ]
