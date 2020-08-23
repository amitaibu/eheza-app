module Pages.AcuteIllnessProgressReport.Model exposing (Model, Msg(..), emptyModel)

import Backend.Entities exposing (..)
import Pages.Page exposing (Page)


type alias Model =
    { showEndEncounetrDialog : Bool
    }


emptyModel : Model
emptyModel =
    { showEndEncounetrDialog = False
    }


type Msg
    = CloseEncounter AcuteIllnessEncounterId
    | SetActivePage Page
    | SetEndEncounterDialogState Bool