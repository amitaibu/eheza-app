module Backend.Measurement.Encoder exposing (..)

import Backend.Measurement.Model exposing (..)
import EverySet
import Gizra.NominalDate
import Json.Encode as Encoder exposing (Value, float, int, list, string)
import Json.Encode.Extra exposing (maybe)
import Restful.Endpoint exposing (EntityId(..), encodeEntityId)


encodeHeight : Height -> List ( String, Value )
encodeHeight =
    encodeChildMeasurement (\(HeightInCm height) -> ( "height", float height ))


encodeMuac : Muac -> List ( String, Value )
encodeMuac =
    encodeChildMeasurement (\(MuacInCm muac) -> ( "muac", float muac ))


encodeWeight : Weight -> List ( String, Value )
encodeWeight =
    encodeChildMeasurement (\(WeightInKg weight) -> ( "weight", float weight ))


encodeNutrition : ChildNutrition -> List ( String, Value )
encodeNutrition =
    encodeChildMeasurement
        (\nutritions ->
            ( "nutrition_signs"
            , EverySet.toList nutritions
                |> List.map encodeNutritionSign
                |> list
            )
        )


encodeFamilyPlanning : FamilyPlanning -> List ( String, Value )
encodeFamilyPlanning =
    encodeMotherMeasurement
        (\familyPlannings ->
            ( "family_planning_signs"
            , EverySet.toList familyPlannings
                |> List.map encodeFamilyPlanningSign
                |> list
            )
        )


encodeChildMeasurement : (value -> ( String, Value )) -> Measurement (EntityId a) value -> List ( String, Value )
encodeChildMeasurement =
    encodeMeasurement "child"


encodeMotherMeasurement : (value -> ( String, Value )) -> Measurement (EntityId a) value -> List ( String, Value )
encodeMotherMeasurement =
    encodeMeasurement "mother"


encodeMeasurement : String -> (value -> ( String, Value )) -> Measurement (EntityId a) value -> List ( String, Value )
encodeMeasurement participantField encoder measurement =
    [ ( participantField, encodeEntityId measurement.participantId )
    , ( "session", maybe encodeEntityId measurement.sessionId )
    , ( "date_measured", Gizra.NominalDate.encodeYYYYMMDD measurement.dateMeasured )
    , encoder measurement.value
    ]


encodeNutritionSign : ChildNutritionSign -> Value
encodeNutritionSign =
    encodeNutritionSignAsString >> string


encodeNutritionSignAsString : ChildNutritionSign -> String
encodeNutritionSignAsString sign =
    case sign of
        AbdominalDisortion ->
            "abdominal-disortion"

        Apathy ->
            "apathy"

        BrittleHair ->
            "brittle-hair"

        DrySkin ->
            "dry-skin"

        Edema ->
            "edema"

        None ->
            "none"

        PoorAppetite ->
            "poor-appetite"


encodeFamilyPlanningSign : FamilyPlanningSign -> Value
encodeFamilyPlanningSign =
    encodeFamilyPlanningSignAsString >> string


encodeFamilyPlanningSignAsString : FamilyPlanningSign -> String
encodeFamilyPlanningSignAsString sign =
    case sign of
        Condoms ->
            "condoms"

        IUD ->
            "iud"

        Injection ->
            "injection"

        Necklace ->
            "necklace"

        NoFamilyPlanning ->
            "none"

        Pill ->
            "pill"
