module Pages.AcuteIllnessActivity.Utils exposing (allSymptomsGISigns, allSymptomsGeneralSigns, allSymptomsRespiratorySigns, fromMalariaTestingValue, fromVitalsValue, laboratoryTasksCompletedFromTotal, malariaTestingFormWithDefault, physicalExamTasksCompletedFromTotal, symptomsGIFormWithDefault, symptomsGeneralFormWithDefault, symptomsRespiratoryFormWithDefault, symptomsTasksCompletedFromTotal, taskNotCompleted, toMalariaTestingValue, toMalariaTestingValueWithDefault, toSymptomsGIValueWithDefault, toSymptomsGeneralValueWithDefault, toSymptomsRespiratoryValueWithDefault, toVitalsValue, toVitalsValueWithDefault, toggleSymptomsSign, vitalsFormWithDefault)

import AssocList as Dict exposing (Dict)
import Backend.Measurement.Model
    exposing
        ( AcuteIllnessMeasurements
        , AcuteIllnessVitalsValue
        , MalariaTestingSign(..)
        , SymptomsGISign(..)
        , SymptomsGeneralSign(..)
        , SymptomsRespiratorySign(..)
        )
import EverySet exposing (EverySet)
import Maybe.Extra exposing (andMap, isJust, or, unwrap)
import Pages.AcuteIllnessActivity.Model exposing (..)
import Pages.PrenatalActivity.Utils exposing (ifEmpty, ifTrue)
import Pages.Utils exposing (taskCompleted)


taskNotCompleted : Bool -> Int
taskNotCompleted notCompleted =
    if notCompleted then
        0

    else
        1


allSymptomsGeneralSigns : ( List SymptomsGeneralSign, SymptomsGeneralSign )
allSymptomsGeneralSigns =
    ( [ SymptomGeneralFever
      , Chills
      , NightSweats
      , BodyAches
      , Headache
      ]
    , NoSymptomsGeneral
    )


allSymptomsRespiratorySigns : ( List SymptomsRespiratorySign, SymptomsRespiratorySign )
allSymptomsRespiratorySigns =
    ( [ Cough
      , ShortnessOfBreath
      , NasalCongestion
      , BloodInSputum
      , SoreThroat
      ]
    , NoSymptomsRespiratory
    )


allSymptomsGISigns : ( List SymptomsGISign, SymptomsGISign )
allSymptomsGISigns =
    ( [ BloodyDiarrhea
      , NonBloodyDiarrhea
      , Nausea
      , Vomiting
      , SymptomGIAbdominalPain
      ]
    , NoSymptomsGI
    )


toggleSymptomsSign : SymptomsTask -> a -> a -> { signs : Dict a Int } -> { signs : Dict a Int }
toggleSymptomsSign task sign noneSign form =
    let
        signs =
            form.signs

        updatedSigns =
            if sign == noneSign then
                Dict.singleton sign 1

            else
                let
                    signs_ =
                        Dict.remove noneSign signs
                in
                if Dict.member sign signs_ then
                    Dict.remove sign signs_

                else
                    Dict.insert sign 1 signs_
    in
    { form | signs = updatedSigns }


symptomsTasksCompletedFromTotal : AcuteIllnessMeasurements -> SymptomsData -> SymptomsTask -> ( Int, Int )
symptomsTasksCompletedFromTotal measurements data task =
    case task of
        SymptomsGeneral ->
            let
                form =
                    measurements.symptomsGeneral
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsGeneralFormWithDefault data.symptomsGeneralForm
            in
            ( taskNotCompleted (Dict.isEmpty form.signs)
            , 1
            )

        SymptomsRespiratory ->
            let
                form =
                    measurements.symptomsRespiratory
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsRespiratoryFormWithDefault data.symptomsRespiratoryForm
            in
            ( taskNotCompleted (Dict.isEmpty form.signs)
            , 1
            )

        SymptomsGI ->
            let
                form =
                    measurements.symptomsGI
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsGIFormWithDefault data.symptomsGIForm
            in
            ( taskNotCompleted (Dict.isEmpty form.signs)
            , 1
            )


physicalExamTasksCompletedFromTotal : AcuteIllnessMeasurements -> PhysicalExamData -> PhysicalExamTask -> ( Int, Int )
physicalExamTasksCompletedFromTotal measurements data task =
    case task of
        PhysicalExamVitals ->
            let
                form =
                    measurements.vitals
                        |> Maybe.map (Tuple.second >> .value)
                        |> vitalsFormWithDefault data.vitalsForm
            in
            ( taskCompleted form.respiratoryRate + taskCompleted form.bodyTemperature
            , 2
            )


laboratoryTasksCompletedFromTotal : AcuteIllnessMeasurements -> LaboratoryData -> LaboratoryTask -> ( Int, Int )
laboratoryTasksCompletedFromTotal measurements data task =
    case task of
        LaboratoryMalariaTesting ->
            let
                form =
                    measurements.malariaTesting
                        |> Maybe.map (Tuple.second >> .value)
                        |> malariaTestingFormWithDefault data.malariaTestingForm
            in
            ( taskCompleted form.rapidTestPositive
            , 1
            )



-- fromSymptomsGeneralValue : Maybe (Dict SymptomsGeneralSign Int) -> SymptomsGeneralForm
-- fromSymptomsGeneralValue saved =
--     { signs = saved }
--
--


symptomsGeneralFormWithDefault : SymptomsGeneralForm -> Maybe (Dict SymptomsGeneralSign Int) -> SymptomsGeneralForm
symptomsGeneralFormWithDefault form saved =
    saved
        |> unwrap
            form
            (\value ->
                if Dict.isEmpty form.signs then
                    SymptomsGeneralForm value

                else
                    form
            )


toSymptomsGeneralValueWithDefault : Maybe (Dict SymptomsGeneralSign Int) -> SymptomsGeneralForm -> Dict SymptomsGeneralSign Int
toSymptomsGeneralValueWithDefault saved form =
    symptomsGeneralFormWithDefault form saved
        |> .signs



--
--
-- toSymptomsGeneralValue : SymptomsGeneralForm -> Maybe (Dict SymptomsGeneralSign Int)
-- toSymptomsGeneralValue form =
--     form.signs
--
--
-- fromSymptomsRespiratoryValue : Maybe (Dict SymptomsRespiratorySign Int) -> SymptomsRespiratoryForm
-- fromSymptomsRespiratoryValue saved =
--     { signs = saved }
--
--


symptomsRespiratoryFormWithDefault : SymptomsRespiratoryForm -> Maybe (Dict SymptomsRespiratorySign Int) -> SymptomsRespiratoryForm
symptomsRespiratoryFormWithDefault form saved =
    saved
        |> unwrap
            form
            (\value ->
                if Dict.isEmpty form.signs then
                    SymptomsRespiratoryForm value

                else
                    form
            )


toSymptomsRespiratoryValueWithDefault : Maybe (Dict SymptomsRespiratorySign Int) -> SymptomsRespiratoryForm -> Dict SymptomsRespiratorySign Int
toSymptomsRespiratoryValueWithDefault saved form =
    symptomsRespiratoryFormWithDefault form saved
        |> .signs



--
--
-- toSymptomsRespiratoryValue : SymptomsRespiratoryForm -> Maybe (Dict SymptomsRespiratorySign Int)
-- toSymptomsRespiratoryValue form =
--     form.signs
--
--
-- fromSymptomsGIValue : Maybe (Dict SymptomsGISign Int) -> SymptomsGIForm
-- fromSymptomsGIValue saved =
--     { signs = saved }
--
--


symptomsGIFormWithDefault : SymptomsGIForm -> Maybe (Dict SymptomsGISign Int) -> SymptomsGIForm
symptomsGIFormWithDefault form saved =
    saved
        |> unwrap
            form
            (\value ->
                if Dict.isEmpty form.signs then
                    SymptomsGIForm value

                else
                    form
            )


toSymptomsGIValueWithDefault : Maybe (Dict SymptomsGISign Int) -> SymptomsGIForm -> Dict SymptomsGISign Int
toSymptomsGIValueWithDefault saved form =
    symptomsGIFormWithDefault form saved
        |> .signs



--
--
-- toSymptomsGIValue : SymptomsGIForm -> Maybe (Dict SymptomsGISign Int)
-- toSymptomsGIValue form =
--     form.signs


fromVitalsValue : Maybe AcuteIllnessVitalsValue -> VitalsForm
fromVitalsValue saved =
    { respiratoryRate = Maybe.map .respiratoryRate saved
    , bodyTemperature = Maybe.map .bodyTemperature saved
    }


vitalsFormWithDefault : VitalsForm -> Maybe AcuteIllnessVitalsValue -> VitalsForm
vitalsFormWithDefault form saved =
    saved
        |> unwrap
            form
            (\value ->
                { respiratoryRate = or form.respiratoryRate (Just value.respiratoryRate)
                , bodyTemperature = or form.bodyTemperature (Just value.bodyTemperature)
                }
            )


toVitalsValueWithDefault : Maybe AcuteIllnessVitalsValue -> VitalsForm -> Maybe AcuteIllnessVitalsValue
toVitalsValueWithDefault saved form =
    vitalsFormWithDefault form saved
        |> toVitalsValue


toVitalsValue : VitalsForm -> Maybe AcuteIllnessVitalsValue
toVitalsValue form =
    Maybe.map AcuteIllnessVitalsValue form.respiratoryRate
        |> andMap form.bodyTemperature


fromMalariaTestingValue : Maybe (EverySet MalariaTestingSign) -> MalariaTestingForm
fromMalariaTestingValue saved =
    { rapidTestPositive = Maybe.map (EverySet.member RapidTestPositive) saved
    }


malariaTestingFormWithDefault : MalariaTestingForm -> Maybe (EverySet MalariaTestingSign) -> MalariaTestingForm
malariaTestingFormWithDefault form saved =
    saved
        |> unwrap
            form
            (\value ->
                { rapidTestPositive = or form.rapidTestPositive (EverySet.member RapidTestPositive value |> Just)
                }
            )


toMalariaTestingValueWithDefault : Maybe (EverySet MalariaTestingSign) -> MalariaTestingForm -> Maybe (EverySet MalariaTestingSign)
toMalariaTestingValueWithDefault saved form =
    malariaTestingFormWithDefault form saved
        |> toMalariaTestingValue


toMalariaTestingValue : MalariaTestingForm -> Maybe (EverySet MalariaTestingSign)
toMalariaTestingValue form =
    [ Maybe.map (ifTrue RapidTestPositive) form.rapidTestPositive
    ]
        |> Maybe.Extra.combine
        |> Maybe.map (List.foldl EverySet.union EverySet.empty >> ifEmpty NoMalariaTestingSigns)
