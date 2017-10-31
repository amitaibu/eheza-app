module Pages.Participant.View
    exposing
        ( viewChild
        , viewMother
        )

import Activity.Model exposing (ActivityListItem, ActivityType(..), ChildActivityType, MotherActivityType(..))
import Activity.Utils exposing (getActivityList, getActivityIcon, getAllChildActivities, getAllMotherActivities, motherHasPendingActivity, childHasPendingActivity)
import Backend.Child.Model exposing (Child, Gender(..))
import Backend.Entities exposing (..)
import Backend.Mother.Model exposing (Mother)
import Backend.Session.Model exposing (EditableSession)
import Backend.Session.Utils exposing (getChild, getMother, getMyMother, getChildren)
import Date exposing (Date)
import EveryDict
import Gizra.Html exposing (emptyNode)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (onClick)
import Maybe.Extra
import Measurement.Model
import Measurement.View
import Pages.Participant.Model exposing (Model, Msg(..), Tab(..))
import Participant.Model exposing (Participant(..), ParticipantId(..), ParticipantTypeFilter(..))
import Participant.Utils exposing (renderAgeMonthsDays, renderDateOfBirth)
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
viewChild : Language -> NominalDate -> ( ChildId, Child ) -> EditableSession -> Model ChildActivityType -> Html (Msg ChildActivityType Measurement.Model.MsgChild)
viewChild language currentDate ( childId, child ) session model =
    let
        childName =
            translate language <|
                Trans.BabyName child.name

        maybeMother =
            child.motherId
                |> Maybe.andThen (\motherId -> getMother motherId session.offlineSession)

        motherInfo =
            maybeMother
                |> Maybe.map (\mother -> text <| translate language <| Trans.MotherName mother.name)
                |> Maybe.Extra.toList

        dateOfBirth =
            renderDateOfBirth language child.birthDate
                |> Trans.ReportDOB
                |> translate language
                |> text

        age =
            renderAgeMonthsDays language child.birthDate currentDate
                |> Trans.ReportAge
                |> translate language
                |> text

        gender =
            child.gender
                |> Trans.Gender
                |> translate language
                |> text

        break =
            br [] []

        content =
            if model.selectedTab == ProgressReport then
                [ viewProgressReport language childId session ]
            else
                [ Html.map MsgMeasurement <|
                    Debug.crash "implement"

                --                   Measurement.View.viewChild language currentDate ( childId, child ) (getLastExaminationFromChild child) model.selectedActivity model.measurements
                ]
    in
        div [ class "wrap" ] <|
            [ viewHeader childConfig language childId session
            , div [ class "ui unstackable items participant-page child" ]
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
            ]
                ++ (viewActivityCards childConfig language childId model.selectedTab model.selectedActivity session)
                ++ content


viewMother : Language -> ( MotherId, Mother ) -> EditableSession -> Model MotherActivityType -> Html (Msg MotherActivityType Measurement.Model.MsgMother)
viewMother language ( motherId, mother ) session model =
    let
        break =
            br [] []

        childrenList =
            getChildren motherId session.offlineSession
                |> List.indexedMap
                    (\index ( _, child ) ->
                        text <| (translate language Trans.Baby) ++ " " ++ toString (index + 1) ++ ": " ++ child.name
                    )
                |> List.intersperse break
    in
        div [ class "wrap" ] <|
            [ viewHeader motherConfig language motherId session
            , div
                [ class "ui unstackable items participant-page mother" ]
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
            ]
                ++ (viewActivityCards motherConfig language motherId model.selectedTab model.selectedActivity session)
                ++ [ Html.map MsgMeasurement <|
                        Debug.crash "implement"

                   --                            Measurement.View.viewMother language model.selectedActivity model.measurements
                   ]


{-| Several functions below work with either mothers or children. To support that,
we provide a typeclass-like config which are specialized to the relevant types.
-}
type alias ParticipantConfig participantId activityType =
    { activities : List activityType
    , getMotherId : participantId -> EditableSession -> Maybe MotherId
    , hasPendingActivity : participantId -> activityType -> EditableSession -> Bool
    , showProgressReportTab : Bool
    , wrapActivityType : activityType -> ActivityType
    , wrapParticipantId : participantId -> ParticipantId
    }


childConfig : ParticipantConfig ChildId ChildActivityType
childConfig =
    { activities = getAllChildActivities
    , getMotherId = \childId session -> getMyMother childId session.offlineSession |> Maybe.map Tuple.first
    , hasPendingActivity = childHasPendingActivity
    , showProgressReportTab = True
    , wrapActivityType = ChildActivity
    , wrapParticipantId = ParticipantChildId
    }


motherConfig : ParticipantConfig MotherId MotherActivityType
motherConfig =
    { activities = getAllMotherActivities
    , getMotherId = \motherId session -> Just motherId
    , hasPendingActivity = motherHasPendingActivity
    , showProgressReportTab = False
    , wrapActivityType = MotherActivity
    , wrapParticipantId = ParticipantMotherId
    }


viewActivityCards : ParticipantConfig participantId activityType -> Language -> participantId -> Tab -> Maybe activityType -> EditableSession -> List (Html (Msg activityType any))
viewActivityCards config language participantId selectedTab selectedActivity session =
    let
        ( pendingActivities, completedActivities ) =
            List.partition (\activity -> config.hasPendingActivity participantId activity session) config.activities

        pendingActivitiesView =
            if List.isEmpty pendingActivities then
                [ span [] [ text <| translate language Trans.PendingSectionEmpty ] ]
            else
                List.map (viewActivityListItem config language selectedActivity) pendingActivities

        completedActivitiesView =
            if List.isEmpty completedActivities then
                [ span [] [ text <| translate language Trans.CompletedSectionEmpty ] ]
            else
                List.map (viewActivityListItem config language selectedActivity) completedActivities

        activeView =
            if selectedTab == ProgressReport then
                emptyNode
            else
                div [ class "ui task segment" ]
                    [ div [ class "ui five column grid" ] <|
                        if selectedTab == Pending then
                            pendingActivitiesView
                        else
                            completedActivitiesView
                    ]

        pendingTabTitle =
            translate language <| Trans.ActivitiesToComplete <| List.length pendingActivities

        completedTabTitle =
            translate language <| Trans.ActivitiesCompleted <| List.length completedActivities

        progressTabTitle =
            translate language <| Trans.ActivitiesTitle <| ChildActivity Activity.Model.ProgressReport

        extraTabs =
            if config.showProgressReportTab then
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


viewActivityListItem : ParticipantConfig participantId activityType -> Language -> Maybe activityType -> activityType -> Html (Msg activityType any)
viewActivityListItem config language selectedActivity activityItem =
    div [ class "column" ]
        [ a
            [ onClick <| SetSelectedActivity activityItem
            , classList
                [ ( "link-section", True )
                , ( "active", selectedActivity == Just activityItem )
                ]
            ]
            [ span [ class ("icon-section icon-" ++ getActivityIcon (config.wrapActivityType activityItem)) ] []
            , text <| translate language <| Trans.ActivitiesTitle <| config.wrapActivityType activityItem
            ]
        ]


{-| Given a mother or a child, this figures out who the whole family is, and shows a header allowing
you to switch between any family member.
-}
viewHeader : ParticipantConfig participantId activityType -> Language -> participantId -> EditableSession -> Html (Msg activityType any)
viewHeader config language participantId session =
    let
        -- Whether we've looking at a child or a mother, we figure out who the
        -- mother is. This will never be `Nothing` so long as the
        -- `EditableSession` is consistent, but it would be difficult to
        -- convince the compiler of that.
        maybeMotherId =
            config.getMotherId participantId session

        -- Whether we're originally given a mother or a child, we figure out who all the
        -- children are, by looking at the motherId we got.
        children =
            maybeMotherId
                |> Maybe.map (\motherId -> getChildren motherId session.offlineSession)
                |> Maybe.withDefault []
                |> List.map Tuple.first

        -- Generate markup for each child
        childrenMarkup =
            List.indexedMap viewChild children

        viewChild index childId =
            let
                -- This determines whether this child is the one we were given
                active =
                    config.wrapParticipantId participantId == ParticipantChildId childId

                attributes =
                    if active then
                        [ class "active" ]
                    else
                        [ onClick <|
                            Debug.crash "redo"

                        {-
                           MsgPagesParticipant (Debug.crash "id") <|
                               Pages.Participant.Model.SetRedirectPage
                                   (App.PageType.Participant (Debug.crash "id"))
                        -}
                        ]
            in
                li attributes
                    [ a []
                        [ span [ class "icon-baby" ] []
                        , span
                            [ class "count" ]
                            [ text <| toString (index + 1) ]
                        ]
                    ]

        motherMarkup =
            Maybe.map viewMother maybeMotherId
                |> Maybe.Extra.toList

        -- Generate the markup for the mother, given a definite motherId
        viewMother motherId =
            let
                -- Figures out whether we're actually looking at this mother
                active =
                    config.wrapParticipantId participantId == ParticipantMotherId motherId

                attributes =
                    if active then
                        [ class "active" ]
                    else
                        [ onClick <|
                            Debug.crash "redo"

                        {-
                           MsgPagesParticipant (Debug.crash "motherId") <|
                               Pages.Participant.Model.SetRedirectPage (App.PageType.Participant (fromEntityId motherId))
                        -}
                        ]
            in
                li attributes
                    [ a []
                        [ span [ class "icon-mother" ] []
                        ]
                    ]
    in
        div
            [ class "ui basic head segment" ]
            [ h1
                [ class "ui header" ]
                [ text <| translate language Trans.Assessment ]
            , a
                [ class "link-back"
                , onClick <|
                    Debug.crash "redo"

                {-
                   MsgPagesParticipant participantId <|
                       Pages.Participant.Model.SetRedirectPage <|
                           App.PageType.Dashboard []
                -}
                ]
                [ span [ class "icon-back" ] [] ]
            , ul
                [ class "links-head" ]
                (motherMarkup ++ childrenMarkup)
            ]
