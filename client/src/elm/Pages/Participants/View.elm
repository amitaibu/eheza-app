module Pages.Participants.View exposing (view)

import Activity.Utils exposing (getTotalsNumberPerActivity, participantHasPendingActivity)
import App.PageType exposing (Page(..))
import Dict
import Drupal.Restful exposing (fromEntityId)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, onWithOptions)
import Pages.Participants.Model exposing (Model, Msg(..), Tab(..), thumbnailDimensions)
import Participant.Model exposing (Participant, ParticipantId, ParticipantType(..), ParticipantTypeFilter(..), ParticipantsDict)
import Participant.Utils exposing (getParticipantAvatarThumb, getParticipantName, getParticipantTypeAsString)
import Translate as Trans exposing (translate, Language)
import Utils.Html exposing (tabItem, thumbnailImage)


view : Language -> ParticipantsDict -> Model -> List (Html Msg)
view language participantsDict model =
    let
        filterMothersByPendingActivity withPending participantId participant =
            case participant.info of
                ParticipantChild child ->
                    False

                ParticipantMother mother ->
                    let
                        children =
                            List.filterMap (\childId -> Dict.get (fromEntityId childId) participantsDict) mother.children

                        gotPendingActivity =
                            participantHasPendingActivity participant || List.any participantHasPendingActivity children
                    in
                        if withPending then
                            gotPendingActivity
                        else
                            not gotPendingActivity

        mothersWithPendingActivity =
            participantsDict
                |> Dict.filter (filterMothersByPendingActivity True)

        mothersWithoutPendingActivity =
            participantsDict
                |> Dict.filter (filterMothersByPendingActivity False)

        tabs =
            let
                pendingTabTitle =
                    translate language <| Trans.ActivitiesToComplete <| Dict.size mothersWithPendingActivity

                completedTabTitle =
                    translate language <| Trans.ActivitiesCompleted <| Dict.size mothersWithoutPendingActivity
            in
                div [ class "ui tabular menu" ]
                    [ tabItem pendingTabTitle (model.selectedTab == Pending) "pending" (SetSelectedTab Pending)
                    , tabItem completedTabTitle (model.selectedTab == Completed) "completed" (SetSelectedTab Completed)
                    ]

        mothers =
            let
                ( selectedMothers, emptySectionMessage ) =
                    case model.selectedTab of
                        Pending ->
                            ( mothersWithPendingActivity, translate language Trans.PendingSectionEmpty )

                        Completed ->
                            ( mothersWithoutPendingActivity, translate language Trans.CompletedSectionEmpty )

                viewMotherCard ( motherId, mother ) =
                    let
                        name =
                            getParticipantName mother

                        imageSrc =
                            getParticipantAvatarThumb mother

                        imageView =
                            thumbnailImage mother.info imageSrc name thumbnailDimensions.height thumbnailDimensions.width
                    in
                        div
                            [ class "card"
                            , onClick <| SetRedirectPage <| App.PageType.Participant motherId
                            ]
                            [ div [ class "image" ]
                                [ imageView ]
                            , div [ class "content" ]
                                [ p [] [ text name ] ]
                            ]

                mothersCards =
                    if Dict.size selectedMothers == 0 then
                        [ span [] [ text emptySectionMessage ] ]
                    else
                        List.map viewMotherCard <|
                            List.sortBy
                                (\( _, mother ) ->
                                    getParticipantName mother
                                )
                            <|
                                Dict.toList selectedMothers
            in
                div [ class "full content" ]
                    [ div [ class "wrap-cards" ]
                        [ div [ class "ui four cards" ]
                            mothersCards
                        ]
                    ]

        endSessionButton =
            div [ class "actions" ]
                [ button
                    [ class "ui fluid button" ]
                    [ text <| translate language Trans.EndSession ]
                ]

        content =
            div
                [ class "ui full segment" ]
                [ mothers, endSessionButton ]
    in
        [ tabs, content ]
