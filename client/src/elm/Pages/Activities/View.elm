module Pages.Activities.View exposing (view)

import Activity.Utils exposing (getActivityIcon, getActivityList)
import Backend.Session.Model exposing (EditableSession)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List as List
import Pages.Activities.Model exposing (Model, Msg(..), Tab(..))
import Pages.Page exposing (Page(..), SessionPage(..), UserPage(..))
import Translate as Trans exposing (Language, translate)
import Utils.Html exposing (tabItem, viewModal)


view : Language -> EditableSession -> Model -> Html Msg
view language session model =
    let
        allActivityList =
            getActivityList session

        pendingActivities =
            List.filter (\activity -> activity.totals.pending > 0) allActivityList

        noPendingActivities =
            List.filter (\activity -> activity.totals.pending == 0) allActivityList

        pendingTabTitle =
            translate language <| Trans.ActivitiesToComplete <| List.length pendingActivities

        completedTabTitle =
            translate language <| Trans.ActivitiesCompleted <| List.length noPendingActivities

        tabs =
            div [ class "ui tabular menu" ]
                [ tabItem pendingTabTitle (model.selectedTab == Pending) "pending" (SetSelectedTab Pending)
                , tabItem completedTabTitle (model.selectedTab == Completed) "completed" (SetSelectedTab Completed)
                ]

        viewCard language item =
            div
                [ class "card" ]
                [ div
                    [ class "image"
                    , onClick <| SetRedirectPage <| UserPage <| SessionPage <| ActivityPage item.activityType
                    ]
                    [ span [ class <| "icon-task icon-task-" ++ getActivityIcon item.activityType ] [] ]
                , div
                    [ class "content" ]
                    [ p [] [ text <| String.toUpper <| translate language (Trans.ActivitiesTitle item.activityType) ]
                    , div
                        [ class "ui tiny progress" ]
                        [ div
                            [ class "label" ]
                            [ text <| translate language <| Trans.ReportCompleted item.totals ]
                        ]
                    ]
                ]

        endSessionDialog =
            if model.showEndSessionDialog then
                Just <|
                    div [ class "ui tiny active modal" ]
                        [ div
                            [ class "header" ]
                            [ text <| translate language Trans.AreYouSure ]
                        , div
                            [ class "content" ]
                            [ p []
                                [ text <| translate language Trans.OnceYouEndYourSession ]
                            ]
                        , div
                            [ class "actions" ]
                            [ div
                                [ class "two ui buttons" ]
                                [ button
                                    [ class "ui fluid button"
                                    , onClick <| ShowEndSessionDialog False
                                    ]
                                    [ text <| translate language Trans.Cancel ]
                                , button
                                    [ class "ui primary fluid button"
                                    , onClick CloseSession
                                    ]
                                    [ text <| translate language Trans.Continue ]
                                ]
                            ]
                        ]

            else
                Nothing

        ( selectedActivities, emptySectionMessage ) =
            case model.selectedTab of
                Pending ->
                    ( pendingActivities, translate language Trans.NoActivitiesPending )

                Completed ->
                    ( noPendingActivities, translate language Trans.NoActivitiesCompleted )
    in
    div
        [ class "wrap wrap-alt-2" ]
        [ div
            [ class "ui basic head segment" ]
            [ h1
                [ class "ui header" ]
                [ text <| translate language Trans.Activities ]
            , a
                [ class "link-back"
                , onClick <| SetRedirectPage <| UserPage <| ClinicsPage <| Just session.offlineSession.session.clinicId
                ]
                [ span [ class "icon-back" ] []
                , span [] []
                ]
            , ul [ class "links-head" ]
                [ li
                    [ onClick <| SetRedirectPage <| UserPage <| SessionPage AttendancePage ]
                    [ a [] [ span [ class "icon-completed" ] [] ] ]
                , li
                    [ onClick <| SetRedirectPage <| UserPage <| SessionPage ParticipantsPage ]
                    [ a [] [ span [ class "icon-mother" ] [] ] ]
                , li
                    [ class "active" ]
                    [ a [] [ span [ class "icon-measurements" ] [] ] ]
                ]
            ]
        , tabs
        , div
            [ class "ui full segment" ]
            [ div
                [ class "full content" ]
                [ div [ class "wrap-cards" ]
                    [ div [ class "ui four cards" ] <|
                        if List.isEmpty selectedActivities then
                            [ span [] [ text emptySectionMessage ] ]

                        else
                            List.map (viewCard language) selectedActivities
                    ]
                ]
            , div
                [ class "actions" ]
                [ button
                    [ class "ui fluid primary button"
                    , onClick <| ShowEndSessionDialog True
                    ]
                    [ text <| translate language Trans.EndSession ]
                ]
            ]
        , viewModal endSessionDialog
        ]
