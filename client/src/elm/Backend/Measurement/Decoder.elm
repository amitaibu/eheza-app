module Backend.Measurement.Decoder exposing (..)

import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (..)
import Dict exposing (Dict)
import EveryDict exposing (EveryDict)
import Gizra.Json exposing (decodeFloat, decodeInt, decodeIntDict, decodeEmptyArrayAs)
import Gizra.NominalDate
import Json.Decode exposing (Decoder, andThen, at, decodeValue, dict, fail, field, int, list, map, map2, nullable, string, succeed, value, oneOf)
import Json.Decode.Pipeline exposing (custom, decode, hardcoded, optional, optionalAt, required, requiredAt)
import Restful.Endpoint exposing (decodeEntity, decodeEntityId, decodeSingleEntity, decodeStorageTuple, toEntityId)
import Utils.Json exposing (decodeEverySet)


{-| Given a decoder for a value, produces a decoder for our `Measurement` type.
-}
decodeChildMeasurement : Decoder value -> Decoder (Measurement ChildId value)
decodeChildMeasurement =
    decodeMeasurement (field "child" decodeEntityId)


{-| Given a decoder for a value, produces a decoder for our `Measurement` type.
-}
decodeMotherMeasurement : Decoder value -> Decoder (Measurement MotherId value)
decodeMotherMeasurement =
    decodeMeasurement (field "mother" decodeEntityId)


decodeMeasurement : Decoder participantId -> Decoder value -> Decoder (Measurement participantId value)
decodeMeasurement participantDecoder valueDecoder =
    decode Measurement
        |> custom participantDecoder
        |> required "session" (nullable decodeEntityId)
        |> required "date_measured" Gizra.NominalDate.decodeYYYYMMDD
        |> custom valueDecoder


{-| Decodes `HistoricalMeasurements` as sent by /api/offline_sessions/
-}
decodeHistoricalMeasurements : Decoder HistoricalMeasurements
decodeHistoricalMeasurements =
    decode HistoricalMeasurements
        |> requiredAt [ "participants", "mother_activity" ]
            (oneOf
                [ decodeEmptyArrayAs EveryDict.empty
                , map (toEveryDict toEntityId) (decodeIntDict decodeMotherMeasurementList)
                ]
            )
        |> requiredAt [ "participants", "child_activity" ]
            (oneOf
                [ decodeEmptyArrayAs EveryDict.empty
                , map (toEveryDict toEntityId) (decodeIntDict decodeChildMeasurementList)
                ]
            )


{-| TODO: Put in elm-essentials.
-}
toEveryDict : (comparable -> a) -> Dict comparable b -> EveryDict a b
toEveryDict func =
    Dict.foldl (\key value acc -> EveryDict.insert (func key) value acc) EveryDict.empty


decodeMotherMeasurementList : Decoder MotherMeasurementList
decodeMotherMeasurementList =
    decode MotherMeasurementList
        |> optional "family-planning" (list (decodeEntity decodeFamilyPlanning)) []


decodeChildMeasurementList : Decoder ChildMeasurementList
decodeChildMeasurementList =
    decode ChildMeasurementList
        |> optional "height" (list (decodeEntity decodeHeight)) []
        |> optional "muac" (list (decodeEntity decodeMuac)) []
        |> optional "nutrition" (list (decodeEntity decodeNutrition)) []
        |> optional "photo" (list (decodeEntity decodePhoto)) []
        |> optional "weight" (list (decodeEntity decodeWeight)) []


{-| The `oneOf` considers the encoding the backend supplies and the encoding
we use for the cache.
-}
decodePhoto : Decoder Photo
decodePhoto =
    oneOf
        [ at [ "photo", "styles", "thumbnail" ] string
        , field "photo" string
        ]
        |> map PhotoValue
        |> decodeChildMeasurement


decodeHeight : Decoder Height
decodeHeight =
    field "height" decodeFloat
        |> map HeightInCm
        |> decodeChildMeasurement


decodeWeight : Decoder Weight
decodeWeight =
    field "weight" decodeFloat
        |> map WeightInKg
        |> decodeChildMeasurement


decodeMuac : Decoder Muac
decodeMuac =
    field "muac" decodeFloat
        |> map MuacInCm
        |> decodeChildMeasurement


decodeFamilyPlanning : Decoder FamilyPlanning
decodeFamilyPlanning =
    decodeEverySet decodeFamilyPlanningSign
        |> field "family_planning_signs"
        |> decodeMotherMeasurement


decodeNutrition : Decoder ChildNutrition
decodeNutrition =
    decodeEverySet decodeChildNutritionSign
        |> field "nutrition_signs"
        |> decodeChildMeasurement


decodeChildNutritionSign : Decoder ChildNutritionSign
decodeChildNutritionSign =
    string
        |> andThen
            (\sign ->
                case sign of
                    "abdominal-disortion" ->
                        succeed AbdominalDisortion

                    "apathy" ->
                        succeed Apathy

                    "brittle-hair" ->
                        succeed BrittleHair

                    "dry-skin" ->
                        succeed DrySkin

                    "edema" ->
                        succeed Edema

                    "none" ->
                        succeed None

                    "poor-appetite" ->
                        succeed PoorAppetite

                    _ ->
                        fail <|
                            sign
                                ++ " is not a recognized ChildNutritionSign"
            )


decodeFamilyPlanningSign : Decoder FamilyPlanningSign
decodeFamilyPlanningSign =
    string
        |> andThen
            (\sign ->
                case sign of
                    "pill" ->
                        succeed Pill

                    "condoms" ->
                        succeed Condoms

                    "iud" ->
                        succeed IUD

                    "injection" ->
                        succeed Injection

                    "necklace" ->
                        succeed Necklace

                    "none" ->
                        succeed NoFamilyPlanning

                    _ ->
                        fail <|
                            sign
                                ++ " is not a recognized FamilyPlanningSign"
            )


{-| Decodes what `encodeMeasurementEdits` produces.
-}
decodeMeasurementEdits : Decoder MeasurementEdits
decodeMeasurementEdits =
    decode MeasurementEdits
        |> required "mothers" (map (toEveryDict toEntityId) (decodeIntDict decodeMotherEdits))
        |> required "children" (map (toEveryDict toEntityId) (decodeIntDict decodeChildEdits))


{-| Decodes what `encodeChildEdits` produces.
-}
decodeChildEdits : Decoder ChildEdits
decodeChildEdits =
    decode ChildEdits
        |> required "height" (decodeEdit decodeHeight)
        |> required "muac" (decodeEdit decodeMuac)
        |> required "nutrition" (decodeEdit decodeNutrition)
        |> required "photo" (decodeEdit decodePhoto)
        |> required "weight" (decodeEdit decodeWeight)


{-| Decodes what `encodeChildEdits` produces.
-}
decodeMotherEdits : Decoder MotherEdits
decodeMotherEdits =
    decode MotherEdits
        |> required "family-planning" (decodeEdit decodeFamilyPlanning)


{-| The opposite of `encodeEdit`
-}
decodeEdit : Decoder value -> Decoder (Edit value)
decodeEdit valueDecoder =
    field "tag" string
        |> andThen
            (\tag ->
                case tag of
                    "unedited" ->
                        succeed Unedited

                    "created" ->
                        field "value" valueDecoder
                            |> map Created

                    "edited" ->
                        map2
                            (\backend edited ->
                                Edited
                                    { backend = backend
                                    , edited = edited
                                    }
                            )
                            (field "backend" valueDecoder)
                            (field "edited" valueDecoder)

                    "deleted" ->
                        field "value" valueDecoder
                            |> map Deleted

                    _ ->
                        fail <|
                            "tag '"
                                ++ tag
                                ++ "' is not a valid tag for an Edit"
            )
