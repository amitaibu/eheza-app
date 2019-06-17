module Pages.Device.Model exposing (Model, Msg(..), emptyModel)

import Backend.Entities exposing (..)
import Pages.Page exposing (Page)


type alias Model =
    { -- The pairing code entered in the UI
      code : String
    }


emptyModel : Model
emptyModel =
    { code = ""
    }


type Msg
    = SetActivePage Page
    | SetCode String
    | HandlePairClicked
    | TrySyncing
    | SetSyncing HealthCenterId Bool