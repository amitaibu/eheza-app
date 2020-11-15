module Backend.IndividualEncounterParticipant.Update exposing (update)

import Backend.Endpoints exposing (individualEncounterParticipantEndpoint)
import Backend.Entities exposing (IndividualEncounterParticipantId)
import Backend.IndividualEncounterParticipant.Encoder exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (..)
import Gizra.NominalDate exposing (NominalDate, encodeYYYYMMDD)
import Json.Encode exposing (object)
import Json.Encode.Extra
import Maybe.Extra exposing (unwrap)
import RemoteData exposing (RemoteData(..))
import Restful.Endpoint exposing (applyBackendUrl, toCmd, withoutDecoder)


update : IndividualEncounterParticipantId -> Maybe IndividualEncounterParticipant -> NominalDate -> Msg -> Model -> ( Model, Cmd Msg )
update participantId maybeParticipant currentDate msg model =
    let
        sw =
            applyBackendUrl "/sw"
    in
    case msg of
        ClosePrenatalSession concludedDate outcome isFacilityDelivery ->
            maybeParticipant
                |> unwrap ( model, Cmd.none )
                    (\participant ->
                        ( { model | closePrenatalSession = Loading }
                        , object
                            [ ( "expected"
                              , object
                                    [ ( "value", encodeYYYYMMDD participant.startDate )
                                    , ( "value2", encodeYYYYMMDD currentDate )
                                    ]
                              )
                            , ( "date_concluded", encodeYYYYMMDD concludedDate )
                            , ( "outcome", encodePregnancyOutcome outcome )
                            , ( "outcome_location", encodeDeliveryLocation isFacilityDelivery )
                            ]
                            |> sw.patchAny individualEncounterParticipantEndpoint participantId
                            |> withoutDecoder
                            |> toCmd (RemoteData.fromResult >> HandleClosedPrenatalSession)
                        )
                    )

        HandleClosedPrenatalSession data ->
            ( { model | closePrenatalSession = data }
            , Cmd.none
            )

        CloseAcuteIllnessSession outcome ->
            maybeParticipant
                |> unwrap ( model, Cmd.none )
                    (\participant ->
                        ( { model | closePrenatalSession = Loading }
                        , object
                            [ ( "expected"
                              , object
                                    [ ( "value", encodeYYYYMMDD participant.startDate )
                                    , ( "value2", encodeYYYYMMDD currentDate )
                                    ]
                              )
                            , ( "outcome", encodeAcuteIllnessOutcome outcome )
                            ]
                            |> sw.patchAny individualEncounterParticipantEndpoint participantId
                            |> withoutDecoder
                            |> toCmd (RemoteData.fromResult >> HandleClosedPrenatalSession)
                        )
                    )

        HandleClosedAcuteIllnessSession data ->
            ( { model | closeAcuteIllnessSession = data }
            , Cmd.none
            )

        SetEddDate eddDate ->
            maybeParticipant
                |> unwrap ( model, Cmd.none )
                    (\participant ->
                        ( { model | setEddDate = Loading }
                        , object
                            [ ( "expected_date_concluded", encodeYYYYMMDD eddDate )
                            ]
                            |> sw.patchAny individualEncounterParticipantEndpoint participantId
                            |> withoutDecoder
                            |> toCmd (RemoteData.fromResult >> HandleSetEddDate)
                        )
                    )

        HandleSetEddDate data ->
            ( { model | setEddDate = data }
            , Cmd.none
            )
