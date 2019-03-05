module Pages.PinCode.Model exposing (Model, Msg(..), OutMsg(..), emptyModel)

{-| This models the PinCode entered by the user.
-}

import Pages.Page exposing (Page)


type alias Model =
    { code : String
    }


type Msg
    = ClearPinCode
    | SendOutMsg OutMsg
    | SetPinCode String
    | HandleLoginClicked
    | HandleLogoutClicked


{-| The message we return when we want to actually attempt a login, or logout.
Whoever calls `update` needs to detect this and do the correct thing.
-}
type OutMsg
    = Logout
    | TryPinCode String
    | SetActivePage Page


emptyModel : Model
emptyModel =
    { code = ""
    }
