module Translate exposing
    ( Adherence(..)
    , ChartPhrase(..)
    , Language
    , LoginPhrase(..)
    , TranslationId(..)
    , ValidationError(..)
    , translate
    , translateActivePage
    , translateAdherence
    , translateChartPhrase
    , translateCounselingTimingHeading
    , translateFormError
    , translateFormField
    , translateHttpError
    , translateLoginPhrase
    , translateValidationError
    , translationSet
    )

{-| This module has just the translations ... for types and
general utilities, see `Translate.Model` and `Translate.Utils`.
-}

import Activity.Model exposing (Activity(..), ChildActivity(..), MotherActivity(..))
import Backend.Clinic.Model exposing (ClinicType(..))
import Backend.Counseling.Model exposing (CounselingTiming(..), CounselingTopic)
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (IndividualEncounterType(..), PregnancyOutcome(..))
import Backend.Measurement.Model exposing (..)
import Backend.Person.Model
    exposing
        ( EducationLevel(..)
        , Gender(..)
        , HIVStatus(..)
        , MaritalStatus(..)
        , ModeOfDelivery(..)
        , VaginalDelivery(..)
        )
import Backend.Relationship.Model exposing (MyRelatedBy(..))
import Date exposing (Month)
import Form.Error exposing (ErrorValue(..))
import Http
import NutritionActivity.Model exposing (NutritionActivity(..))
import Pages.Attendance.Model exposing (InitialResultsDisplay(..))
import Pages.Page exposing (..)
import Pages.PrenatalActivity.Model
    exposing
        ( ExaminationTask(..)
        , HistoryTask(..)
        , LmpRange(..)
        , PatientProvisionsTask(..)
        )
import PrenatalActivity.Model
    exposing
        ( HighRiskFactor(..)
        , HighSeverityAlert(..)
        , MedicalDiagnosis(..)
        , ObstetricalDiagnosis(..)
        , PregnancyTrimester(..)
        , PrenatalActivity(..)
        , RecurringHighSeverityAlert(..)
        , RiskFactor(..)
        )
import Restful.Endpoint exposing (fromEntityUuid)
import Restful.Login exposing (LoginError(..), LoginMethod(..))
import Time exposing (Month(..))
import Translate.Model exposing (TranslationSet)
import Translate.Utils exposing (..)


{-| We re-export this one for convenience, so you don't have to import
`Translate.Model` in simple cases. That is, you can do this, which will be
enough for most "view" modules:

    import Translate exposing (translate, Language)

Note that importing `Language` from here gives you only the type, not the
constructors. For more complex cases, where you need `English` and
`Kinyarwanda` as well, you have to do this instead:

    import Translate.Model exposing (Language(..))

-}
type alias Language =
    Translate.Model.Language


translate : Language -> TranslationId -> String
translate lang trans =
    selectLanguage lang (translationSet trans)


type LoginPhrase
    = CheckingCachedCredentials
    | ForgotPassword1
    | ForgotPassword2
    | LoggedInAs
    | LoginError Http.Error
    | LoginRejected LoginMethod
    | LoginOrWorkOffline
    | Logout
    | LogoutInProgress
    | LogoutFailed
    | Password
    | PinCode
    | PinCodeRejected
    | SignIn
    | SignOut
    | Username
    | WorkOffline
    | YouMustLoginBefore


type ChartPhrase
    = AgeCompletedMonthsYears
    | Birth
    | BirthToTwoYears
    | LengthCm
    | LengthForAgeBoys
    | LengthForAgeGirls
    | Months
    | OneYear
    | WeightForAgeBoys
    | WeightForAgeGirls
    | WeightForLengthBoys
    | WeightForLengthGirls
    | WeightKg
    | YearsPlural Int
    | ZScoreChartsAvailableAt


type ValidationError
    = DigitsOnly
    | InvalidBirthDate
    | InvalidBirthDateForAdult
    | InvalidBirthDateForChild
    | InvalidHmisNumber
    | LengthError Int
    | LettersOnly
    | RequiredField
    | UnknownGroup
    | UnknownProvince
    | UnknownDistrict
    | UnknownSector
    | UnknownCell
    | UnknownVillage
    | DecoderError String


type Adherence
    = PrescribedAVRs
    | CorrectDosage
    | TimeOfDay
    | Adhering


type TranslationId
    = Abdomen
    | AbdomenCPESign AbdomenCPESign
    | Abnormal
    | Abortions
    | AccompaniedByPartner
    | AccessDenied
    | Activities
    | ActivitiesCompleted Int
    | ActivitiesHelp Activity
    | ActivitiesLabel Activity
    | ActivitiesTitle Activity
    | ActivitiesToComplete Int
    | ActivityProgressReport Activity
    | ActivePage Page
    | AddChild
    | AddFamilyMember
    | AddFamilyMemberFor String
    | AddParentOrCaregiver
    | AddToGroup
    | Admin
    | AddressInformation
    | Adherence Adherence
    | AgeWord
    | Age Int Int
    | AgeDays Int
    | AgeMonthsWithoutDay Int
    | AgeSingleBoth Int Int
    | AgeSingleMonth Int Int
    | AgeSingleMonthWithoutDay Int
    | AgeSingleDayWithMonth Int Int
    | AgeSingleDayWithoutMonth Int Int
    | AppName
    | AreYouSure
    | Assessment
    | Asthma
    | Attendance
    | Baby
    | BabyDiedOnDayOfBirthPreviousDelivery
    | BabyName String
    | Back
    | BackendError
    | BeginNewEncounter
    | BloodPressure
    | BloodPressureElevatedOcassions
    | BloodPressureDiaLabel
    | BloodPressureSysLabel
    | BMI
    | BMIHelper
    | BodyTemperature
    | Born
    | BowedLegs
    | BpmUnit
    | BreastExam
    | BreastExamSign BreastExamSign
    | BreastExamQuestion
    | BrittleHair
    | Cancel
    | CardiacDisease
    | CaregiverName
    | CaregiverNationalId
    | CentimeterShorthand
    | Celsius
    | Cell
    | ChartPhrase ChartPhrase
    | CheckIn
    | ChildHmisNumber
    | ChildDemographicInformation
    | ChildNutritionSignLabel ChildNutritionSign
    | ChildNutritionSignReport ChildNutritionSign
    | ChildOf
    | Children
    | ChildrenNames
    | ChildrenNationalId
    | Clear
    | ClickTheCheckMark
    | ClinicType ClinicType
    | Clinical
    | ClinicalProgressReport
    | ConvulsionsAndUnconsciousPreviousDelivery
    | ConvulsionsPreviousDelivery
    | CSectionScar CSectionScar
    | GroupNotFound
    | Group
    | Groups
    | GroupUnauthorized
    | Close
    | Closed
    | ConfirmationRequired
    | ConfirmDeleteTrainingGroupEncounters
    | ConfirmRegisterParticipant
    | Connected
    | ContactInformation
    | Continue
    | CounselingTimingHeading CounselingTiming
    | CounselingTopic CounselingTopic
    | CounselorReviewed
    | CounselorSignature
    | CSectionInPreviousDelivery
    | CSectionReason
    | CSectionReasons CSectionReason
    | CreateGroupEncounter
    | CreateRelationship
    | CreateTrainingGroupEncounters
    | CurrentlyPregnant
    | DangerSign DangerSign
    | Dashboard
    | DateOfLastAssessment
    | DatePregnancyConcluded
    | Day
    | DaySinglePlural Int
    | DateOfBirth
    | Days
    | Delete
    | DeleteTrainingGroupEncounters
    | DeliveryLocation
    | DeliveryOutcome
    | DemographicInformation
    | DemographicsReport
    | Device
    | DeviceNotAuthorized
    | DeviceStatus
    | Diabetes
    | District
    | DOB
    | DropzoneDefaultMessage
    | DueDate
    | Edd
    | EddHeader
    | Edema
    | EditRelationship
    | Ega
    | EgaHeader
    | EgaWeeks
    | EmptyString
    | EndEncounter
    | EndGroupEncounter
    | EnterPairingCode
    | ErrorCheckLocalConfig
    | ErrorConfigurationError
    | Estimated
    | ExaminationTask ExaminationTask
    | Extremities
    | Eyes
    | Facility
    | Failure
    | FamilyInformation
    | FamilyMembers
    | FamilyPlanningInFutureQuestion
    | FamilyPlanningSignLabel FamilyPlanningSign
    | FamilyUbudehe
    | FetalHeartRate
    | FetalMovement
    | FetalPresentationLabel
    | FetalPresentation FetalPresentation
    | Fetch
    | FatherName
    | FatherNationalId
    | FilterByName
    | FirstAntenatalVisit
    | FirstName
    | FiveVisits
    | ForIllustrativePurposesOnly
    | FormError (ErrorValue ValidationError)
    | FormField String
    | FundalHeight
    | Gender Gender
    | GenderLabel
    | GestationalDiabetesPreviousPregnancy
    | GoHome
    | GroupAssessment
    | Gravida
    | GroupEncounter
    | Hands
    | HandsCPESign HandsCPESign
    | HeadHair
    | HealthCenter
    | Heart
    | HeartMurmur
    | HeartCPESign HeartCPESign
    | HeartRate
    | Height
    | High
    | HighRiskFactor HighRiskFactor
    | HighRiskFactors
    | HighSeverityAlert HighSeverityAlert
    | HighSeverityAlerts
    | HistoryTask HistoryTask
    | HIV
    | HIVStatus HIVStatus
    | HIVStatusLabel
    | Home
    | HouseholdSize
    | HttpError Http.Error
    | HypertensionBeforePregnancy
    | IncompleteCervixPreviousPregnancy
    | IndividualEncounter
    | IndividualEncounterFirstVisit IndividualEncounterType
    | IndividualEncounterLabel IndividualEncounterType
    | IndividualEncounterSelectVisit IndividualEncounterType
    | IndividualEncounterSubsequentVisit IndividualEncounterType
    | IndividualEncounterType IndividualEncounterType
    | IndividualEncounterTypes
    | InitialResultsDisplay InitialResultsDisplay
    | KilogramShorthand
    | LastChecked
    | LastSuccesfulContactLabel
    | Legs
    | LegsCPESign LegsCPESign
    | LevelOfEducationLabel
    | LevelOfEducation EducationLevel
    | LinkToMother
    | LiveChildren
    | LmpDateConfidentHeader
    | LmpDateHeader
    | LmpRangeHeader
    | LmpRange LmpRange
    | LoginPhrase LoginPhrase
    | Low
    | Lungs
    | LungsCPESign LungsCPESign
    | MakeSureYouAreConnected
    | MaritalStatusLabel
    | MaritalStatus MaritalStatus
    | MeasurementNoChange
    | MeasurementGained Float
    | MeasurementLost Float
    | MedicalDiagnosis
    | MedicalDiagnosisAlert MedicalDiagnosis
    | MedicalFormHelper
    | MentalHealthHistory
    | MemoryQuota { totalJSHeapSize : Int, usedJSHeapSize : Int, jsHeapSizeLimit : Int }
    | MMHGUnit
    | MiddleName
    | MinutesAgo Int
    | ModeOfDelivery ModeOfDelivery
    | ModeOfDeliveryLabel
    | Month
    | MonthAbbrev
    | MonthsOld
    | Mother
    | MotherDemographicInformation
    | MotherName String
    | MotherNameLabel
    | MotherNationalId
    | Mothers
    | MUAC
    | MuacIndication MuacIndication
    | MyAccount
    | MyRelatedBy MyRelatedBy
    | MyRelatedByQuestion MyRelatedBy
    | Name
    | NationalIdNumber
    | Neck
    | NeckCPESign NeckCPESign
    | Next
    | No
    | NoActivitiesCompleted
    | NoActivitiesCompletedForThisParticipant
    | NoActivitiesPending
    | NoActivitiesPendingForThisParticipant
    | NoGroupsFound
    | NoMatchesFound
    | NoParticipantsPending
    | NoParticipantsPendingForThisActivity
    | NoParticipantsCompleted
    | NoParticipantsCompletedForThisActivity
    | Normal
    | NoChildrenRegisteredInTheSystem
    | NoParticipantsFound
    | NotAvailable
    | NotConnected
    | NumberOfAbortions
    | NumberOfChildrenUnder5
    | NumberOfCSections
    | NumberOfLiveChildren
    | NumberOfStillbirthsAtTerm
    | NumberOfStillbirthsPreTerm
    | NutritionActivityHelper NutritionActivity
    | NutritionActivityTitle NutritionActivity
    | ObstetricalDiagnosis
    | ObstetricalDiagnosisAlert ObstetricalDiagnosis
    | OK
    | Old
    | OneVisit
    | OnceYouEndYourGroupEncounter
    | Or
    | Page
    | Page404
    | PageNotFoundMsg
    | PaleConjuctiva
    | Pallor
    | Para
    | PartialPlacentaPreviousDelivery
    | ParticipantDirectory
    | Participants
    | ParticipantReviewed
    | ParticipantSignature
    | ParticipantSummary
    | ParticipantDemographicInformation
    | ParticipantInformation
    | PartnerHivTestResult
    | PartnerReceivedHivCounseling
    | PartnerReceivedHivTesting
    | PatientProgress
    | PatientInformation
    | PatientProvisionsTask PatientProvisionsTask
    | People
    | PersistentStorage Bool
    | Person
    | PersonHasBeenSaved
    | PlaceholderEnterHeight
    | PlaceholderEnterMUAC
    | PlaceholderEnterParticipantName
    | PlaceholderEnterWeight
    | PleaseSelectGroup
    | PleaseSync
    | PreeclampsiaPreviousPregnancy
    | PregnancyTrimester PregnancyTrimester
    | PrenatalActivitiesTitle PrenatalActivity
    | PrenatalPhotoHelper
    | PreTerm
    | PregnancyConcludedLabel
    | PregnancyOutcomeLabel
    | PregnancyOutcome PregnancyOutcome
    | PreviousCSectionScar
    | PreviousDelivery
    | PreviousDeliveryPeriods PreviousDeliveryPeriod
    | PreviousFloatMeasurement Float
    | PreviousMeasurementNotFound
    | Profession
    | Programs
    | ProgressPhotos
    | ProgressReport
    | ProgressTimeline
    | ProgressTrends
    | PrenatalParticipant
    | PrenatalParticipants
    | PreTermPregnancy
    | Province
    | ReasonForCSection
    | ReceivedDewormingPill
    | ReceivedIronFolicAcid
    | ReceivedMosquitoNet
    | RecordPregnancyOutcome
    | RecurringHighSeverityAlert RecurringHighSeverityAlert
    | Register
    | RegisterHelper
    | RegisterNewParticipant
    | RegistratingHealthCenter
    | RegistrationSuccessful
    | RegistrationSuccessfulParticipantAdded
    | RegistrationSuccessfulSuggestAddingChild
    | RegistrationSuccessfulSuggestAddingMother
    | RelationSuccessful
    | RelationSuccessfulChildWithMother
    | RelationSuccessfulMotherWithChild
    | RemainingForDownloadLabel
    | RemainingForUploadLabel
    | RenalDisease
    | ReportAge String
    | ReportDOB String
    | ReportRemaining Int
    | ReportResultsOfSearch Int
    | Reports
    | RecentAndUpcomingGroupEncounters
    | ReportCompleted { pending : Int, completed : Int }
    | ResolveMonth Month
    | RespiratoryRate
    | Retry
    | RhNegative
    | RiskFactorAlert RiskFactor
    | RiskFactors
    | Save
    | SaveAndNext
    | SaveError
    | Search
    | SearchByName
    | SearchExistingParticipants
    | SearchHelper
    | SearchHelperFamilyMember
    | SecondName
    | Sector
    | SelectAntenatalVisit
    | SelectAllSigns
    | SelectDangerSigns
    | SelectEncounterType
    | SelectGroup
    | SelectProgram
    | SelectLanguage
    | SelectYourGroup
    | SelectYourHealthCenter
    | SelectYourVillage
    | SelectedHCDownloading
    | SelectedHCNotSynced
    | SelectedHCSyncing
    | SelectedHCUploading
    | ServiceWorkerActive
    | ServiceWorkerCurrent
    | ServiceWorkerCheckForUpdates
    | ServiceWorkerInstalling
    | ServiceWorkerInstalled
    | ServiceWorkerSkipWaiting
    | ServiceWorkerRestarting
    | ServiceWorkerActivating
    | ServiceWorkerActivated
    | ServiceWorkerRedundant
    | ServiceWorkerInactive
    | ServiceWorkerRegNotAsked
    | ServiceWorkerRegLoading
    | ServiceWorkerRegErr
    | ServiceWorkerRegSuccess
    | ServiceWorkerStatus
    | SevereHemorrhagingPreviousDelivery
    | SocialHistoryHivTestingResult SocialHistoryHivTestingResult
    | StillbornPreviousDelivery
    | SubsequentAntenatalVisit
    | SuccessiveAbortions
    | SuccessivePrematureDeliveries
    | GroupEncounterClosed
    | GroupEncounterClosed2 SessionId
    | GroupEncounterLoading
    | GroupEncounterUnauthorized
    | GroupEncounterUnauthorized2
    | ShowAll
    | StartEndDate
    | StartDate
    | EndDate
    | StartSyncing
    | StatusLabel
    | StopSyncing
    | StorageQuota { usage : Int, quota : Int }
    | Submit
    | SubmitPairingCode
    | Success
    | SyncGeneral
    | TakenCareOfBy
    | TasksCompleted Int Int
    | TelephoneNumber
    | Term
    | TermPregnancy
    | ThisActionCannotBeUndone
    | ThisGroupHasNoMothers
    | Training
    | TrainingGroupEncounterCreateSuccessMessage
    | TrainingGroupEncounterDeleteSuccessMessage
    | TrySyncing
    | TuberculosisPast
    | TuberculosisPresent
    | TwoVisits
    | UbudeheLabel
    | Unknown
    | Update
    | UpdateError
    | UterineMyoma
    | ValidationErrors
    | Version
    | View
    | ViewProgressReport
    | Village
    | WeekSinglePlural Int
    | Weight
    | WelcomeUser String
    | WhatDoYouWantToDo
    | Year
    | YearsOld Int
    | Yes
    | YouAreNotAnAdmin
    | YourGroupEncounterHasBeenSaved
    | ZScoreHeightForAge
    | ZScoreMuacForAge
    | ZScoreWeightForAge
    | ZScoreWeightForHeight


translationSet : TranslationId -> TranslationSet String
translationSet trans =
    case trans of
        Abdomen ->
            { english = "Abdomen"
            , kinyarwanda = Just "Isanzwe"
            }

        AbdomenCPESign option ->
            case option of
                Hepatomegaly ->
                    { english = "Hepatomegaly"
                    , kinyarwanda = Just "Kubyimba umwijima"
                    }

                Splenomegaly ->
                    { english = "Splenomegaly"
                    , kinyarwanda = Just "Kubyimba urwangashya"
                    }

                TPRightUpper ->
                    { english = "Tender to Palpation right upper"
                    , kinyarwanda = Just "Igice cyo hejuru iburyo kirababara  iyo ugikanze"
                    }

                TPRightLower ->
                    { english = "Tender to Palpation right lower"
                    , kinyarwanda = Just "Igice cyo hasi iburyo kirababara  iyo ugikanze"
                    }

                TPLeftUpper ->
                    { english = "Tender to Palpation left upper"
                    , kinyarwanda = Just "Igice cyo hejuru ibumoso kirababara  iyo ugikanze"
                    }

                TPLeftLower ->
                    { english = "Tender to Palpation left lower"
                    , kinyarwanda = Just "Igice cyo hasi ibumoso kirababara  iyo ugikanze"
                    }

                Hernia ->
                    { english = "Hernia"
                    , kinyarwanda = Just "Urugingo ruyobera cg rwinjira mu rundi"
                    }

                NormalAbdomen ->
                    translationSet Normal

        Abnormal ->
            { english = "Abnormal"
            , kinyarwanda = Nothing
            }

        Abortions ->
            { english = "Abortions"
            , kinyarwanda = Just "Inda yavuyemo"
            }

        AccompaniedByPartner ->
            { english = "Was the patient accompanied by partner during the assessment"
            , kinyarwanda = Just "Umubyeyi yaherekejwe n'umugabo we mu gihe yaje kwipimisha?"
            }

        AccessDenied ->
            { english = "Access denied"
            , kinyarwanda = Just "Kwinjira ntibyemera"
            }

        AddChild ->
            { english = "Add Child"
            , kinyarwanda = Just "Ongeraho umwana"
            }

        AddFamilyMember ->
            { english = "Add Family Member"
            , kinyarwanda = Nothing
            }

        AddFamilyMemberFor name ->
            { english = "Add Family Member for " ++ name
            , kinyarwanda = Nothing
            }

        AddParentOrCaregiver ->
            { english = "Add Parent or Caregiver"
            , kinyarwanda = Just "Ongeraho umubyeyi cyangwa umurezi"
            }

        AddToGroup ->
            { english = "Add to Group..."
            , kinyarwanda = Just "Ongeraho itsinda..."
            }

        Admin ->
            { english = "Administration"
            , kinyarwanda = Just "Abakuriye"
            }

        AddressInformation ->
            { english = "Address Information"
            , kinyarwanda = Just "Aho atuye/Aho abarizwa"
            }

        AgeWord ->
            { english = "Age"
            , kinyarwanda = Just "Imyaka"
            }

        Activities ->
            { english = "Activities"
            , kinyarwanda = Just "Ibikorwa"
            }

        ActivitiesCompleted count ->
            { english = "Completed (" ++ Debug.toString count ++ ")"
            , kinyarwanda = Just <| "Ibyarangiye (" ++ Debug.toString count ++ ")"
            }

        ActivitiesHelp activity ->
            case activity of
                MotherActivity Activity.Model.FamilyPlanning ->
                    { english = "Every mother should be asked about her family planning method(s) each month. If a mother needs family planning, refer her to a clinic."
                    , kinyarwanda = Just "Buri mubyeyi agomba kubazwa uburyo bwo kuboneza urubyaro akoresha buri kwezi. Niba umubyeyi akeneye kuboneza urubyaro mwohereze ku kigo nderabuzima k'ubishinzwe"
                    }

                MotherActivity ParticipantConsent ->
                    { english = "Please review the following forms with the participant."
                    , kinyarwanda = Nothing
                    }

                {- ChildActivity Counseling ->
                   { english = "Please refer to this list during counseling sessions and ensure that each task has been completed."
                   , kinyarwanda = Just "Kurikiza iyi lisiti mu gihe utanga ubujyanama, witondere kureba ko buri gikorwa cyakozwe."
                   }
                -}
                ChildActivity Activity.Model.Height ->
                    { english = "Ask the mother to hold the baby’s head at the end of the measuring board. Move the slider to the baby’s heel and pull their leg straight."
                    , kinyarwanda = Just "Saba Umubyeyi guhagarara inyuma y’umwana we agaramye, afata umutwe ku gice cy’amatwi. Sunikira akabaho ku buryo gakora mu bworo by’ibirenge byombi."
                    }

                ChildActivity Activity.Model.Muac ->
                    { english = "Make sure to measure at the center of the baby’s upper arm."
                    , kinyarwanda = Just "Ibuka gupima icya kabiri cy'akaboko ko hejuru kugira bigufashe guoima ikizigira cy'akaboko"
                    }

                ChildActivity Activity.Model.NutritionSigns ->
                    { english = "Explain to the mother how to check the malnutrition signs for their own child."
                    , kinyarwanda = Just "Sobanurira umubyeyi gupima ibimenyetso by'imirire mibi ku giti cye."
                    }

                ChildActivity Activity.Model.ChildPicture ->
                    { english = "Take each baby’s photo at each health assessment. Photos should show the entire body of each child."
                    , kinyarwanda = Just "Fata ifoto ya buri mwana kuri buri bikorwa by'ipimwa Ifoto igomba kwerekana ibice by'umubiri wose by'umwana"
                    }

                ChildActivity Activity.Model.Weight ->
                    { english = "Calibrate the scale before taking the first baby's weight. Place baby in harness with no clothes on."
                    , kinyarwanda = Just "Ibuka kuregera umunzani mbere yo gupima ibiro by'umwana wa mbere. Ambika umwana ikariso y'ibiro wabanje kumukuramo imyenda iremereye"
                    }

        ActivitiesLabel activity ->
            case activity of
                MotherActivity Activity.Model.FamilyPlanning ->
                    { english = "Which, if any, of the following methods do you use?"
                    , kinyarwanda = Just "Ni ubuhe buryo, niba hari ubuhari, mu buryo bukurikira bwo kuboneza urubyaro ukoresha? Muri ubu buryo bukurikira bwo kuboneza urubyaro, ni ubuhe buryo mukoresha?"
                    }

                MotherActivity ParticipantConsent ->
                    { english = "Forms:"
                    , kinyarwanda = Nothing
                    }

                {- ChildActivity Counseling ->
                   { english = "Please refer to this list during counseling sessions and ensure that each task has been completed."
                   , kinyarwanda = Just "Kurikiza iyi lisiti mu gihe utanga ubujyanama, witondere kureba ko buri gikorwa cyakozwe."
                   }
                -}
                ChildActivity Activity.Model.Height ->
                    { english = "Height:"
                    , kinyarwanda = Just "Uburere:"
                    }

                ChildActivity Activity.Model.Muac ->
                    { english = "MUAC:"
                    , kinyarwanda = Just "Ikizigira cy'akaboko:"
                    }

                ChildActivity Activity.Model.NutritionSigns ->
                    { english = "Select all signs that are present:"
                    , kinyarwanda = Just "Hitamo ibimenyetso by'imirire byose bishoboka umwana afite:"
                    }

                ChildActivity Activity.Model.ChildPicture ->
                    { english = "Photo:"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Activity.Model.Weight ->
                    { english = "Weight:"
                    , kinyarwanda = Just "Ibiro:"
                    }

        ActivitiesTitle activity ->
            case activity of
                MotherActivity Activity.Model.FamilyPlanning ->
                    { english = "Family Planning"
                    , kinyarwanda = Just "Kuboneza Urubyaro?"
                    }

                MotherActivity ParticipantConsent ->
                    { english = "Forms"
                    , kinyarwanda = Nothing
                    }

                {- ChildActivity Counseling ->
                   { english = "Counseling"
                   , kinyarwanda = Just "Ubujyanama"
                   }
                -}
                ChildActivity Activity.Model.Height ->
                    { english = "Height"
                    , kinyarwanda = Just "Uburebure"
                    }

                ChildActivity Activity.Model.Muac ->
                    { english = "MUAC"
                    , kinyarwanda = Just "Ikizigira cy'akaboko"
                    }

                ChildActivity Activity.Model.NutritionSigns ->
                    { english = "Nutrition"
                    , kinyarwanda = Just "Imirire"
                    }

                ChildActivity Activity.Model.ChildPicture ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Activity.Model.Weight ->
                    { english = "Weight"
                    , kinyarwanda = Just "Ibiro"
                    }

        ActivityProgressReport activity ->
            case activity of
                MotherActivity Activity.Model.FamilyPlanning ->
                    { english = "Family Planning"
                    , kinyarwanda = Just "Kuboneza Urubyaro? nticyaza muri raporo yimikurire yumwana"
                    }

                MotherActivity ParticipantConsent ->
                    { english = "Forms"
                    , kinyarwanda = Nothing
                    }

                {- ChildActivity Counseling ->
                   { english = "Counseling"
                   , kinyarwanda = Nothing
                   }
                -}
                ChildActivity Activity.Model.Height ->
                    { english = "Height"
                    , kinyarwanda = Just "Uburebure"
                    }

                ChildActivity Activity.Model.Muac ->
                    { english = "MUAC"
                    , kinyarwanda = Just "Ikizigira cy'akaboko"
                    }

                ChildActivity Activity.Model.NutritionSigns ->
                    { english = "Nutrition Signs"
                    , kinyarwanda = Just "Ibimenyetso by'imirire"
                    }

                ChildActivity Activity.Model.ChildPicture ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Activity.Model.Weight ->
                    { english = "Weight"
                    , kinyarwanda = Just "Ibiro"
                    }

        ActivitiesToComplete count ->
            { english = "To Do (" ++ Debug.toString count ++ ")"
            , kinyarwanda = Just <| "Ibisabwa gukora (" ++ Debug.toString count ++ ")"
            }

        ActivePage page ->
            translateActivePage page

        Adherence adherence ->
            translateAdherence adherence

        Age months days ->
            { english = Debug.toString months ++ " months " ++ Debug.toString days ++ " days"
            , kinyarwanda = Just <| Debug.toString months ++ " Amezi " ++ Debug.toString days ++ " iminsi"
            }

        AgeDays days ->
            { english = Debug.toString days ++ " days"
            , kinyarwanda = Just <| Debug.toString days ++ " Iminsi"
            }

        AgeMonthsWithoutDay months ->
            { english = Debug.toString months ++ " month"
            , kinyarwanda = Just <| Debug.toString months ++ " Ukwezi"
            }

        AgeSingleBoth months days ->
            { english = Debug.toString months ++ " month " ++ Debug.toString days ++ " day"
            , kinyarwanda = Just <| Debug.toString months ++ " Ukwezi " ++ Debug.toString days ++ " Umunsi"
            }

        AgeSingleMonth months days ->
            { english = Debug.toString months ++ " month " ++ Debug.toString days ++ " days"
            , kinyarwanda = Just <| Debug.toString months ++ " Ukwezi " ++ Debug.toString days ++ " Iminsi"
            }

        AgeSingleDayWithMonth months days ->
            { english = Debug.toString months ++ " months " ++ Debug.toString days ++ " day"
            , kinyarwanda = Just <| Debug.toString months ++ " Amezi " ++ Debug.toString days ++ " Umunsi"
            }

        AgeSingleDayWithoutMonth months days ->
            { english = Debug.toString days ++ " day"
            , kinyarwanda = Just <| Debug.toString days ++ " Umunsi"
            }

        AgeSingleMonthWithoutDay month ->
            { english = Debug.toString month ++ " month"
            , kinyarwanda = Just <| Debug.toString month ++ " Ukwezi"
            }

        AppName ->
            { english = "E-Heza System"
            , kinyarwanda = Just "E-heza sisiteme"
            }

        AreYouSure ->
            { english = "Are you sure?"
            , kinyarwanda = Just "Urabyizeye?"
            }

        Assessment ->
            { english = "Assessment"
            , kinyarwanda = Just "Ipimwa"
            }

        Asthma ->
            { english = "Asthma"
            , kinyarwanda = Just "Asthma (Agahema)"
            }

        Attendance ->
            { english = "Attendance"
            , kinyarwanda = Just "Ubwitabire"
            }

        Baby ->
            { english = "Baby"
            , kinyarwanda = Just "Umwana"
            }

        BabyDiedOnDayOfBirthPreviousDelivery ->
            { english = "Live Birth but the baby died the same day in previous delivery"
            , kinyarwanda = Just "Aheruka kubyara umwana muzima apfa uwo munsi"
            }

        BabyName name ->
            { english = "Baby: " ++ name
            , kinyarwanda = Just <| "Umwana: " ++ name
            }

        Back ->
            { english = "Back"
            , kinyarwanda = Nothing
            }

        BackendError ->
            { english = "Error contacting backend"
            , kinyarwanda = Just "Seriveri yerekanye amakosa akurikira"
            }

        BeginNewEncounter ->
            { english = "Begin a New Encounter"
            , kinyarwanda = Nothing
            }

        BloodPressure ->
            { english = "Blood Pressure"
            , kinyarwanda = Just "Umuvuduko w'amaraso"
            }

        BloodPressureElevatedOcassions ->
            { english = "Blood Pressure Elevated occasions"
            , kinyarwanda = Nothing
            }

        BloodPressureDiaLabel ->
            { english = "Diastolic"
            , kinyarwanda = Just "Umuvuduko w'amaraso wo hasi"
            }

        BloodPressureSysLabel ->
            { english = "Systolic"
            , kinyarwanda = Just "Umubare w'umuviduko w'amaraso wo hejuru"
            }

        BMI ->
            { english = "BMI"
            , kinyarwanda = Nothing
            }

        BMIHelper ->
            { english = "Calculated based on Height and Weight"
            , kinyarwanda = Just "Byabazwe hashingiwe ku burebure n'ibiro"
            }

        BodyTemperature ->
            { english = "Body Temperature"
            , kinyarwanda = Just "Ubushyuhe bw'umubiri"
            }

        Born ->
            { english = "Born"
            , kinyarwanda = Just "Kuvuka/ itariki y'amavuko"
            }

        BowedLegs ->
            { english = "Bowed Legs"
            , kinyarwanda = Just "Amaguru atameze neza (yagize imitego)"
            }

        BpmUnit ->
            { english = "bpm"
            , kinyarwanda = Just "Inshuro ahumeka ku munota"
            }

        BreastExam ->
            { english = "Breast Exam"
            , kinyarwanda = Just "Gusuzuma amabere"
            }

        BreastExamQuestion ->
            { english = "Did you show the patient how to perform a self breast exam"
            , kinyarwanda = Just "Weretse umubyeyi uko yakwisuzuma amabere?"
            }

        BreastExamSign option ->
            case option of
                Mass ->
                    { english = "Mass"
                    , kinyarwanda = Just "Uburemere"
                    }

                Discharge ->
                    { english = "Discharge"
                    , kinyarwanda = Just "Gusezererwa"
                    }

                Infection ->
                    { english = "Infection"
                    , kinyarwanda = Just "Indwara iterwa n'udukoko tutabonwa n'amaso (Microbes)"
                    }

                NormalBreast ->
                    translationSet Normal

        BrittleHair ->
            { english = "Brittle Hair"
            , kinyarwanda = Just "Gucurama no guhindura ibara ku misatsi"
            }

        Cancel ->
            { english = "Cancel"
            , kinyarwanda = Just "Guhagarika"
            }

        CardiacDisease ->
            { english = "Cardiac Disease"
            , kinyarwanda = Just "Indwara z'umutima"
            }

        CaregiverName ->
            { english = "Caregiver's Name"
            , kinyarwanda = Nothing
            }

        CaregiverNationalId ->
            { english = "Caregiver's National ID"
            , kinyarwanda = Nothing
            }

        Cell ->
            { english = "Cell"
            , kinyarwanda = Just "Akagali"
            }

        CentimeterShorthand ->
            { english = "cm"
            , kinyarwanda = Just "cm"
            }

        Celsius ->
            { english = "Celsius"
            , kinyarwanda = Nothing
            }

        ChartPhrase phrase ->
            translateChartPhrase phrase

        CheckIn ->
            { english = "Check in:"
            , kinyarwanda = Just "Kureba abaje"
            }

        ChildHmisNumber ->
            { english = "Child HMIS Number"
            , kinyarwanda = Just "Numero y'umwana muri HMIS"
            }

        ChildDemographicInformation ->
            { english = "Child Demographic Information"
            , kinyarwanda = Nothing
            }

        ChildNutritionSignLabel sign ->
            case sign of
                AbdominalDistension ->
                    { english = "Abdominal Distension"
                    , kinyarwanda = Just "Kubyimba inda"
                    }

                Apathy ->
                    { english = "Apathy"
                    , kinyarwanda = Just "Kwigunga"
                    }

                Backend.Measurement.Model.BrittleHair ->
                    translationSet BrittleHair

                DrySkin ->
                    { english = "Dry Skin"
                    , kinyarwanda = Just "Uruhu ryumye"
                    }

                Backend.Measurement.Model.Edema ->
                    translationSet Edema

                NormalChildNutrition ->
                    { english = "None of these"
                    , kinyarwanda = Just "Nta bimenyetso "
                    }

                PoorAppetite ->
                    { english = "Poor Appetite"
                    , kinyarwanda = Just "Kubura apeti /kunanirwa kurya"
                    }

        ChildNutritionSignReport sign ->
            case sign of
                AbdominalDistension ->
                    { english = "Abdominal Distension"
                    , kinyarwanda = Just "Kubyimba inda"
                    }

                Apathy ->
                    { english = "Apathy"
                    , kinyarwanda = Just "Kwigunga"
                    }

                Backend.Measurement.Model.BrittleHair ->
                    translationSet BrittleHair

                DrySkin ->
                    { english = "Dry Skin"
                    , kinyarwanda = Just "Uruhu ryumye"
                    }

                Backend.Measurement.Model.Edema ->
                    translationSet Edema

                NormalChildNutrition ->
                    { english = "None"
                    , kinyarwanda = Just "Nta bimenyetso"
                    }

                PoorAppetite ->
                    { english = "Poor Appetite"
                    , kinyarwanda = Just "kubura apeti (kunanirwa kurya)"
                    }

        Children ->
            { english = "Children"
            , kinyarwanda = Just "Abana"
            }

        ChildrenNames ->
            { english = "Children's names"
            , kinyarwanda = Just "Amazina y'umwana"
            }

        ChildrenNationalId ->
            { english = "Children's National ID"
            , kinyarwanda = Just "Indangamuntu y'umwana"
            }

        ChildOf ->
            { english = "Child of"
            , kinyarwanda = Just "Umwana wa"
            }

        Clear ->
            { english = "Clear"
            , kinyarwanda = Just "Gukuraho"
            }

        ClickTheCheckMark ->
            { english = "Click the check mark if the mother / caregiver is in attendance. The check mark will appear green when a mother / caregiver has been signed in."
            , kinyarwanda = Just "Kanda (kuri) ku kazu niba umubyeyi ahari. Ku kazu harahita hahindura ibara habe icyaytsi niba wemeje ko umubyeyi ahari"
            }

        ClinicType clinicType ->
            case clinicType of
                Chw ->
                    { english = "CHW"
                    , kinyarwanda = Nothing
                    }

                Fbf ->
                    { english = "Fbf"
                    , kinyarwanda = Nothing
                    }

                Pmtct ->
                    { english = "Pmtct"
                    , kinyarwanda = Nothing
                    }

                Sorwathe ->
                    { english = "Sorwathe"
                    , kinyarwanda = Nothing
                    }

        Clinical ->
            { english = "Clinical"
            , kinyarwanda = Just "Ikigo Nderabuzima"
            }

        ClinicalProgressReport ->
            { english = "Clinical Progress Report"
            , kinyarwanda = Just "Erekana raporo yibyavuye mu isuzuma"
            }

        ConvulsionsAndUnconsciousPreviousDelivery ->
            { english = "Experienced convulsions and resulted in becoming unconscious after delivery"
            , kinyarwanda = Just "Ubushize yahinze umushyitsi bimuviramo kutumva akimara kubyara"
            }

        ConvulsionsPreviousDelivery ->
            { english = "Experienced convulsions in previous delivery"
            , kinyarwanda = Just "Ubushize yahinze umushyitsi abyara"
            }

        CSectionScar scar ->
            case scar of
                Vertical ->
                    { english = "Vertical"
                    , kinyarwanda = Just "Irahagaze"
                    }

                Horizontal ->
                    { english = "Horizontal"
                    , kinyarwanda = Just "Iratambitse"
                    }

                NoScar ->
                    { english = "None"
                    , kinyarwanda = Just "Ntabyo"
                    }

        GroupNotFound ->
            { english = "Group not found"
            , kinyarwanda = Nothing
            }

        Group ->
            { english = "Group"
            , kinyarwanda = Just "Itsinda"
            }

        Groups ->
            { english = "Groups"
            , kinyarwanda = Just "Itsinda"
            }

        Close ->
            { english = "Close"
            , kinyarwanda = Nothing
            }

        Closed ->
            { english = "Closed"
            , kinyarwanda = Just "Gufunga"
            }

        GroupUnauthorized ->
            { english = "You are not authorized to work with this Group."
            , kinyarwanda = Nothing
            }

        ConfirmDeleteTrainingGroupEncounters ->
            { english = "Are you sure you want to delete all training Group Encounters?"
            , kinyarwanda = Nothing
            }

        ConfirmRegisterParticipant ->
            { english = "Are you sure you want to save this participant's data?"
            , kinyarwanda = Nothing
            }

        ConfirmationRequired ->
            { english = "Please confirm:"
            , kinyarwanda = Nothing
            }

        Connected ->
            { english = "Connected"
            , kinyarwanda = Just "Ufite interineti (murandasi)"
            }

        ContactInformation ->
            { english = "Contact Information"
            , kinyarwanda = Just "Uburyo bwakwifashishwa mu kugera ku mugenerwabikorwa"
            }

        Continue ->
            { english = "Continue"
            , kinyarwanda = Just "Gukomeza"
            }

        CounselingTimingHeading timing ->
            translateCounselingTimingHeading timing

        CounselingTopic topic ->
            { english = topic.english
            , kinyarwanda = topic.kinyarwanda
            }

        CounselorReviewed ->
            { english = "I have reviewed the above with the participant."
            , kinyarwanda = Nothing
            }

        CounselorSignature ->
            { english = "Entry Counselor Signature"
            , kinyarwanda = Nothing
            }

        CSectionInPreviousDelivery ->
            { english = "C-section in previous delivery"
            , kinyarwanda = Just "Yarabazwe ku nda ishize"
            }

        CSectionReason ->
            { english = "Reason for C-section"
            , kinyarwanda = Just "Impamvu yo kubagwa"
            }

        CSectionReasons reason ->
            case reason of
                Breech ->
                    { english = "Breech"
                    , kinyarwanda = Just "Abanje ikibuno(umwana yaje yicaye)"
                    }

                Emergency ->
                    { english = "Emergency"
                    , kinyarwanda = Just "Ibyihutirwa"
                    }

                FailureToProgress ->
                    { english = "Failure to Progress"
                    , kinyarwanda = Just "Ntibyiyongera"
                    }

                Backend.Measurement.Model.None ->
                    { english = "None"
                    , kinyarwanda = Just "Ntabyo"
                    }

                Other ->
                    { english = "Other"
                    , kinyarwanda = Just "Ibindi"
                    }

        CreateGroupEncounter ->
            { english = "Create Group Encounter"
            , kinyarwanda = Just "Tangira igikorwa"
            }

        CreateRelationship ->
            { english = "Create Relationship"
            , kinyarwanda = Just "Ibijyanye no guhuza amasano"
            }

        CreateTrainingGroupEncounters ->
            { english = "Create All Training Group Encounters"
            , kinyarwanda = Nothing
            }

        CurrentlyPregnant ->
            { english = "Currently Pregnant"
            , kinyarwanda = Just "Aratwite"
            }

        DeleteTrainingGroupEncounters ->
            { english = "Delete All Training Group Encounters"
            , kinyarwanda = Nothing
            }

        DeliveryLocation ->
            { english = "Delivery Location"
            , kinyarwanda = Nothing
            }

        DeliveryOutcome ->
            { english = "Delivery Outcome"
            , kinyarwanda = Nothing
            }

        DangerSign sign ->
            case sign of
                VaginalBleeding ->
                    { english = "Vaginal bleeding"
                    , kinyarwanda = Just "Kuva"
                    }

                HeadacheBlurredVision ->
                    { english = "Severe headaches with blurred vision"
                    , kinyarwanda = Just "Kuribwa umutwe bidasanzwe ukareba ibikezikezi"
                    }

                Convulsions ->
                    { english = "Convulsions"
                    , kinyarwanda = Just "Kugagara"
                    }

                AbdominalPain ->
                    { english = "Abdominal pain"
                    , kinyarwanda = Just "Kuribwa mu nda"
                    }

                DifficultyBreathing ->
                    { english = "Difficulty breathing"
                    , kinyarwanda = Just "Guhumeka nabi"
                    }

                Fever ->
                    { english = "Fever"
                    , kinyarwanda = Just "Umuriro"
                    }

                ExtremeWeakness ->
                    { english = "Extreme weakness"
                    , kinyarwanda = Just "Gucika intege cyane"
                    }

                NoDangerSign ->
                    { english = "None of these"
                    , kinyarwanda = Just "Nta bimenyetso/nta na kimwe"
                    }

        Dashboard ->
            { english = "Dashboard"
            , kinyarwanda = Just "Tabeau de bord"
            }

        DateOfLastAssessment ->
            { english = "Date of last Assessment"
            , kinyarwanda = Just "Amakuru y'ipimwa ry'ubushize"
            }

        DatePregnancyConcluded ->
            { english = "Date Pregnancy Concluded"
            , kinyarwanda = Just "Date Pregnancy Concluded"
            }

        Day ->
            { english = "Day"
            , kinyarwanda = Just "Umunsi"
            }

        DaySinglePlural value ->
            if value == 1 then
                { english = "1 Day"
                , kinyarwanda = Just "1 Umunsi"
                }

            else
                { english = Debug.toString value ++ " Days"
                , kinyarwanda = Just <| Debug.toString value ++ " Iminsi"
                }

        DateOfBirth ->
            { english = "Date of Birth"
            , kinyarwanda = Just "Itariki y'amavuko"
            }

        Days ->
            { english = "days"
            , kinyarwanda = Just "Iminsi"
            }

        Delete ->
            { english = "Delete"
            , kinyarwanda = Nothing
            }

        DemographicInformation ->
            { english = "Demographic Information"
            , kinyarwanda = Just "Umwirondoro"
            }

        DemographicsReport ->
            { english = "Demographics Report"
            , kinyarwanda = Just "Raporo y'umwirondoro"
            }

        Device ->
            { english = "Device"
            , kinyarwanda = Nothing
            }

        DeviceNotAuthorized ->
            { english =
                """This device has not yet been authorized to sync data with the backend, or the
                authorization has expired or been revoked. To authorize or re-authorize this
                device, enter a pairing code below. This will permit sensitive data to be stored
                on this device and updated to the backend. You should only authorize devices that
                are under your control and which are secure."""
            , kinyarwanda = Nothing
            }

        DeviceStatus ->
            { english = "Device Status"
            , kinyarwanda = Just "Uko igikoresho cy'ikoranabuhanga gihagaze"
            }

        Diabetes ->
            { english = "Diabetes"
            , kinyarwanda = Just "Diyabete (Indwara y'igisukari)"
            }

        District ->
            { english = "District"
            , kinyarwanda = Just "Akarere"
            }

        DOB ->
            { english = "DOB"
            , kinyarwanda = Nothing
            }

        DropzoneDefaultMessage ->
            { english = "Touch here to take a photo, or drop a photo file here."
            , kinyarwanda = Just "Kanda hano niba ushaka gufotora cg ukure ifoto mu bubiko hano."
            }

        DueDate ->
            { english = "Due Date"
            , kinyarwanda = Just "Itariki azabyariraho"
            }

        Edd ->
            { english = "EDD"
            , kinyarwanda = Nothing
            }

        EddHeader ->
            { english = "Estimated Date of Delivery"
            , kinyarwanda = Just "Itariki y'agateganyo azabyariraho"
            }

        Edema ->
            { english = "Edema"
            , kinyarwanda = Just "Kubyimba"
            }

        EditRelationship ->
            { english = "Edit Relationship"
            , kinyarwanda = Nothing
            }

        Ega ->
            { english = "EGA"
            , kinyarwanda = Nothing
            }

        EgaHeader ->
            { english = "Estimated Gestational Age"
            , kinyarwanda = Just "Amezi y'agateganyo y'inda"
            }

        EgaWeeks ->
            { english = "EGA (Weeks)"
            , kinyarwanda = Just "EGA (Ibyumweru)"
            }

        EmptyString ->
            { english = ""
            , kinyarwanda = Just ""
            }

        EndEncounter ->
            { english = "End Encounter"
            , kinyarwanda = Just "Rangiza ibyo wakoraga"
            }

        EndGroupEncounter ->
            { english = "End Group Encounter"
            , kinyarwanda = Just "Gusoza igikorwa"
            }

        EnterPairingCode ->
            { english = "Enter pairing code"
            , kinyarwanda = Just "Umubare uhuza igikoresho cy'ikoranabuhanga na apulikasiyo"
            }

        MemoryQuota quota ->
            { english = "Memory used " ++ Debug.toString (quota.usedJSHeapSize // (1024 * 1024)) ++ " MB of available " ++ Debug.toString (quota.jsHeapSizeLimit // (1024 * 1024)) ++ " MB"
            , kinyarwanda = Just <| "Hamaze gukoreshwa umwanya wa memori (ushobora kubika amakuru igihe gito) ungana na MB" ++ Debug.toString (quota.usedJSHeapSize // (1024 * 1024)) ++ " kuri MB" ++ Debug.toString (quota.jsHeapSizeLimit // (1024 * 1024))
            }

        StorageQuota quota ->
            { english = "Storage used " ++ Debug.toString (quota.usage // (1024 * 1024)) ++ " MB of available " ++ Debug.toString (quota.quota // (1024 * 1024)) ++ " MB"
            , kinyarwanda = Just <| "Hamaze gukoreshwa umwanya ungana na MB" ++ Debug.toString (quota.usage // (1024 * 1024)) ++ " umwanya wose ungana na MB" ++ Debug.toString (quota.quota // (1024 * 1024))
            }

        SubmitPairingCode ->
            { english = "Submit Pairing Code"
            , kinyarwanda = Just "Umubare uhuza igikoresho cy'ikoranabuhanga na apulikasiyo"
            }

        ErrorCheckLocalConfig ->
            { english = "Check your LocalConfig.elm file and make sure you have defined the enviorement properly"
            , kinyarwanda = Nothing
            }

        ErrorConfigurationError ->
            { english = "Configuration error"
            , kinyarwanda = Just "Ikosa mu igena miterere"
            }

        Estimated ->
            { english = "Estimated"
            , kinyarwanda = Just "Itariki y'amavuko igenekerejwe"
            }

        ExaminationTask task ->
            case task of
                Vitals ->
                    { english = "Vitals"
                    , kinyarwanda = Just "Ibimenyetso by'ubuzima"
                    }

                NutritionAssessment ->
                    { english = "Nutrition Assessment"
                    , kinyarwanda = Just "Gusuzuma imirire"
                    }

                CorePhysicalExam ->
                    { english = "Core Physical Exam"
                    , kinyarwanda = Just "Isuzuma ryimbitse"
                    }

                ObstetricalExam ->
                    { english = "Obstetrical Exam"
                    , kinyarwanda = Just "Ibipimo by'inda"
                    }

                Pages.PrenatalActivity.Model.BreastExam ->
                    translationSet BreastExam

        Failure ->
            { english = "Failure"
            , kinyarwanda = Nothing
            }

        Extremities ->
            { english = "Extremities"
            , kinyarwanda = Nothing
            }

        Eyes ->
            { english = "Eyes"
            , kinyarwanda = Just "Amaso"
            }

        Facility ->
            { english = "Facility"
            , kinyarwanda = Nothing
            }

        FamilyInformation ->
            { english = "Family Information"
            , kinyarwanda = Just "Amakuru ku muryango"
            }

        FamilyMembers ->
            { english = "Family Members"
            , kinyarwanda = Just "Abagize umuryango"
            }

        FamilyPlanningInFutureQuestion ->
            { english = "Which, if any, of these methods will you use after your pregnancy"
            , kinyarwanda = Just "Niba buhari, ni ubuhe buryo uzakoresha nyuma yo kubyara?"
            }

        FamilyPlanningSignLabel sign ->
            case sign of
                AutoObservation ->
                    { english = "Auto-observation"
                    , kinyarwanda = Just "Kwigenzura ururenda"
                    }

                Condoms ->
                    { english = "Condoms"
                    , kinyarwanda = Just "Udukingirizo"
                    }

                CycleBeads ->
                    { english = "Cycle beads"
                    , kinyarwanda = Just "Urunigi"
                    }

                CycleCounting ->
                    { english = "Cycle counting"
                    , kinyarwanda = Just "Kubara "
                    }

                Hysterectomy ->
                    { english = "Hysterectomy"
                    , kinyarwanda = Just "Bakuyemo nyababyeyi"
                    }

                Implants ->
                    { english = "Implants"
                    , kinyarwanda = Just "Akapira ko mu kaboko"
                    }

                Injectables ->
                    { english = "Injectables"
                    , kinyarwanda = Just "Urushinge"
                    }

                IUD ->
                    { english = "IUD"
                    , kinyarwanda = Just "Akapira ko mu mura (agapira ko munda ibyara)"
                    }

                LactationAmenorrhea ->
                    { english = "Lactation amenorrhea"
                    , kinyarwanda = Just "Uburyo bwo konsa"
                    }

                NoFamilyPlanning ->
                    { english = "None of these"
                    , kinyarwanda = Just "Nta buryo bwo kuboneza urubyaro akoresha"
                    }

                OralContraceptives ->
                    { english = "Oral contraceptives"
                    , kinyarwanda = Just "Ibinini"
                    }

                Spermicide ->
                    { english = "Spermicide"
                    , kinyarwanda = Just "Ibinini byica intangangabo bicishwa mu gitsina"
                    }

                TubalLigatures ->
                    { english = "Tubal ligatures"
                    , kinyarwanda = Just "Gufunga umuyoborantanga ku bagore"
                    }

                Vasectomy ->
                    { english = "Vasectomy"
                    , kinyarwanda = Just "Gufunga umuyoborantanga ku bagabo"
                    }

        FamilyUbudehe ->
            { english = "Family Ubudehe"
            , kinyarwanda = Just "Icyiciro cy'ubudehe umuryango uherereyemo"
            }

        FatherName ->
            { english = "Father's Name"
            , kinyarwanda = Nothing
            }

        FatherNationalId ->
            { english = "Father's National ID"
            , kinyarwanda = Nothing
            }

        FetalHeartRate ->
            { english = "Fetal Heart Rate"
            , kinyarwanda = Just "Uko umutima w'umwana utera"
            }

        FetalMovement ->
            { english = "Fetal Movement"
            , kinyarwanda = Just "Uko umwana akina mu nda"
            }

        FetalPresentationLabel ->
            { english = "Fetal Presentation"
            , kinyarwanda = Just "Uko umwana ameze mu nda"
            }

        FetalPresentation option ->
            case option of
                FetalBreech ->
                    { english = "Breech"
                    , kinyarwanda = Just "Abanje ikibuno(umwana yaje yicaye)"
                    }

                Cephalic ->
                    { english = "Cephalic"
                    , kinyarwanda = Just "Umwana abanje umutwe"
                    }

                Transverse ->
                    { english = "Transverse"
                    , kinyarwanda = Just "Gitambitse (Umwana aritambitse)"
                    }

                Twins ->
                    { english = "Twins"
                    , kinyarwanda = Just "Impanga"
                    }

                Backend.Measurement.Model.Unknown ->
                    { english = "Unknown"
                    , kinyarwanda = Just "Ntibizwi"
                    }

        Fetch ->
            { english = "Fetch"
            , kinyarwanda = Just "Gushakisha"
            }

        FilterByName ->
            { english = "Filter by name"
            , kinyarwanda = Just "Hitamo izina ryuwo ushaka"
            }

        FirstAntenatalVisit ->
            { english = "First Antenatal Visit"
            , kinyarwanda = Just "Kwipimisha inda bwa mbere"
            }

        FirstName ->
            { english = "First Name"
            , kinyarwanda = Just "Izina ry'idini"
            }

        FiveVisits ->
            { english = "Five visits"
            , kinyarwanda = Just "Inshuro eshanu"
            }

        ForIllustrativePurposesOnly ->
            { english = "For illustrative purposes only"
            , kinyarwanda = Nothing
            }

        FormError errorValue ->
            translateFormError errorValue

        FormField field ->
            translateFormField field

        FundalHeight ->
            { english = "Fundal Height"
            , kinyarwanda = Just "Uburebure bwa Nyababyeyi"
            }

        Gender gender ->
            case gender of
                Male ->
                    { english = "Male"
                    , kinyarwanda = Just "Gabo"
                    }

                Female ->
                    { english = "Female"
                    , kinyarwanda = Just "Gore"
                    }

        GenderLabel ->
            { english = "Gender"
            , kinyarwanda = Just "Igitsina"
            }

        GestationalDiabetesPreviousPregnancy ->
            { english = "Gestational Diabetes in previous pregnancy"
            , kinyarwanda = Just "Ubushize yarwaye Diyabete itewe no gutwita"
            }

        GoHome ->
            { english = "Go to main page"
            , kinyarwanda = Just "Kujya ahabanza"
            }

        GroupAssessment ->
            { english = "Group Encounter"
            , kinyarwanda = Just "Gukorera itsinda"
            }

        GroupEncounter ->
            { english = "Group Encounter"
            , kinyarwanda = Nothing
            }

        Gravida ->
            { english = "Gravida"
            , kinyarwanda = Nothing
            }

        Hands ->
            { english = "Hands"
            , kinyarwanda = Just "Ibiganza"
            }

        HandsCPESign option ->
            case option of
                PallorHands ->
                    translationSet Pallor

                EdemaHands ->
                    translationSet Edema

                NormalHands ->
                    translationSet Normal

        HeadHair ->
            { english = "Head/Hair"
            , kinyarwanda = Just "Umutwe/Umusatsi"
            }

        HealthCenter ->
            { english = "Health Center"
            , kinyarwanda = Just "Ikigo Nderabuzima"
            }

        Heart ->
            { english = "Heart"
            , kinyarwanda = Just "Umutima"
            }

        HeartMurmur ->
            { english = "Heart Murmur"
            , kinyarwanda = Just "Ijwi ry'umutima igihe utera"
            }

        HeartCPESign sign ->
            case sign of
                IrregularRhythm ->
                    { english = "Irregular Rhythm"
                    , kinyarwanda = Just "Injyana ihindagurika"
                    }

                NormalRateAndRhythm ->
                    { english = "Normal Rate And Rhythm"
                    , kinyarwanda = Just "Bimeze neza/Injyana imeze neza"
                    }

                SinusTachycardia ->
                    { english = "Sinus Tachycardia"
                    , kinyarwanda = Just "Gutera k'umutima birenze cyane igipimo gisanzwe"
                    }

        HeartRate ->
            { english = "Heart Rate"
            , kinyarwanda = Just "Gutera k'umutima (inshuro umutima utera)"
            }

        Height ->
            { english = "Height"
            , kinyarwanda = Just "Uburebure"
            }

        High ->
            { english = "High"
            , kinyarwanda = Nothing
            }

        HighRiskFactor factor ->
            case factor of
                PrenatalActivity.Model.ConvulsionsAndUnconsciousPreviousDelivery ->
                    { english = "Patient experienced convulsions in previous delivery and became unconscious after delivery"
                    , kinyarwanda = Nothing
                    }

                PrenatalActivity.Model.ConvulsionsPreviousDelivery ->
                    { english = "Patient experienced convulsions in previous delivery"
                    , kinyarwanda = Nothing
                    }

        HighRiskFactors ->
            { english = "High Risk Factors"
            , kinyarwanda = Just "Abafite ibyago byinshi byo"
            }

        HighSeverityAlert alert ->
            case alert of
                PrenatalActivity.Model.BodyTemperature ->
                    { english = "Body Temperature"
                    , kinyarwanda = Just "Ubushyuhe bw'umubiri"
                    }

                PrenatalActivity.Model.FetalHeartRate ->
                    { english = "No fetal heart rate noted"
                    , kinyarwanda = Just "Umutima w'umwana ntutera"
                    }

                PrenatalActivity.Model.FetalMovement ->
                    { english = "No fetal movement noted"
                    , kinyarwanda = Just "Umwana ntakina mu nda"
                    }

                PrenatalActivity.Model.HeartRate ->
                    { english = "Heart Rate"
                    , kinyarwanda = Nothing
                    }

                PrenatalActivity.Model.RespiratoryRate ->
                    { english = "Respiratory Rate"
                    , kinyarwanda = Just "Inshuro ahumeka"
                    }

        HighSeverityAlerts ->
            { english = "High Severity Alerts"
            , kinyarwanda = Just "Bimenyetso mpuruza bikabije"
            }

        HistoryTask task ->
            case task of
                Obstetric ->
                    { english = "Obstetric History"
                    , kinyarwanda = Just "Amateka y'inda zibanza (ku nda yatwise)"
                    }

                Medical ->
                    { english = "Medical History"
                    , kinyarwanda = Just "Amateka y'uburwayi busanzwe"
                    }

                Social ->
                    { english = "Partner Information"
                    , kinyarwanda = Just "Amakuru y'uwo bashakanye (umugabo)"
                    }

        HIV ->
            { english = "HIV"
            , kinyarwanda = Just "Amaguru atameze neza(yagize imitego)"
            }

        HIVStatus status ->
            case status of
                HIVExposedInfant ->
                    { english = "HIV-exposed Infant"
                    , kinyarwanda = Just "Umwana uvuka ku mubyeyi ubana n'ubwandu bwa virusi ya SIDA"
                    }

                Negative ->
                    { english = "Negative"
                    , kinyarwanda = Just "Nta bwandu afite"
                    }

                NegativeDiscordantCouple ->
                    { english = "Negative - discordant couple"
                    , kinyarwanda = Just "Nta bwandu afite ariko abana n'ubufite"
                    }

                Positive ->
                    { english = "Positive"
                    , kinyarwanda = Just "Afite ubwandu"
                    }

                Backend.Person.Model.Unknown ->
                    { english = "Unknown"
                    , kinyarwanda = Just "Ntabizi"
                    }

        HIVStatusLabel ->
            { english = "HIV Status"
            , kinyarwanda = Just "Uko ahagaze ku bijyanye n'ubwandu bwa virusi ya SIDA"
            }

        Home ->
            { english = "Home"
            , kinyarwanda = Nothing
            }

        HouseholdSize ->
            { english = "Household Size"
            , kinyarwanda = Nothing
            }

        HttpError error ->
            translateHttpError error

        HypertensionBeforePregnancy ->
            { english = "Hypertension before pregnancy"
            , kinyarwanda = Just "Umuvuduko w'amaraso mbere yo gutwita"
            }

        IncompleteCervixPreviousPregnancy ->
            { english = "Incomplete Cervix in previous pregnancy"
            , kinyarwanda = Just "Ubushize inkondo y'umura ntiyashoboye kwifunga neza "
            }

        IndividualEncounter ->
            { english = "Individual Encounter"
            , kinyarwanda = Just "Gukorera umuntu umwe"
            }

        IndividualEncounterFirstVisit type_ ->
            case type_ of
                AntenatalEncounter ->
                    { english = "First Antenatal Encounter"
                    , kinyarwanda = Nothing
                    }

                InmmunizationEncounter ->
                    { english = "First Inmmunization Encounter"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounter ->
                    { english = "First Nutrition Encounter"
                    , kinyarwanda = Nothing
                    }

        IndividualEncounterLabel type_ ->
            case type_ of
                AntenatalEncounter ->
                    { english = "Antenatal Encounter"
                    , kinyarwanda = Nothing
                    }

                InmmunizationEncounter ->
                    { english = "Inmmunization Encounter"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounter ->
                    { english = "Nutrition Encounter"
                    , kinyarwanda = Nothing
                    }

        IndividualEncounterSelectVisit type_ ->
            case type_ of
                AntenatalEncounter ->
                    { english = "Select Antenatal Visit"
                    , kinyarwanda = Nothing
                    }

                InmmunizationEncounter ->
                    { english = "Select Inmmunization Visit"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounter ->
                    { english = "Select Nutrition Visit"
                    , kinyarwanda = Nothing
                    }

        IndividualEncounterSubsequentVisit type_ ->
            case type_ of
                AntenatalEncounter ->
                    { english = "Subsequent Antenatal Encounter"
                    , kinyarwanda = Nothing
                    }

                InmmunizationEncounter ->
                    { english = "Subsequent Inmmunization Encounter"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounter ->
                    { english = "Subsequent Nutrition Encounter"
                    , kinyarwanda = Nothing
                    }

        IndividualEncounterType type_ ->
            case type_ of
                AntenatalEncounter ->
                    { english = "Antenatal"
                    , kinyarwanda = Nothing
                    }

                InmmunizationEncounter ->
                    { english = "Inmmunization"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounter ->
                    { english = "Child Nutrition"
                    , kinyarwanda = Nothing
                    }

        IndividualEncounterTypes ->
            { english = "Individual Encounter Types"
            , kinyarwanda = Nothing
            }

        InitialResultsDisplay display ->
            case display of
                InitialResultsHidden ->
                    { english = "Display all mothers / caregivers"
                    , kinyarwanda = Just "Kugaragaza ababyeyi bose / abarezi"
                    }

                InitialResultsShown ->
                    { english = "Hide all mothers / caregivers"
                    , kinyarwanda = Just "Hisha ababyeyi bose / abarezi"
                    }

        KilogramShorthand ->
            { english = "kg"
            , kinyarwanda = Just "kg"
            }

        LastChecked ->
            { english = "Last checked"
            , kinyarwanda = Just "Isuzuma riheruka"
            }

        LastSuccesfulContactLabel ->
            { english = "Last Successful Contact"
            , kinyarwanda = Just "Itariki n'isaha yanyuma igikoresho giheruka gukoresherezaho interineti bikagenda neza"
            }

        Legs ->
            { english = "Legs"
            , kinyarwanda = Just "Amaguru"
            }

        LegsCPESign option ->
            case option of
                PallorLegs ->
                    translationSet Pallor

                EdemaLegs ->
                    translationSet Edema

                NormalLegs ->
                    translationSet Normal

        LevelOfEducationLabel ->
            { english = "Level of Education"
            , kinyarwanda = Just <| "Amashuri wize"
            }

        LevelOfEducation educationLevel ->
            case educationLevel of
                NoSchooling ->
                    { english = "No Schooling"
                    , kinyarwanda = Just "Ntayo"
                    }

                PrimarySchool ->
                    { english = "Primary School"
                    , kinyarwanda = Just "Abanza"
                    }

                VocationalTrainingSchool ->
                    { english = "Vocational Training School"
                    , kinyarwanda = Just "Imyuga"
                    }

                SecondarySchool ->
                    { english = "Secondary School"
                    , kinyarwanda = Just "Ayisumbuye"
                    }

                DiplomaProgram ->
                    { english = "Diploma Program (2 years of University)"
                    , kinyarwanda = Just "Amashuri 2 ya Kaminuza"
                    }

                HigherEducation ->
                    { english = "Higher Education (University)"
                    , kinyarwanda = Just "(A0)"
                    }

                AdvancedDiploma ->
                    { english = "Advanced Diploma"
                    , kinyarwanda = Just "(A1)"
                    }

        LinkToMother ->
            { english = "Link to mother"
            , kinyarwanda = Just "Guhuza n'amakuru y'umubyeyi"
            }

        LiveChildren ->
            { english = "Live Children"
            , kinyarwanda = Just "Abana bariho"
            }

        LmpDateConfidentHeader ->
            { english = "Is the Patient confident of LMP Date"
            , kinyarwanda = Just "Ese umubyeyi azi neza itariki aherukira mu mihango?"
            }

        LmpDateHeader ->
            { english = "Last Menstrual Period Date"
            , kinyarwanda = Just "Itariki aherukira mu mihango"
            }

        LmpRangeHeader ->
            { english = "When was the Patient's Last Menstrual Period"
            , kinyarwanda = Just "Ni ryari umubyeyi aherukira mu mihango?"
            }

        LmpRange range ->
            case range of
                OneMonth ->
                    { english = "Within 1 month"
                    , kinyarwanda = Just "Mu kwezi kumwe"
                    }

                ThreeMonth ->
                    { english = "Within 3 months"
                    , kinyarwanda = Just "Mu mezi atatu"
                    }

                SixMonth ->
                    { english = "Within 6 months"
                    , kinyarwanda = Just "Mu mezi atandatu"
                    }

        LoginPhrase phrase ->
            translateLoginPhrase phrase

        Low ->
            { english = "Low"
            , kinyarwanda = Just "Kwemeza amakosa"
            }

        Lungs ->
            { english = "Lungs"
            , kinyarwanda = Just "Ibihaha"
            }

        LungsCPESign option ->
            case option of
                Wheezes ->
                    { english = "Wheezes"
                    , kinyarwanda = Just "Ijwi ryumvikana igihe umuntu ahumeka"
                    }

                Crackles ->
                    { english = "Crackles"
                    , kinyarwanda = Just "Ijwi ryumvikana umuntu ahumeka ariko afite indwara z'ubuhumekero"
                    }

                NormalLungs ->
                    translationSet Normal

        MakeSureYouAreConnected ->
            { english = "Make sure you are connected to the internet. If the issue continues, call The Ihangane Project at +250 788 817 542."
            , kinyarwanda = Just "Banza urebe ko ufite interineti. Ikibazo nigikomeza, hamagara The Ihangane Project kuri +250 788 817 542"
            }

        MaritalStatusLabel ->
            { english = "Marital Status"
            , kinyarwanda = Just "Irangamimerere"
            }

        MaritalStatus status ->
            case status of
                Divorced ->
                    { english = "Divorced"
                    , kinyarwanda = Just "Yatandukanye n'uwo bashakanye"
                    }

                Married ->
                    { english = "Married"
                    , kinyarwanda = Just "Arubatse"
                    }

                Single ->
                    { english = "Single"
                    , kinyarwanda = Just "Ingaragu"
                    }

                Widowed ->
                    { english = "Widowed"
                    , kinyarwanda = Just "Umupfakazi"
                    }

        MeasurementNoChange ->
            { english = "No Change"
            , kinyarwanda = Just "nta cyahindutse"
            }

        MeasurementGained amount ->
            { english = "Gained " ++ Debug.toString amount
            , kinyarwanda = Just <| "Kwiyongera " ++ Debug.toString amount
            }

        MeasurementLost amount ->
            { english = "Lost " ++ Debug.toString amount
            , kinyarwanda = Just <| "Kwiyongera " ++ Debug.toString amount
            }

        MedicalDiagnosis ->
            { english = "Medical Diagnosis"
            , kinyarwanda = Just "Uburwayi bwemejwe na Muganga"
            }

        MedicalDiagnosisAlert diagnosis ->
            case diagnosis of
                DiagnosisUterineMyoma ->
                    { english = "Uterine Myoma"
                    , kinyarwanda = Just "Ibibyimba byo mu mura/Nyababyeyi"
                    }

                DiagnosisDiabetes ->
                    { english = "Diabetes"
                    , kinyarwanda = Just "Diyabete (Indwara y'igisukari)"
                    }

                DiagnosisCardiacDisease ->
                    { english = "Cardiac Disease"
                    , kinyarwanda = Just "Indwara z'umutima"
                    }

                DiagnosisRenalDisease ->
                    { english = "Renal Disease"
                    , kinyarwanda = Just "Indwara z'impyiko"
                    }

                DiagnosisHypertensionBeforePregnancy ->
                    { english = "Hypertension"
                    , kinyarwanda = Nothing
                    }

                DiagnosisTuberculosis ->
                    { english = "Tuberculosis"
                    , kinyarwanda = Nothing
                    }

                DiagnosisAsthma ->
                    { english = "Asthma"
                    , kinyarwanda = Just "Asthma (Agahema)"
                    }

                DiagnosisBowedLegs ->
                    { english = "Bowed Legs"
                    , kinyarwanda = Just "Amaguru atameze neza (yagize imitego)"
                    }

                DiagnosisHIV ->
                    { english = "HIV"
                    , kinyarwanda = Just "Virus itera SIDA"
                    }

                DiagnosisMentalHealthHistory ->
                    { english = "History of Mental Health Problems"
                    , kinyarwanda = Just "Niba yaragize uburwayi bwo mumutwe"
                    }

        MedicalFormHelper ->
            { english = "Please record if the mother was diagnosed with the following medical issues"
            , kinyarwanda = Just "Andika niba umubyeyi yaragaragaweho indwara zikurikira"
            }

        MentalHealthHistory ->
            { english = "History of Mental Health Problems"
            , kinyarwanda = Just "Niba yaragize uburwayi bwo mumutwe"
            }

        MMHGUnit ->
            { english = "mmHG"
            , kinyarwanda = Nothing
            }

        MiddleName ->
            { english = "Middle Name"
            , kinyarwanda = Nothing
            }

        MinutesAgo minutes ->
            { english =
                if minutes == 0 then
                    "just now"

                else if minutes == 1 then
                    "one minute ago"

                else
                    Debug.toString minutes ++ " minutes ago"
            , kinyarwanda =
                if minutes == 0 then
                    Just "Nonaha"

                else if minutes == 1 then
                    Just "Umunota umwe ushize"

                else
                    Just <| Debug.toString minutes ++ " hashize iminota micye"
            }

        ModeOfDelivery mode ->
            case mode of
                VaginalDelivery (Spontaneous True) ->
                    { english = "Spontaneous vaginal delivery with episiotomy"
                    , kinyarwanda = Just "Yabyaye neza ariko bamwongereye"
                    }

                VaginalDelivery (Spontaneous False) ->
                    { english = "Spontaneous vaginal delivery without episiotomy"
                    , kinyarwanda = Just "Yabyaye neza"
                    }

                VaginalDelivery WithVacuumExtraction ->
                    { english = "Vaginal delivery with vacuum extraction"
                    , kinyarwanda = Just "Yabyaye neza ariko hanifashishijwe icyuma gikurura umwana"
                    }

                CesareanDelivery ->
                    { english = "Cesarean delivery"
                    , kinyarwanda = Just "Yabyaye bamubaze"
                    }

        ModeOfDeliveryLabel ->
            { english = "Mode of delivery"
            , kinyarwanda = Just "Uburyo yabyayemo"
            }

        Month ->
            { english = "Month"
            , kinyarwanda = Just "Ukwezi"
            }

        MonthAbbrev ->
            { english = "mo"
            , kinyarwanda = Just "amezi"
            }

        MonthsOld ->
            { english = "months old"
            , kinyarwanda = Just "Amezi"
            }

        Mother ->
            { english = "Mother"
            , kinyarwanda = Just "Umubyeyi"
            }

        MotherDemographicInformation ->
            { english = "Mother Demographic Information"
            , kinyarwanda = Nothing
            }

        MotherName name ->
            { english = "Mother/Caregiver: " ++ name
            , kinyarwanda = Just <| "Umubyeyi: " ++ name
            }

        MotherNameLabel ->
            { english = "Mother's Name"
            , kinyarwanda = Nothing
            }

        MotherNationalId ->
            { english = "Mother's National ID"
            , kinyarwanda = Nothing
            }

        Mothers ->
            { english = "Mothers"
            , kinyarwanda = Just "Ababyeyi"
            }

        MUAC ->
            { english = "MUAC"
            , kinyarwanda = Just "Ikizigira"
            }

        MuacIndication indication ->
            case indication of
                MuacRed ->
                    { english = "red"
                    , kinyarwanda = Just "Umutuku"
                    }

                MuacYellow ->
                    { english = "yellow"
                    , kinyarwanda = Just "Umuhondo"
                    }

                MuacGreen ->
                    { english = "green"
                    , kinyarwanda = Just "Icyatsi"
                    }

        MyAccount ->
            { english = "My Account"
            , kinyarwanda = Just "Konti yanjye"
            }

        MyRelatedBy relationship ->
            translateMyRelatedBy relationship

        MyRelatedByQuestion relationship ->
            translateMyRelatedByQuestion relationship

        Name ->
            { english = "Name"
            , kinyarwanda = Nothing
            }

        NationalIdNumber ->
            { english = "National ID Number"
            , kinyarwanda = Just "Numero y'irangamuntu"
            }

        Neck ->
            { english = "Neck"
            , kinyarwanda = Nothing
            }

        NeckCPESign option ->
            case option of
                EnlargedThyroid ->
                    { english = "Enlarged Thyroid"
                    , kinyarwanda = Just "Umwingo"
                    }

                EnlargedLymphNodes ->
                    { english = "Enlarged Lymph Nodes"
                    , kinyarwanda = Just "Inturugunyu/Amatakara"
                    }

                NormalNeck ->
                    translationSet Normal

        Next ->
            { english = "Next"
            , kinyarwanda = Nothing
            }

        No ->
            { english = "No"
            , kinyarwanda = Just "Oya"
            }

        NoActivitiesCompleted ->
            { english = "No activities are entirely completed for the attending participants."
            , kinyarwanda = Just "Nta gikorwa cyarangiye cyose kubitabiriye."
            }

        NoActivitiesPending ->
            { english = "All activities are completed for the attending participants."
            , kinyarwanda = Just "Ibikorwa byose byarangiye kubitabiriye."
            }

        NoActivitiesCompletedForThisParticipant ->
            { english = "No activities are completed for this participant."
            , kinyarwanda = Just "Nta gikorwa cyarangiye kubitabiriye."
            }

        NoActivitiesPendingForThisParticipant ->
            { english = "All activities are completed for this participant."
            , kinyarwanda = Just "Ibikorwa byose byarangiye kubitabiriye."
            }

        NoGroupsFound ->
            { english = "No groups found."
            , kinyarwanda = Nothing
            }

        NoMatchesFound ->
            { english = "No matches found"
            , kinyarwanda = Nothing
            }

        NoParticipantsCompleted ->
            { english = "No participants have completed all their activities yet."
            , kinyarwanda = Just "Ntagikorwa nakimwe kirarangira kubitabiriye."
            }

        NoParticipantsPending ->
            { english = "All attending participants have completed their activities."
            , kinyarwanda = Just "Abaje bose barangirijwe"
            }

        NoParticipantsCompletedForThisActivity ->
            { english = "No participants have completed this activity yet."
            , kinyarwanda = Just "Ntawaje warangirijwe kukorerwa."
            }

        NoParticipantsPendingForThisActivity ->
            { english = "All attending participants have completed this activitity."
            , kinyarwanda = Just "Ababje bose barangirijwe."
            }

        Normal ->
            { english = "Normal"
            , kinyarwanda = Just "Bimeze neza/Nta kibazo gihari"
            }

        NoChildrenRegisteredInTheSystem ->
            { english = "No children registered in the system"
            , kinyarwanda = Just "Ntamwana wanditswe muriyi sisiteme"
            }

        NoParticipantsFound ->
            { english = "No participants found"
            , kinyarwanda = Just "Ntamuntu ugaragaye"
            }

        NotAvailable ->
            { english = "not available"
            , kinyarwanda = Just "Ntibiboneste"
            }

        NotConnected ->
            { english = "Not Connected"
            , kinyarwanda = Just "Ntamurandasi"
            }

        NumberOfAbortions ->
            { english = "Number of Abortions"
            , kinyarwanda = Just "Umubare w'inda zavuyemo"
            }

        NumberOfChildrenUnder5 ->
            { english = "Number of Children under 5"
            , kinyarwanda = Just "Umubare w'abana bari munsi y'imyaka 5"
            }

        NumberOfCSections ->
            { english = "Number of C-Sections"
            , kinyarwanda = Just "Umubare w'inshuro yabazwe"
            }

        NumberOfLiveChildren ->
            { english = "Number of Live Children"
            , kinyarwanda = Just "Umubare w'abana bariho"
            }

        NumberOfStillbirthsAtTerm ->
            { english = "Number of Stillbirths at Term"
            , kinyarwanda = Just "Umubare w'abapfiriye mu nda bashyitse"
            }

        NumberOfStillbirthsPreTerm ->
            { english = "Number of Stillbirths pre Term"
            , kinyarwanda = Just "Umubare w'abapfiriye mu nda badashyitse"
            }

        NutritionActivityHelper activity ->
            case activity of
                NutritionActivity.Model.Muac ->
                    { english = "Make sure to measure at the center of the baby’s upper arm."
                    , kinyarwanda = Just "Ibuka gupima icya kabiri cy'akaboko ko hejuru kugira bigufashe guoima ikizigira cy'akaboko"
                    }

                NutritionActivity.Model.Height ->
                    { english = "Ask the mother to hold the baby’s head at the end of the measuring board. Move the slider to the baby’s heel and pull their leg straight."
                    , kinyarwanda = Just "Saba Umubyeyi guhagarara inyuma y’umwana we agaramye, afata umutwe ku gice cy’amatwi. Sunikira akabaho ku buryo gakora mu bworo by’ibirenge byombi."
                    }

                NutritionActivity.Model.Nutrition ->
                    { english = "Explain to the mother how to check the malnutrition signs for their own child."
                    , kinyarwanda = Just "Sobanurira umubyeyi gupima ibimenyetso by'imirire mibi ku giti cye."
                    }

                NutritionActivity.Model.Photo ->
                    { english = "Take each baby’s photo at each health assessment. Photos should show the entire body of each child."
                    , kinyarwanda = Just "Fata ifoto ya buri mwana kuri buri bikorwa by'ipimwa Ifoto igomba kwerekana ibice by'umubiri wose by'umwana"
                    }

                NutritionActivity.Model.Weight ->
                    { english = "Calibrate the scale before taking the first baby's weight. Place baby in harness with no clothes on."
                    , kinyarwanda = Just "Ibuka kuregera umunzani mbere yo gupima ibiro by'umwana wa mbere. Ambika umwana ikariso y'ibiro wabanje kumukuramo imyenda iremereye"
                    }

        NutritionActivityTitle activity ->
            case activity of
                NutritionActivity.Model.Muac ->
                    { english = "MUAC"
                    , kinyarwanda = Just "Ikizigira cy'akaboko"
                    }

                NutritionActivity.Model.Height ->
                    { english = "Height"
                    , kinyarwanda = Just "Uburebure"
                    }

                NutritionActivity.Model.Nutrition ->
                    { english = "Nutrition"
                    , kinyarwanda = Just "Imirire"
                    }

                NutritionActivity.Model.Photo ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

                NutritionActivity.Model.Weight ->
                    { english = "Weight"
                    , kinyarwanda = Just "Ibiro"
                    }

        ObstetricalDiagnosis ->
            { english = "Obstetrical Diagnosis"
            , kinyarwanda = Just "Uburwayi bwemejwe n'inzobere mu gusuzuma abagore batwite"
            }

        ObstetricalDiagnosisAlert diagnosis ->
            case diagnosis of
                DiagnosisRhNegative ->
                    { english = "Patient is RH Negative"
                    , kinyarwanda = Nothing
                    }

                DiagnosisModerateUnderweight ->
                    { english = "Moderate underweight"
                    , kinyarwanda = Nothing
                    }

                DiagnosisSevereUnderweight ->
                    { english = "Severe underweight"
                    , kinyarwanda = Just "Afite ibiro bikie bikabije"
                    }

                DiagnosisOverweight ->
                    { english = "Overweight"
                    , kinyarwanda = Nothing
                    }

                DiagnosisObese ->
                    { english = "Obese"
                    , kinyarwanda = Just "Kubyibuha gukabije"
                    }

                DisgnosisPeripheralEdema ->
                    { english = "Peripheral Edema"
                    , kinyarwanda = Nothing
                    }

                DiagnosisFetusBreech ->
                    { english = "Fetus is in breech"
                    , kinyarwanda = Nothing
                    }

                DiagnosisFetusTransverse ->
                    { english = "Fetus is transverse"
                    , kinyarwanda = Nothing
                    }

                DiagnosisBreastExamination ->
                    { english = "Breast exam showed"
                    , kinyarwanda = Nothing
                    }

                DiagnosisHypotension ->
                    { english = "Hypotension"
                    , kinyarwanda = Nothing
                    }

                DiagnosisPregnancyInducedHypertension ->
                    { english = "Pregnancy-induced hypertension"
                    , kinyarwanda = Nothing
                    }

                DiagnosisPreeclampsiaHighRisk ->
                    { english = "High Risk for Preeclampsia"
                    , kinyarwanda = Nothing
                    }

        OK ->
            { english = "OK"
            , kinyarwanda = Just "Nibyo, yego"
            }

        Old ->
            { english = "old"
            , kinyarwanda = Just "imyaka"
            }

        OneVisit ->
            { english = "One visit"
            , kinyarwanda = Just "Inshuro imwe"
            }

        OnceYouEndYourGroupEncounter ->
            { english = "Once you end your Group Encounter, you will no longer be able to edit or add data."
            , kinyarwanda = Just "Igihe ushoze igikorwa, ntabwo ushobora guhindura cg wongeremo andi makuru."
            }

        Or ->
            { english = "or"
            , kinyarwanda = Nothing
            }

        Page ->
            { english = "Page"
            , kinyarwanda = Just "Paji"
            }

        Page404 ->
            { english = "404 page"
            , kinyarwanda = Just "404 paji"
            }

        PageNotFoundMsg ->
            { english = "Sorry, nothing found in this URL."
            , kinyarwanda = Just "Mutwihanganire ntabwo ubufasha mwasabye mubashije kuboneka."
            }

        Pallor ->
            { english = "Pallor"
            , kinyarwanda = Just "Kweruruka (k'urugingo rw'umubiri)"
            }

        Para ->
            { english = "Para"
            , kinyarwanda = Nothing
            }

        PaleConjuctiva ->
            { english = "Pale Conjuctiva"
            , kinyarwanda = Just "Ibihenehene byeruruka"
            }

        PartialPlacentaPreviousDelivery ->
            { english = "Partial Placenta in previous delivery"
            , kinyarwanda = Just "Ubwo aheruka kubyara iya nyuma ntiyavuyeyo  yose (yaje igice)"
            }

        ParticipantDirectory ->
            { english = "Participant Directory"
            , kinyarwanda = Just "Ububiko bw'amakuru y'umurwayi"
            }

        Participants ->
            { english = "Participants"
            , kinyarwanda = Just "Ubwitabire"
            }

        ParticipantReviewed ->
            { english = "I have reviewed and understand the above."
            , kinyarwanda = Nothing
            }

        ParticipantSignature ->
            { english = "Participant Signature"
            , kinyarwanda = Nothing
            }

        ParticipantSummary ->
            { english = "Participant Summary"
            , kinyarwanda = Just "Umwirondoro w’urera umwana"
            }

        ParticipantDemographicInformation ->
            { english = "Participant Demographic Information"
            , kinyarwanda = Just "Umwirondoro w'umugenerwabikorwa"
            }

        ParticipantInformation ->
            { english = "Participant Information"
            , kinyarwanda = Nothing
            }

        PartnerHivTestResult ->
            { english = "What was the partners HIV Test result"
            , kinyarwanda = Nothing
            }

        PartnerReceivedHivCounseling ->
            { english = "Did partner receive HIV Counseling during this pregnancy"
            , kinyarwanda = Just "Umugabo yahawe ubujyanama kuri Virusi itera SIDA? "
            }

        PartnerReceivedHivTesting ->
            { english = "Did partner receive HIV Testing during this pregnancy"
            , kinyarwanda = Just "Umugabo  yasuzumwe Virusi itera SIDA?"
            }

        PatientProgress ->
            { english = "Patient Progress"
            , kinyarwanda = Just "Uruhererekane rw'ibyakorewe umubyeyi"
            }

        PatientInformation ->
            { english = "Patient Information"
            , kinyarwanda = Just "Amakuru k'umurwayi"
            }

        PatientProvisionsTask task ->
            case task of
                Medication ->
                    { english = "Medication"
                    , kinyarwanda = Nothing
                    }

                Resources ->
                    { english = "Resources"
                    , kinyarwanda = Just "Ibihabwa umubyeyi utwite"
                    }

        People ->
            { english = "People"
            , kinyarwanda = Just "Abantu"
            }

        PersistentStorage authorized ->
            if authorized then
                { english = "Persistent storage has been authorized. The browser will not delete locally cached data without your approval."
                , kinyarwanda = Just "Ububiko buhoraho bwaremejwe,amakuru wabitse ntabwo yatsibama udatanze uburenganzira/utabyemeje"
                }

            else
                { english = "Persistent storage has not been authorized. The browser may delete locally cached data if storage runs low."
                , kinyarwanda = Just "Ibikwa ry'amakuru ntabwo remejwe. Sisiteme mushakisha ukoreramo ishobora kubisiba umwanya ubaye muto."
                }

        Person ->
            { english = "Person"
            , kinyarwanda = Just "Umuntu"
            }

        PersonHasBeenSaved ->
            { english = "Person has been saved"
            , kinyarwanda = Just "Amakuru kuri uyu muntu yabitswe"
            }

        PlaceholderEnterHeight ->
            { english = "Enter height here…"
            , kinyarwanda = Just "Andika uburebure hano…"
            }

        PlaceholderEnterMUAC ->
            { english = "Enter MUAC here…"
            , kinyarwanda = Just "Andika uburebure hano…"
            }

        PlaceholderEnterParticipantName ->
            { english = "Enter participant name here"
            , kinyarwanda = Just "Andika izina ry'umurwayi hano"
            }

        PlaceholderEnterWeight ->
            { english = "Enter weight here…"
            , kinyarwanda = Just "Andika ibiro hano…"
            }

        PleaseSelectGroup ->
            { english = "Please select the relevant Group for the new encounter"
            , kinyarwanda = Nothing
            }

        PleaseSync ->
            { english = "Please sync data for selected Health Center."
            , kinyarwanda = Nothing
            }

        PreeclampsiaPreviousPregnancy ->
            { english = "Preeclampsia in previous pregnancy "
            , kinyarwanda = Just "Ubushize yagize ibimenyetso bibanziriza guhinda umushyitsi"
            }

        PregnancyTrimester trimester ->
            case trimester of
                FirstTrimester ->
                    { english = "First Trimester"
                    , kinyarwanda = Just "Igihembwe cya mbere"
                    }

                SecondTrimester ->
                    { english = "Second Trimester"
                    , kinyarwanda = Just "Igihembwe cya kabiri"
                    }

                ThirdTrimester ->
                    { english = "Third Trimester"
                    , kinyarwanda = Just "Igihembwe cya gatatu"
                    }

        PrenatalActivitiesTitle activity ->
            case activity of
                DangerSigns ->
                    { english = "Danger Signs"
                    , kinyarwanda = Just "Ibimenyetso mpuruza"
                    }

                Examination ->
                    { english = "Examination"
                    , kinyarwanda = Just "Gusuzuma"
                    }

                PrenatalActivity.Model.FamilyPlanning ->
                    { english = "Family Planning"
                    , kinyarwanda = Just "Kuboneza Urubyaro"
                    }

                History ->
                    { english = "History"
                    , kinyarwanda = Just "Amateka y'ibyamubayeho"
                    }

                PatientProvisions ->
                    { english = "Patient Provisions"
                    , kinyarwanda = Just "Ibyo umubyeyi/umurwayi yahawe"
                    }

                PregnancyDating ->
                    { english = "Pregnancy Dating"
                    , kinyarwanda = Just "Igihe inda imaze"
                    }

                PrenatalPhoto ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

        PrenatalPhotoHelper ->
            { english = "Take a picture of the mother's belly. Then you and the mother will see how the belly has grown!"
            , kinyarwanda = Just "Fata ifoto y'inda y'umubyeyi hanyuma uyimwereke arebe uko yakuze/yiyongereye."
            }

        PreTerm ->
            { english = "Pre Term"
            , kinyarwanda = Just "Inda itaragera igihe"
            }

        PregnancyConcludedLabel ->
            { english = "or Pregnancy Concluded"
            , kinyarwanda = Just "Cyangwa Iherezo ry'inda"
            }

        PregnancyOutcomeLabel ->
            { english = "Pregnancy Outcome"
            , kinyarwanda = Nothing
            }

        PregnancyOutcome outcome ->
            case outcome of
                OutcomeLiveAtTerm ->
                    { english = "Live Birth at Term (38 weeks EGA or more)"
                    , kinyarwanda = Just "Kubyara umwana muzima/Ushyitse (ku byumweru 38 kuzamura)"
                    }

                OutcomeLivePreTerm ->
                    { english = "Live Birth Preterm (less than 38 weeks EGA)"
                    , kinyarwanda = Just "Kubyara mwana udashyitse (munsi y'ibyumweru 38)"
                    }

                OutcomeStillAtTerm ->
                    { english = "Stillbirth at Term (38 weeks EGA or more)"
                    , kinyarwanda = Just "Abana bapfiriye mu nda bageze igihe cyo kuvuka (ku byumweru 38 kuzamura)"
                    }

                OutcomeStillPreTerm ->
                    { english = "Stillbirth Preterm (less than 38 weeks EGA)"
                    , kinyarwanda = Just "Abana bapfiriye mu nda batagejeje igihe cyo kuvuka (munsi y'ibyumweru 38)"
                    }

                OutcomeAbortions ->
                    { english = "Abortions (before 24 weeks EGA)"
                    , kinyarwanda = Just "Kuvanamo inda (mbere y'ibyumweru 24)"
                    }

        PreviousCSectionScar ->
            { english = "Previous C-section scar"
            , kinyarwanda = Just "Inkovu yaho bababze ubushize"
            }

        PreviousDelivery ->
            { english = "Previous Delivery"
            , kinyarwanda = Just "Kubyara guheruka"
            }

        PreviousDeliveryPeriods period ->
            case period of
                LessThan18Month ->
                    { english = "Less than 18 month ago"
                    , kinyarwanda = Just "Munsi y'amezi 18 ashize"
                    }

                MoreThan5Years ->
                    { english = "More than 5 years ago"
                    , kinyarwanda = Just "Hejuru y'imyaka itanu ishize"
                    }

                Neither ->
                    { english = "Neither"
                    , kinyarwanda = Just "Nta na kimwe"
                    }

        PreviousFloatMeasurement value ->
            { english = "Previous measurement: " ++ Debug.toString value
            , kinyarwanda = Just <| "Ibipimo by'ubushize: " ++ Debug.toString value
            }

        PreviousMeasurementNotFound ->
            { english = "No previous measurement on record"
            , kinyarwanda = Just "Nta gipimo cy'ubushize cyanditswe"
            }

        Profession ->
            { english = "Profession"
            , kinyarwanda = Nothing
            }

        Programs ->
            { english = "Programs"
            , kinyarwanda = Just "Porogaramu"
            }

        ProgressPhotos ->
            { english = "Progress Photos"
            , kinyarwanda = Just "Uko amafoto agenda ahinduka"
            }

        ProgressReport ->
            { english = "Progress Report"
            , kinyarwanda = Just "Raporo igaragaza imikurire y'umwana"
            }

        ProgressTimeline ->
            { english = "Progress Timeline"
            , kinyarwanda = Just "Uko inda igenda ikura"
            }

        ProgressTrends ->
            { english = "Progress Trends"
            , kinyarwanda = Just "Uko ibipimo bigenda bizamuka"
            }

        PrenatalParticipant ->
            { english = "Antenatal Participant"
            , kinyarwanda = Just "Umubyeyi witabiriye kwipimisha inda"
            }

        PrenatalParticipants ->
            { english = "Antenatal Participants"
            , kinyarwanda = Just "Ababyeyi bitabiriye kwipimisha inda"
            }

        PreTermPregnancy ->
            { english = "Number of Pre-term Pregnancies (Live Birth)"
            , kinyarwanda = Just "Umubare w'abavutse ari bazima badashyitse"
            }

        Province ->
            { english = "Province"
            , kinyarwanda = Just "Intara"
            }

        ReasonForCSection ->
            { english = "Reason for C-section"
            , kinyarwanda = Nothing
            }

        ReceivedDewormingPill ->
            { english = "Has the mother received deworming pill"
            , kinyarwanda = Nothing
            }

        ReceivedIronFolicAcid ->
            { english = "Has the mother received iron and folic acid supplement"
            , kinyarwanda = Just "Umubyeyi yahawe ibinini bya Fer cg Folic Acid byongera amaraso?"
            }

        ReceivedMosquitoNet ->
            { english = "Has the mother received a mosquito net"
            , kinyarwanda = Just "Umubyeyi yahawe inzitiramubu?"
            }

        RecordPregnancyOutcome ->
            { english = "Record Pregnancy Outcome"
            , kinyarwanda = Just "Andika iherezo ry'inda"
            }

        RecurringHighSeverityAlert alert ->
            case alert of
                PrenatalActivity.Model.BloodPressure ->
                    { english = "Blood Pressure"
                    , kinyarwanda = Just "Umuvuduko w'amaraso"
                    }

        Register ->
            { english = "Register"
            , kinyarwanda = Nothing
            }

        RegisterHelper ->
            { english = "Not the participant you were looking for?"
            , kinyarwanda = Just "Umugenerwabikorwa ubonye si we washakaga?"
            }

        RegisterNewParticipant ->
            { english = "Register a new participant"
            , kinyarwanda = Just "Andika umurwayi mushya"
            }

        RegistratingHealthCenter ->
            { english = "Registrating Health Center"
            , kinyarwanda = Just "Izina ry'ikigo nderabuzima umugenerwabikorwa abarizwamo"
            }

        RegistrationSuccessful ->
            { english = "Registration Successful"
            , kinyarwanda = Nothing
            }

        RegistrationSuccessfulParticipantAdded ->
            { english = "The participant has been added to E-Heza."
            , kinyarwanda = Nothing
            }

        RegistrationSuccessfulSuggestAddingChild ->
            { english = "The participant has been added to E-Heza. Would you like to add a child for this participant?"
            , kinyarwanda = Nothing
            }

        RegistrationSuccessfulSuggestAddingMother ->
            { english = "The participant has been added to E-Heza. Would you like to add a mother for this participant?"
            , kinyarwanda = Nothing
            }

        RelationSuccessful ->
            { english = "Relation Successful"
            , kinyarwanda = Nothing
            }

        RelationSuccessfulChildWithMother ->
            { english = "Child succesfully assocoated with mother."
            , kinyarwanda = Nothing
            }

        RelationSuccessfulMotherWithChild ->
            { english = "Mother succesfully assocoated with child."
            , kinyarwanda = Nothing
            }

        RenalDisease ->
            { english = "Renal Disease"
            , kinyarwanda = Just "Indwara z'impyiko"
            }

        RemainingForDownloadLabel ->
            { english = "Remaining for Download"
            , kinyarwanda = Just "Ibisigaye gukurwa kuri seriveri"
            }

        RemainingForUploadLabel ->
            { english = "Remaining for Upload"
            , kinyarwanda = Just "Ibisigaye koherezwa kuri seriveri"
            }

        ReportAge age ->
            { english = "Age: " ++ age
            , kinyarwanda = Just <| "Imyaka: " ++ age
            }

        ReportDOB dob ->
            { english = "DOB: " ++ dob
            , kinyarwanda = Just <| "Itariki y'amavuko: " ++ dob
            }

        ReportRemaining remaining ->
            { english = Debug.toString remaining ++ " remaning"
            , kinyarwanda = Just <| Debug.toString remaining ++ " iyibutswa rya raporo"
            }

        ReportResultsOfSearch total ->
            case total of
                1 ->
                    { english = "There is 1 participant that matches your search."
                    , kinyarwanda = Just "Hari umujyenerwabikorwa 1 uhuye nuwo washatse"
                    }

                _ ->
                    { english = "There are " ++ Debug.toString total ++ " participants that match your search."
                    , kinyarwanda = Just <| "Hari abagenerwabikorwa " ++ Debug.toString total ++ " bahuye nuwo ushaka mu ishakiro"
                    }

        Reports ->
            { english = "Reports"
            , kinyarwanda = Just "Raporo"
            }

        RecentAndUpcomingGroupEncounters ->
            { english = "Recent and upcoming Group Encounters"
            , kinyarwanda = Just "Ahabarizwa amatsinda aheruka gukorerwa n'agiye gukorerwa"
            }

        ReportCompleted { pending, completed } ->
            { english = Debug.toString completed ++ " / " ++ Debug.toString (pending + completed) ++ " Completed"
            , kinyarwanda = Just <| Debug.toString completed ++ " / " ++ Debug.toString (pending + completed) ++ " Raporo irarangiye"
            }

        ResolveMonth month ->
            translateMonth month

        RespiratoryRate ->
            { english = "Respiratory Rate"
            , kinyarwanda = Just "Inshuro ahumeka"
            }

        Retry ->
            { english = "Retry"
            , kinyarwanda = Just "Kongera kugerageza"
            }

        RhNegative ->
            { english = "RH Negative"
            , kinyarwanda = Just "Ubwoko bw'amaraso ni Negatifu"
            }

        RiskFactorAlert factor ->
            case factor of
                FactorNumberOfCSections number ->
                    if number == 1 then
                        { english = "1 previous C-section"
                        , kinyarwanda = Just "Yabazwe inshuro imwe ubushize"
                        }

                    else
                        { english = Debug.toString number ++ " previous C-sections"
                        , kinyarwanda = Just <| Debug.toString number ++ " ubushize yarabazwe"
                        }

                FactorCSectionInPreviousDelivery ->
                    { english = "C-section in previous delivery"
                    , kinyarwanda = Just "Yarabazwe ku nda ishize"
                    }

                FactorCSectionReason ->
                    { english = "C-section in previous delivery due to"
                    , kinyarwanda = Just "Ubushize yabazwe abyara kubera"
                    }

                FactorPreviousDeliveryPeriod ->
                    { english = "Previous delivery"
                    , kinyarwanda = Just "kubyara guheruka"
                    }

                FactorSuccessiveAbortions ->
                    { english = "Patient experienced successive abortions"
                    , kinyarwanda = Just "Umubyeyi yavanyemo inda zikurikiranye"
                    }

                FactorSuccessivePrematureDeliveries ->
                    { english = "Patient experienced successive preterm deliveries"
                    , kinyarwanda = Just "Umubyeyi yabyaye inda zidashyitse zikurikiranye"
                    }

                FactorStillbornPreviousDelivery ->
                    { english = "Stillbirth in previous delivery"
                    , kinyarwanda = Just "Ubushize yabyaye umwana upfuye(wapfiriye mu nda)"
                    }

                FactorBabyDiedOnDayOfBirthPreviousDelivery ->
                    { english = "Live Birth but the baby died the same day in previous delivery"
                    , kinyarwanda = Just "Aheruka kubyara umwana muzima apfa uwo munsi"
                    }

                FactorPartialPlacentaPreviousDelivery ->
                    { english = "Patient had partial placenta in previous pregnancy"
                    , kinyarwanda = Just "Ku nda y'ubushize iya nyuma ntiyavutse yose/yaje igice"
                    }

                FactorSevereHemorrhagingPreviousDelivery ->
                    { english = "Patient experienced severe hemorrhage in previous pregnancy"
                    , kinyarwanda = Just "Umubyeyi yaravuye cyane/bikabije ku nda y'ubushize"
                    }

                FactorPreeclampsiaPreviousPregnancy ->
                    { english = "Patient had preeclampsia in previous pregnancy"
                    , kinyarwanda = Just "Umubyeyi yagize ibimenyetso bibanziriza kugagara ku nda y'ubushize"
                    }

                FactorConvulsionsPreviousDelivery ->
                    { english = "Patient experienced convulsions in previous delivery"
                    , kinyarwanda = Just "Ubushize mubyeyi yagize ibimenyetso byo kugagara/Guhinda umushyitsi abyara"
                    }

                FactorConvulsionsAndUnconsciousPreviousDelivery ->
                    { english = "Patient experienced convulsions and resulted in becoming unconscious after delivery"
                    , kinyarwanda = Just "Umubyeyi yagize ibimenyetso byo kugagara nyuma yo kubyara bimuviramo kutumva/guta ubwenge"
                    }

                FactorIncompleteCervixPreviousPregnancy ->
                    { english = "Patient had an Incomplete Cervix in previous pregnancy"
                    , kinyarwanda = Just "Ku nda y'ubushize inkondo y'umura ntiyashoboye kwifunga neza"
                    }

                FactorVerticalCSectionScar ->
                    { english = "Vertical C-Section Scar"
                    , kinyarwanda = Just "Inkovu yo kubagwa irahagaze"
                    }

                FactorGestationalDiabetesPreviousPregnancy ->
                    { english = "Patient had Gestational Diabetes in previous pregnancy"
                    , kinyarwanda = Just "Ubushize umubyeyi yagize indwara ya Diyabete itewe no gutwita"
                    }

        RiskFactors ->
            { english = "Risk Factors"
            , kinyarwanda = Just "Abashobora kwibasirwa n'indwara runaka (kubera impamvu zitandukanye:kuba atwite..)"
            }

        Save ->
            { english = "Save"
            , kinyarwanda = Just "Kubika"
            }

        SaveAndNext ->
            { english = "Save & Next"
            , kinyarwanda = Nothing
            }

        SaveError ->
            { english = "Save Error"
            , kinyarwanda = Just "Kubika error (ikosa mu kubika)"
            }

        Search ->
            { english = "Search"
            , kinyarwanda = Nothing
            }

        SearchByName ->
            { english = "Search by Name"
            , kinyarwanda = Just "Gushakisha izina"
            }

        SearchExistingParticipants ->
            { english = "Search Existing Participants"
            , kinyarwanda = Just "Gushaka abagenerwabikorwa basanzwe muri sisiteme"
            }

        SearchHelper ->
            { english = "Search to see if the participant already exists in E-Heza. If the person you are looking for does not appear in the search, please create a new record for them."
            , kinyarwanda = Just "Shakisha kugirango urebe niba umugenerwabikorwa asanzwe ari muri E-Heza. Niba atagaragara, mwandike nku mushya."
            }

        SearchHelperFamilyMember ->
            { english = "Search to see if the additional family member already exists in E-Heza. If the person you are looking for does not appear in the search, please create a new record for them."
            , kinyarwanda = Just "Kanda ku Ishakiro kugirango urebe niba umugenerwabikorwa asanzwe ari muri E-Heza. Niba uwo muntu atagaragara mu ishakiro, mwandike nk'umugenerwabikorwa mushya."
            }

        SecondName ->
            { english = "Second Name"
            , kinyarwanda = Just "Izina ry'umuryango"
            }

        Sector ->
            { english = "Sector"
            , kinyarwanda = Just "Umurenge"
            }

        SelectAntenatalVisit ->
            { english = "Select an Antenatal Visit"
            , kinyarwanda = Just "Hitamo inshuro aje kwipimishaho inda"
            }

        SelectAllSigns ->
            { english = "Select all signs that are present"
            , kinyarwanda = Just "Hitamo ibimenyetso by'imirire byose bishoboka umwana afite"
            }

        SelectDangerSigns ->
            { english = "Please select one or more of the danger signs the patient is experiencing"
            , kinyarwanda = Just "Hitamo kimwe cg byinshi mu bimenyetso mpuruza umubyeyi yaba afite"
            }

        SelectEncounterType ->
            { english = "Select encounter type"
            , kinyarwanda = Just "Hitamo ubwoko bw'icyiciro cyo gukorera"
            }

        SelectLanguage ->
            { english = "Select language"
            , kinyarwanda = Nothing
            }

        SelectGroup ->
            { english = "Select Group..."
            , kinyarwanda = Just "Hitamo itsinda ryawe..."
            }

        SelectProgram ->
            { english = "Select Program"
            , kinyarwanda = Just "Hitamo porogaramu"
            }

        SelectYourGroup ->
            { english = "Select your Group"
            , kinyarwanda = Just "Hitamo itsinda ryawe"
            }

        SelectYourHealthCenter ->
            { english = "Select your Health Center"
            , kinyarwanda = Just "Hitamo ikigo nderabuzima"
            }

        SelectYourVillage ->
            { english = "Select your village"
            , kinyarwanda = Just "Hitamo umudugudu wawe"
            }

        SelectedHCDownloading ->
            { english = "Downloading data for selected Health Center. Please wait until completed."
            , kinyarwanda = Nothing
            }

        SelectedHCNotSynced ->
            { english = "Data is not synced"
            , kinyarwanda = Nothing
            }

        SelectedHCSyncing ->
            { english = "Data is syncing"
            , kinyarwanda = Nothing
            }

        SelectedHCUploading ->
            { english = "Uploading data for selected Health Center. Please wait until completed."
            , kinyarwanda = Nothing
            }

        ServiceWorkerActive ->
            { english = "The app is installed on this device."
            , kinyarwanda = Just "Apulikasiyo muri icyi cyuma cy'inkoranabuhanga yinjijwe."
            }

        ServiceWorkerCurrent ->
            { english = "You have the current version of the app."
            , kinyarwanda = Just "Ufite apulikasiyo nshya igezweho uyu munsi"
            }

        ServiceWorkerCheckForUpdates ->
            { english = "Check for updates"
            , kinyarwanda = Just "Kugenzura ibyavuguruwe"
            }

        ServiceWorkerInstalling ->
            { english = "A new version of the app has been detected and is being downloaded. You can continue to work while this is in progress."
            , kinyarwanda = Nothing
            }

        ServiceWorkerInstalled ->
            { english = "A new version of the app has been downloaded."
            , kinyarwanda = Just "Gufungura verisio nshyashya byarangiye."
            }

        ServiceWorkerSkipWaiting ->
            { english = "Activate new version of the app"
            , kinyarwanda = Just "Gufungura verisio nshyashya"
            }

        ServiceWorkerRestarting ->
            { english = "The app should reload momentarily with the new version."
            , kinyarwanda = Nothing
            }

        ServiceWorkerActivating ->
            { english = "A new version of the app is preparing itself for use."
            , kinyarwanda = Nothing
            }

        ServiceWorkerActivated ->
            { english = "A new version of the app is ready for use."
            , kinyarwanda = Nothing
            }

        ServiceWorkerRedundant ->
            { english = "An error occurred installing a new version of the app."
            , kinyarwanda = Nothing
            }

        ServiceWorkerInactive ->
            { english = "The app is not yet installed on this device."
            , kinyarwanda = Nothing
            }

        ServiceWorkerRegNotAsked ->
            { english = "We have not yet attempted to install the app on this device."
            , kinyarwanda = Nothing
            }

        ServiceWorkerRegLoading ->
            { english = "Installation of the app on this device is progressing."
            , kinyarwanda = Nothing
            }

        ServiceWorkerRegErr ->
            { english = "There was an error installing the app on this device. To try again, reload this page."
            , kinyarwanda = Nothing
            }

        ServiceWorkerRegSuccess ->
            { english = "The app was successfully registered with this device."
            , kinyarwanda = Just "Igikorwa cyo gushyira apulikasiyo kuri iki gikoresho cy'ikoranabuhanga cyagenze neza."
            }

        ServiceWorkerStatus ->
            { english = "Deployment Status"
            , kinyarwanda = Just "Ibijyanye no kuvugurura no kongerera ubushobozi sisiteme"
            }

        SevereHemorrhagingPreviousDelivery ->
            { english = "Severe Hemorrhaging in previous delivery (>500 ml)"
            , kinyarwanda = Just "Ubushize yavuye cyane akimara kubyara hejuru ya Ml 500"
            }

        SocialHistoryHivTestingResult result ->
            case result of
                ResultHivPositive ->
                    { english = "Positive"
                    , kinyarwanda = Nothing
                    }

                ResultHivNegative ->
                    { english = "Negative"
                    , kinyarwanda = Nothing
                    }

                ResultHivIndeterminate ->
                    { english = "Indeterminate"
                    , kinyarwanda = Nothing
                    }

                NoHivTesting ->
                    { english = "Ntibiboneste"
                    , kinyarwanda = Nothing
                    }

        StillbornPreviousDelivery ->
            { english = "Stillborn in previous delivery"
            , kinyarwanda = Just "Aheruka kubyara umwana upfuye"
            }

        SubsequentAntenatalVisit ->
            { english = "Subsequent Antenatal Visit"
            , kinyarwanda = Just "Igihe cyo kongera kwipimisha inda"
            }

        SuccessiveAbortions ->
            { english = "Successive Abortions"
            , kinyarwanda = Just "Inda zavuyemo zikurikiranye"
            }

        SuccessivePrematureDeliveries ->
            { english = "Successive Premature Deliveries"
            , kinyarwanda = Just "Inda zavutse zidashyitse zikurikiranye"
            }

        GroupEncounterClosed ->
            { english = "Group Encounter closed"
            , kinyarwanda = Nothing
            }

        GroupEncounterClosed2 sessionId ->
            { english =
                String.join " "
                    [ "Group Encounter"
                    , fromEntityUuid sessionId
                    , """is closed. If you need to make further modifications
            to it, please contact an administrator to have it
            re-opened."""
                    ]
            , kinyarwanda = Nothing
            }

        GroupEncounterLoading ->
            { english = "Loading Group Encounter"
            , kinyarwanda = Just "Gufungura icyiciro cyo gukorera"
            }

        GroupEncounterUnauthorized ->
            { english = "Group Encounter unauthorized"
            , kinyarwanda = Nothing
            }

        GroupEncounterUnauthorized2 ->
            { english =
                """You are not authorized to view this health assessment.
        Please contact the Ihangane project for further
        instructions."""
            , kinyarwanda = Nothing
            }

        ShowAll ->
            { english = "Show All"
            , kinyarwanda = Just "Erekana amazina yose"
            }

        StartEndDate ->
            { english = "Start - End"
            , kinyarwanda = Nothing
            }

        StartDate ->
            { english = "Start Date"
            , kinyarwanda = Just "Itariki utangireyeho"
            }

        EndDate ->
            { english = "End Date"
            , kinyarwanda = Just "Itariki urangirijeho"
            }

        StartSyncing ->
            { english = "Start Syncing"
            , kinyarwanda = Just "Tangira uhuze amakuru kuri seriveri"
            }

        StatusLabel ->
            { english = "Status"
            , kinyarwanda = Just "Uko bihagaze kugeza ubu"
            }

        StopSyncing ->
            { english = "Stop Syncing"
            , kinyarwanda = Just "Tangira gukura amakuru kuri seriveri"
            }

        Submit ->
            { english = "Submit"
            , kinyarwanda = Nothing
            }

        Success ->
            { english = "Success"
            , kinyarwanda = Just "Byagezweho"
            }

        SyncGeneral ->
            { english = "Sync Status (General)"
            , kinyarwanda = Just "Ibijyanye no guhuza amakuru yafashwe n'igikoresho cy'ikoranabuhanga n'abitse kuri seriveri"
            }

        TakenCareOfBy ->
            { english = "Taken care of by"
            , kinyarwanda = Nothing
            }

        TasksCompleted completed total ->
            { english = Debug.toString completed ++ "/" ++ Debug.toString total ++ " Tasks Completed"
            , kinyarwanda = Just <| Debug.toString completed ++ "/" ++ Debug.toString total ++ " Ibikorwa byarangiye"
            }

        TelephoneNumber ->
            { english = "Telephone Number"
            , kinyarwanda = Just "Numero ya telefoni"
            }

        Term ->
            { english = "Term"
            , kinyarwanda = Just "Inda igeze igihe"
            }

        TermPregnancy ->
            { english = "Number of Term Pregnancies (Live Birth)"
            , kinyarwanda = Just "Umubare w'abavutse ari bazima bashyitse"
            }

        ThisActionCannotBeUndone ->
            { english = "This action cannot be undone."
            , kinyarwanda = Nothing
            }

        ThisGroupHasNoMothers ->
            { english = "This Group has no mothers assigned to it."
            , kinyarwanda = Just "Iki cyiciro nta mubyeyi cyagenewe."
            }

        Training ->
            { english = "Training"
            , kinyarwanda = Nothing
            }

        TrainingGroupEncounterCreateSuccessMessage ->
            { english = "Training encounters were created."
            , kinyarwanda = Nothing
            }

        TrainingGroupEncounterDeleteSuccessMessage ->
            { english = "Training encounters were deleted."
            , kinyarwanda = Nothing
            }

        TrySyncing ->
            { english = "Try syncing with backend"
            , kinyarwanda = Just "Gerageza guhuza amakuru y'iki gikoresho cy'ikoranabuhanga n'abakoze E-Heza"
            }

        TuberculosisPast ->
            { english = "Tuberculosis in the past"
            , kinyarwanda = Just "Yigeze kurwara igituntu"
            }

        TuberculosisPresent ->
            { english = "Tuberculosis in the present"
            , kinyarwanda = Just "Arwaye igituntu"
            }

        TwoVisits ->
            { english = "Two visits"
            , kinyarwanda = Just "Inshuro ebyiri"
            }

        UbudeheLabel ->
            { english = "Ubudehe: "
            , kinyarwanda = Nothing
            }

        Unknown ->
            { english = "Unknown"
            , kinyarwanda = Just "Ntabizi"
            }

        Update ->
            { english = "Update"
            , kinyarwanda = Just "Kuvugurura"
            }

        UpdateError ->
            { english = "Update Error"
            , kinyarwanda = Just "ikosa mwivugurura"
            }

        UterineMyoma ->
            { english = "Uterine Myoma"
            , kinyarwanda = Just "Ibibyimba byo mu mura/Nyababyeyi"
            }

        ValidationErrors ->
            { english = "Validation Errors"
            , kinyarwanda = Nothing
            }

        -- As in, the version the app
        Version ->
            { english = "Version"
            , kinyarwanda = Nothing
            }

        View ->
            { english = "View"
            , kinyarwanda = Nothing
            }

        ViewProgressReport ->
            { english = "View Progress Report"
            , kinyarwanda = Just "Garagaza uruhererekane rw'imikurire y'umwana"
            }

        Village ->
            { english = "Village"
            , kinyarwanda = Just "Umudugudu"
            }

        WeekSinglePlural value ->
            if value == 1 then
                { english = "1 Week"
                , kinyarwanda = Just "1 Icyumweru"
                }

            else
                { english = Debug.toString value ++ " Weeks"
                , kinyarwanda = Just <| Debug.toString value ++ " Ibyumweru"
                }

        Weight ->
            { english = "Weight"
            , kinyarwanda = Just "Ibiro"
            }

        WelcomeUser name ->
            { english = "Welcome " ++ name
            , kinyarwanda = Just <| "Murakaza neza " ++ name
            }

        WhatDoYouWantToDo ->
            { english = "What do you want to do?"
            , kinyarwanda = Just "Urashaka gukora iki?"
            }

        Year ->
            { english = "Year"
            , kinyarwanda = Just "Umwaka"
            }

        YearsOld int ->
            { english = Debug.toString int ++ " years old"
            , kinyarwanda = Nothing
            }

        Yes ->
            { english = "Yes"
            , kinyarwanda = Just "Yego"
            }

        YouAreNotAnAdmin ->
            { english = "You are not logged in as an Administrator."
            , kinyarwanda = Nothing
            }

        YourGroupEncounterHasBeenSaved ->
            { english = "Your Group Encounter has been saved."
            , kinyarwanda = Nothing
            }

        ZScoreHeightForAge ->
            { english = "Z-Score Height for Age: "
            , kinyarwanda = Just "Z-score Uburebure ku myaka: "
            }

        ZScoreMuacForAge ->
            { english = "MUAC for Age: "
            , kinyarwanda = Just "MUAC ku myaka: "
            }

        ZScoreWeightForAge ->
            { english = "Z-Score Weight for Age: "
            , kinyarwanda = Just "Z-score Ibiro ku myaka: "
            }

        ZScoreWeightForHeight ->
            { english = "Z-Score Weight for Height: "
            , kinyarwanda = Just "Z-score Ibiro ku uburebure: "
            }


translateMyRelatedBy : MyRelatedBy -> TranslationSet String
translateMyRelatedBy relationship =
    case relationship of
        MyChild ->
            { english = "Child"
            , kinyarwanda = Just "Umwana"
            }

        MyParent ->
            { english = "Parent"
            , kinyarwanda = Nothing
            }

        MyCaregiven ->
            { english = "Care given"
            , kinyarwanda = Nothing
            }

        MyCaregiver ->
            { english = "Caregiver"
            , kinyarwanda = Nothing
            }


{-| Basically, this is backwards. Our data is showing what the second
person is from the first person's point of view, but we want to
ask the question the opposite way.
-}
translateMyRelatedByQuestion : MyRelatedBy -> TranslationSet String
translateMyRelatedByQuestion relationship =
    case relationship of
        MyChild ->
            { english = "is the parent of"
            , kinyarwanda = Just "ni umubyeyi wa"
            }

        MyParent ->
            { english = "is the child of"
            , kinyarwanda = Nothing
            }

        MyCaregiven ->
            { english = "is the caregiver for"
            , kinyarwanda = Just "ni umurezi wa"
            }

        MyCaregiver ->
            { english = "is given care by"
            , kinyarwanda = Nothing
            }


translateActivePage : Page -> TranslationSet String
translateActivePage page =
    case page of
        DevicePage ->
            { english = "Device Status"
            , kinyarwanda = Just "Uko igikoresho cy'ikoranabuhanga gihagaze"
            }

        PinCodePage ->
            { english = "PIN Code"
            , kinyarwanda = Just "Umubare w'ibanga"
            }

        PageNotFound url ->
            { english = "Missing"
            , kinyarwanda = Just "Ibibura"
            }

        ServiceWorkerPage ->
            { english = "Deployment"
            , kinyarwanda = Nothing
            }

        UserPage userPage ->
            case userPage of
                ClinicalPage ->
                    { english = "Clinical"
                    , kinyarwanda = Nothing
                    }

                ClinicsPage _ ->
                    { english = "Groups"
                    , kinyarwanda = Just "Itsinda"
                    }

                ClinicalProgressReportPage _ ->
                    { english = "Clinical Progress Report"
                    , kinyarwanda = Just "Erekana raporo yibyavuye mu isuzuma"
                    }

                CreatePersonPage _ _ ->
                    { english = "Create Person"
                    , kinyarwanda = Nothing
                    }

                DemographicsReportPage _ ->
                    { english = "Demographics Report"
                    , kinyarwanda = Just "Raporo y'umwirondoro"
                    }

                EditPersonPage _ ->
                    { english = "Edit Person"
                    , kinyarwanda = Nothing
                    }

                MyAccountPage ->
                    { english = "My Account"
                    , kinyarwanda = Just "Compte"
                    }

                PersonPage id ->
                    { english = "Person"
                    , kinyarwanda = Nothing
                    }

                PersonsPage _ ->
                    { english = "Participant Directory"
                    , kinyarwanda = Just "Ububiko bw'amakuru y'umurwayi"
                    }

                PrenatalParticipantPage _ ->
                    { english = "Antenatal Participant"
                    , kinyarwanda = Nothing
                    }

                IndividualEncounterParticipantsPage encounterType ->
                    case encounterType of
                        AntenatalEncounter ->
                            { english = "Antenatal Participants"
                            , kinyarwanda = Nothing
                            }

                        InmmunizationEncounter ->
                            { english = "Inmmunization Participants"
                            , kinyarwanda = Nothing
                            }

                        NutritionEncounter ->
                            { english = "Nutrition Participants"
                            , kinyarwanda = Nothing
                            }

                RelationshipPage _ _ ->
                    { english = "Relationship"
                    , kinyarwanda = Nothing
                    }

                SessionPage sessionId sessionPage ->
                    case sessionPage of
                        ActivitiesPage ->
                            { english = "Activities"
                            , kinyarwanda = Just "Ibikorwa"
                            }

                        ActivityPage activityType ->
                            { english = "Activity"
                            , kinyarwanda = Just "Igikorwa"
                            }

                        AttendancePage ->
                            { english = "Attendance"
                            , kinyarwanda = Just "Ubwitabire"
                            }

                        ParticipantsPage ->
                            { english = "Participants"
                            , kinyarwanda = Just "Abagenerwabikorwa"
                            }

                        ChildPage childId ->
                            { english = "Child"
                            , kinyarwanda = Just "Umwana"
                            }

                        MotherPage motherId ->
                            { english = "Mother"
                            , kinyarwanda = Just "Umubyeyi"
                            }

                        ProgressReportPage childId ->
                            { english = "Progress Report"
                            , kinyarwanda = Just "Raporo igaragaza imikurire y'umwana"
                            }

                PrenatalEncounterPage _ ->
                    { english = "Antenatal Encounter"
                    , kinyarwanda = Nothing
                    }

                PrenatalActivityPage _ _ ->
                    { english = "Antenatal Activity"
                    , kinyarwanda = Nothing
                    }

                IndividualEncounterTypesPage ->
                    { english = "Encounter Types"
                    , kinyarwanda = Nothing
                    }

                PregnancyOutcomePage _ ->
                    { english = "Pregnancy Outcome"
                    , kinyarwanda = Nothing
                    }

                NutritionParticipantPage _ ->
                    { english = "Nutrition Encounter"
                    , kinyarwanda = Nothing
                    }

                NutritionEncounterPage _ ->
                    { english = "Nutrition Encounter"
                    , kinyarwanda = Nothing
                    }

                NutritionActivityPage _ _ ->
                    { english = "Nutrition Activity"
                    , kinyarwanda = Nothing
                    }

                NutritionProgressReportPage _ ->
                    { english = "Nutrition Progress Report"
                    , kinyarwanda = Nothing
                    }


translateAdherence : Adherence -> TranslationSet String
translateAdherence adherence =
    case adherence of
        PrescribedAVRs ->
            { english = "Ask the mother to name or describe her prescribed AVRs. Can she correctly describe her medication?"
            , kinyarwanda = Just "Saba umubyeyi kuvuga izina ry’imiti igabanya ubukana bamuhaye. Ese abashije kuyivuga neza?"
            }

        CorrectDosage ->
            { english = "Can she tell you the correct dosage?"
            , kinyarwanda = Just "Yaba abasha kukubwira neza uburyo ayifata?"
            }

        TimeOfDay ->
            { english = "Can she tell you the correct time of day to make her ARVs?"
            , kinyarwanda = Just "Yaba abasha kukubwira amasaha ayifatiraho buri munsi?"
            }

        Adhering ->
            { english = "Based on your conversations with her, do you think she is adhering to her ARV regimen?"
            , kinyarwanda = Just "Ugendeye ku kiganiro mwagiranye, utekereza ko ari gufata imiti ye neza?"
            }


translateCounselingTimingHeading : CounselingTiming -> TranslationSet String
translateCounselingTimingHeading timing =
    case timing of
        Entry ->
            { english = "Entry Counseling Checklist:"
            , kinyarwanda = Just "Ibigomba kugirwaho inama ku ntangiriro:"
            }

        MidPoint ->
            { english = "Mid Program Review Checklist:"
            , kinyarwanda = Just "Ibigomba kugirwaho inama hagati mu gusubiramo gahunda:"
            }

        Exit ->
            { english = "Exit Counseling Checklist:"
            , kinyarwanda = Just "Ibigomba kugirwaho inama kumuntu usohotse muri gahunda:"
            }

        BeforeMidpoint ->
            { english = "Reminder"
            , kinyarwanda = Just "Kwibutsa"
            }

        BeforeExit ->
            { english = "Reminder"
            , kinyarwanda = Just "Kwibutsa"
            }


translateChartPhrase : ChartPhrase -> TranslationSet String
translateChartPhrase phrase =
    case phrase of
        AgeCompletedMonthsYears ->
            { english = "Age (completed months and years)"
            , kinyarwanda = Just "Imyaka uzuza amazi n'imyaka"
            }

        Birth ->
            { english = "Birth"
            , kinyarwanda = Just "kuvuka"
            }

        BirthToTwoYears ->
            { english = "Birth to 2 years (z-scores)"
            , kinyarwanda = Just "kuvuka (Kuva avutse)  kugeza ku myaka 2 Z-score"
            }

        LengthCm ->
            { english = "Length (cm)"
            , kinyarwanda = Just "Uburere cm"
            }

        LengthForAgeBoys ->
            { english = "Length-for-age BOYS"
            , kinyarwanda = Just "Uburebure ku myaka/ umuhungu"
            }

        LengthForAgeGirls ->
            { english = "Length-for-age GIRLS"
            , kinyarwanda = Just "uburebure ku myaka umukobwa"
            }

        Months ->
            { english = "Months"
            , kinyarwanda = Just "Amezi"
            }

        OneYear ->
            { english = "1 year"
            , kinyarwanda = Just "Umwaka umwe"
            }

        WeightForAgeBoys ->
            { english = "Weight-for-age BOYS"
            , kinyarwanda = Just "Ibiro ku myaka umuhungu"
            }

        WeightForAgeGirls ->
            { english = "Weight-for-age GIRLS"
            , kinyarwanda = Just "ibiro ku myaka umukobwa"
            }

        WeightForLengthBoys ->
            { english = "Weight-for-length BOYS"
            , kinyarwanda = Just "Ibiro ku Uburebure umuhungu"
            }

        WeightForLengthGirls ->
            { english = "Weight-for-length GIRLS"
            , kinyarwanda = Just "ibiro ku uburebure umukobwa"
            }

        WeightKg ->
            { english = "Weight (kg)"
            , kinyarwanda = Just "Ibiro kg"
            }

        YearsPlural value ->
            { english = Debug.toString value ++ " years"
            , kinyarwanda = Just <| "Imyaka " ++ Debug.toString value
            }

        ZScoreChartsAvailableAt ->
            { english = "Z-score charts available at"
            , kinyarwanda = Just "Raporo ku mikurire y'umwana"
            }


translateLoginPhrase : LoginPhrase -> TranslationSet String
translateLoginPhrase phrase =
    case phrase of
        CheckingCachedCredentials ->
            { english = "Checking cached credentials"
            , kinyarwanda = Nothing
            }

        ForgotPassword1 ->
            { english = "Forgot your password?"
            , kinyarwanda = Just "Wibagiwe ijambo ry'ibanga?"
            }

        ForgotPassword2 ->
            { english = "Call The Ihangane Project at +250 788 817 542"
            , kinyarwanda = Just "Hamagara The Ihangane Project kuri +250 788 817 542(Hamagara kumushinga wa ihangane"
            }

        LoggedInAs ->
            { english = "Logged in as"
            , kinyarwanda = Just "Kwinjira nka"
            }

        LoginRejected method ->
            case method of
                ByAccessToken ->
                    { english = "Your access token has expired. You will need to sign in again."
                    , kinyarwanda = Just "Igihe cyo gukoresha sisitemu cyarangiye . Ongera winjore muri sisitemu"
                    }

                ByPassword ->
                    { english = "The server rejected your username or password."
                    , kinyarwanda = Just "Seriveri yanze ijambo ryo kwinjira cg ijambo ry'ibanga"
                    }

        LoginError error ->
            translateHttpError error

        LoginOrWorkOffline ->
            { english = "Either login below, or work offline without logging in."
            , kinyarwanda = Nothing
            }

        Logout ->
            { english = "Logout"
            , kinyarwanda = Just "Gufunga"
            }

        LogoutInProgress ->
            { english = "Logout in progress ..."
            , kinyarwanda = Just "sisitemi irikwifunga"
            }

        LogoutFailed ->
            { english = "Logout Failed"
            , kinyarwanda = Just "Gufunga byanze"
            }

        Password ->
            { english = "Password"
            , kinyarwanda = Just "Ijambo ry'ibanga"
            }

        PinCode ->
            { english = "PIN code"
            , kinyarwanda = Nothing
            }

        PinCodeRejected ->
            { english = "Your PIN code was not recognized."
            , kinyarwanda = Just "Umubare wawe w'ibanga ntabwo uzwi."
            }

        SignIn ->
            { english = "Sign In"
            , kinyarwanda = Just "Kwinjira"
            }

        SignOut ->
            { english = "Sign Out"
            , kinyarwanda = Just "Gusohoka muri sisiteme"
            }

        Username ->
            { english = "Username"
            , kinyarwanda = Just "Izina ryo kwinjira"
            }

        WorkOffline ->
            { english = "Work Offline"
            , kinyarwanda = Just "Gukora nta internet"
            }

        YouMustLoginBefore ->
            { english = "You must sign in before you can access the"
            , kinyarwanda = Just "Ugomba kubanza kwinjira muri sisitemi mbere yuko ubona"
            }


translateMonth : Month -> TranslationSet String
translateMonth month =
    case month of
        Jan ->
            { english = "January"
            , kinyarwanda = Just "Mutarama"
            }

        Feb ->
            { english = "February"
            , kinyarwanda = Just "Gashyantare"
            }

        Mar ->
            { english = "March"
            , kinyarwanda = Just "Werurwe"
            }

        Apr ->
            { english = "April"
            , kinyarwanda = Just "Mata"
            }

        May ->
            { english = "May"
            , kinyarwanda = Just "Gicurasi"
            }

        Jun ->
            { english = "June"
            , kinyarwanda = Just "Kamena"
            }

        Jul ->
            { english = "July"
            , kinyarwanda = Just "Nyakanga"
            }

        Aug ->
            { english = "August"
            , kinyarwanda = Just "Kanama"
            }

        Sep ->
            { english = "September"
            , kinyarwanda = Just "Nzeri"
            }

        Oct ->
            { english = "October"
            , kinyarwanda = Just "Ukwakira"
            }

        Nov ->
            { english = "November"
            , kinyarwanda = Just "Ugushyingo"
            }

        Dec ->
            { english = "December"
            , kinyarwanda = Just "Ukuboza"
            }


translateHttpError : Http.Error -> TranslationSet String
translateHttpError error =
    case error of
        Http.NetworkError ->
            { english = "A network error occurred contacting the server. Are you connected to the Internet?"
            , kinyarwanda = Just "Hari ikibazo cya reseau hamagara kuri seriveri. Ufite intereneti? (murandasi)"
            }

        Http.Timeout ->
            { english = "The request to the server timed out."
            , kinyarwanda = Just "Ibyo wasabye kuri seriveri byarengeje igihe."
            }

        Http.BadUrl url ->
            { english = "URL is not valid: " ++ url
            , kinyarwanda = Nothing
            }

        Http.BadStatus response ->
            { english = "The server indicated the following error:"
            , kinyarwanda = Just "Aya makosa yagaragaye hamagara kuri seriveri:"
            }

        Http.BadPayload message response ->
            { english = "The server responded with data of an unexpected type."
            , kinyarwanda = Nothing
            }


translateValidationError : ValidationError -> TranslationSet String
translateValidationError id =
    case id of
        DigitsOnly ->
            { english = "should contain only digit characters"
            , kinyarwanda = Nothing
            }

        InvalidBirthDate ->
            { english = "is invalid"
            , kinyarwanda = Nothing
            }

        InvalidBirthDateForAdult ->
            { english = "is invalid - adult should at least 13 years old"
            , kinyarwanda = Nothing
            }

        InvalidBirthDateForChild ->
            { english = "is invalid - child should be below the age of 13"
            , kinyarwanda = Nothing
            }

        InvalidHmisNumber ->
            { english = "is invalid - child should be between 1 and 15"
            , kinyarwanda = Nothing
            }

        LengthError correctLength ->
            { english = "should contain " ++ Debug.toString correctLength ++ " characters"
            , kinyarwanda = Nothing
            }

        LettersOnly ->
            { english = "should contain only letter characters"
            , kinyarwanda = Nothing
            }

        RequiredField ->
            { english = "is a required field"
            , kinyarwanda = Just "ni ngombwa kuhuzuza"
            }

        UnknownGroup ->
            { english = "is not a known Group"
            , kinyarwanda = Nothing
            }

        UnknownProvince ->
            { english = "is not a known province"
            , kinyarwanda = Nothing
            }

        UnknownDistrict ->
            { english = "is not a known district"
            , kinyarwanda = Nothing
            }

        UnknownSector ->
            { english = "is not a known sector"
            , kinyarwanda = Nothing
            }

        UnknownCell ->
            { english = "is not a known cell"
            , kinyarwanda = Nothing
            }

        UnknownVillage ->
            { english = "is not a known village"
            , kinyarwanda = Nothing
            }

        DecoderError err ->
            { english = "Decoder error: " ++ err
            , kinyarwanda = Nothing
            }


translateFormError : ErrorValue ValidationError -> TranslationSet String
translateFormError error =
    case error of
        Empty ->
            { english = "should not be empty"
            , kinyarwanda = Nothing
            }

        InvalidString ->
            { english = "is not a valid string"
            , kinyarwanda = Just "Ntibyemewe kwandikama inyuguti"
            }

        InvalidEmail ->
            { english = "is not a valid email"
            , kinyarwanda = Nothing
            }

        InvalidFormat ->
            { english = "is not a valid format"
            , kinyarwanda = Nothing
            }

        InvalidInt ->
            { english = "is not a valid integer"
            , kinyarwanda = Nothing
            }

        InvalidFloat ->
            { english = "is not a valid number"
            , kinyarwanda = Nothing
            }

        InvalidBool ->
            { english = "is not a valid boolean"
            , kinyarwanda = Nothing
            }

        SmallerIntThan int ->
            { english = "must be smaller than " ++ Debug.toString int
            , kinyarwanda = Nothing
            }

        GreaterIntThan int ->
            { english = "must be larger than " ++ Debug.toString int
            , kinyarwanda = Nothing
            }

        SmallerFloatThan float ->
            { english = "must be smaller than " ++ Debug.toString float
            , kinyarwanda = Nothing
            }

        GreaterFloatThan float ->
            { english = "must be larger than " ++ Debug.toString float
            , kinyarwanda = Nothing
            }

        ShorterStringThan int ->
            { english = "must have fewer than " ++ Debug.toString int ++ " characters"
            , kinyarwanda = Nothing
            }

        LongerStringThan int ->
            { english = "must have more than " ++ Debug.toString int ++ " characters"
            , kinyarwanda = Nothing
            }

        NotIncludedIn ->
            { english = "was not among the valid options"
            , kinyarwanda = Nothing
            }

        CustomError e ->
            translateValidationError e


{-| This one is hampered by the fact that the field names in etaque/elm-form
are untyped strings, but we do our best.
-}
translateFormField : String -> TranslationSet String
translateFormField field =
    case field of
        "clinic_id" ->
            translationSet Group

        "closed" ->
            translationSet Closed

        "training" ->
            translationSet Group

        "scheduled_date.start" ->
            translationSet StartDate

        "scheduled_date.end" ->
            translationSet EndDate

        _ ->
            { english = field
            , kinyarwanda = Nothing
            }
