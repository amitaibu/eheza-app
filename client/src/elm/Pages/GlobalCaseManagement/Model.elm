module Pages.GlobalCaseManagement.Model exposing (..)

import AssocList exposing (Dict)
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (IndividualEncounterType)
import Backend.Measurement.Model exposing (FollowUpOption(..), FollowUpValue, NutritionAssesment)
import EverySet exposing (EverySet)
import Gizra.NominalDate exposing (NominalDate)
import Pages.Page exposing (Page)


type alias Model =
    { encounterTypeFilter : Maybe IndividualEncounterType
    , dialogState : Maybe FollowUpEncounterDataType
    }


emptyModel : Model
emptyModel =
    { encounterTypeFilter = Nothing
    , dialogState = Nothing
    }


type FollowUpDueOption
    = DueToday
    | DueThisWeek
    | DueThisMonth
    | OverDue


type alias NutritionFollowUpItem =
    { dateMeasured : NominalDate
    , value : FollowUpValue
    }


type alias AcuteIllnessFollowUpItem =
    { dateMeasured : NominalDate
    , encounterId : Maybe AcuteIllnessEncounterId

    -- Since there may ne multiple encounters during same day,
    -- we need to know sequence number to be able to order
    -- follow ups correctly.
    , encounterSequenceNumber : Int
    , value : EverySet FollowUpOption
    }


type FollowUpEncounterDataType
    = FollowUpNutrition FollowUpNutritionData
    | FollowUpAcuteIllness FollowUpAcuteIllnessData


type alias FollowUpNutritionData =
    { personId : PersonId
    , personName : String
    }


type alias FollowUpAcuteIllnessData =
    { personId : PersonId
    , personName : String
    , participantId : IndividualEncounterParticipantId
    , sequenceNumber : Int
    }


type Msg
    = SetActivePage Page
    | SetEncounterTypeFilter (Maybe IndividualEncounterType)
    | SetDialogState (Maybe FollowUpEncounterDataType)
    | StartFollowUpEncounter FollowUpEncounterDataType
