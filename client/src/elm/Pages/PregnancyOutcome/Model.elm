module Pages.PregnancyOutcome.Model exposing (Model, Msg(..), emptyModel)

import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (PregnancyOutcome(..))
import Date exposing (Date)
import Pages.Page exposing (Page)


type alias Model =
    { pregnancyConcludedDate : Maybe Date
    , pregnancyOutcome : Maybe PregnancyOutcome
    , isFacilityDelivery : Maybe Bool
    , isDateSelectorOpen : Bool
    }


type Msg
    = NoOp
      -- Page is the destination page where nurse / chw
      -- is forwarded after form is saved.
    | SavePregnancyOutcome Page
    | SetActivePage Page
    | SetDeliveryLocation Bool
    | SetPregnancyConcludedDate Date
    | SetPregnancyOutcome String
    | ToggleDateSelector


emptyModel : Model
emptyModel =
    { pregnancyConcludedDate = Nothing
    , pregnancyOutcome = Nothing
    , isFacilityDelivery = Nothing
    , isDateSelectorOpen = False
    }
