module Backend.PrenatalEncounter.Encoder exposing (encodePrenatalEncounter)

import Backend.PrenatalEncounter.Model exposing (..)
import Gizra.NominalDate exposing (encodeYYYYMMDD)
import Json.Encode exposing (..)
import Json.Encode.Extra exposing (maybe)
import Restful.Endpoint exposing (encodeEntityUuid)


{-| Encodes a `PrenatalEncounter`.
-}
encodePrenatalEncounter : PrenatalEncounter -> List ( String, Value )
encodePrenatalEncounter session =
    [ ( "scheduled_date"
      , object
            [ ( "value", encodeYYYYMMDD session.startDate )
            , ( "value2", maybe encodeYYYYMMDD session.endDate )
            ]
      )
    , ( "individual_participant", encodeEntityUuid session.participant )
    , ( "shard", maybe encodeEntityUuid session.shard )
    ]
