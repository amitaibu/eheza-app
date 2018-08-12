module Pages.Activity.Utils exposing (..)

import Activity.Model exposing (ChildActivity(..), MotherActivity(..))
import Backend.Entities exposing (..)
import Backend.Session.Model exposing (EditableSession)
import Backend.Session.Utils exposing (getChild, getChildMeasurementData, getMother, getMotherMeasurementData)
import Gizra.Html exposing (emptyNode)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (Html)
import Measurement.Model
import Measurement.Utils exposing (getChildForm, getMotherForm)
import Measurement.View
import Pages.Activity.Model exposing (..)
import Translate exposing (Language)
import ZScore.Model


{-| These are conveniences for the way the code was structured.
Ideally, we'd have smaller capabilities in `Participant` that
this could be built on more generically, but this will do for now.
-}
viewChildMeasurements : Language -> NominalDate -> ZScore.Model.Model -> ChildId -> ChildActivity -> EditableSession -> Html (Msg ChildId Measurement.Model.MsgChild)
viewChildMeasurements language currentDate zscores childId activity session =
    let
        measurements =
            getChildMeasurementData childId session

        form =
            getChildForm childId session
    in
    getChild childId session.offlineSession
        |> Maybe.map
            (\child ->
                Measurement.View.viewChild language currentDate child activity measurements zscores form
                    |> Html.map MsgMeasurement
            )
        |> Maybe.withDefault emptyNode


viewMotherMeasurements : Language -> NominalDate -> MotherId -> MotherActivity -> EditableSession -> Html (Msg MotherId Measurement.Model.MsgMother)
viewMotherMeasurements language currentDate motherId activity session =
    let
        measurements =
            getMotherMeasurementData motherId session

        form =
            getMotherForm motherId session
    in
    Measurement.View.viewMother language activity measurements form
        |> Html.map MsgMeasurement
