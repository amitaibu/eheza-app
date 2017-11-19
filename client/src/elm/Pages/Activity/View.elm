module Pages.Activity.View exposing (view)

import Activity.Utils exposing (getActivityIcon, onlyCheckedIn, childHasPendingActivity, motherHasPendingActivity)
import Backend.Session.Model exposing (EditableSession)
import EveryDict exposing (EveryDict)
import Gizra.Html exposing (emptyNode)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import List as List
import Pages.Activity.Model exposing (Model, Msg(..), Tab(..))
import Participant.Model exposing (Participant)
import Translate exposing (translate, Language)
import Utils.Html exposing (tabItem, thumbnailImage)


thumbnailDimensions : { height : Int, width : Int }
thumbnailDimensions =
    { width = 96
    , height = 96
    }


view : Participant id value activity -> Language -> NominalDate -> activity -> EditableSession -> Model id -> Html (Msg id)
view config language currentDate selectedActivity fullSession model =
    let
        checkedIn =
            onlyCheckedIn fullSession

        ( pendingParticipants, completedParticipants ) =
            config.getParticipants checkedIn
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

        participants =
            let
                ( selectedParticipants, emptySectionMessage ) =
                    case model.selectedTab of
                        Pending ->
                            ( pendingParticipants, translate language Translate.NoParticipantsPendingForThisActivity )

                        Completed ->
                            ( completedParticipants, translate language Translate.NoParticipantsCompletedForThisActivity )

                viewParticipantCard ( participantId, participant ) =
                    let
                        name =
                            config.getName participant

                        imageSrc =
                            config.getAvatarThumb participant

                        imageView =
                            thumbnailImage config.iconClass imageSrc name thumbnailDimensions.height thumbnailDimensions.width
                    in
                        div
                            [ classList
                                [ ( "participant card", True )
                                , ( "active", Just participantId == model.selectedParticipant )
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
                            |> List.sortBy (\( _, participant ) -> config.getName participant)
                            |> List.map viewParticipantCard
            in
                div
                    [ class "ui participant segment" ]
                    [ div [ class "ui four participant cards" ]
                        participantsCards
                    ]

        measurementsForm =
            -- TODO: Re-implement
            emptyNode

        {-
           case model.selectedParticipant of
               Just (ParticipantChildId childId) ->
                   getChild childId fullSession
                       |> Maybe.map
                           (\child ->
                               Measurement.View.viewChild language currentDate child selectedActivity
                           )
                       |> Maybe.withDefault emptyNode

               Just (ParticipantMotherId motherId) ->
                   Measurement.View.viewMother language selectedActivity

               Nothing ->
                   emptyNode
        -}
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
        div
            [ class "wrap" ]
            [ header
            , activityDescription
            , tabs
            , participants
            , measurementsForm
            ]
