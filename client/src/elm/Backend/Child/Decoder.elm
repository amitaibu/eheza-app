module Backend.Child.Decoder exposing (decodeChild)

import Backend.Child.Model exposing (..)
import Gizra.NominalDate exposing (decodeYYYYMMDD)
import Json.Decode exposing (Decoder, andThen, at, dict, fail, field, int, list, map, map2, nullable, oneOf, string, succeed)
import Json.Decode.Pipeline exposing (custom, decode, hardcoded, optional, optionalAt, required)
import Restful.Endpoint exposing (decodeEntityUuid)


decodeChild : Decoder Child
decodeChild =
    decode Child
        |> required "label" string
        |> optional "avatar" (nullable string) Nothing
        |> required "mother" (nullable decodeEntityUuid)
        |> required "date_birth" decodeYYYYMMDD
        |> required "gender" decodeGender


decodeGender : Decoder Gender
decodeGender =
    string
        |> andThen
            (\gender ->
                if gender == "female" then
                    succeed Female

                else if gender == "male" then
                    succeed Male

                else
                    fail (gender ++ " is not a recognized 'type' for Gender.")
            )
