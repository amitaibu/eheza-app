module Backend.IndividualEncounterParticipant.Model exposing
    ( IndividualEncounterParticipant
    , IndividualEncounterType(..)
    , Model
    , Msg(..)
    , PregnancyOutcome(..)
    , allPregnancyOutcome
    , emptyModel
    )

import Backend.Entities exposing (..)
import Date exposing (Date)
import Gizra.NominalDate exposing (NominalDate)
import RemoteData exposing (RemoteData(..), WebData)


type alias IndividualEncounterParticipant =
    { person : PersonId
    , encounterType : IndividualEncounterType
    , startDate : NominalDate
    , endDate : Maybe NominalDate
    , eddDate : Maybe NominalDate
    }


type alias Model =
    { closePrenatalSession : WebData ()
    , setEddDate : WebData ()
    }


type Msg
    = ClosePrenatalSession Date PregnancyOutcome Bool
    | HandleClosedPrenatalSession (WebData ())
    | SetEddDate NominalDate
    | HandleSetEddDate (WebData ())


emptyModel : Model
emptyModel =
    { closePrenatalSession = NotAsked
    , setEddDate = NotAsked
    }


type IndividualEncounterType
    = AntenatalEncounter
    | InmmunizationEncounter
    | NutritionEncounter


type PregnancyOutcome
    = OutcomeLiveAtTerm
    | OutcomeLivePreTerm
    | OutcomeStillAtTerm
    | OutcomeStillPreTerm
    | OutcomeAbortions


allPregnancyOutcome : List PregnancyOutcome
allPregnancyOutcome =
    [ OutcomeLiveAtTerm
    , OutcomeLivePreTerm
    , OutcomeStillAtTerm
    , OutcomeStillPreTerm
    , OutcomeAbortions
    ]