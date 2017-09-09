module Measurement.Decoder
    exposing
        ( decodeChildNutritionSign
        , decodeFamilyPlanning
        , decodeFamilyPlanningSign
        , decodeHeight
        , decodeMuac
        , decodeNutrition
        , decodePhotoFromResponse
        , decodeWeight
        )

import Activity.Model exposing (FamilyPlanningSign(..), ChildNutritionSign(..))
import EverySet exposing (EverySet)
import Json.Decode exposing (Decoder, andThen, at, dict, fail, field, int, list, map, map2, nullable, string, succeed)
import Json.Decode.Pipeline exposing (custom, decode, hardcoded, optional, optionalAt, required, requiredAt)
import Measurement.Model exposing (FamilyPlanningId(..), Photo, PhotoId, HeightId(..), MuacId(..), NutritionId(..), WeightId(..))
import StorageKey exposing (StorageKey(..))
import Utils.Json exposing (decodeFloat, decodeInt)


decodePhoto : Decoder Photo
decodePhoto =
    decode Photo
        |> requiredAt [ "photo", "styles", "thumbnail" ] string


decodePhotoTuple : Decoder ( PhotoId, Photo )
decodePhotoTuple =
    decode
        (,)
        |> required "id" decodeInt
        |> custom decodePhoto


decodePhotoFromResponse : Decoder ( PhotoId, Photo )
decodePhotoFromResponse =
    at [ "data", "0" ] decodePhotoTuple


decodeHeight : Decoder ( StorageKey HeightId, Float )
decodeHeight =
    decodeStorageTuple (decodeId HeightId) (field "height" decodeFloat)


decodeWeight : Decoder ( StorageKey WeightId, Float )
decodeWeight =
    decodeStorageTuple (decodeId WeightId) (field "weight" decodeFloat)


decodeMuac : Decoder ( StorageKey MuacId, Float )
decodeMuac =
    decodeStorageTuple (decodeId MuacId) (field "muac" decodeFloat)


decodeFamilyPlanning : Decoder ( StorageKey FamilyPlanningId, EverySet FamilyPlanningSign )
decodeFamilyPlanning =
    decodeStorageTuple (decodeId FamilyPlanningId) (field "family_planning_signs" (decodeEverySet decodeFamilyPlanningSign))


decodeNutrition : Decoder ( StorageKey NutritionId, EverySet ChildNutritionSign )
decodeNutrition =
    decodeStorageTuple (decodeId NutritionId) (field "nutrition_signs" (decodeEverySet decodeChildNutritionSign))


{-| Given a decoder, decodes a JSON list of that type, and then
turns it into an `EverySet`.
-}
decodeEverySet : Decoder a -> Decoder (EverySet a)
decodeEverySet =
    map EverySet.fromList << list


decodeChildNutritionSign : Decoder ChildNutritionSign
decodeChildNutritionSign =
    string
        |> andThen
            (\s ->
                case s of
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
                            s
                                ++ " is not a recognized ChildNutritionSign"
            )


decodeFamilyPlanningSign : Decoder FamilyPlanningSign
decodeFamilyPlanningSign =
    string
        |> andThen
            (\s ->
                case s of
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
                            s
                                ++ " is not a recognized FamilyPlanningSign"
            )


{-| Convenience for the pattern where you have a field called "id",
and you want to wrap the result in a type (e.g. PersonId Int). You can
just use `decodeId PersonId`.
-}
decodeId : (Int -> a) -> Decoder a
decodeId wrapper =
    map wrapper (field "id" decodeInt)


{-| Convenience for the case where you have a decoder for the ID,
a decoder for the value, and you want to decode a tuple of StorageKey and
value.
-}
decodeStorageTuple : Decoder key -> Decoder value -> Decoder ( StorageKey key, value )
decodeStorageTuple keyDecoder valueDecoder =
    map2 (,)
        (map Existing keyDecoder)
        valueDecoder
