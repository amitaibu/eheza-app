module Pages.Activity.View exposing (view)

import Activity.Model exposing (ActivityType(..), ChildActivityType(..), MotherActivityType(..))
import Activity.Utils exposing (getActivityIdentity)
import App.PageType exposing (Page(..))
import Config.Model exposing (BackendUrl)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List as List
import Pages.Activity.Model exposing (Model, Msg(..), Tab(..))
import Translate as Trans exposing (translate, Language)
import User.Model exposing (User)
import Utils.Html exposing (tabItem)


view : BackendUrl -> String -> User -> Language -> Date -> Model -> List (Html Msg)
view backendUrl accessToken user language currentDate model =
    let
        identity =
            getActivityIdentity model.selectedActivity

        description =
            case identity.activityType of
                Child ChildPicture ->
                    Trans.ActivityChildPhotoDescription

                Child Height ->
                    Trans.ActivityHeightDescription

                Child Muac ->
                    Trans.ActivityMuacDescription

                Child NutritionSigns ->
                    Trans.ActivityNutritionSigns

                Child Weight ->
                    Trans.ActivityWeightDescription

                Mother FamilyPlanning ->
                    Trans.ActivityFamilyPlanningDescription

                _ ->
                    Trans.EmptyString

        activityDescription =
            div
                [ class "ui unstackable items" ]
                [ div [ class "item" ]
                    [ div [ class "ui image" ]
                        [ span [ class <| "icon-item icon-item-" ++ identity.icon ] [] ]
                    , div [ class "content" ]
                        [ p [] [ text <| translate language description ] ]
                    ]
                ]

        pendingParticipants =
            []

        completedParticipants =
            []

        pendingTabTitle =
            translate language <| Trans.ActivitiesToComplete <| List.length pendingParticipants

        completedTabTitle =
            translate language <| Trans.ActivitiesCompleted <| List.length completedParticipants

        tabs =
            div [ class "ui tabular menu" ]
                [ tabItem pendingTabTitle (model.selectedTab == Pending) (SetSelectedTab Pending)
                , tabItem completedTabTitle (model.selectedTab == Completed) (SetSelectedTab Completed)
                ]
    in
        [ activityDescription, tabs ]



-- let
--     allActivityList =
--         getActivityList currentDate model.participantTypeFilter participants
--
--     pendingActivities =
--         List.filter (\activity -> (Tuple.first activity.totals > 0)) allActivityList
--
--     noPendingActivities =
--         List.filter (\activity -> (Tuple.first activity.totals == 0)) allActivityList
--
--     tabItem tab activitiesList =
--         let
--             tabTitle =
--                 case tab of
--                     Pending ->
--                         Trans.ActivitiesToComplete
--
--                     Completed ->
--                         Trans.ActivitiesCompleted
--
--             tabClass tab =
--                 [ ( "item", True )
--                 , ( "active", model.activeTab == tab )
--                 ]
--         in
--             a
--                 [ classList <| tabClass tab
--                 , onClick <| SetActiveTab tab
--                 ]
--                 [ text <| translate language <| tabTitle <| List.length activitiesList ]
--
--     tabs =
--         div [ class "ui tabular menu" ]
--             [ tabItem Pending pendingActivities
--             , tabItem Completed noPendingActivities
--             ]
--
--     viewCard language identity =
--         div
--             [ class "card" ]
--             [ div
--                 [ class "image" ]
--                 [ span [ class <| "icon-task icon-task-" ++ identity.activity.icon ] [] ]
--             , div
--                 [ class "content" ]
--                 [ p [] [ text <| String.toUpper identity.activity.name ]
--                 , div
--                     [ class "ui tiny progress" ]
--                     [ div
--                         [ class "label" ]
--                         [ text <| translate language <| Trans.ReportCompleted identity.totals ]
--                     ]
--                 ]
--             ]
--
--     selectedActivies =
--         case model.activeTab of
--             Pending ->
--                 pendingActivities
--
--             Completed ->
--                 noPendingActivities
-- in
--     [ tabs
--     , div
--         [ class "ui full segment" ]
--         [ div [ class "content" ]
--             [ div [ class "ui four cards" ] <|
--                 List.map (viewCard language) selectedActivies
--             ]
--         , div [ class "actions" ]
--             [ button
--                 [ class "ui fluid button" ]
--                 [ text <| translate language Trans.EndSession ]
--             ]
--         ]
--     ]
