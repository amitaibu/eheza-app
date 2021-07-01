module Pages.WellChildActivity.Update exposing (update)

import App.Model
import App.Ports exposing (bindDropZone)
import AssocList as Dict
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model
import Backend.Measurement.Model exposing (..)
import Backend.Model exposing (ModelIndexedDb)
import Backend.WellChildEncounter.Model
import EverySet exposing (EverySet)
import Gizra.NominalDate exposing (NominalDate)
import Gizra.Update exposing (sequenceExtra)
import Maybe.Extra exposing (isJust, isNothing, unwrap)
import Measurement.Model
    exposing
        ( HeightForm
        , MuacForm
        , NutritionForm
        , PhotoForm
        , WeightForm
        , emptyHeightForm
        , emptyMuacForm
        , emptyNutritionForm
        , emptyPhotoForm
        , emptyWeightForm
        )
import Measurement.Utils exposing (..)
import Pages.Page exposing (Page(..), UserPage(..))
import Pages.Utils exposing (setMultiSelectInputValue)
import Pages.WellChildActivity.Model exposing (..)
import Pages.WellChildActivity.Utils exposing (..)
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)


update : NominalDate -> WellChildEncounterId -> ModelIndexedDb -> Msg -> Model -> ( Model, Cmd Msg, List App.Model.Msg )
update currentDate id db msg model =
    let
        generateExtraMsgs nextTask =
            nextTask
                |> Maybe.map (\task -> [ SetActiveNutritionAssesmentTask task ])
                |> Maybe.withDefault [ SetActivePage <| UserPage <| WellChildEncounterPage id ]
    in
    case msg of
        SetActivePage page ->
            ( model
            , Cmd.none
            , [ App.Model.SetActivePage page ]
            )

        SetWarningPopupState state ->
            ( { model | warningPopupState = state }, Cmd.none, [] )

        NoOp ->
            ( model
            , Cmd.none
            , []
            )

        SetECDBoolInput formUpdateFunc value ->
            let
                updatedForm =
                    formUpdateFunc value model.ecdForm
            in
            ( { model | ecdForm = updatedForm }
            , Cmd.none
            , []
            )

        SaveECD personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.ecdForm
                        |> toWellChildECDValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.WellChildEncounter.Model.SaveECD personId measurementId value
                                    |> Backend.Model.MsgWellChildEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| WellChildEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetActiveNutritionAssesmentTask task ->
            let
                cmd =
                    case task of
                        TaskPhoto ->
                            bindDropZone ()

                        _ ->
                            Cmd.none

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | activeTask = Just task })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , cmd
            , []
            )

        SetHeight string ->
            let
                updatedForm =
                    model.nutritionAssessmentData.heightForm
                        |> (\form ->
                                { form | height = String.toFloat string, heightDirty = True }
                           )

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | heightForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveHeight personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.heightForm
                        |> toHeightValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveHeight personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetMuac string ->
            let
                updatedForm =
                    model.nutritionAssessmentData.muacForm
                        |> (\form ->
                                { form | muac = String.toFloat string, muacDirty = True }
                           )

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | muacForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveMuac personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.muacForm
                        |> toMuacValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveMuac personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetNutritionSign sign ->
            let
                form =
                    Dict.get id db.wellChildMeasurements
                        |> Maybe.withDefault NotAsked
                        |> RemoteData.toMaybe
                        |> Maybe.map
                            (.nutrition
                                >> Maybe.map (Tuple.second >> .value)
                                >> nutritionFormWithDefault model.nutritionAssessmentData.nutritionForm
                            )
                        |> Maybe.withDefault model.nutritionAssessmentData.nutritionForm

                updatedForm =
                    setMultiSelectInputValue .signs
                        (\signs -> { form | signs = signs })
                        NormalChildNutrition
                        sign
                        form

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | nutritionForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveNutrition personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.nutritionForm
                        |> toNutritionValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveNutrition personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        DropZoneComplete result ->
            let
                updatedForm =
                    model.nutritionAssessmentData.photoForm
                        |> (\form -> { form | url = Just (PhotoUrl result.url) })

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | photoForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SavePhoto personId maybePhotoId url nextTask_ ->
            let
                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    Backend.WellChildEncounter.Model.SavePhoto personId maybePhotoId url
                        |> Backend.Model.MsgWellChildEncounter id
                        |> App.Model.MsgIndexedDb
                        >> List.singleton

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | photoForm = emptyPhotoForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetWeight string ->
            let
                updatedForm =
                    model.nutritionAssessmentData.weightForm
                        |> (\form ->
                                { form | weight = String.toFloat string, weightDirty = True }
                           )

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | weightForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveWeight personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.weightForm
                        |> toWeightValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveWeight personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetReferToHealthCenter value ->
            let
                form =
                    model.nutritionAssessmentData.sendToHCForm

                updatedForm =
                    { form | referToHealthCenter = Just value, reasonForNotSendingToHC = Nothing }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | sendToHCForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SetHandReferralForm value ->
            let
                form =
                    model.nutritionAssessmentData.sendToHCForm

                updatedForm =
                    { form | handReferralForm = Just value }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | sendToHCForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SetReasonForNotSendingToHC value ->
            let
                form =
                    model.nutritionAssessmentData.sendToHCForm

                updatedForm =
                    { form | reasonForNotSendingToHC = Just value }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | sendToHCForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveSendToHC personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.sendToHCForm
                        |> toSendToHCValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveSendToHC personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetProvidedEducationForDiagnosis value ->
            let
                form =
                    model.nutritionAssessmentData.healthEducationForm

                updatedForm =
                    { form | educationForDiagnosis = Just value, reasonForNotProvidingHealthEducation = Nothing }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | healthEducationForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SetReasonForNotProvidingHealthEducation value ->
            let
                form =
                    model.nutritionAssessmentData.healthEducationForm

                updatedForm =
                    { form | reasonForNotProvidingHealthEducation = Just value }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | healthEducationForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveHealthEducation personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.healthEducationForm
                        |> toHealthEducationValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveHealthEducation personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetContributingFactorsSign sign ->
            let
                form =
                    Dict.get id db.wellChildMeasurements
                        |> Maybe.withDefault NotAsked
                        |> RemoteData.toMaybe
                        |> Maybe.map
                            (.contributingFactors
                                >> Maybe.map (Tuple.second >> .value)
                                >> contributingFactorsFormWithDefault model.nutritionAssessmentData.contributingFactorsForm
                            )
                        |> Maybe.withDefault model.nutritionAssessmentData.contributingFactorsForm

                updatedForm =
                    setMultiSelectInputValue .signs
                        (\signs -> { form | signs = signs })
                        NoContributingFactorsSign
                        sign
                        form

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | contributingFactorsForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveContributingFactors personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.contributingFactorsForm
                        |> toContributingFactorsValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveContributingFactors personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs

        SetFollowUpOption option ->
            let
                form =
                    model.nutritionAssessmentData.followUpForm

                updatedForm =
                    { form | option = Just option }

                updatedData =
                    model.nutritionAssessmentData
                        |> (\data -> { data | followUpForm = updatedForm })
            in
            ( { model | nutritionAssessmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveFollowUp personId saved assesment nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                extraMsgs =
                    generateExtraMsgs nextTask_

                appMsgs =
                    model.nutritionAssessmentData.followUpForm
                        |> (\form -> { form | assesment = Just assesment })
                        |> toFollowUpValueWithDefault measurement
                        |> Maybe.map
                            (Backend.WellChildEncounter.Model.SaveFollowUp personId measurementId
                                >> Backend.Model.MsgWellChildEncounter id
                                >> App.Model.MsgIndexedDb
                                >> List.singleton
                            )
                        |> Maybe.withDefault []
            in
            ( model
            , Cmd.none
            , appMsgs
            )
                |> sequenceExtra (update currentDate id db) extraMsgs