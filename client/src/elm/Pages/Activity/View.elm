module Pages.Activity.View exposing (view)

import Activity.Utils exposing (childHasPendingActivity, getActivityIcon, motherHasPendingActivity, onlyCheckedIn)
import Backend.Session.Model exposing (EditableSession)
import EveryDict exposing (EveryDict)
import Gizra.Html exposing (divKeyed, emptyNode, keyed, keyedDivKeyed)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List as List
import Pages.Activity.Model exposing (Model, Msg(..), Tab(..))
import Pages.Activity.Utils exposing (selectParticipantForTab)
import Pages.Utils exposing (filterDependentNoResultsMessage, matchFilter, normalizeFilter, viewNameFilter)
import Participant.Model exposing (Participant)
import Translate exposing (Language, translate)
import Utils.Html exposing (tabItem, thumbnailImage)
import ZScore.Model


thumbnailDimensions : { height : Int, width : Int }
thumbnailDimensions =
    { width = 96
    , height = 96
    }


view : Participant id value activity msg -> Language -> NominalDate -> ZScore.Model.Model -> activity -> EditableSession -> Model id -> Html (Msg id msg)
view config language currentDate zscores selectedActivity fullSession model =
    let
        checkedIn =
            onlyCheckedIn fullSession

        filter =
            normalizeFilter model.filter

        ( pendingParticipants, completedParticipants ) =
            config.getParticipants checkedIn
                |> EveryDict.filter (\_ participant -> participant |> config.getName |> matchFilter filter)
                |> EveryDict.partition (\id _ -> config.hasPendingActivity id selectedActivity checkedIn)

        activityDescription =
            div
                [ class "ui unstackable items" ]
                [ div [ class "item" ]
                    [ div [ class "ui image" ]
                        [ span [ class <| "icon-item icon-item-" ++ getActivityIcon (config.tagActivityType selectedActivity) ] [] ]
                    , div [ class "content" ]
                        [ p [] [ text <| translate language <| Translate.ActivitiesHelp <| config.tagActivityType selectedActivity ] ]
                    ]
                ]

        tabs =
            let
                pendingTabTitle =
                    EveryDict.size pendingParticipants
                        |> Translate.ActivitiesToComplete
                        |> translate language

                completedTabTitle =
                    EveryDict.size completedParticipants
                        |> Translate.ActivitiesCompleted
                        |> translate language
            in
            div [ class "ui tabular menu" ]
                [ tabItem pendingTabTitle (model.selectedTab == Pending) "pending" (SetSelectedTab Pending)
                , tabItem completedTabTitle (model.selectedTab == Completed) "completed" (SetSelectedTab Completed)
                ]

        -- We compute this so that it's consistent with the tab
        selectedParticipant =
            selectParticipantForTab config model.selectedTab selectedActivity fullSession model.selectedParticipant

        participants =
            let
                ( selectedParticipants, emptySectionMessage ) =
                    case model.selectedTab of
                        Pending ->
                            ( pendingParticipants, filterDependentNoResultsMessage language filter Translate.NoParticipantsPendingForThisActivity )

                        Completed ->
                            ( completedParticipants, filterDependentNoResultsMessage language filter Translate.NoParticipantsCompletedForThisActivity )

                viewParticipantCard ( participantId, participant ) =
                    let
                        name =
                            config.getName participant

                        imageSrc =
                            config.getAvatarUrl participant

                        imageView =
                            thumbnailImage (config.iconClass ++ " rounded") imageSrc name thumbnailDimensions.height thumbnailDimensions.width
                    in
                    div
                        [ classList
                            [ ( "participant card", True )
                            , ( "active", Just participantId == selectedParticipant )
                            ]
                        , Just participantId
                            |> SetSelectedParticipant
                            |> onClick
                        ]
                        [ div
                            [ class "image" ]
                            [ imageView ]
                        , div [ class "content" ]
                            [ p [] [ text <| config.getName participant ] ]
                        ]

                participantsCards =
                    if EveryDict.size selectedParticipants == 0 then
                        [ span [] [ text emptySectionMessage ] ]

                    else
                        selectedParticipants
                            |> EveryDict.toList
                            |> List.sortBy (Tuple.second >> config.getName)
                            |> List.map viewParticipantCard
            in
            div
                [ class "ui participant segment" ]
                [ viewNameFilter language model.filter SetFilter
                , div [ class "ui four participant cards" ]
                    participantsCards
                ]

        measurementsForm =
            case selectedParticipant of
                Just id ->
                    -- This is a convenience for the way the code was structured ... ideally,
                    -- we'd build a `viewMeasurements` on top of smaller capabilities of the
                    -- `Participant` config, but this is faster for now.
                    config.viewMeasurements language currentDate zscores id selectedActivity checkedIn

                Nothing ->
                    emptyNode

        header =
            div
                [ class "ui basic head segment" ]
                [ h1 [ class "ui header" ]
                    [ config.tagActivityType selectedActivity
                        |> Translate.ActivitiesTitle
                        |> translate language
                        |> text
                    ]
                , a
                    [ class "link-back"
                    , onClick GoBackToActivitiesPage
                    ]
                    [ span [ class "icon-back" ] [] ]
                ]
    in
    divKeyed
        [ class "wrap page-activity" ]
        [ header |> keyed "header"
        , activityDescription |> keyed "activity-description"
        , tabs |> keyed "tabs"
        , participants |> keyed "participants"
        , measurementsForm |> keyed "measurements-form"
        ]
