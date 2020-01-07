module Backend.IndividualEncounterParticipant.Encoder exposing (encodeIndividualEncounterParticipant)

import Backend.IndividualEncounterParticipant.Model exposing (..)
import Backend.IndividualEncounterParticipant.Utils exposing (encoudeIndividualEncounterTypeAsString)
import Gizra.NominalDate exposing (encodeYYYYMMDD)
import Json.Encode exposing (..)
import Json.Encode.Extra exposing (maybe)
import Restful.Endpoint exposing (encodeEntityUuid)


encodeIndividualEncounterParticipant : IndividualEncounterParticipant -> Value
encodeIndividualEncounterParticipant data =
    object
        [ ( "person", encodeEntityUuid data.person )
        , ( "encounter_type", encodeIndividualEncounterType data.encounterType )
        , ( "expected"
          , object
                [ ( "value", encodeYYYYMMDD data.startDate )
                , ( "value2", maybe encodeYYYYMMDD data.endDate )
                ]
          )
        ]


encodeIndividualEncounterType : IndividualEncounterType -> Value
encodeIndividualEncounterType type_ =
    encoudeIndividualEncounterTypeAsString type_ |> string
