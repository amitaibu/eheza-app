module Pages.Participants.View exposing (view)

import Activity.Utils exposing (getTotalsNumberPerActivity, motherOrAnyChildHasAnyPendingActivity)
import Backend.Session.Model exposing (OfflineSession, EditableSession)
import EveryDictList
import Html exposing (..)
import Html.Attributes exposing (..)
import Pages.Participants.Model exposing (Model, Msg(..), Tab(..))
import Pages.Utils exposing (viewDashboardPageHeader, DashboardPage(..))
import Participant.Model exposing (Participant(..), ParticipantId(..), ParticipantTypeFilter(..))
import Translate as Trans exposing (translate, Language)
import Utils.Html exposing (tabItem, thumbnailImage)


thumbnailDimensions : { width : Int, height : Int }
thumbnailDimensions =
    { width = 122
    , height = 122
    }


view : Language -> EditableSession -> Model -> Html Msg
view language editableSession model =
    let
        allMothers =
            editableSession.offlineSession.mothers

        ( mothersWithPendingActivity, mothersWithoutPendingActivity ) =
            EveryDictList.partition (\motherId _ -> motherOrAnyChildHasAnyPendingActivity motherId editableSession) allMothers

        tabs =
            let
                pendingTabTitle =
                    EveryDictList.size mothersWithPendingActivity
                        |> Trans.ActivitiesToComplete
                        |> translate language

                completedTabTitle =
                    EveryDictList.size mothersWithoutPendingActivity
                        |> Trans.ActivitiesCompleted
                        |> translate language
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
                    div
                        [ class "card"
                        , Debug.crash "redo"

                        {-
                           , App.PageType.PageMother motherId
                               |> SetRedirectPage
                               |> onClick
                        -}
                        ]
                        [ div
                            [ class "image" ]
                            [ thumbnailImage (ParticipantMother mother) mother.image mother.name thumbnailDimensions.height thumbnailDimensions.width ]
                        , div
                            [ class "content" ]
                            [ p [] [ text mother.name ] ]
                        ]

                mothersCards =
                    if EveryDictList.size selectedMothers == 0 then
                        [ span [] [ text emptySectionMessage ] ]
                    else
                        selectedMothers
                            |> EveryDictList.toList
                            |> List.sortBy (\( _, mother ) -> mother.name)
                            |> List.map viewMotherCard
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
        div
            [ class "wrap wrap-alt page-participants" ]
            [ viewDashboardPageHeader SetRedirectPage language ParticipantsDashboard
            , tabs
            , content
            ]
