module Backend.Session.Encoder exposing (..)

import Backend.Child.Encoder exposing (encodeChild)
import Backend.Clinic.Encoder exposing (encodeClinic)
import Backend.Entities exposing (..)
import Backend.Measurement.Encoder exposing (encodeChildMeasurementList, encodeMotherMeasurementList)
import Backend.Model exposing (TrainingSessionAction(..), TrainingSessionRequest)
import Backend.Mother.Encoder exposing (encodeMother)
import Backend.Session.Model exposing (..)
import EveryDict
import EveryDictList
import Gizra.NominalDate exposing (encodeDrupalRange, encodeYYYYMMDD)
import Json.Encode exposing (..)
import Restful.Endpoint exposing (encodeEntityId, fromEntityId)


encodeTrainingSessionRequest : TrainingSessionRequest -> Value
encodeTrainingSessionRequest req =
    object
        [ ( "action", encodeTrainingSessionAction req.action )
        ]


{-| Encodes a `TrainingSessionAction`.
-}
encodeTrainingSessionAction : TrainingSessionAction -> Value
encodeTrainingSessionAction action =
    case action of
        CreateAll ->
            string "create_all"

        DeleteAll ->
            string "delete_all"


{-| Encodes a `Session`.
-}
encodeSession : Session -> List ( String, Value )
encodeSession session =
    [ ( "scheduled_date", encodeDrupalRange encodeYYYYMMDD session.scheduledDate )
    , ( "clinic", encodeEntityId session.clinicId )
    , ( "closed", bool session.closed )
    , ( "training", bool session.training )
    ]


encodeOfflineSession : OfflineSession -> List ( String, Value )
encodeOfflineSession offline =
    -- The first three encode the data for this particular session
    [ ( "scheduled_date", encodeDrupalRange encodeYYYYMMDD offline.session.scheduledDate )
    , ( "clinic", encodeEntityId offline.session.clinicId )
    , ( "closed", bool offline.session.closed )

    -- TODO: Generalize the "withId" encoding in a function somewhere
    , ( "all_sessions"
      , EveryDictList.toList offline.allSessions
            |> List.map (\( id, session ) -> object (( "id", encodeEntityId id ) :: encodeSession session))
            |> list
      )
    , ( "clinics"
      , EveryDictList.toList offline.clinics
            |> List.map (\( id, clinic ) -> object (( "id", encodeEntityId id ) :: encodeClinic clinic))
            |> list
      )
    , ( "participants"
      , object
            [ ( "mothers"
              , EveryDictList.toList offline.mothers
                    |> List.map (\( id, mother ) -> object (( "id", encodeEntityId id ) :: encodeMother mother))
                    |> list
              )
            , ( "children"
              , EveryDictList.toList offline.children
                    |> List.map (\( id, child ) -> object (( "id", encodeEntityId id ) :: encodeChild child))
                    |> list
              )
            , ( "mother_activity"
              , EveryDict.toList offline.historicalMeasurements.mothers
                    |> List.map (Tuple.mapFirst (fromEntityId >> toString) >> Tuple.mapSecond encodeMotherMeasurementList)
                    |> object
              )
            , ( "child_activity"
              , EveryDict.toList offline.historicalMeasurements.children
                    |> List.map (Tuple.mapFirst (fromEntityId >> toString) >> Tuple.mapSecond encodeChildMeasurementList)
                    |> object
              )
            ]
      )
    ]


{-| We use this for caching to local storage.
-}
encodeOfflineSessionWithId : SessionId -> OfflineSession -> Value
encodeOfflineSessionWithId sessionId session =
    object <|
        ( "id", encodeEntityId sessionId )
            :: encodeOfflineSession session
