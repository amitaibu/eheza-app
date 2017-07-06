module Pages.Activities.Model exposing (..)

import App.PageType exposing (Page(..))
import Patient.Model exposing (PatientTypeFilter(..))


type alias Model =
    { patientTypeFilter : PatientTypeFilter }


type Msg
    = SetPatientTypeFilter String
    | SetRedirectPage Page


emptyModel : Model
emptyModel =
    { patientTypeFilter = All }