module Pages.AcuteIllnessActivity.View exposing (view, viewAdministeredMedicationLabel, viewHCRecomendation, viewOralSolutionPrescription, viewSendToHCActionLabel, viewTabletsPrescription)

import AcuteIllnessActivity.Model exposing (AcuteIllnessActivity(..))
import AssocList as Dict exposing (Dict)
import Backend.AcuteIllnessEncounter.Model exposing (AcuteIllnessEncounter)
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (IndividualEncounterParticipant)
import Backend.Measurement.Encoder exposing (malariaRapidTestResultAsString)
import Backend.Measurement.Model exposing (..)
import Backend.Model exposing (ModelIndexedDb)
import Backend.Person.Model exposing (Person)
import Backend.Person.Utils exposing (isPersonAFertileWoman)
import EverySet
import Gizra.Html exposing (emptyNode)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Maybe.Extra exposing (isJust, isNothing, unwrap)
import Pages.AcuteIllnessActivity.Model exposing (..)
import Pages.AcuteIllnessActivity.Utils exposing (..)
import Pages.AcuteIllnessEncounter.Model exposing (AcuteIllnessDiagnosis(..), AssembledData)
import Pages.AcuteIllnessEncounter.Utils exposing (..)
import Pages.AcuteIllnessEncounter.View exposing (viewPersonDetailsWithAlert, warningPopup)
import Pages.Page exposing (Page(..), UserPage(..))
import Pages.Utils
    exposing
        ( isTaskCompleted
        , taskCompleted
        , taskListCompleted
        , tasksBarId
        , viewBoolInput
        , viewCheckBoxMultipleSelectInput
        , viewCheckBoxSelectCustomInput
        , viewCheckBoxSelectInput
        , viewCheckBoxValueInput
        , viewCustomLabel
        , viewLabel
        , viewMeasurementInput
        , viewPhotoThumbFromPhotoUrl
        , viewPreviousMeasurement
        , viewQuestionLabel
        )
import RemoteData exposing (RemoteData(..), WebData)
import Translate exposing (Language, TranslationId, translate)
import Utils.Html exposing (viewModal)
import Utils.NominalDate exposing (renderDate)
import Utils.WebData exposing (viewWebData)


view : Language -> NominalDate -> AcuteIllnessEncounterId -> AcuteIllnessActivity -> ModelIndexedDb -> Model -> Html Msg
view language currentDate id activity db model =
    let
        data =
            generateAssembledData id db
    in
    viewWebData language (viewHeaderAndContent language currentDate id activity model) identity data


viewHeaderAndContent : Language -> NominalDate -> AcuteIllnessEncounterId -> AcuteIllnessActivity -> Model -> AssembledData -> Html Msg
viewHeaderAndContent language currentDate id activity model data =
    let
        diagnosis =
            resolveAcuteIllnessDiagnosis currentDate data.person data.measurements
    in
    div [ class "page-activity acute-illness" ]
        [ viewHeader language id activity diagnosis
        , viewContent language currentDate id activity model data
        , viewModal <|
            warningPopup language
                model.warningPopupState
                SetWarningPopupState
        ]


viewHeader : Language -> AcuteIllnessEncounterId -> AcuteIllnessActivity -> Maybe AcuteIllnessDiagnosis -> Html Msg
viewHeader language id activity diagnosis =
    let
        title =
            case activity of
                AcuteIllnessNextSteps ->
                    let
                        prefix =
                            diagnosis
                                |> Maybe.map
                                    (Translate.AcuteIllnessDiagnosis
                                        >> translate language
                                        >> (\diagnosisTitle -> diagnosisTitle ++ ": ")
                                    )
                                |> Maybe.withDefault ""
                    in
                    prefix ++ translate language (Translate.AcuteIllnessActivityTitle activity)

                _ ->
                    translate language <| Translate.AcuteIllnessActivityTitle activity
    in
    div
        [ class "ui basic segment head" ]
        [ h1
            [ class "ui header" ]
            [ text title ]
        , a
            [ class "link-back"
            , onClick <| SetActivePage <| UserPage <| AcuteIllnessEncounterPage id
            ]
            [ span [ class "icon-back" ] []
            , span [] []
            ]
        ]


viewContent : Language -> NominalDate -> AcuteIllnessEncounterId -> AcuteIllnessActivity -> Model -> AssembledData -> Html Msg
viewContent language currentDate id activity model data =
    let
        diagnosis =
            resolveAcuteIllnessDiagnosis currentDate data.person data.measurements
    in
    (viewPersonDetailsWithAlert language currentDate data.person diagnosis model.showAlertsDialog SetAlertsDialogState
        :: viewActivity language currentDate id activity diagnosis data model
    )
        |> div [ class "ui unstackable items" ]


viewActivity : Language -> NominalDate -> AcuteIllnessEncounterId -> AcuteIllnessActivity -> Maybe AcuteIllnessDiagnosis -> AssembledData -> Model -> List (Html Msg)
viewActivity language currentDate id activity diagnosis data model =
    let
        personId =
            data.participant.person

        measurements =
            data.measurements
    in
    case activity of
        AcuteIllnessSymptoms ->
            viewAcuteIllnessSymptomsContent language currentDate id ( personId, measurements ) model.symptomsData

        AcuteIllnessPhysicalExam ->
            viewAcuteIllnessPhysicalExam language currentDate id ( personId, measurements ) model.physicalExamData

        AcuteIllnessPriorTreatment ->
            viewAcuteIllnessPriorTreatment language currentDate id ( personId, measurements ) model.priorTreatmentData

        AcuteIllnessLaboratory ->
            viewAcuteIllnessLaboratory language currentDate id ( personId, data.person, measurements ) model.laboratoryData

        AcuteIllnessExposure ->
            viewAcuteIllnessExposure language currentDate id ( personId, measurements ) model.exposureData

        AcuteIllnessNextSteps ->
            viewAcuteIllnessNextSteps language currentDate id ( personId, data.person, measurements ) diagnosis model.nextStepsData


viewAcuteIllnessSymptomsContent : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, AcuteIllnessMeasurements ) -> SymptomsData -> List (Html Msg)
viewAcuteIllnessSymptomsContent language currentDate id ( personId, measurements ) data =
    let
        activity =
            AcuteIllnessSymptoms

        tasks =
            [ SymptomsGeneral, SymptomsRespiratory, SymptomsGI ]

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        SymptomsGeneral ->
                            ( "symptoms-general", isJust measurements.symptomsGeneral )

                        SymptomsRespiratory ->
                            ( "symptoms-respiratory", isJust measurements.symptomsRespiratory )

                        SymptomsGI ->
                            ( "symptoms-gi", isJust measurements.symptomsGI )

                isActive =
                    task == data.activeTask

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActiveSymptomsTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.SymptomsTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, symptomsTasksCompletedFromTotal measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            Dict.get data.activeTask tasksCompletedFromTotalDict
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case data.activeTask of
                SymptomsGeneral ->
                    measurements.symptomsGeneral
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsGeneralFormWithDefault data.symptomsGeneralForm
                        |> viewSymptomsGeneralForm language currentDate measurements

                SymptomsRespiratory ->
                    measurements.symptomsRespiratory
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsRespiratoryFormWithDefault data.symptomsRespiratoryForm
                        |> viewSymptomsRespiratoryForm language currentDate measurements

                SymptomsGI ->
                    measurements.symptomsGI
                        |> Maybe.map (Tuple.second >> .value)
                        |> symptomsGIFormWithDefault data.symptomsGIForm
                        |> viewSymptomsGIForm language currentDate measurements

        getNextTask currentTask =
            case currentTask of
                SymptomsGeneral ->
                    [ SymptomsRespiratory, SymptomsGI ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                SymptomsRespiratory ->
                    [ SymptomsGI, SymptomsGeneral ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                SymptomsGI ->
                    [ SymptomsGeneral, SymptomsRespiratory ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

        actions =
            let
                nextTask =
                    getNextTask data.activeTask

                saveMsg =
                    case data.activeTask of
                        SymptomsGeneral ->
                            SaveSymptomsGeneral personId measurements.symptomsGeneral nextTask

                        SymptomsRespiratory ->
                            SaveSymptomsRespiratory personId measurements.symptomsRespiratory nextTask

                        SymptomsGI ->
                            SaveSymptomsGI personId measurements.symptomsGI nextTask
            in
            div [ class "actions symptoms" ]
                [ button
                    [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                    , onClick saveMsg
                    ]
                    [ text <| translate language Translate.Save ]
                ]
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui three column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewSymptomsGeneralForm : Language -> NominalDate -> AcuteIllnessMeasurements -> SymptomsGeneralForm -> Html Msg
viewSymptomsGeneralForm language currentDate measurements form =
    viewCheckBoxValueInput language
        allSymptomsGeneralSigns
        form.signs
        ToggleSymptomsGeneralSign
        SetSymptomsGeneralSignValue
        Translate.SymptomsGeneralSign
        |> List.append
            [ viewQuestionLabel language Translate.PatientGotAnySymptoms
            , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
            ]
        |> div [ class "symptoms-form general" ]


viewSymptomsRespiratoryForm : Language -> NominalDate -> AcuteIllnessMeasurements -> SymptomsRespiratoryForm -> Html Msg
viewSymptomsRespiratoryForm language currentDate measurements form =
    viewCheckBoxValueInput language
        allSymptomsRespiratorySigns
        form.signs
        ToggleSymptomsRespiratorySign
        SetSymptomsRespiratorySignValue
        Translate.SymptomsRespiratorySign
        |> List.append
            [ viewQuestionLabel language Translate.PatientGotAnySymptoms
            , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
            ]
        |> div [ class "symptoms-form respiratory" ]


viewSymptomsGIForm : Language -> NominalDate -> AcuteIllnessMeasurements -> SymptomsGIForm -> Html Msg
viewSymptomsGIForm language currentDate measurements form =
    let
        symptoms =
            viewCheckBoxValueInput language
                allSymptomsGISigns
                form.signs
                ToggleSymptomsGISign
                SetSymptomsGISignValue
                Translate.SymptomsGISign
                |> List.append
                    [ viewQuestionLabel language Translate.PatientGotAnySymptoms
                    , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
                    ]

        derivedQuestions =
            if Dict.member Vomiting form.signs then
                [ viewQuestionLabel language Translate.IntractableVomitingQuestion
                , viewBoolInput language
                    form.intractableVomiting
                    SetSymptomsGIIntractableVomiting
                    "intractable-vomiting"
                    Nothing
                ]

            else
                []
    in
    div [ class "symptoms-form gi" ]
        [ div [ class "symptoms" ] symptoms
        , div [ class "derived-questions" ] derivedQuestions
        ]


viewAcuteIllnessPhysicalExam : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, AcuteIllnessMeasurements ) -> PhysicalExamData -> List (Html Msg)
viewAcuteIllnessPhysicalExam language currentDate id ( personId, measurements ) data =
    let
        activity =
            AcuteIllnessPhysicalExam

        tasks =
            [ PhysicalExamVitals, PhysicalExamAcuteFindings ]

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        PhysicalExamVitals ->
                            ( "physical-exam-vitals"
                            , isJust measurements.vitals
                            )

                        PhysicalExamAcuteFindings ->
                            ( "acute-findings"
                            , isJust measurements.acuteFindings
                            )

                isActive =
                    task == data.activeTask

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActivePhysicalExamTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.PhysicalExamTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, physicalExamTasksCompletedFromTotal measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            Dict.get data.activeTask tasksCompletedFromTotalDict
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case data.activeTask of
                PhysicalExamVitals ->
                    measurements.vitals
                        |> Maybe.map (Tuple.second >> .value)
                        |> vitalsFormWithDefault data.vitalsForm
                        |> viewVitalsForm language currentDate measurements

                PhysicalExamAcuteFindings ->
                    measurements.acuteFindings
                        |> Maybe.map (Tuple.second >> .value)
                        |> acuteFindingsFormWithDefault data.acuteFindingsForm
                        |> viewAcuteFindingsForm language currentDate measurements

        getNextTask currentTask =
            case currentTask of
                PhysicalExamVitals ->
                    [ PhysicalExamAcuteFindings ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                PhysicalExamAcuteFindings ->
                    [ PhysicalExamVitals ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

        actions =
            let
                nextTask =
                    getNextTask data.activeTask

                saveMsg =
                    case data.activeTask of
                        PhysicalExamVitals ->
                            SaveVitals personId measurements.vitals nextTask

                        PhysicalExamAcuteFindings ->
                            SaveAcuteFindings personId measurements.acuteFindings nextTask
            in
            div [ class "actions symptoms" ]
                [ button
                    [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                    , onClick saveMsg
                    ]
                    [ text <| translate language Translate.Save ]
                ]
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui three column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewVitalsForm : Language -> NominalDate -> AcuteIllnessMeasurements -> VitalsForm -> Html Msg
viewVitalsForm language currentDate measurements form =
    let
        respiratoryRatePreviousValue =
            -- Todo
            -- resolvePreviousValue assembled .vitals .respiratoryRate
            --     |> Maybe.map toFloat
            Nothing

        bodyTemperaturePreviousValue =
            -- Todo
            -- resolvePreviousValue assembled .vitals .bodyTemperature
            Nothing
    in
    div [ class "ui form examination vitals" ]
        [ viewLabel language Translate.RespiratoryRate
        , viewMeasurementInput
            language
            (Maybe.map toFloat form.respiratoryRate)
            SetVitalsResporatoryRate
            "respiratory-rate"
            Translate.BpmUnit
        , viewPreviousMeasurement language respiratoryRatePreviousValue Translate.BpmUnit
        , div [ class "separator" ] []
        , viewLabel language Translate.BodyTemperature
        , viewMeasurementInput
            language
            form.bodyTemperature
            SetVitalsBodyTemperature
            "body-temperature"
            Translate.Celsius
        , viewPreviousMeasurement language bodyTemperaturePreviousValue Translate.Celsius
        ]


viewAcuteFindingsForm : Language -> NominalDate -> AcuteIllnessMeasurements -> AcuteFindingsForm -> Html Msg
viewAcuteFindingsForm language currentDate measurements form_ =
    let
        form =
            measurements.acuteFindings
                |> Maybe.map (Tuple.second >> .value)
                |> acuteFindingsFormWithDefault form_
    in
    div [ class "ui form examination acute-findings" ]
        [ viewQuestionLabel language Translate.PatientExhibitAnyFindings
        , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
        , viewCheckBoxMultipleSelectInput language
            [ LethargicOrUnconscious, AcuteFindingsPoorSuck, SunkenEyes, PoorSkinTurgor, Jaundice, NoAcuteFindingsGeneralSigns ]
            []
            (form.signsGeneral |> Maybe.withDefault [])
            Nothing
            SetAcuteFindingsGeneralSign
            Translate.AcuteFindingsGeneralSign
        , viewQuestionLabel language Translate.PatientExhibitAnyRespiratoryFindings
        , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
        , viewCheckBoxMultipleSelectInput language
            [ Stridor, NasalFlaring, SevereWheezing, SubCostalRetractions, NoAcuteFindingsRespiratorySigns ]
            []
            (form.signsRespiratory |> Maybe.withDefault [])
            Nothing
            SetAcuteFindingsRespiratorySign
            Translate.AcuteFindingsRespiratorySign
        ]


viewAcuteIllnessLaboratory : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, Person, AcuteIllnessMeasurements ) -> LaboratoryData -> List (Html Msg)
viewAcuteIllnessLaboratory language currentDate id ( personId, person, measurements ) data =
    let
        activity =
            AcuteIllnessLaboratory

        tasks =
            [ LaboratoryMalariaTesting ]

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        LaboratoryMalariaTesting ->
                            ( "laboratory-malaria-testing"
                            , isJust measurements.malariaTesting
                            )

                isActive =
                    task == data.activeTask

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActiveLaboratoryTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.LaboratoryTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, laboratoryTasksCompletedFromTotal measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            Dict.get data.activeTask tasksCompletedFromTotalDict
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case data.activeTask of
                LaboratoryMalariaTesting ->
                    measurements.malariaTesting
                        |> Maybe.map (Tuple.second >> .value)
                        |> malariaTestingFormWithDefault data.malariaTestingForm
                        |> viewMalariaTestingForm language currentDate person

        getNextTask currentTask =
            case currentTask of
                LaboratoryMalariaTesting ->
                    []

        actions =
            let
                saveMsg =
                    case data.activeTask of
                        LaboratoryMalariaTesting ->
                            SaveMalariaTesting personId measurements.malariaTesting
            in
            div [ class "actions malaria-testing" ]
                [ button
                    [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                    , onClick saveMsg
                    ]
                    [ text <| translate language Translate.Save ]
                ]
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui three column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewMalariaTestingForm : Language -> NominalDate -> Person -> MalariaTestingForm -> Html Msg
viewMalariaTestingForm language currentDate person form =
    let
        emptyOption =
            if isNothing form.rapidTestResult then
                option
                    [ value ""
                    , selected (form.rapidTestResult == Nothing)
                    ]
                    [ text "" ]

            else
                emptyNode

        resultInput =
            emptyOption
                :: ([ RapidTestNegative, RapidTestPositive, RapidTestIndeterminate, RapidTestUnableToRun ]
                        |> List.map
                            (\result ->
                                option
                                    [ value (malariaRapidTestResultAsString result)
                                    , selected (form.rapidTestResult == Just result)
                                    ]
                                    [ text <| translate language <| Translate.MalariaRapidTestResult result ]
                            )
                   )
                |> select [ onInput SetRapidTestResult, class "form-input rapid-test-result" ]

        testResultPositive =
            form.rapidTestResult == Just RapidTestPositive || form.rapidTestResult == Just RapidTestPositiveAndPregnant

        isPregnantInput =
            if testResultPositive && isPersonAFertileWoman currentDate person then
                [ viewQuestionLabel language Translate.CurrentlyPregnant
                , viewBoolInput
                    language
                    form.isPregnant
                    SetIsPregnant
                    "is-pregnant"
                    Nothing
                ]

            else
                []
    in
    div [ class "ui form laboratory malaria-testing" ] <|
        [ viewLabel language Translate.MalariaRapidDiagnosticTest
        , resultInput
        ]
            ++ isPregnantInput


viewAcuteIllnessExposure : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, AcuteIllnessMeasurements ) -> ExposureData -> List (Html Msg)
viewAcuteIllnessExposure language currentDate id ( personId, measurements ) data =
    let
        activity =
            AcuteIllnessExposure

        tasks =
            [ ExposureTravel, ExposureExposure ]

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        ExposureTravel ->
                            ( "exposure-travel"
                            , isJust measurements.travelHistory
                            )

                        ExposureExposure ->
                            ( "exposure-exposure"
                            , isJust measurements.exposure
                            )

                isActive =
                    task == data.activeTask

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActiveExposureTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.ExposureTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, exposureTasksCompletedFromTotal measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            Dict.get data.activeTask tasksCompletedFromTotalDict
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case data.activeTask of
                ExposureTravel ->
                    measurements.travelHistory
                        |> Maybe.map (Tuple.second >> .value)
                        |> travelHistoryFormWithDefault data.travelHistoryForm
                        |> viewTravelHistoryForm language currentDate measurements

                ExposureExposure ->
                    measurements.exposure
                        |> Maybe.map (Tuple.second >> .value)
                        |> exposureFormWithDefault data.exposureForm
                        |> viewExposureForm language currentDate measurements

        getNextTask currentTask =
            case data.activeTask of
                ExposureTravel ->
                    [ ExposureExposure ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                ExposureExposure ->
                    [ ExposureTravel ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

        actions =
            let
                nextTask =
                    getNextTask data.activeTask

                saveMsg =
                    case data.activeTask of
                        ExposureTravel ->
                            SaveTravelHistory personId measurements.travelHistory nextTask

                        ExposureExposure ->
                            SaveExposure personId measurements.exposure nextTask
            in
            div [ class "actions exposure" ]
                [ button
                    [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                    , onClick saveMsg
                    ]
                    [ text <| translate language Translate.Save ]
                ]
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui five column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewTravelHistoryForm : Language -> NominalDate -> AcuteIllnessMeasurements -> TravelHistoryForm -> Html Msg
viewTravelHistoryForm language currentDate measurements form =
    div [ class "ui form exposure travel-history" ]
        [ viewQuestionLabel language Translate.TraveledToCOVID19CountryQuestion
        , viewBoolInput
            language
            form.covid19Country
            SetCovid19Country
            "covid19-country"
            Nothing
        ]


viewExposureForm : Language -> NominalDate -> AcuteIllnessMeasurements -> ExposureForm -> Html Msg
viewExposureForm language currentDate measurements form =
    div [ class "ui form exposure" ]
        [ viewQuestionLabel language Translate.ContactWithCOVID19SymptomsQuestion
        , div [ class "question-helper" ] [ text <| translate language Translate.ContactWithCOVID19SymptomsHelper ++ "." ]
        , viewBoolInput
            language
            form.covid19Symptoms
            SetCovid19Symptoms
            "covid19-symptoms"
            Nothing
        ]


viewHCRecomendation : Language -> HCRecomendation -> Html any
viewHCRecomendation language recomendation =
    let
        riskLevel =
            case recomendation of
                SendAmbulance ->
                    Translate.HighRiskCase

                HomeIsolation ->
                    Translate.HighRiskCase

                ComeToHealthCenter ->
                    Translate.LowRiskCase

                ChwMonitoring ->
                    Translate.LowRiskCase

                HCRecomendationNotApplicable ->
                    Translate.LowRiskCase
    in
    label []
        [ translate language Translate.HealthCenterDetermined |> text
        , span [ class "strong" ] [ translate language riskLevel |> text ]
        , translate language Translate.And |> text
        , span [ class "strong" ] [ Translate.HCRecomendation recomendation |> translate language |> text ]
        ]


viewAcuteIllnessPriorTreatment : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, AcuteIllnessMeasurements ) -> PriorTreatmentData -> List (Html Msg)
viewAcuteIllnessPriorTreatment language currentDate id ( personId, measurements ) data =
    let
        activity =
            AcuteIllnessPriorTreatment

        tasks =
            [ TreatmentReview ]

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        TreatmentReview ->
                            ( "treatment-review"
                            , isJust measurements.treatmentReview
                            )

                isActive =
                    task == data.activeTask

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActivePriorTreatmentTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.PriorTreatmentTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, treatmentTasksCompletedFromTotal measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            Dict.get data.activeTask tasksCompletedFromTotalDict
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case data.activeTask of
                TreatmentReview ->
                    measurements.treatmentReview
                        |> Maybe.map (Tuple.second >> .value)
                        |> treatmentReviewFormWithDefault data.treatmentReviewForm
                        |> viewTreatmentReviewForm language currentDate measurements

        getNextTask currentTask =
            case currentTask of
                TreatmentReview ->
                    []

        actions =
            let
                saveMsg =
                    case data.activeTask of
                        TreatmentReview ->
                            SaveTreatmentReview personId measurements.treatmentReview
            in
            div [ class "actions malaria-testing" ]
                [ button
                    [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                    , onClick saveMsg
                    ]
                    [ text <| translate language Translate.Save ]
                ]
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui three column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewTreatmentReviewForm : Language -> NominalDate -> AcuteIllnessMeasurements -> TreatmentReviewForm -> Html Msg
viewTreatmentReviewForm language currentDate measurements form =
    let
        feverPast6HoursUpdateFunc value form_ =
            if value then
                { form_ | feverPast6Hours = Just True }

            else
                { form_ | feverPast6Hours = Just False, feverPast6HoursHelped = Nothing }

        feverPast6HoursHelpedUpdateFunc value form_ =
            { form_ | feverPast6HoursHelped = Just value }

        malariaTodayUpdateFunc value form_ =
            if value then
                { form_ | malariaToday = Just True }

            else
                { form_ | malariaToday = Just False, malariaTodayHelped = Nothing }

        malariaTodayHelpedUpdateFunc value form_ =
            { form_ | malariaTodayHelped = Just value }

        malariaWithinPastMonthUpdateFunc value form_ =
            if value then
                { form_ | malariaWithinPastMonth = Just True }

            else
                { form_ | malariaWithinPastMonth = Just False, malariaWithinPastMonthHelped = Nothing }

        malariaWithinPastMonthHelpedUpdateFunc value form_ =
            { form_ | malariaWithinPastMonthHelped = Just value }

        medicationHelpedQuestion =
            div [ class "ui grid" ]
                [ div [ class "one wide column" ] []
                , div [ class "fifteen wide column" ]
                    [ viewQuestionLabel language Translate.MedicationHelpedQuestion ]
                ]

        feverPast6HoursSection =
            let
                feverPast6HoursPositive =
                    form.feverPast6Hours
                        |> Maybe.withDefault False

                feverPast6HoursHelpedInput =
                    if feverPast6HoursPositive then
                        [ medicationHelpedQuestion
                        , viewBoolInput
                            language
                            form.feverPast6HoursHelped
                            (SetTreatmentReviewBoolInput feverPast6HoursHelpedUpdateFunc)
                            "fever-past-6-hours-helped derived"
                            Nothing
                        ]

                    else
                        []
            in
            [ viewQuestionLabel language Translate.MedicationForFeverPast6HoursQuestion
            , viewBoolInput
                language
                form.feverPast6Hours
                (SetTreatmentReviewBoolInput feverPast6HoursUpdateFunc)
                "fever-past-6-hours"
                Nothing
            ]
                ++ feverPast6HoursHelpedInput

        malariaTodaySection =
            let
                malariaTodayPositive =
                    form.malariaToday
                        |> Maybe.withDefault False

                malariaTodayHelpedInput =
                    if malariaTodayPositive then
                        [ medicationHelpedQuestion
                        , viewBoolInput
                            language
                            form.malariaTodayHelped
                            (SetTreatmentReviewBoolInput malariaTodayHelpedUpdateFunc)
                            "malaria-today-helped derived"
                            Nothing
                        ]

                    else
                        []
            in
            [ viewQuestionLabel language Translate.MedicationForMalariaWithinPastMonthQuestion
            , viewBoolInput
                language
                form.malariaToday
                (SetTreatmentReviewBoolInput malariaTodayUpdateFunc)
                "malaria-today"
                Nothing
            ]
                ++ malariaTodayHelpedInput

        malariaWithinPastMonth =
            let
                malariaWithinPastMonthPositive =
                    form.malariaWithinPastMonth
                        |> Maybe.withDefault False

                malariaWithinPastMonthHelpedInput =
                    if malariaWithinPastMonthPositive then
                        [ medicationHelpedQuestion
                        , viewBoolInput
                            language
                            form.malariaWithinPastMonthHelped
                            (SetTreatmentReviewBoolInput malariaWithinPastMonthHelpedUpdateFunc)
                            "malaria-within-past-month-helped derived"
                            Nothing
                        ]

                    else
                        []
            in
            [ viewQuestionLabel language Translate.MedicationForMalariaTodayQuestion
            , viewBoolInput
                language
                form.malariaWithinPastMonth
                (SetTreatmentReviewBoolInput malariaWithinPastMonthUpdateFunc)
                "malaria-within-past-month"
                Nothing
            ]
                ++ malariaWithinPastMonthHelpedInput
    in
    feverPast6HoursSection
        ++ malariaTodaySection
        ++ malariaWithinPastMonth
        |> div [ class "ui form treatment-review" ]


viewAcuteIllnessNextSteps : Language -> NominalDate -> AcuteIllnessEncounterId -> ( PersonId, Person, AcuteIllnessMeasurements ) -> Maybe AcuteIllnessDiagnosis -> NextStepsData -> List (Html Msg)
viewAcuteIllnessNextSteps language currentDate id ( personId, person, measurements ) diagnosis data =
    let
        activity =
            AcuteIllnessNextSteps

        tasks =
            resolveNextStepsTasks currentDate person diagnosis

        activeTask =
            Maybe.Extra.or data.activeTask (List.head tasks)

        viewTask task =
            let
                ( iconClass, isCompleted ) =
                    case task of
                        NextStepsIsolation ->
                            ( "next-steps-isolation"
                            , isJust measurements.isolation
                            )

                        NextStepsContactHC ->
                            ( "next-steps-contact-hc"
                            , isJust measurements.hcContact
                            )

                        NextStepsMedicationDistribution ->
                            ( "next-steps-medication-distribution"
                            , isJust measurements.medicationDistribution
                            )

                        NextStepsSendToHC ->
                            ( "next-steps-send-to-hc"
                            , isJust measurements.sendToHC
                            )

                isActive =
                    activeTask == Just task

                attributes =
                    classList [ ( "link-section", True ), ( "active", isActive ), ( "completed", not isActive && isCompleted ) ]
                        :: (if isActive then
                                []

                            else
                                [ onClick <| SetActiveNextStepsTask task ]
                           )
            in
            div [ class "column" ]
                [ a attributes
                    [ span [ class <| "icon-activity-task icon-" ++ iconClass ] []
                    , text <| translate language (Translate.NextStepsTask task)
                    ]
                ]

        tasksCompletedFromTotalDict =
            tasks
                |> List.map
                    (\task ->
                        ( task, nextStepsTasksCompletedFromTotal diagnosis measurements data task )
                    )
                |> Dict.fromList

        ( tasksCompleted, totalTasks ) =
            activeTask
                |> Maybe.andThen (\task -> Dict.get task tasksCompletedFromTotalDict)
                |> Maybe.withDefault ( 0, 0 )

        viewForm =
            case activeTask of
                Just NextStepsIsolation ->
                    measurements.isolation
                        |> Maybe.map (Tuple.second >> .value)
                        |> isolationFormWithDefault data.isolationForm
                        |> viewIsolationForm language currentDate measurements

                Just NextStepsContactHC ->
                    measurements.hcContact
                        |> Maybe.map (Tuple.second >> .value)
                        |> hcContactFormWithDefault data.hcContactForm
                        |> viewHCContactForm language currentDate measurements

                Just NextStepsMedicationDistribution ->
                    measurements.medicationDistribution
                        |> Maybe.map (Tuple.second >> .value)
                        |> medicationDistributionFormWithDefault data.medicationDistributionForm
                        |> viewMedicationDistributionForm language currentDate person diagnosis

                Just NextStepsSendToHC ->
                    measurements.sendToHC
                        |> Maybe.map (Tuple.second >> .value)
                        |> sendToHCFormWithDefault data.sendToHCForm
                        |> viewSendToHCForm language currentDate

                Nothing ->
                    emptyNode

        getNextTask currentTask =
            case currentTask of
                NextStepsIsolation ->
                    [ NextStepsContactHC ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                NextStepsContactHC ->
                    [ NextStepsIsolation ]
                        |> List.filter (isTaskCompleted tasksCompletedFromTotalDict >> not)
                        |> List.head

                NextStepsMedicationDistribution ->
                    Nothing

                NextStepsSendToHC ->
                    Nothing

        actions =
            activeTask
                |> Maybe.map
                    (\task ->
                        let
                            nextTask =
                                getNextTask task

                            saveMsg =
                                case task of
                                    NextStepsIsolation ->
                                        SaveIsolation personId measurements.isolation nextTask

                                    NextStepsContactHC ->
                                        SaveHCContact personId measurements.hcContact nextTask

                                    NextStepsSendToHC ->
                                        SaveSendToHC personId measurements.sendToHC

                                    NextStepsMedicationDistribution ->
                                        SaveMedicationDistribution personId measurements.medicationDistribution
                        in
                        div [ class "actions next-steps" ]
                            [ button
                                [ classList [ ( "ui fluid primary button", True ), ( "disabled", tasksCompleted /= totalTasks ) ]
                                , onClick saveMsg
                                ]
                                [ text <| translate language Translate.Save ]
                            ]
                    )
                |> Maybe.withDefault emptyNode
    in
    [ div [ class "ui task segment blue", Html.Attributes.id tasksBarId ]
        [ div [ class "ui three column grid" ] <|
            List.map viewTask tasks
        ]
    , div [ class "tasks-count" ] [ text <| translate language <| Translate.TasksCompleted tasksCompleted totalTasks ]
    , div [ class "ui full segment" ]
        [ div [ class "full content" ]
            [ viewForm
            , actions
            ]
        ]
    ]


viewIsolationForm : Language -> NominalDate -> AcuteIllnessMeasurements -> IsolationForm -> Html Msg
viewIsolationForm language currentDate measurements form =
    let
        patientIsolatedInput =
            [ viewQuestionLabel language Translate.PatientIsolatedQuestion
            , viewBoolInput
                language
                form.patientIsolated
                SetPatientIsolated
                "patient-isolated"
                Nothing
            ]

        derivedInputs =
            case form.patientIsolated of
                Just True ->
                    [ viewQuestionLabel language Translate.SignOnDoorPostedQuestion
                    , viewBoolInput
                        language
                        form.signOnDoor
                        SetSignOnDoor
                        "sign-on-door"
                        Nothing
                    ]
                        ++ healthEducationInput

                Just False ->
                    [ viewQuestionLabel language Translate.WhyNot
                    , viewCustomLabel language Translate.CheckAllThatApply "." "helper"
                    , viewCheckBoxMultipleSelectInput language
                        [ NoSpace, TooIll, CanNotSeparateFromFamily, OtherReason ]
                        []
                        (form.reasonsForNotIsolating |> Maybe.withDefault [])
                        Nothing
                        SetReasonForNotIsolating
                        Translate.ReasonForNotIsolating
                    ]
                        ++ healthEducationInput

                Nothing ->
                    []

        healthEducationInput =
            [ viewQuestionLabel language Translate.HealthEducationProvidedQuestion
            , viewBoolInput
                language
                form.healthEducation
                SetHealthEducation
                "health-education"
                Nothing
            ]
    in
    patientIsolatedInput
        ++ derivedInputs
        |> div [ class "ui form exposure isolation" ]


viewHCContactForm : Language -> NominalDate -> AcuteIllnessMeasurements -> HCContactForm -> Html Msg
viewHCContactForm language currentDate measurements form =
    let
        contactedHCInput =
            [ viewQuestionLabel language Translate.ContactedHCQuestion
            , viewBoolInput
                language
                form.contactedHC
                SetContactedHC
                "contacted-hc"
                Nothing
            ]

        derivedInputs =
            case form.contactedHC of
                Just True ->
                    let
                        hcRespnonseInput =
                            [ viewQuestionLabel language Translate.HCResponseQuestion
                            , viewCheckBoxSelectCustomInput language
                                [ SendAmbulance, HomeIsolation, ComeToHealthCenter, ChwMonitoring ]
                                []
                                form.recomendations
                                SetHCRecommendation
                                (viewHCRecomendation language)
                            ]

                        hcRespnonsePeriodInput =
                            [ viewQuestionLabel language Translate.HCResponsePeriodQuestion
                            , viewCheckBoxSelectInput language
                                [ LessThan30Min, Between30min1Hour, Between1Hour2Hour, Between2Hour1Day ]
                                []
                                form.responsePeriod
                                SetResponsePeriod
                                Translate.ResponsePeriod
                            ]

                        derivedInput =
                            form.recomendations
                                |> Maybe.map
                                    (\recomendations ->
                                        if recomendations == SendAmbulance then
                                            [ viewQuestionLabel language Translate.AmbulancArrivalPeriodQuestion
                                            , viewCheckBoxSelectInput language
                                                [ LessThan30Min, Between30min1Hour, Between1Hour2Hour, Between2Hour1Day ]
                                                []
                                                form.ambulanceArrivalPeriod
                                                SetAmbulanceArrivalPeriod
                                                Translate.ResponsePeriod
                                            ]

                                        else
                                            []
                                    )
                                |> Maybe.withDefault []
                    in
                    hcRespnonseInput ++ hcRespnonsePeriodInput ++ derivedInput

                _ ->
                    []
    in
    contactedHCInput
        ++ derivedInputs
        |> div [ class "ui form exposure hc-contact" ]


viewSendToHCForm : Language -> NominalDate -> SendToHCForm -> Html Msg
viewSendToHCForm language currentDate form =
    div [ class "ui form send-to-hc" ]
        [ h2 [] [ text <| translate language Translate.ActionsToTake ++ ":" ]
        , div [ class "instructions" ]
            [ viewSendToHCActionLabel language Translate.CompleteHCReferralForm "icon-forms" Nothing
            , viewSendToHCActionLabel language Translate.SendPatientToHC "icon-shuttle" Nothing
            ]
        , viewQuestionLabel language Translate.ReferredPatientToHealthCenterQuestion
        , viewBoolInput
            language
            form.referToHealthCenter
            SetReferToHealthCenter
            "refer-to-hc"
            Nothing
        , viewQuestionLabel language Translate.HandedReferralFormQuestion
        , viewBoolInput
            language
            form.handReferralForm
            SetHandReferralForm
            "hand-referral-form"
            Nothing
        ]


viewSendToHCActionLabel : Language -> TranslationId -> String -> Maybe NominalDate -> Html any
viewSendToHCActionLabel language actionTranslationId iconClass maybeDate =
    div [ class "header" ] <|
        [ i [ class iconClass ] []
        , text <| translate language actionTranslationId
        ]
            ++ renderDatePart language maybeDate
            ++ [ text "." ]


viewMedicationDistributionForm : Language -> NominalDate -> Person -> Maybe AcuteIllnessDiagnosis -> MedicationDistributionForm -> Html Msg
viewMedicationDistributionForm language currentDate person diagnosis form =
    let
        viewAdministeredMedicationQuestion medicineTranslationId =
            div [ class "label" ]
                [ text <|
                    translate language Translate.AdministeredMedicationQuestion
                        ++ " "
                        ++ translate language medicineTranslationId
                        ++ " "
                        ++ translate language Translate.ToThePatient
                        ++ "?"
                ]

        ( instructions, questions ) =
            case diagnosis of
                Just DiagnosisMalariaUncomplicated ->
                    let
                        coartemUpdateFunc value form_ =
                            { form_ | coartem = Just value }
                    in
                    ( resolveCoartemDosage currentDate person
                        |> Maybe.map
                            (\dosage ->
                                div [ class "instructions malaria-uncomplicated" ]
                                    [ viewAdministeredMedicationLabel language Translate.Administer (Translate.MedicationDistributionSign Coartem) "icon-pills" Nothing
                                    , viewTabletsPrescription language dosage (Translate.ByMouthTwiceADayForXDays 3)
                                    ]
                            )
                        |> Maybe.withDefault emptyNode
                    , [ viewAdministeredMedicationQuestion (Translate.MedicationDistributionSign Coartem)
                      , viewBoolInput
                            language
                            form.coartem
                            (SetMedicationDistributionBoolInput coartemUpdateFunc)
                            "coartem-medication"
                            Nothing
                      ]
                    )

                Just DiagnosisGastrointestinalInfectionUncomplicated ->
                    let
                        orsUpdateFunc value form_ =
                            { form_ | ors = Just value }

                        zincUpdateFunc value form_ =
                            { form_ | zinc = Just value }
                    in
                    ( Maybe.map2
                        (\orsDosage zincDosage ->
                            div [ class "instructions gastrointestinal-uncomplicated" ]
                                [ viewAdministeredMedicationLabel language Translate.Administer (Translate.MedicationDistributionSign ORS) "icon-oral-solution" Nothing
                                , viewOralSolutionPrescription language orsDosage
                                , viewAdministeredMedicationLabel language Translate.Administer (Translate.MedicationDistributionSign Zinc) "icon-pills" Nothing
                                , viewTabletsPrescription language zincDosage (Translate.ByMouthDaylyForXDays 10)
                                ]
                        )
                        (resolveORSDosage currentDate person)
                        (resolveZincDosage currentDate person)
                        |> Maybe.withDefault emptyNode
                    , [ viewAdministeredMedicationQuestion (Translate.MedicationDistributionSign ORS)
                      , viewBoolInput
                            language
                            form.ors
                            (SetMedicationDistributionBoolInput orsUpdateFunc)
                            "ors-medication"
                            Nothing
                      , viewAdministeredMedicationQuestion (Translate.MedicationDistributionSign Zinc)
                      , viewBoolInput
                            language
                            form.zinc
                            (SetMedicationDistributionBoolInput zincUpdateFunc)
                            "zinc-medication"
                            Nothing
                      ]
                    )

                Just DiagnosisSimpleColdAndCough ->
                    let
                        lemonJuiceOrHoneyUpdateFunc value form_ =
                            { form_ | lemonJuiceOrHoney = Just value }
                    in
                    ( div [ class "instructions simple-cough-and-cold" ]
                        [ viewAdministeredMedicationLabel language Translate.Administer (Translate.MedicationDistributionSign LemonJuiceOrHoney) "icon-pills" Nothing ]
                    , [ viewAdministeredMedicationQuestion (Translate.MedicationDistributionSign LemonJuiceOrHoney)
                      , viewBoolInput
                            language
                            form.lemonJuiceOrHoney
                            (SetMedicationDistributionBoolInput lemonJuiceOrHoneyUpdateFunc)
                            "lemon-juice-or-honey-medication"
                            Nothing
                      ]
                    )

                Just DiagnosisRespiratoryInfectionUncomplicated ->
                    let
                        amoxicillinUpdateFunc value form_ =
                            { form_ | amoxicillin = Just value }
                    in
                    ( resolveAmoxicillinDosage currentDate person
                        |> Maybe.map
                            (\dosage ->
                                div [ class "instructions respiratory-infection-uncomplicated" ]
                                    [ viewAdministeredMedicationLabel language Translate.Administer (Translate.MedicationDistributionSign Amoxicillin) "icon-pills" Nothing
                                    , viewTabletsPrescription language dosage (Translate.ByMouthTwiceADayForXDays 5)
                                    ]
                            )
                        |> Maybe.withDefault emptyNode
                    , [ viewAdministeredMedicationQuestion (Translate.MedicationDistributionSign Amoxicillin)
                      , viewBoolInput
                            language
                            form.amoxicillin
                            (SetMedicationDistributionBoolInput amoxicillinUpdateFunc)
                            "amoxicillin-medication"
                            Nothing
                      ]
                    )

                _ ->
                    ( emptyNode, [] )
    in
    div [ class "ui form medication-distribution" ] <|
        [ h2 [] [ text <| translate language Translate.ActionsToTake ++ ":" ]
        , instructions
        ]
            ++ questions


viewAdministeredMedicationLabel : Language -> TranslationId -> TranslationId -> String -> Maybe NominalDate -> Html any
viewAdministeredMedicationLabel language administerTranslationId medicineTranslationId iconClass maybeDate =
    div [ class "header" ] <|
        [ i [ class iconClass ] []
        , text <| translate language administerTranslationId
        , text " "
        , span [ class "medicine" ] [ text <| translate language medicineTranslationId ]
        ]
            ++ renderDatePart language maybeDate
            ++ [ text ":" ]


viewTabletsPrescription : Language -> String -> TranslationId -> Html any
viewTabletsPrescription language dosage duration =
    div [ class "prescription" ]
        [ span [] [ text <| translate language (Translate.TabletSinglePlural dosage) ]
        , text " "
        , text <| translate language duration
        , text "."
        ]


viewOralSolutionPrescription : Language -> String -> Html any
viewOralSolutionPrescription language dosage =
    div [ class "prescription" ]
        [ span [] [ text <| dosage ++ " " ++ translate language Translate.Glass ]
        , text " "
        , text <| translate language Translate.AfterEachLiquidStool
        , text "."
        ]


renderDatePart : Language -> Maybe NominalDate -> List (Html any)
renderDatePart language maybeDate =
    maybeDate
        |> Maybe.map (\date -> [ span [ class "date" ] [ text <| " (" ++ renderDate language date ++ ")" ] ])
        |> Maybe.withDefault []