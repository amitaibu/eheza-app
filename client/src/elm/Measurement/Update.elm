module Pages.Patient.Update exposing (update)

import App.PageType exposing (Page(..))
import Config.Model exposing (BackendUrl)
import Measurement.Model exposing (Model, Msg(..))
import Patient.Model exposing (Patient, PatientId)
import RemoteData exposing (RemoteData(..))
import User.Model exposing (..)


update : BackendUrl -> String -> User -> ( PatientId, Patient ) -> Msg -> Model -> ( Model, Cmd Msg )
update backendUrl accessToken user ( patientId, patient ) msg model =
    case msg of
        HandleWeightSave (Ok ()) ->
            { model | status = NotAsked } ! []

        HandleWeightSave (Err err) ->
            let
                _ =
                    Debug.log "HandleWeightSave (Err)" False
            in
                { model | status = Failure err } ! []

        WeightSave ->
            model ! []

        WeightUpdate val ->
            model ! []
