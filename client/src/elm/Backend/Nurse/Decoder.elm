module Backend.Nurse.Decoder exposing (decodeNurse)

import Backend.Nurse.Model exposing (..)
import EverySet
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Restful.Endpoint exposing (decodeEntityUuid)


decodeNurse : Decoder Nurse
decodeNurse =
    decode Nurse
        |> required "label" string
        |> optional "clinics" (list decodeEntityUuid) []
        |> optional "role" (map EverySet.fromList (list decodeRole)) EverySet.empty
        |> optional "email" (map Just string) Nothing


decodeRole : Decoder Role
decodeRole =
    string
        |> andThen
            (\s ->
                case s of
                    "nurse" ->
                        succeed RoleNurse

                    "admin" ->
                        succeed RoleAdministrator

                    _ ->
                        fail <|
                            s
                                ++ " is not a recognized role."
            )