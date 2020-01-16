module Pages.PrenatalEncounter.Model exposing (AssembledData, Model, Msg(..), Tab(..), emptyModel)

import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (ObstetricHistoryValue, PrenatalMeasurements)
import Backend.Person.Model exposing (Person)
import Backend.PrenatalEncounter.Model exposing (..)
import Backend.PrenatalParticipant.Model exposing (PrenatalParticipant)
import Gizra.NominalDate exposing (NominalDate, diffDays, formatMMDDYYYY)
import Pages.Page exposing (Page)


type alias Model =
    { selectedTab : Tab
    , showAlertsDialog : Bool
    }


type alias AssembledData =
    { id : PrenatalEncounterId
    , encounter : PrenatalEncounter
    , participant : PrenatalParticipant
    , person : Person
    , measurements : PrenatalMeasurements
    , previousMeasurementsWithDates : List ( NominalDate, PrenatalMeasurements )
    , globalLmpDate : Maybe NominalDate
    , globalObstetricHistory : Maybe ObstetricHistoryValue
    }


type Msg
    = CloseEncounter PrenatalEncounterId
    | SetActivePage Page
    | SetAlertsDialogState Bool
    | SetSelectedTab Tab


type Tab
    = Completed
    | Pending
    | Reports


emptyModel : Model
emptyModel =
    { selectedTab = Pending
    , showAlertsDialog = False
    }
