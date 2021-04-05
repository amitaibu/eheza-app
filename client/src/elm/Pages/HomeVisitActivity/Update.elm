module Pages.HomeVisitActivity.Update exposing (update)

import App.Model
import AssocList as Dict
import Backend.Entities exposing (..)
import Backend.HomeVisitEncounter.Model
import Backend.IndividualEncounterParticipant.Model
import Backend.Model exposing (ModelIndexedDb)
import Gizra.NominalDate exposing (NominalDate)
import Maybe.Extra exposing (isJust, isNothing, unwrap)
import Pages.HomeVisitActivity.Model exposing (..)
import Pages.HomeVisitActivity.Utils exposing (..)
import Pages.Page exposing (Page(..), UserPage(..))
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)


update : NominalDate -> HomeVisitEncounterId -> ModelIndexedDb -> Msg -> Model -> ( Model, Cmd Msg, List App.Model.Msg )
update currentDate id db msg model =
    case msg of
        SetActivePage page ->
            ( model
            , Cmd.none
            , [ App.Model.SetActivePage page ]
            )

        SetFeedingBoolInput formUpdateFunc value ->
            let
                updatedForm =
                    formUpdateFunc value model.feedingForm
            in
            ( { model | feedingForm = updatedForm }
            , Cmd.none
            , []
            )

        SetNutritionSupplementType value ->
            let
                form =
                    model.feedingForm

                updatedForm =
                    { form | supplementType = Just value }
            in
            ( { model | feedingForm = updatedForm }
            , Cmd.none
            , []
            )

        SetSachetsPerDay value ->
            let
                form =
                    model.feedingForm

                updatedForm =
                    { form | sachetsPerDay = String.toFloat value }
            in
            ( { model | feedingForm = updatedForm }
            , Cmd.none
            , []
            )

        SaveFeeding personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.feedingForm
                        |> toNutritionFeedingValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.HomeVisitEncounter.Model.SaveFeeding personId measurementId value
                                    |> Backend.Model.MsgHomeVisitEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| HomeVisitEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetHygieneBoolInput formUpdateFunc value ->
            let
                updatedForm =
                    formUpdateFunc value model.hygieneForm
            in
            ( { model | hygieneForm = updatedForm }
            , Cmd.none
            , []
            )

        SetMainWaterSource value ->
            let
                form =
                    model.hygieneForm

                updatedForm =
                    { form | mainWaterSource = Just value }
            in
            ( { model | hygieneForm = updatedForm }
            , Cmd.none
            , []
            )

        SaveHygiene personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.hygieneForm
                        |> toNutritionHygieneValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.HomeVisitEncounter.Model.SaveHygiene personId measurementId value
                                    |> Backend.Model.MsgHomeVisitEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| HomeVisitEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetFoodSecurityBoolInput formUpdateFunc value ->
            let
                updatedForm =
                    formUpdateFunc value model.foodSecurityForm
            in
            ( { model | foodSecurityForm = updatedForm }
            , Cmd.none
            , []
            )

        SetMainIncomeSource value ->
            let
                form =
                    model.foodSecurityForm

                updatedForm =
                    { form | mainIncomeSource = Just value }
            in
            ( { model | foodSecurityForm = updatedForm }
            , Cmd.none
            , []
            )

        SaveFoodSecurity personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.foodSecurityForm
                        |> toNutritionFoodSecurityValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.HomeVisitEncounter.Model.SaveFoodSecurity personId measurementId value
                                    |> Backend.Model.MsgHomeVisitEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| HomeVisitEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetParentsAliveAndHealthy value ->
            let
                form =
                    model.caringForm

                updatedForm =
                    { form | parentHealth = Just value }
            in
            ( { model | caringForm = updatedForm }
            , Cmd.none
            , []
            )

        SetChildClean value ->
            let
                form =
                    model.caringForm

                updatedForm =
                    { form | childClean = Just value }
            in
            ( { model | caringForm = updatedForm }
            , Cmd.none
            , []
            )

        SetNutritionCaringOption option ->
            let
                form =
                    model.caringForm

                updatedForm =
                    { form | caringOption = Just option }
            in
            ( { model | caringForm = updatedForm }
            , Cmd.none
            , []
            )

        SaveNutritionCaring personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], Just task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| HomeVisitEncounterPage id ]
                            , Nothing
                            )

                appMsgs =
                    model.caringForm
                        |> toNutritionCaringValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.HomeVisitEncounter.Model.SaveCaring personId measurementId value
                                    |> Backend.Model.MsgHomeVisitEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )
