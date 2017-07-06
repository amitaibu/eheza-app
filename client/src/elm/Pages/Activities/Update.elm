module Pages.Activities.Update exposing (update)

import App.PageType exposing (Page(..))
import Config.Model exposing (BackendUrl)
import User.Model exposing (..)
import Pages.Activities.Model exposing (Model, Msg(..))
import Patient.Model exposing (PatientTypeFilter(..), PatientsDict)


update : BackendUrl -> String -> User -> Msg -> PatientsDict -> Model -> ( Model, Cmd Msg, Maybe Page )
update backendUrl accessToken user msg patients model =
    case msg of
        SetPatientTypeFilter patientTypeFilterString ->
            let
                patientTypeFilter =
                    if patientTypeFilterString == "All" then
                        All
                    else if patientTypeFilterString == "Children" then
                        Children
                    else if patientTypeFilterString == "Mothers" then
                        Mothers
                    else
                        model.patientTypeFilter
            in
                ( { model | patientTypeFilter = patientTypeFilter }
                , Cmd.none
                , Nothing
                )

        SetRedirectPage page ->
            ( model, Cmd.none, Just page )