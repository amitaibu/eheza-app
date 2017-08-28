module Participant.View
    exposing
        ( getParticipantAge
        , renderParticipantAge
        , viewParticipantTypeFilter
        )

import Date exposing (Date)
import Date.Extra.Period
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, onWithOptions)
import Participant.Model exposing (AgeDay, Participant, ParticipantType(..), ParticipantTypeFilter(..))
import Translate as Trans exposing (translate, Language)


getParticipantAge : Participant -> Date -> AgeDay
getParticipantAge participant now =
    let
        birthDate =
            case participant.info of
                ParticipantChild child ->
                    child.birthDate

                ParticipantMother mother ->
                    mother.birthDate

        diff =
            Date.Extra.Period.diff birthDate now
    in
        Participant.Model.AgeDay diff.day


renderParticipantAge : Participant -> String
renderParticipantAge participant =
    let
        ageDay =
            getParticipantAge participant
    in
        "4 months and 2 days"


viewParticipantTypeFilter : Language -> (String -> msg) -> ParticipantTypeFilter -> Html msg
viewParticipantTypeFilter language msg participantTypeFilter =
    div []
        [ select
            [ class "ui dropdown"
            , value <| toString participantTypeFilter
            , onInput msg
            ]
            (List.map
                (\filterType ->
                    option
                        [ value <| toString filterType ]
                        [ text <| toString filterType ]
                )
                [ All, Children, Mothers ]
            )
        ]
