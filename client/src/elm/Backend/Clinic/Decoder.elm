module Backend.Clinic.Decoder exposing (decodeClinic)

import Backend.Clinic.Model exposing (..)
import Json.Decode exposing (Decoder, andThen, fail, string, succeed)
import Json.Decode.Pipeline exposing (required)
import Restful.Endpoint exposing (decodeEntityUuid)


decodeClinic : Decoder Clinic
decodeClinic =
    succeed Clinic
        |> required "label" string
        |> required "health_center" decodeEntityUuid
        |> required "group_type" decodeClinicType


decodeClinicType : Decoder ClinicType
decodeClinicType =
    string
        |> andThen
            (\s ->
                case s of
                    "fbf" ->
                        succeed Fbf

                    "pmtct" ->
                        succeed Pmtct

                    "sorwathe" ->
                        succeed Sorwathe

                    _ ->
                        fail <|
                            s
                                ++ " is not a recognized ClinicType"
            )
