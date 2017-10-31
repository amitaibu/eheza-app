module Pages.Participant.View
    exposing
        ( viewChild
        , viewMother
        )

import Activity.Model exposing (ActivityListItem, ActivityType(..))
import Activity.Utils exposing (getActivityList)
import Backend.Child.Model exposing (Child, Gender(..))
import Backend.Entities exposing (..)
import Backend.Mother.Model exposing (Mother)
import Date exposing (Date)
import EveryDict
import Gizra.Html exposing (emptyNode)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (onClick)
import Measurement.View
import Pages.Participant.Model exposing (Model, Msg(..), Tab(..), thumbnailDimensions)
import Participant.Model exposing (Participant(..), ParticipantId(..), ParticipantTypeFilter(..), ParticipantsDict)
import Participant.Utils exposing (renderParticipantAge, renderParticipantDateOfBirth)
import ProgressReport.View exposing (viewProgressReport)
import RemoteData exposing (RemoteData(..), WebData)
import Translate as Trans exposing (Language, translate)
import Utils.Html exposing (tabItem, thumbnailImage)


thumbnailDimensions : { width : Int, height : Int }
thumbnailDimensions =
    { width = 222
    , height = 222
    }


{-| This one needs the `currentDate` in order to calculate ages from dates of birth.
-}
viewChild : Language -> Date -> ChildId -> EditableSession -> Model -> Html Msg
viewChild language currentDate childId session model =
    let
        childParticipant =
            ParticipantChild child

        participants =
            EveryDict.insert (ParticipantChildId childId) childParticipant EveryDict.empty

        childName =
            translate language <| Trans.BabyName child.name

        motherInfo =
            case child.motherId of
                Nothing ->
                    []

                Just motherId ->
                    case motherWebData of
                        Success mother ->
                            [ text <| translate language <| Trans.MotherName mother.name ]

                        _ ->
                            []

        dateOfBirth =
            text <| translate language <| Trans.ReportDOB <| renderParticipantDateOfBirth language childParticipant

        age =
            text <| translate language <| Trans.ReportAge <| renderParticipantAge language childParticipant currentDate

        gender =
            case child.gender of
                Male ->
                    text <| translate language <| Trans.Male

                Female ->
                    text <| translate language <| Trans.Female

        break =
            br [] []

        content =
            if model.selectedTab == ProgressReport then
                [ viewProgressReport language ( childId, child ) ]
            else
                [ Html.map MsgMeasurement <|
                    Measurement.View.viewChild language currentDate ( childId, child ) (getLastExaminationFromChild child) model.selectedActivity model.measurements
                ]
    in
        div [ class "ui unstackable items participant-page child" ]
            [ div [ class "item" ]
                [ div [ class "ui image" ]
                    [ thumbnailImage (ParticipantChild child) child.image childName thumbnailDimensions.height thumbnailDimensions.width ]
                , div [ class "content" ]
                    [ h2 [ class "ui header" ]
                        [ text childName ]
                    , p [] <|
                        motherInfo
                            ++ [ break, dateOfBirth, break, age, break, gender ]
                    ]
                ]
            ]
            :: ((viewActivityCards language participants Children model.selectedTab model.selectedActivity)
                    ++ content
               )


viewMother : Language -> MotherId -> EditableSession -> Model -> List (Html Msg)
viewMother language motherId session model =
    let
        break =
            br [] []

        childrenList =
            List.intersperse break <|
                List.indexedMap
                    (\index childWebData ->
                        case childWebData of
                            Success ( childId, child ) ->
                                text <| (translate language Trans.Baby) ++ " " ++ toString (index + 1) ++ ": " ++ child.name

                            _ ->
                                text ""
                    )
                    children

        participants =
            EveryDict.insert (ParticipantMotherId motherId) (ParticipantMother mother) EveryDict.empty
    in
        div [ class "ui unstackable items participant-page mother" ]
            [ div [ class "item" ]
                [ div [ class "ui image" ]
                    [ thumbnailImage (ParticipantMother mother) mother.image mother.name thumbnailDimensions.height thumbnailDimensions.width ]
                , div [ class "content" ]
                    [ h2 [ class "ui header" ]
                        [ text mother.name ]
                    , p [] childrenList
                    ]
                ]
            ]
            :: ((viewActivityCards language participants Mothers model.selectedTab model.selectedActivity)
                    ++ [ Html.map MsgMeasurement <|
                            Measurement.View.viewMother language model.selectedActivity model.measurements
                       ]
               )


viewActivityCards : Language -> ParticipantTypeFilter -> Tab -> Maybe ActivityType -> EditableSession -> Html Msg
viewActivityCards language participantTypeFilter selectedTab selectedActivity session =
    let
        allActivityList =
            getActivityList participantTypeFilter participants

        pendingActivities =
            List.filter (\activity -> (Tuple.first activity.totals) > 0) allActivityList

        noPendingActivities =
            List.filter (\activity -> (Tuple.first activity.totals) == 0) allActivityList

        pendingActivitiesView =
            if List.isEmpty pendingActivities then
                [ span [] [ text <| translate language Trans.PendingSectionEmpty ] ]
            else
                List.map (viewActivityListItem language selectedActivity) pendingActivities

        noPendingActivitiesView =
            if List.isEmpty noPendingActivities then
                [ span [] [ text <| translate language Trans.CompletedSectionEmpty ] ]
            else
                List.map (viewActivityListItem language selectedActivity) noPendingActivities

        activeView =
            if selectedTab == ProgressReport then
                emptyNode
            else
                div [ class "ui task segment" ]
                    [ div [ class "ui five column grid" ] <|
                        if selectedTab == Pending then
                            pendingActivitiesView
                        else
                            noPendingActivitiesView
                    ]

        pendingTabTitle =
            translate language <| Trans.ActivitiesToComplete <| List.length pendingActivities

        completedTabTitle =
            translate language <| Trans.ActivitiesCompleted <| List.length noPendingActivities

        progressTabTitle =
            translate language Trans.ActivitiesProgressReport

        extraTabs =
            if participantTypeFilter == Children then
                [ tabItem progressTabTitle (selectedTab == ProgressReport) "progressreport" (SetSelectedTab ProgressReport) ]
            else
                []

        tabs =
            div [ class "ui tabular menu" ] <|
                [ tabItem pendingTabTitle (selectedTab == Pending) "pending" (SetSelectedTab Pending)
                , tabItem completedTabTitle (selectedTab == Completed) "completed" (SetSelectedTab Completed)
                ]
                    ++ extraTabs
    in
        [ tabs, activeView ]


viewActivityListItem : Language -> Maybe ActivityType -> ActivityListItem -> Html Msg
viewActivityListItem language selectedActivity report =
    let
        clickHandler =
            onClick <| SetSelectedActivity (Just <| report.activity.activityType)
    in
        div [ class "column" ]
            [ a
                [ clickHandler
                , classList [ ( "link-section", True ), ( "active", selectedActivity == (Just <| report.activity.activityType) ) ]
                ]
                [ span [ class ("icon-section icon-" ++ report.activity.icon) ] []
                , text report.activity.name
                ]
            ]
