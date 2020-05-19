module Backend.SyncData.Decoder exposing (decodeBackendGeneralEntityList, decodeSyncData)

import Backend.Person.Decoder exposing (decodePerson)
import Backend.SyncData.Model exposing (BackendGeneralEntity(..), DownloadStatus, SyncAttempt(..), SyncData, SyncError(..), UploadStatus)
import Gizra.Json exposing (decodeFloat, decodeInt)
import Json.Decode exposing (..)
import Json.Decode.Pipeline exposing (..)
import Time


decodeBackendGeneralEntityList : Decoder (List BackendGeneralEntity)
decodeBackendGeneralEntityList =
    list decodeBackendGeneralEntity


decodeBackendGeneralEntity : Decoder BackendGeneralEntity
decodeBackendGeneralEntity =
    field "type" string
        |> andThen
            (\type_ ->
                case type_ of
                    "person" ->
                        decodePerson
                            |> andThen (\person -> succeed (BackendGeneralEntityPerson person))

                    _ ->
                        succeed BackendGeneralEntityUnknown
            )


decodeSyncData : Decoder SyncData
decodeSyncData =
    succeed SyncData
        |> optional "download" (nullable decodeDownloadStatus) Nothing
        |> optional "upload" (nullable decodeUploadStatus) Nothing
        |> required "attempt" decodeSyncAttempt


decodeDownloadStatus : Decoder DownloadStatus
decodeDownloadStatus =
    succeed DownloadStatus
        |> custom (decodeTimeField "last_contact")
        |> required "last_timestamp" decodeInt
        |> required "remaining" decodeInt


decodeUploadStatus : Decoder UploadStatus
decodeUploadStatus =
    succeed UploadStatus
        |> optional "first_timestamp" (nullable decodeInt) Nothing
        |> required "remaining" decodeInt


decodeSyncAttempt : Decoder SyncAttempt
decodeSyncAttempt =
    field "tag" string
        |> andThen
            (\s ->
                case s of
                    "NotAsked" ->
                        succeed NotAsked

                    "Success" ->
                        succeed Success

                    "DatabaseError" ->
                        succeed DatabaseError
                            |> required "message" string
                            |> decodeFailure

                    "NetworkError" ->
                        succeed NetworkError
                            |> required "message" string
                            |> decodeFailure

                    "ImageNotFound" ->
                        succeed ImageNotFound
                            |> required "url" string
                            |> decodeFailure

                    "NoCredentials" ->
                        succeed NoCredentials
                            |> decodeFailure

                    "BadResponse" ->
                        succeed BadResponse
                            |> required "status" decodeInt
                            |> required "statusText" string
                            |> decodeFailure

                    "BadJson" ->
                        succeed BadJson
                            |> decodeFailure

                    "Loading" ->
                        succeed Downloading
                            |> custom (decodeTimeField "timestamp")
                            |> required "revision" decodeInt

                    "Uploading" ->
                        succeed Uploading
                            |> custom (decodeTimeField "timestamp")

                    _ ->
                        fail <|
                            s
                                ++ " is not a recognized SyncAttempt tag"
            )


decodeFailure : Decoder SyncError -> Decoder SyncAttempt
decodeFailure =
    map2 Backend.SyncData.Model.Failure (decodeTimeField "timestamp")


decodeTimeField : String -> Decoder Time.Posix
decodeTimeField fieldName =
    map Time.millisToPosix (field fieldName decodeInt)
