module ParticipantManager.View
    exposing
        ( viewActivities
        , viewPageActivity
        , viewPageParticipant
        , viewParticipants
        )

import Activity.Model exposing (ActivityType)
import Activity.Utils exposing (getActivityIdentity)
import App.PageType
import Date exposing (Date)
import Dict
import Drupal.Restful exposing (fromEntityId, toEntityId)
import Html exposing (..)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Pages.Activities.Model
import Pages.Activities.View
import Pages.Activity.Model
import Pages.Activity.View
import Pages.Participant.Model
import Pages.Participant.Update
import Pages.Participant.View
import Pages.Participants.Model
import Pages.Participants.View
import Participant.Model exposing (Participant, ParticipantId, ParticipantType(..), ParticipantTypeFilter(..), ParticipantsDict)
import ParticipantManager.Model exposing (..)
import ParticipantManager.Utils exposing (getChildren, getMother, getParticipant, unwrapParticipantsDict)
import RemoteData exposing (RemoteData(..))
import Translate as Trans exposing (Language, translate)
import Utils.WebData exposing (viewError)


{-| Show all Participants page.
-}
viewParticipants : Language -> Model -> Html Msg
viewParticipants language model =
    let
        participants =
            unwrapParticipantsDict model.participants
    in
        div [ class "wrap wrap-alt page-participants" ] <|
            viewDashboardPageHeader language App.PageType.ParticipantsDashboard
                :: (List.map (Html.map MsgPagesParticipants) <|
                        Pages.Participants.View.view language participants model.participantsPage
                   )


viewDashboardPageHeader : Language -> App.PageType.DashboardPage -> Html Msg
viewDashboardPageHeader language dashboardPage =
    let
        ( header, activitiesLinkAttributes, participantsLinkAttributes ) =
            case dashboardPage of
                App.PageType.ActivitiesDashboard ->
                    ( Trans.Activities
                    , [ class "active" ]
                    , [ onClick <|
                            MsgPagesActivities <|
                                Pages.Activities.Model.SetRedirectPage <|
                                    App.PageType.Dashboard []
                      ]
                    )

                App.PageType.ParticipantsDashboard ->
                    ( Trans.Participants
                    , [ onClick <|
                            MsgPagesParticipants <|
                                Pages.Participants.Model.SetRedirectPage App.PageType.Activities
                      ]
                    , [ class "active" ]
                    )
    in
        div
            [ class "ui basic head segment" ]
            [ h1
                [ class "ui header" ]
                [ text <| translate language header ]
            , a
                [ class "link-back" ]
                [ span [ class "icon-back" ] [] ]
            , ul
                [ class "links-head" ]
                [ li participantsLinkAttributes
                    [ a [] [ span [ class "icon-mother" ] [] ] ]
                , li activitiesLinkAttributes
                    [ a [] [ span [ class "icon-activity" ] [] ] ]
                ]
            ]


{-| Show the Participant page.

This one needs the `currentDate` to calculate ages.

-}
viewPageParticipant : Language -> Date -> ParticipantId -> Model -> Html Msg
viewPageParticipant language currentDate id model =
    case getParticipant id model of
        NotAsked ->
            -- This shouldn't happen, but if it does, we provide
            -- a button to load the editor
            div
                [ class "ui button"
                , onClick <| Subscribe id
                ]
                [ text <| translate language Trans.ReloadParticipant ]

        Loading ->
            div [] []

        Failure error ->
            div []
                [ viewError language error
                , div
                    [ class "ui button"
                    , onClick <| Subscribe id
                    ]
                    [ text <| translate language Trans.Retry ]
                ]

        Success participant ->
            let
                participantModel =
                    Maybe.map identity (Dict.get id model.participantPage)
                        |> Maybe.withDefault (Pages.Participant.Update.init participant)
            in
                div [ class "wrap" ] <|
                    viewPageParticipantHeader language ( id, participant )
                        :: (case participant.info of
                                ParticipantChild child ->
                                    let
                                        motherWebData =
                                            getMother child.motherId model
                                    in
                                        List.map (Html.map (MsgPagesParticipant id)) <|
                                            Pages.Participant.View.viewChild language currentDate motherWebData ( toEntityId id, child ) participantModel

                                ParticipantMother mother ->
                                    let
                                        childrenWebData =
                                            getChildren mother model
                                    in
                                        List.map (Html.map (MsgPagesParticipant id)) <|
                                            Pages.Participant.View.viewMother language (toEntityId id) mother childrenWebData participantModel
                           )


viewPageParticipantHeader : Language -> ( ParticipantId, Participant ) -> Html Msg
viewPageParticipantHeader language ( participantId, participant ) =
    let
        viewChild id maybeIndex active =
            let
                attributes =
                    if active then
                        [ class "active" ]
                    else
                        [ onClick <|
                            MsgPagesParticipant id <|
                                Pages.Participant.Model.SetRedirectPage (App.PageType.Participant id)
                        ]
            in
                li attributes
                    [ a [] <|
                        span [ class "icon-baby" ] []
                            :: case maybeIndex of
                                Just index ->
                                    [ span [ class "count" ] [ text <| toString (index + 1) ] ]

                                Nothing ->
                                    []
                    ]

        ( motherAttributes, children ) =
            case participant.info of
                ParticipantChild child ->
                    ( case child.motherId of
                        Just motherId ->
                            [ onClick <|
                                MsgPagesParticipant (fromEntityId motherId) <|
                                    Pages.Participant.Model.SetRedirectPage (App.PageType.Participant (fromEntityId motherId))
                            ]

                        Nothing ->
                            []
                    , List.indexedMap (\index childId -> viewChild childId (Just index) (childId == participantId)) <|
                        List.sort <|
                            participantId
                                :: case child.siblingId of
                                    Just siblingId ->
                                        [ fromEntityId siblingId ]

                                    Nothing ->
                                        []
                    )

                ParticipantMother mother ->
                    ( [ class "active" ]
                    , List.indexedMap (\index childId -> viewChild (fromEntityId childId) (Just index) False) mother.children
                    )
    in
        div
            [ class "ui basic head segment" ]
            [ h1
                [ class "ui header" ]
                [ text <| translate language Trans.Assessment ]
            , a
                [ class "link-back"
                , onClick <|
                    MsgPagesParticipant participantId <|
                        Pages.Participant.Model.SetRedirectPage <|
                            App.PageType.Dashboard []
                ]
                [ span [ class "icon-back" ] [] ]
            , ul
                [ class "links-head" ]
              <|
                li
                    motherAttributes
                    [ a []
                        [ span [ class "icon-mother" ] [] ]
                    ]
                    :: children
            ]


viewActivities : Language -> Model -> Html Msg
viewActivities language model =
    let
        participants =
            unwrapParticipantsDict model.participants
    in
        div [ class "wrap wrap-alt" ] <|
            viewDashboardPageHeader language App.PageType.ActivitiesDashboard
                :: (List.map (Html.map MsgPagesActivities) <|
                        Pages.Activities.View.view language participants model.activitiesPage
                   )


viewPageActivity : Language -> Date -> Maybe ActivityType -> Model -> Html Msg
viewPageActivity language currentDate maybeActivityType model =
    let
        activitytModel =
            case maybeActivityType of
                Just activityType ->
                    let
                        initialModel =
                            model.activityPage
                    in
                        { initialModel | selectedActivity = activityType }

                Nothing ->
                    model.activityPage

        participants =
            unwrapParticipantsDict model.participants
    in
        div [ class "wrap" ] <|
            viewPageActivityHeader activitytModel
                :: (List.map (Html.map MsgPagesActivity) <|
                        Pages.Activity.View.view language currentDate participants activitytModel
                   )


viewPageActivityHeader : Pages.Activity.Model.Model -> Html Msg
viewPageActivityHeader pageActivity =
    let
        identity =
            getActivityIdentity pageActivity.selectedActivity
    in
        div
            [ class "ui basic head segment" ]
            [ h1 [ class "ui header" ]
                [ text identity.name ]
            , a
                [ class "link-back"
                , onClick <|
                    MsgPagesActivity <|
                        Pages.Activity.Model.SetRedirectPage <|
                            App.PageType.Activities
                ]
                [ span [ class "icon-back" ] [] ]
            ]
