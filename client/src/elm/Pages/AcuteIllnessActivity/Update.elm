module Pages.AcuteIllnessActivity.Update exposing (update)

import App.Model
import AssocList as Dict
import Backend.AcuteIllnessEncounter.Model
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model
import Backend.Measurement.Decoder exposing (malariaRapidTestResultFromString)
import Backend.Measurement.Model
    exposing
        ( AcuteFindingsGeneralSign(..)
        , AcuteFindingsRespiratorySign(..)
        , AcuteIllnessDangerSign(..)
        , HCRecommendation(..)
        , MalariaRapidTestResult(..)
        , MedicationDistributionSign(..)
        , MedicationNonAdministrationSign(..)
        , ReasonForNotIsolating(..)
        , Recommendation114(..)
        , RecommendationSite(..)
        , ResponsePeriod(..)
        , SymptomsGISign(..)
        , SymptomsGeneralSign(..)
        , SymptomsRespiratorySign(..)
        )
import Backend.Model exposing (ModelIndexedDb)
import EverySet exposing (EverySet)
import Gizra.NominalDate exposing (NominalDate)
import Maybe.Extra exposing (isJust, isNothing, unwrap)
import Pages.AcuteIllnessActivity.Model exposing (..)
import Pages.AcuteIllnessActivity.Utils exposing (..)
import Pages.Page exposing (Page(..), UserPage(..))
import Pages.Utils exposing (ifEverySetEmpty)
import RemoteData exposing (RemoteData(..))
import Result exposing (Result)


update : NominalDate -> AcuteIllnessEncounterId -> ModelIndexedDb -> Msg -> Model -> ( Model, Cmd Msg, List App.Model.Msg )
update currentDate id db msg model =
    let
        noChange =
            ( model, Cmd.none, [] )

        resolveFormWithDefaults getMeasurementFunc formWithDefaultsFunc form =
            Dict.get id db.acuteIllnessMeasurements
                |> Maybe.withDefault NotAsked
                |> RemoteData.toMaybe
                |> Maybe.map
                    (getMeasurementFunc
                        >> Maybe.map (Tuple.second >> .value)
                        >> formWithDefaultsFunc form
                    )
                |> Maybe.withDefault form

        symptomsGeneralForm =
            resolveFormWithDefaults .symptomsGeneral symptomsGeneralFormWithDefault model.symptomsData.symptomsGeneralForm

        symptomsRespiratoryForm =
            resolveFormWithDefaults .symptomsRespiratory symptomsRespiratoryFormWithDefault model.symptomsData.symptomsRespiratoryForm

        symptomsGIForm =
            resolveFormWithDefaults .symptomsGI symptomsGIFormWithDefault model.symptomsData.symptomsGIForm

        acuteFindingsForm =
            resolveFormWithDefaults .acuteFindings acuteFindingsFormWithDefault model.physicalExamData.acuteFindingsForm

        reviewDangerSignsForm =
            resolveFormWithDefaults .dangerSigns dangerSignsReviewFormWithDefault model.dangerSignsData.reviewDangerSignsForm
    in
    case msg of
        SetActivePage page ->
            ( model
            , Cmd.none
            , [ App.Model.SetActivePage page ]
            )

        SetAlertsDialogState isOpen ->
            ( { model | showAlertsDialog = isOpen }, Cmd.none, [] )

        SetWarningPopupState diagnosis ->
            ( { model | warningPopupState = diagnosis }, Cmd.none, [] )

        SetPertinentSymptomsPopupState isOpen ->
            ( { model | showPertinentSymptomsPopup = isOpen }, Cmd.none, [] )

        SetActiveSymptomsTask task ->
            let
                updatedData =
                    model.symptomsData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , []
            )

        ToggleSymptomsGeneralSign sign ->
            let
                updatedSigns =
                    toggleSymptomsSign SymptomsGeneral sign NoSymptomsGeneral symptomsGeneralForm.signs

                updatedForm =
                    { symptomsGeneralForm | signs = updatedSigns, signsDirty = True }

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | symptomsGeneralForm = updatedForm })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , []
            )

        ToggleSymptomsGISign sign ->
            let
                updatedSigns =
                    toggleSymptomsSign SymptomsGI sign NoSymptomsGI symptomsGIForm.signs

                updatedForm =
                    { symptomsGIForm | signs = updatedSigns, signsDirty = True }

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | symptomsGIForm = updatedForm })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , []
            )

        ToggleSymptomsRespiratorySign sign ->
            let
                updatedSigns =
                    toggleSymptomsSign SymptomsRespiratory sign NoSymptomsRespiratory symptomsRespiratoryForm.signs

                updatedForm =
                    { symptomsRespiratoryForm | signs = updatedSigns, signsDirty = True }

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | symptomsRespiratoryForm = updatedForm })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , []
            )

        SetSymptomsGeneralSignValue sign string ->
            String.toInt string
                |> Maybe.map
                    (\value ->
                        let
                            updatedForm =
                                { symptomsGeneralForm | signs = Dict.insert sign value symptomsGeneralForm.signs }

                            updatedData =
                                model.symptomsData
                                    |> (\data -> { data | symptomsGeneralForm = updatedForm })
                        in
                        ( { model | symptomsData = updatedData }
                        , Cmd.none
                        , []
                        )
                    )
                |> Maybe.withDefault noChange

        SetSymptomsGISignValue sign string ->
            String.toInt string
                |> Maybe.map
                    (\value ->
                        let
                            updatedForm =
                                { symptomsGIForm | signs = Dict.insert sign value symptomsGIForm.signs }

                            updatedData =
                                model.symptomsData
                                    |> (\data -> { data | symptomsGIForm = updatedForm })
                        in
                        ( { model | symptomsData = updatedData }
                        , Cmd.none
                        , []
                        )
                    )
                |> Maybe.withDefault noChange

        SetSymptomsRespiratorySignValue sign string ->
            String.toInt string
                |> Maybe.map
                    (\value ->
                        let
                            updatedForm =
                                { symptomsRespiratoryForm | signs = Dict.insert sign value symptomsRespiratoryForm.signs }

                            updatedData =
                                model.symptomsData
                                    |> (\data -> { data | symptomsRespiratoryForm = updatedForm })
                        in
                        ( { model | symptomsData = updatedData }
                        , Cmd.none
                        , []
                        )
                    )
                |> Maybe.withDefault noChange

        SetSymptomsGIIntractableVomiting value ->
            let
                updatedForm =
                    { symptomsGIForm | intractableVomiting = Just value, intractableVomitingDirty = True }

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | symptomsGIForm = updatedForm })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , []
            )

        SaveSymptomsGeneral personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , SymptomsGeneral
                            )

                form =
                    model.symptomsData.symptomsGeneralForm

                value =
                    toSymptomsGeneralValueWithDefault measurement form

                appMsgs =
                    (Backend.AcuteIllnessEncounter.Model.SaveSymptomsGeneral personId measurementId value
                        |> Backend.Model.MsgAcuteIllnessEncounter id
                        |> App.Model.MsgIndexedDb
                    )
                        :: backToActivitiesMsg

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SaveSymptomsRespiratory personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , SymptomsGeneral
                            )

                form =
                    model.symptomsData.symptomsRespiratoryForm

                value =
                    toSymptomsRespiratoryValueWithDefault measurement form

                appMsgs =
                    (Backend.AcuteIllnessEncounter.Model.SaveSymptomsRespiratory personId measurementId value
                        |> Backend.Model.MsgAcuteIllnessEncounter id
                        |> App.Model.MsgIndexedDb
                    )
                        :: backToActivitiesMsg

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SaveSymptomsGI personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , SymptomsGeneral
                            )

                form =
                    model.symptomsData.symptomsGIForm

                value =
                    toSymptomsGIValueWithDefault measurement form

                appMsgs =
                    (Backend.AcuteIllnessEncounter.Model.SaveSymptomsGI personId measurementId value
                        |> Backend.Model.MsgAcuteIllnessEncounter id
                        |> App.Model.MsgIndexedDb
                    )
                        :: backToActivitiesMsg

                updatedData =
                    model.symptomsData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | symptomsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetActivePhysicalExamTask task ->
            let
                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , []
            )

        SetVitalsResporatoryRate value ->
            let
                form =
                    model.physicalExamData.vitalsForm

                updatedForm =
                    { form | respiratoryRate = String.toInt value, respiratoryRateDirty = True }

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | vitalsForm = updatedForm })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , []
            )

        SetVitalsBodyTemperature value ->
            let
                form =
                    model.physicalExamData.vitalsForm

                updatedForm =
                    { form | bodyTemperature = String.toFloat value, bodyTemperatureDirty = True }

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | vitalsForm = updatedForm })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , []
            )

        SetAcuteFindingsGeneralSign sign ->
            let
                form =
                    acuteFindingsForm

                updatedForm =
                    case form.signsGeneral of
                        Just signs ->
                            if List.member sign signs then
                                let
                                    updatedSigns =
                                        if List.length signs == 1 then
                                            Nothing

                                        else
                                            signs |> List.filter ((/=) sign) |> Just
                                in
                                { form | signsGeneral = updatedSigns }

                            else
                                case sign of
                                    NoAcuteFindingsGeneralSigns ->
                                        { form | signsGeneral = Just [ sign ] }

                                    _ ->
                                        let
                                            updatedSigns =
                                                case signs of
                                                    [ NoAcuteFindingsGeneralSigns ] ->
                                                        Just [ sign ]

                                                    _ ->
                                                        Just (sign :: signs)
                                        in
                                        { form | signsGeneral = updatedSigns }

                        Nothing ->
                            { form | signsGeneral = Just [ sign ] }

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | acuteFindingsForm = updatedForm })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , []
            )

        SetAcuteFindingsRespiratorySign sign ->
            let
                form =
                    acuteFindingsForm

                updatedForm =
                    case form.signsRespiratory of
                        Just signs ->
                            if List.member sign signs then
                                let
                                    updatedSigns =
                                        if List.length signs == 1 then
                                            Nothing

                                        else
                                            signs |> List.filter ((/=) sign) |> Just
                                in
                                { form | signsRespiratory = updatedSigns }

                            else
                                case sign of
                                    NoAcuteFindingsRespiratorySigns ->
                                        { form | signsRespiratory = Just [ sign ] }

                                    _ ->
                                        let
                                            updatedSigns =
                                                case signs of
                                                    [ NoAcuteFindingsRespiratorySigns ] ->
                                                        Just [ sign ]

                                                    _ ->
                                                        Just (sign :: signs)
                                        in
                                        { form | signsRespiratory = updatedSigns }

                        Nothing ->
                            { form | signsRespiratory = Just [ sign ] }

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | acuteFindingsForm = updatedForm })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , []
            )

        SaveVitals personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , PhysicalExamVitals
                            )

                appMsgs =
                    model.physicalExamData.vitalsForm
                        |> toVitalsValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveVitals personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SaveAcuteFindings personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , PhysicalExamVitals
                            )

                appMsgs =
                    model.physicalExamData.acuteFindingsForm
                        |> toAcuteFindingsValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveAcuteFindings personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.physicalExamData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | physicalExamData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetActiveLaboratoryTask task ->
            let
                updatedData =
                    model.laboratoryData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | laboratoryData = updatedData }
            , Cmd.none
            , []
            )

        SetRapidTestResult value ->
            let
                form =
                    model.laboratoryData.malariaTestingForm

                updatedForm =
                    { form | rapidTestResult = malariaRapidTestResultFromString value }

                updatedData =
                    model.laboratoryData
                        |> (\data -> { data | malariaTestingForm = updatedForm })
            in
            ( { model | laboratoryData = updatedData }
            , Cmd.none
            , []
            )

        SetIsPregnant value ->
            let
                form =
                    model.laboratoryData.malariaTestingForm

                updatedForm =
                    { form | isPregnant = Just value }

                updatedData =
                    model.laboratoryData
                        |> (\data -> { data | malariaTestingForm = updatedForm })
            in
            ( { model | laboratoryData = updatedData }
            , Cmd.none
            , []
            )

        SaveMalariaTesting personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.laboratoryData.malariaTestingForm
                        |> toMalariaTestingValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveMalariaTesting personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetActiveExposureTask task ->
            let
                updatedData =
                    model.exposureData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | exposureData = updatedData }
            , Cmd.none
            , []
            )

        SetCovid19Country value ->
            let
                form =
                    model.exposureData.travelHistoryForm

                updatedForm =
                    { form | covid19Country = Just value }

                updatedData =
                    model.exposureData
                        |> (\data -> { data | travelHistoryForm = updatedForm })
            in
            ( { model | exposureData = updatedData }
            , Cmd.none
            , []
            )

        SaveTravelHistory personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , ExposureTravel
                            )

                appMsgs =
                    model.exposureData.travelHistoryForm
                        |> toTravelHistoryValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveTravelHistory personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.exposureData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | exposureData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetCovid19Symptoms value ->
            let
                form =
                    model.exposureData.exposureForm

                updatedForm =
                    { form | covid19Symptoms = Just value }

                updatedData =
                    model.exposureData
                        |> (\data -> { data | exposureForm = updatedForm })
            in
            ( { model | exposureData = updatedData }
            , Cmd.none
            , []
            )

        SaveExposure personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , ExposureTravel
                            )

                appMsgs =
                    model.exposureData.exposureForm
                        |> toExposureValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveExposure personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.exposureData
                        |> (\data -> { data | activeTask = nextTask })
            in
            ( { model | exposureData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetActivePriorTreatmentTask task ->
            let
                updatedData =
                    model.priorTreatmentData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | priorTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SetTreatmentReviewBoolInput formUpdateFunc value ->
            let
                updatedData =
                    let
                        updatedForm =
                            formUpdateFunc value model.priorTreatmentData.treatmentReviewForm
                    in
                    model.priorTreatmentData
                        |> (\data -> { data | treatmentReviewForm = updatedForm })
            in
            ( { model | priorTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveTreatmentReview personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.priorTreatmentData.treatmentReviewForm
                        |> toTreatmentReviewValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveTreatmentReview personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetActiveNextStepsTask task ->
            let
                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | activeTask = Just task })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetPatientIsolated value ->
            let
                form =
                    model.nextStepsData.isolationForm

                updatedForm =
                    { form | patientIsolated = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | isolationForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetHealthEducation value ->
            let
                form =
                    model.nextStepsData.isolationForm

                updatedForm =
                    { form | healthEducation = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | isolationForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetSignOnDoor value ->
            let
                form =
                    model.nextStepsData.isolationForm

                updatedForm =
                    { form | signOnDoor = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | isolationForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetReasonForNotIsolating reason ->
            let
                form =
                    Dict.get id db.acuteIllnessMeasurements
                        |> Maybe.withDefault NotAsked
                        |> RemoteData.toMaybe
                        |> Maybe.map
                            (.isolation
                                >> Maybe.map (Tuple.second >> .value)
                                >> isolationFormWithDefault model.nextStepsData.isolationForm
                            )
                        |> Maybe.withDefault model.nextStepsData.isolationForm

                updatedForm =
                    case form.reasonsForNotIsolating of
                        Just reasons ->
                            case reasons of
                                [ IsolationReasonNotApplicable ] ->
                                    { form | reasonsForNotIsolating = [ reason ] |> Just }

                                _ ->
                                    if List.member reason reasons then
                                        let
                                            updated =
                                                if List.length reasons == 1 then
                                                    Nothing

                                                else
                                                    reasons |> List.filter ((/=) reason) |> Just
                                        in
                                        { form | reasonsForNotIsolating = updated }

                                    else
                                        { form | reasonsForNotIsolating = reason :: reasons |> Just }

                        Nothing ->
                            { form | reasonsForNotIsolating = Just [ reason ] }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | isolationForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SaveIsolation personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , NextStepsIsolation
                            )

                appMsgs =
                    model.nextStepsData.isolationForm
                        |> toIsolationValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveIsolation personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | activeTask = Just nextTask })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetContactedHC value ->
            let
                form =
                    model.nextStepsData.hcContactForm

                updatedForm =
                    { form | contactedHC = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | hcContactForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetHCRecommendation value ->
            let
                form =
                    model.nextStepsData.hcContactForm

                updatedForm =
                    case form.recommendations of
                        Just period ->
                            if period == value then
                                { form | recommendations = Nothing }

                            else
                                { form | recommendations = Just value }

                        Nothing ->
                            { form | recommendations = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | hcContactForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetResponsePeriod value ->
            let
                form =
                    model.nextStepsData.hcContactForm

                updatedForm =
                    case form.responsePeriod of
                        Just period ->
                            if period == value then
                                { form | responsePeriod = Nothing }

                            else
                                { form | responsePeriod = Just value }

                        Nothing ->
                            { form | responsePeriod = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | hcContactForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetAmbulanceArrivalPeriod value ->
            let
                form =
                    model.nextStepsData.hcContactForm

                updatedForm =
                    case form.ambulanceArrivalPeriod of
                        Just period ->
                            if period == value then
                                { form | ambulanceArrivalPeriod = Nothing }

                            else
                                { form | ambulanceArrivalPeriod = Just value }

                        Nothing ->
                            { form | ambulanceArrivalPeriod = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | hcContactForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SaveHCContact personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , NextStepsIsolation
                            )

                appMsgs =
                    model.nextStepsData.hcContactForm
                        |> toHCContactValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveHCContact personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | activeTask = Just nextTask })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetCalled114 value ->
            let
                form =
                    model.nextStepsData.call114Form

                updatedForm =
                    { form
                        | called114 = Just value
                        , recommendation114 = Nothing
                        , recommendation114Dirty = True
                        , contactedSite = Nothing
                        , contactedSiteDirty = True
                        , recommendationSite = Nothing
                        , recommendationSiteDirty = True
                    }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | call114Form = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetRecommendation114 value ->
            let
                form =
                    model.nextStepsData.call114Form

                updatedForm =
                    case form.recommendation114 of
                        Just period ->
                            if period == value then
                                { form
                                    | recommendation114 = Nothing
                                    , recommendation114Dirty = True
                                    , contactedSite = Nothing
                                    , contactedSiteDirty = True
                                    , recommendationSite = Nothing
                                    , recommendationSiteDirty = True
                                }

                            else
                                { form
                                    | recommendation114 = Just value
                                    , recommendation114Dirty = True
                                    , contactedSite = Nothing
                                    , contactedSiteDirty = True
                                    , recommendationSite = Nothing
                                    , recommendationSiteDirty = True
                                }

                        Nothing ->
                            { form
                                | recommendation114 = Just value
                                , recommendation114Dirty = True
                                , contactedSite = Nothing
                                , contactedSiteDirty = True
                                , recommendationSite = Nothing
                                , recommendationSiteDirty = True
                            }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | call114Form = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetContactedSite value ->
            let
                form =
                    model.nextStepsData.call114Form

                updatedForm =
                    { form
                        | contactedSite = Just value
                        , contactedSiteDirty = True
                        , recommendationSite = Nothing
                        , recommendationSiteDirty = True
                    }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | call114Form = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetRecommendationSite value ->
            let
                form =
                    model.nextStepsData.call114Form

                updatedForm =
                    case form.recommendationSite of
                        Just period ->
                            if period == value then
                                { form | recommendationSite = Nothing, recommendationSiteDirty = True }

                            else
                                { form | recommendationSite = Just value, recommendationSiteDirty = True }

                        Nothing ->
                            { form | recommendationSite = Just value, recommendationSiteDirty = True }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | call114Form = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SaveCall114 personId saved nextTask_ ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                ( backToActivitiesMsg, nextTask ) =
                    nextTask_
                        |> Maybe.map (\task -> ( [], task ))
                        |> Maybe.withDefault
                            ( [ App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id ]
                            , NextStepsIsolation
                            )

                appMsgs =
                    model.nextStepsData.call114Form
                        |> toCall114ValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                (Backend.AcuteIllnessEncounter.Model.SaveCall114 personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                )
                                    :: backToActivitiesMsg
                            )

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | activeTask = Just nextTask })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , appMsgs
            )

        SetReferToHealthCenter value ->
            let
                form =
                    model.nextStepsData.sendToHCForm

                updatedForm =
                    { form | referToHealthCenter = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | sendToHCForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetHandReferralForm value ->
            let
                form =
                    model.nextStepsData.sendToHCForm

                updatedForm =
                    { form | handReferralForm = Just value }

                updatedData =
                    model.nextStepsData
                        |> (\data -> { data | sendToHCForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SaveSendToHC personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.nextStepsData.sendToHCForm
                        |> toSendToHCValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveSendToHC personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetMedicationDistributionBoolInput formUpdateFunc value ->
            let
                updatedData =
                    let
                        updatedForm =
                            formUpdateFunc value model.nextStepsData.medicationDistributionForm
                    in
                    model.nextStepsData
                        |> (\data -> { data | medicationDistributionForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SetMedicationDistributionMedicationNonAdministrationReason currentValue medication reason ->
            let
                form =
                    model.nextStepsData.medicationDistributionForm

                updatedValue =
                    nonAdministrationReasonToSign medication reason

                updatedNonAdministrationSigns =
                    form.nonAdministrationSigns
                        |> Maybe.map
                            (\nonAdministrationSigns ->
                                case currentValue of
                                    Just value ->
                                        EverySet.remove (nonAdministrationReasonToSign medication value) nonAdministrationSigns
                                            |> EverySet.insert updatedValue

                                    Nothing ->
                                        EverySet.insert updatedValue nonAdministrationSigns
                            )
                        |> Maybe.withDefault (EverySet.singleton updatedValue)

                updatedData =
                    let
                        updatedForm =
                            { form | nonAdministrationSigns = Just updatedNonAdministrationSigns }
                    in
                    model.nextStepsData
                        |> (\data -> { data | medicationDistributionForm = updatedForm })
            in
            ( { model | nextStepsData = updatedData }
            , Cmd.none
            , []
            )

        SaveMedicationDistribution personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.nextStepsData.medicationDistributionForm
                        |> toMedicationDistributionValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveMedicationDistribution personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetActiveOngoingTreatmentTask task ->
            let
                updatedData =
                    model.ongoingTreatmentData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | ongoingTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SetOngoingTreatmentReviewBoolInput formUpdateFunc value ->
            let
                updatedData =
                    let
                        updatedForm =
                            formUpdateFunc value model.ongoingTreatmentData.treatmentReviewForm
                    in
                    model.ongoingTreatmentData
                        |> (\data -> { data | treatmentReviewForm = updatedForm })
            in
            ( { model | ongoingTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SetReasonForNotTaking value ->
            let
                form =
                    model.ongoingTreatmentData.treatmentReviewForm

                updatedForm =
                    { form | reasonForNotTaking = Just value, reasonForNotTakingDirty = True }

                updatedData =
                    model.ongoingTreatmentData
                        |> (\data -> { data | treatmentReviewForm = updatedForm })
            in
            ( { model | ongoingTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SetTotalMissedDoses value ->
            let
                form =
                    model.ongoingTreatmentData.treatmentReviewForm

                updatedForm =
                    { form | totalMissedDoses = String.toInt value, totalMissedDosesDirty = True }

                updatedData =
                    model.ongoingTreatmentData
                        |> (\data -> { data | treatmentReviewForm = updatedForm })
            in
            ( { model | ongoingTreatmentData = updatedData }
            , Cmd.none
            , []
            )

        SaveOngoingTreatmentReview personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.ongoingTreatmentData.treatmentReviewForm
                        |> toOngoingTreatmentReviewValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveTreatmentOngoing personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )

        SetActiveDangerSignsTask task ->
            let
                updatedData =
                    model.dangerSignsData
                        |> (\data -> { data | activeTask = task })
            in
            ( { model | dangerSignsData = updatedData }
            , Cmd.none
            , []
            )

        SetConditionImproving value ->
            let
                form =
                    model.dangerSignsData.reviewDangerSignsForm

                updatedForm =
                    { form | conditionImproving = Just value }

                updatedData =
                    model.dangerSignsData
                        |> (\data -> { data | reviewDangerSignsForm = updatedForm })
            in
            ( { model | dangerSignsData = updatedData }
            , Cmd.none
            , []
            )

        SetDangerSign sign ->
            let
                form =
                    reviewDangerSignsForm

                updatedForm =
                    case form.symptoms of
                        Just signs ->
                            if List.member sign signs then
                                let
                                    updatedSigns =
                                        if List.length signs == 1 then
                                            Nothing

                                        else
                                            signs |> List.filter ((/=) sign) |> Just
                                in
                                { form | symptoms = updatedSigns }

                            else
                                case sign of
                                    NoAcuteIllnessDangerSign ->
                                        { form | symptoms = Just [ sign ] }

                                    _ ->
                                        let
                                            updatedSigns =
                                                case signs of
                                                    [ NoAcuteIllnessDangerSign ] ->
                                                        Just [ sign ]

                                                    _ ->
                                                        Just (sign :: signs)
                                        in
                                        { form | symptoms = updatedSigns }

                        Nothing ->
                            { form | symptoms = Just [ sign ] }

                updatedData =
                    model.dangerSignsData
                        |> (\data -> { data | reviewDangerSignsForm = updatedForm })
            in
            ( { model | dangerSignsData = updatedData }
            , Cmd.none
            , []
            )

        SaveReviewDangerSigns personId saved ->
            let
                measurementId =
                    Maybe.map Tuple.first saved

                measurement =
                    Maybe.map (Tuple.second >> .value) saved

                appMsgs =
                    model.dangerSignsData.reviewDangerSignsForm
                        |> toDangerSignsReviewValueWithDefault measurement
                        |> unwrap
                            []
                            (\value ->
                                [ Backend.AcuteIllnessEncounter.Model.SaveAcuteIllnessDangerSigns personId measurementId value
                                    |> Backend.Model.MsgAcuteIllnessEncounter id
                                    |> App.Model.MsgIndexedDb
                                , App.Model.SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
                                ]
                            )
            in
            ( model
            , Cmd.none
            , appMsgs
            )
