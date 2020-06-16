module Measurement.Utils exposing (fromChildMeasurementData, fromMotherMeasurementData, getChildForm, getInputConstraintsHeight, getInputConstraintsMuac, getInputConstraintsWeight, getMotherForm, resolvePreviousValueInCommonContext)

import Activity.Utils exposing (expectCounselingActivity, expectParticipantConsent)
import AssocList as Dict exposing (Dict)
import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (..)
import Backend.Measurement.Utils exposing (currentValue, currentValues, fbfValueToForm, lactationSignsToForm, mapMeasurementData)
import Backend.Session.Model exposing (EditableSession)
import Backend.Session.Utils exposing (getChildMeasurementData, getMotherMeasurementData)
import EverySet
import Gizra.NominalDate exposing (NominalDate)
import LocalData
import Measurement.Model exposing (..)
import Pages.Session.Model


getInputConstraintsHeight : FloatInputConstraints
getInputConstraintsHeight =
    { minVal = 25
    , maxVal = 250
    }


getInputConstraintsMuac : FloatInputConstraints
getInputConstraintsMuac =
    { minVal = 5
    , maxVal = 99
    }


getInputConstraintsWeight : FloatInputConstraints
getInputConstraintsWeight =
    { minVal = 0.5
    , maxVal = 200
    }


{-| Initialize (or reset) a form with the given data.
-}
fromChildMeasurementData : MeasurementData ChildMeasurements -> ModelChild
fromChildMeasurementData data =
    -- TODO: Clearly there is some kind of pattern below, but we won't try to abstract that
    -- just yet. Ultimately, this is the kind of thing which `RestfulData` would organize.
    { height =
        data
            |> mapMeasurementData .height
            |> currentValue
            |> Maybe.map (.value >> (\(HeightInCm cm) -> String.fromFloat cm))
            |> Maybe.withDefault ""
    , muac =
        data
            |> mapMeasurementData .muac
            |> currentValue
            |> Maybe.map (.value >> (\(MuacInCm cm) -> String.fromFloat cm))
            |> Maybe.withDefault ""
    , nutritionSigns =
        data
            |> mapMeasurementData .nutrition
            |> currentValue
            |> Maybe.map .value
            |> Maybe.withDefault EverySet.empty
    , counseling =
        data
            |> mapMeasurementData .counselingSession
            |> currentValue
            |> Maybe.map .value
    , photo =
        data
            |> mapMeasurementData .photo
            |> currentValue
            |> Maybe.map .value
    , weight =
        data
            |> mapMeasurementData .weight
            |> currentValue
            |> Maybe.map (.value >> (\(WeightInKg kg) -> String.fromFloat kg))
            |> Maybe.withDefault ""
    , fbfForm =
        data
            |> mapMeasurementData .fbf
            |> currentValue
            |> Maybe.map (.value >> fbfValueToForm)
            |> Maybe.withDefault (FbfForm Nothing Nothing)
    }


{-| Initialize (or reset) a form with the given data.
-}
fromMotherMeasurementData : MeasurementData MotherMeasurements -> ModelMother
fromMotherMeasurementData data =
    let
        -- We show the UI as completed for all current consents
        progress =
            data
                |> mapMeasurementData .consent
                |> currentValues
                |> List.map (Tuple.second >> .value >> .formId)
                |> List.map (\formId -> ( formId, completedParticipantFormProgress ))
                |> Dict.fromList
    in
    { familyPlanningSigns =
        data
            |> mapMeasurementData .familyPlanning
            |> currentValue
            |> Maybe.map .value
            |> Maybe.withDefault EverySet.empty
    , participantConsent =
        { expected = Dict.empty
        , view = Nothing
        , progress = progress
        }
    , lactationForm =
        data
            |> mapMeasurementData .lactation
            |> currentValue
            |> Maybe.map (.value >> lactationSignsToForm)
            |> Maybe.withDefault (LactationForm Nothing)
    , fbfForm =
        data
            |> mapMeasurementData .fbf
            |> currentValue
            |> Maybe.map (.value >> fbfValueToForm)
            |> Maybe.withDefault (FbfForm Nothing Nothing)
    }


getMotherForm : PersonId -> Pages.Session.Model.Model -> EditableSession -> ModelMother
getMotherForm motherId pages session =
    -- Could use `Maybe.withDefault` here instead, but then
    -- `fromMotherMeasurementData` would get calculated every time
    case Dict.get motherId pages.motherForms of
        Just motherForm ->
            motherForm

        Nothing ->
            getMotherMeasurementData motherId session
                |> LocalData.unwrap
                    emptyModelMother
                    (fromMotherMeasurementData
                        >> (\form ->
                                { form
                                    | participantConsent =
                                        { expected = expectParticipantConsent session.offlineSession motherId
                                        , view = Nothing
                                        , progress = form.participantConsent.progress
                                        }
                                }
                           )
                    )


getChildForm : PersonId -> Pages.Session.Model.Model -> EditableSession -> ModelChild
getChildForm childId pages session =
    -- Could use `Maybe.withDefault` here instead, but then
    -- `fromChildMeasurementData` would get calculated every time
    case Dict.get childId pages.childForms of
        Just childForm ->
            childForm

        Nothing ->
            getChildMeasurementData childId session
                |> LocalData.unwrap
                    emptyModelChild
                    (fromChildMeasurementData
                        >> (\form ->
                                -- We need some special logic for the counseling
                                -- session, to fill in the correct kind of session.
                                -- This seems to be the best place to do that, though
                                -- that may need some more thinking at some point.
                                case form.counseling of
                                    Just _ ->
                                        form

                                    Nothing ->
                                        { form
                                            | counseling =
                                                expectCounselingActivity session childId
                                                    |> Maybe.map
                                                        (\timing ->
                                                            ( timing, EverySet.empty )
                                                        )
                                        }
                           )
                    )


{-| Here we get a Float measurement value with it's date\_measured, from group and individual contexts.
We return the most recent value, or Nothing, if both provided parameters were Nothing.
-}
resolvePreviousValueInCommonContext : Maybe ( NominalDate, Float ) -> Maybe ( NominalDate, Float ) -> Maybe Float
resolvePreviousValueInCommonContext previousGroupMeasurement previousIndividualMeasurement =
    case previousGroupMeasurement of
        Just ( pgmDate, pgmValue ) ->
            case previousIndividualMeasurement of
                Just ( pimDate, pimValue ) ->
                    case Gizra.NominalDate.compare pgmDate pimDate of
                        GT ->
                            Just pgmValue

                        _ ->
                            Just pimValue

                Nothing ->
                    Just pgmValue

        Nothing ->
            Maybe.map Tuple.second previousIndividualMeasurement
