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
import Backend.Measurement.Model exposing (ChildNutritionSign(..), FamilyPlanningSign(..), MuacIndication(..))
import Backend.Person.Model exposing (EducationLevel(..), Gender(..), HIVStatus(..), MaritalStatus(..), ModeOfDelivery(..), VaginalDelivery(..))
import Backend.Relationship.Model exposing (MyRelatedBy(..))
import Date exposing (Month)
import Form.Error exposing (ErrorValue(..))
import Http
import Pages.Attendance.Model exposing (InitialResultsDisplay(..))
import Pages.Page exposing (..)
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
    = AccessDenied
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
    | Attendance
    | Baby
    | BabyName String
    | Back
    | BackendError
    | Born
    | Cancel
    | CaregiverName
    | CaregiverNationalId
    | CentimeterShorthand
    | Cell
    | ChartPhrase ChartPhrase
    | CheckIn
    | ChildHmisNumber
    | ChildDemographicInformation
    | ChildNutritionSignLabel ChildNutritionSign
    | ChildNutritionSignReport ChildNutritionSign
    | ChildOf
    | Children
    | Clear
    | ClickTheCheckMark
    | ClinicType ClinicType
    | Clinical
    | GroupNotFound
    | Group
    | Groups
    | GroupUnauthorized
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
    | CreateGroupEncounter
    | CreateRelationship
    | CreateTrainingGroupEncounters
    | DeleteTrainingGroupEncounters
    | Dashboard
    | DateOfLastAssessment
    | Day
    | DateOfBirth
    | Days
    | Delete
    | DemographicInformation
    | Device
    | DeviceNotAuthorized
    | DeviceStatus
    | District
    | DOB
    | DropzoneDefaultMessage
    | EditRelationship
    | EndGroupEncounter
    | EnterPairingCode
    | ErrorCheckLocalConfig
    | ErrorConfigurationError
    | Estimated
    | FamilyInformation
    | FamilyMembers
    | FamilyPlanningSignLabel FamilyPlanningSign
    | FamilyUbudehe
    | Fetch
    | FatherName
    | FatherNationalId
    | FilterByName
    | FirstName
    | FormError (ErrorValue ValidationError)
    | FormField String
    | Gender Gender
    | GenderLabel
    | GoHome
    | GroupAssessment
    | HaveYouSynced
    | HealthCenter
    | HIVStatus HIVStatus
    | HIVStatusLabel
    | HouseholdSize
    | HttpError Http.Error
    | InitialResultsDisplay InitialResultsDisplay
    | KilogramShorthand
    | LastChecked
    | LevelOfEducationLabel
    | LevelOfEducation EducationLevel
    | LinkToMother
    | LoginPhrase LoginPhrase
    | MakeSureYouAreConnected
    | MaritalStatusLabel
    | MaritalStatus MaritalStatus
    | MeasurementNoChange
    | MeasurementGained Float
    | MeasurementLost Float
    | MemoryQuota { totalJSHeapSize : Int, usedJSHeapSize : Int, jsHeapSizeLimit : Int }
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
    | MuacIndication MuacIndication
    | MyAccount
    | MyRelatedBy MyRelatedBy
    | MyRelatedByQuestion MyRelatedBy
    | NationalIdNumber
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
    | NoChildrenRegisteredInTheSystem
    | NoParticipantsFound
    | NotAvailable
    | NotConnected
    | NumberOfChildrenUnder5
    | OK
    | Old
    | OnceYouEndYourGroupEncounter
    | Or
    | Page
    | Page404
    | PageNotFoundMsg
    | ParticipantDirectory
    | Participants
    | ParticipantReviewed
    | ParticipantSignature
    | ParticipantSummary
    | ParticipantDemographicInformation
    | ParticipantInformation
    | People
    | PersistentStorage Bool
    | Person
    | PersonHasBeenSaved
    | PlaceholderEnterHeight
    | PlaceholderEnterMUAC
    | PlaceholderEnterParticipantName
    | PlaceholderEnterWeight
    | PleaseSelectGroup
    | PreviousFloatMeasurement Float
    | Profession
    | Programs
    | ProgressReport
    | Province
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
    | ReportAge String
    | ReportDOB String
    | ReportRemaining Int
    | ReportResultsOfSearch Int
    | RecentAndUpcomingGroupEncounters
    | ReportCompleted { pending : Int, completed : Int }
    | ResolveMonth Month
    | Retry
    | Save
    | SaveError
    | Search
    | SearchByName
    | SearchHelper
    | SearchHelperFamilyMember
    | SecondName
    | Sector
    | SelectGroup
    | SelectProgram
    | SelectLanguage
    | SelectYourGroup
    | SelectYourHealthCenter
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
    | StopSyncing
    | StorageQuota { usage : Int, quota : Int }
    | Submit
    | SubmitPairingCode
    | Success
    | SyncGeneral
    | TelephoneNumber
    | TakenCareOfBy
    | ThisActionCannotBeUndone
    | ThisGroupHasNoMothers
    | Training
    | TrainingGroupEncounterCreateSuccessMessage
    | TrainingGroupEncounterDeleteSuccessMessage
    | TrySyncing
    | UbudeheLabel
    | Unknown
    | Update
    | UpdateError
    | ValidationErrors
    | Version
    | ViewProgressReport
    | Village
    | WelcomeUser String
    | WhatDoYouWantToDo
    | Year
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
        AccessDenied ->
            { english = "Access denied"
            , kinyarwanda = Just "Kwinjira ntibyemera"
            }

        AddChild ->
            { english = "Add Child"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        AddToGroup ->
            { english = "Add to Group..."
            , kinyarwanda = Nothing
            }

        Admin ->
            { english = "Administration"
            , kinyarwanda = Just "Abakuriye"
            }

        AddressInformation ->
            { english = "Address Information"
            , kinyarwanda = Nothing
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
                MotherActivity FamilyPlanning ->
                    { english = "Every mother should be asked about her family planning method(s) each month. If a mother needs family planning, refer her to a clinic."
                    , kinyarwanda = Just "Buri mubyeyi agomba kubazwa uburyo bwo kuboneza urubyaro akoresha buri kwezi. Niba umubyeyi akeneye kuboneza urubyaro mwohereze ku kigo nderabuzima k'ubishinzwe"
                    }

                {- MotherActivity ParticipantConsent ->
                       { english = "Please review the following forms with the participant."
                       , kinyarwanda = Nothing
                       }

                   ChildActivity Counseling ->
                       { english = "Please refer to this list during counseling sessions and ensure that each task has been completed."
                       , kinyarwanda = Just "Kurikiza iyi lisiti mu gihe utanga ubujyanama, witondere kureba ko buri gikorwa cyakozwe."
                       }
                -}
                ChildActivity Height ->
                    { english = "Ask the mother to hold the baby’s head at the end of the measuring board. Move the slider to the baby’s heel and pull their leg straight."
                    , kinyarwanda = Just "Saba Umubyeyi guhagarara inyuma y’umwana we agaramye, afata umutwe ku gice cy’amatwi. Sunikira akabaho ku buryo gakora mu bworo by’ibirenge byombi."
                    }

                ChildActivity Muac ->
                    { english = "Make sure to measure at the center of the baby’s upper arm."
                    , kinyarwanda = Just "Ibuka gupima icya kabiri cy'akaboko ko hejuru kugira bigufashe guoima ikizigira cy'akaboko"
                    }

                ChildActivity NutritionSigns ->
                    { english = "Explain to the mother how to check the malnutrition signs for their own child."
                    , kinyarwanda = Just "Sobanurira umubyeyi gupima ibimenyetso by'imirire mibi ku giti cye"
                    }

                ChildActivity ChildPicture ->
                    { english = "Take each baby’s photo at each health assessment. Photos should show the entire body of each child."
                    , kinyarwanda = Just "Fata ifoto ya buri mwana kuri buri bikorwa by'ipimwa Ifoto igomba kwerekana ibice by'umubiri wose by'umwana"
                    }

                ChildActivity Weight ->
                    { english = "Calibrate the scale before taking the first baby's weight. Place baby in harness with no clothes on."
                    , kinyarwanda = Just "Ibuka kuregera umunzani mbere yo gupima ibiro by'umwana wa mbere. Ambika umwana ikariso y'ibiro wabanje kumukuramo imyenda iremereye"
                    }

        ActivitiesLabel activity ->
            case activity of
                MotherActivity FamilyPlanning ->
                    { english = "Which, if any, of the following methods do you use?"
                    , kinyarwanda = Just "Ni ubuhe buryo, niba hari ubuhari, mu buryo bukurikira bwo kuboneza urubyaro ukoresha? Muri ubu buryo bukurikira bwo kuboneza urubyaro, ni ubuhe buryo mukoresha?"
                    }

                {- MotherActivity ParticipantConsent ->
                       { english = "Forms:"
                       , kinyarwanda = Nothing
                       }

                   ChildActivity Counseling ->
                       { english = "Please refer to this list during counseling sessions and ensure that each task has been completed."
                       , kinyarwanda = Just "Kurikiza iyi lisiti mu gihe utanga ubujyanama, witondere kureba ko buri gikorwa cyakozwe."
                       }
                -}
                ChildActivity Height ->
                    { english = "Height:"
                    , kinyarwanda = Just "Uburere:"
                    }

                ChildActivity Muac ->
                    { english = "MUAC:"
                    , kinyarwanda = Just "Ikizigira cy'akaboko:"
                    }

                ChildActivity NutritionSigns ->
                    { english = "Select all signs that are present:"
                    , kinyarwanda = Just "Hitamo ibimenyetso by'imirire byose bishoboka umwana afite:"
                    }

                ChildActivity ChildPicture ->
                    { english = "Photo:"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Weight ->
                    { english = "Weight:"
                    , kinyarwanda = Just "Ibiro:"
                    }

        ActivitiesTitle activity ->
            case activity of
                MotherActivity FamilyPlanning ->
                    { english = "Family Planning"
                    , kinyarwanda = Just "Kuboneza Urubyaro? nticyaza muri raporo yimikurire yumwana"
                    }

                {- MotherActivity ParticipantConsent ->
                       { english = "Forms"
                       , kinyarwanda = Nothing
                       }

                   ChildActivity Counseling ->
                       { english = "Counseling"
                       , kinyarwanda = Just "Ubujyanama"
                       }
                -}
                ChildActivity Height ->
                    { english = "Height"
                    , kinyarwanda = Just "Uburebure"
                    }

                ChildActivity Muac ->
                    { english = "MUAC"
                    , kinyarwanda = Just "Ikizigira cy'akaboko"
                    }

                ChildActivity NutritionSigns ->
                    { english = "Nutrition"
                    , kinyarwanda = Just "Imirire"
                    }

                ChildActivity ChildPicture ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Weight ->
                    { english = "Weight"
                    , kinyarwanda = Just "Ibiro"
                    }

        ActivityProgressReport activity ->
            case activity of
                MotherActivity FamilyPlanning ->
                    { english = "Family Planning"
                    , kinyarwanda = Just "Kuboneza Urubyaro? nticyaza muri raporo yimikurire yumwana"
                    }

                {- MotherActivity ParticipantConsent ->
                       { english = "Forms"
                       , kinyarwanda = Nothing
                       }

                   ChildActivity Counseling ->
                       { english = "Counseling"
                       , kinyarwanda = Nothing
                       }
                -}
                ChildActivity Height ->
                    { english = "Height"
                    , kinyarwanda = Just "Uburebure"
                    }

                ChildActivity Muac ->
                    { english = "MUAC"
                    , kinyarwanda = Just "Ikizigira cy'akaboko"
                    }

                ChildActivity NutritionSigns ->
                    { english = "Nutrition Signs"
                    , kinyarwanda = Just "Ibimenyetso by'imirire"
                    }

                ChildActivity ChildPicture ->
                    { english = "Photo"
                    , kinyarwanda = Just "Ifoto"
                    }

                ChildActivity Weight ->
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

        Attendance ->
            { english = "Attendance"
            , kinyarwanda = Just "Ubwitabire"
            }

        Baby ->
            { english = "Baby"
            , kinyarwanda = Just "Umwana"
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

        Born ->
            { english = "Born"
            , kinyarwanda = Just "Kuvuka/ itariki y'amavuko"
            }

        Cancel ->
            { english = "Cancel"
            , kinyarwanda = Just "Guhagarika"
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
            , kinyarwanda = Nothing
            }

        CentimeterShorthand ->
            { english = "cm"
            , kinyarwanda = Just "cm"
            }

        ChartPhrase phrase ->
            translateChartPhrase phrase

        CheckIn ->
            { english = "Check in:"
            , kinyarwanda = Just "Kureba abaje"
            }

        ChildHmisNumber ->
            { english = "Child HMIS Number"
            , kinyarwanda = Nothing
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

                BrittleHair ->
                    { english = "Brittle Hair"
                    , kinyarwanda = Just "Gucurama no guhindura ibara ku misatsi"
                    }

                DrySkin ->
                    { english = "Dry Skin"
                    , kinyarwanda = Just "Uruhu ryumye"
                    }

                Edema ->
                    { english = "Edema"
                    , kinyarwanda = Just "Kubyimba"
                    }

                None ->
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

                BrittleHair ->
                    { english = "Brittle Hair"
                    , kinyarwanda = Just "Gucurama umusatsi"
                    }

                DrySkin ->
                    { english = "Dry Skin"
                    , kinyarwanda = Just "Uruhu ryumye"
                    }

                Edema ->
                    { english = "Edema"
                    , kinyarwanda = Just "Kubyimba"
                    }

                None ->
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

        ChildOf ->
            { english = "Child of"
            , kinyarwanda = Just "Umwana wa"
            }

        Clear ->
            { english = "Clear"
            , kinyarwanda = Nothing
            }

        ClickTheCheckMark ->
            { english = "Click the check mark if the mother / caregiver is in attendance. The check mark will appear green when a mother / caregiver has been signed in."
            , kinyarwanda = Just "Kanda (kuri) ku kazu niba umubyeyi ahari. Ku kazu harahita hahindura ibara habe icyaytsi niba wemeje ko umubyeyi ahari"
            }

        ClinicType clinicType ->
            case clinicType of
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
            , kinyarwanda = Nothing
            }

        GroupNotFound ->
            { english = "Group not found"
            , kinyarwanda = Nothing
            }

        Group ->
            { english = "Group"
            , kinyarwanda = Nothing
            }

        Groups ->
            { english = "Groups"
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
            , kinyarwanda = Nothing
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

        CreateGroupEncounter ->
            { english = "Create Group Encounter"
            , kinyarwanda = Just "Tangira igikorwa"
            }

        CreateRelationship ->
            { english = "Create Relationship"
            , kinyarwanda = Nothing
            }

        CreateTrainingGroupEncounters ->
            { english = "Create All Training Group Encounters"
            , kinyarwanda = Nothing
            }

        DeleteTrainingGroupEncounters ->
            { english = "Delete All Training Group Encounters"
            , kinyarwanda = Nothing
            }

        Dashboard ->
            { english = "Dashboard"
            , kinyarwanda = Just "Tabeau de bord"
            }

        DateOfLastAssessment ->
            { english = "Date of last Assessment"
            , kinyarwanda = Just "Amakuru y'ipimwa ry'ubushize"
            }

        Day ->
            { english = "Day"
            , kinyarwanda = Just "Umunsi"
            }

        DateOfBirth ->
            { english = "Date of Birth"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        District ->
            { english = "District"
            , kinyarwanda = Nothing
            }

        DOB ->
            { english = "DOB"
            , kinyarwanda = Nothing
            }

        DropzoneDefaultMessage ->
            { english = "Touch here to take a photo, or drop a photo file here."
            , kinyarwanda = Just "Kanda hano niba ushaka gufotora cg ukure ifoto mu bubiko hano."
            }

        EditRelationship ->
            { english = "Edit Relationship"
            , kinyarwanda = Nothing
            }

        EndGroupEncounter ->
            { english = "End Group Encounter"
            , kinyarwanda = Nothing
            }

        EnterPairingCode ->
            { english = "Enter pairing code"
            , kinyarwanda = Nothing
            }

        MemoryQuota quota ->
            { english = "Memory used " ++ Debug.toString (quota.usedJSHeapSize // (1024 * 1024)) ++ " MB of available " ++ Debug.toString (quota.jsHeapSizeLimit // (1024 * 1024)) ++ " MB"
            , kinyarwanda = Nothing
            }

        StorageQuota quota ->
            { english = "Storage used " ++ Debug.toString (quota.usage // (1024 * 1024)) ++ " MB of available " ++ Debug.toString (quota.quota // (1024 * 1024)) ++ " MB"
            , kinyarwanda = Nothing
            }

        SubmitPairingCode ->
            { english = "Submit Pairing Code"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        FamilyInformation ->
            { english = "Family Information"
            , kinyarwanda = Nothing
            }

        FamilyMembers ->
            { english = "Family Members"
            , kinyarwanda = Nothing
            }

        FamilyPlanningSignLabel sign ->
            case sign of
                AutoObservation ->
                    { english = "Auto-observation"
                    , kinyarwanda = Nothing
                    }

                Condoms ->
                    { english = "Condoms"
                    , kinyarwanda = Just "Udukingirizo"
                    }

                CycleBeads ->
                    { english = "Cycle beads"
                    , kinyarwanda = Nothing
                    }

                CycleCounting ->
                    { english = "Cycle counting"
                    , kinyarwanda = Nothing
                    }

                Hysterectomy ->
                    { english = "Hysterectomy"
                    , kinyarwanda = Nothing
                    }

                Implants ->
                    { english = "Implants"
                    , kinyarwanda = Just "Akapira ko mu kaboko"
                    }

                Injectables ->
                    { english = "Injectables"
                    , kinyarwanda = Nothing
                    }

                IUD ->
                    { english = "IUD"
                    , kinyarwanda = Just "Akapira ko mu mura (agapira ko munda ibyara)"
                    }

                LactationAmenorrhea ->
                    { english = "Lactation amenorrhea"
                    , kinyarwanda = Nothing
                    }

                NoFamilyPlanning ->
                    { english = "None of these"
                    , kinyarwanda = Just "nta buryo bwo kuboneza urubyaro akoresha"
                    }

                OralContraceptives ->
                    { english = "Oral contraceptives"
                    , kinyarwanda = Nothing
                    }

                Spermicide ->
                    { english = "Spermicide"
                    , kinyarwanda = Nothing
                    }

                TubalLigatures ->
                    { english = "Tubal ligatures"
                    , kinyarwanda = Nothing
                    }

                Vasectomy ->
                    { english = "Vasectomy"
                    , kinyarwanda = Nothing
                    }

        FamilyUbudehe ->
            { english = "Family Ubudehe"
            , kinyarwanda = Nothing
            }

        FatherName ->
            { english = "Father's Name"
            , kinyarwanda = Nothing
            }

        FatherNationalId ->
            { english = "Father's National ID"
            , kinyarwanda = Nothing
            }

        Fetch ->
            { english = "Fetch"
            , kinyarwanda = Just "Gushakisha"
            }

        FilterByName ->
            { english = "Filter by name"
            , kinyarwanda = Nothing
            }

        FirstName ->
            { english = "First Name"
            , kinyarwanda = Nothing
            }

        FormError errorValue ->
            translateFormError errorValue

        FormField field ->
            translateFormField field

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
            , kinyarwanda = Nothing
            }

        GoHome ->
            { english = "Go to main page"
            , kinyarwanda = Just "Kujya ahabanza"
            }

        GroupAssessment ->
            { english = "Group Assessment"
            , kinyarwanda = Nothing
            }

        HaveYouSynced ->
            { english = "Have you synced data for the health center you are working with?"
            , kinyarwanda = Nothing
            }

        HealthCenter ->
            { english = "Health Center"
            , kinyarwanda = Nothing
            }

        HIVStatus status ->
            case status of
                HIVExposedInfant ->
                    { english = "HIV-exposed Infant"
                    , kinyarwanda = Nothing
                    }

                Negative ->
                    { english = "Negative"
                    , kinyarwanda = Nothing
                    }

                NegativeDiscordantCouple ->
                    { english = "Negative - discordant couple"
                    , kinyarwanda = Nothing
                    }

                Positive ->
                    { english = "Positive"
                    , kinyarwanda = Nothing
                    }

                Backend.Person.Model.Unknown ->
                    { english = "Unknown"
                    , kinyarwanda = Nothing
                    }

        HIVStatusLabel ->
            { english = "HIV Status"
            , kinyarwanda = Nothing
            }

        HouseholdSize ->
            { english = "Household Size"
            , kinyarwanda = Nothing
            }

        HttpError error ->
            translateHttpError error

        InitialResultsDisplay display ->
            case display of
                InitialResultsHidden ->
                    { english = "Display all mothers / caregivers"
                    , kinyarwanda = Nothing
                    }

                InitialResultsShown ->
                    { english = "Hide all mothers / caregivers"
                    , kinyarwanda = Nothing
                    }

        KilogramShorthand ->
            { english = "kg"
            , kinyarwanda = Just "kg"
            }

        LastChecked ->
            { english = "Last checked"
            , kinyarwanda = Nothing
            }

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

        LoginPhrase phrase ->
            translateLoginPhrase phrase

        MakeSureYouAreConnected ->
            { english = "Make sure you are connected to the internet. If the issue continues, call The Ihangane Project at +250 788 817 542."
            , kinyarwanda = Just "Banza urebe ko ufite interineti. Ikibazo nigikomeza, hamagara The Ihangane Project kuri +250 788 817 542"
            }

        MaritalStatusLabel ->
            { english = "Marital Status"
            , kinyarwanda = Nothing
            }

        MaritalStatus status ->
            case status of
                Divorced ->
                    { english = "Divorced"
                    , kinyarwanda = Nothing
                    }

                Married ->
                    { english = "Married"
                    , kinyarwanda = Nothing
                    }

                Single ->
                    { english = "Single"
                    , kinyarwanda = Nothing
                    }

                Widowed ->
                    { english = "Widowed"
                    , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        ModeOfDelivery mode ->
            case mode of
                VaginalDelivery (Spontaneous True) ->
                    { english = "Spontaneous vaginal delivery with episiotomy"
                    , kinyarwanda = Nothing
                    }

                VaginalDelivery (Spontaneous False) ->
                    { english = "Spontaneous vaginal delivery without episiotomy"
                    , kinyarwanda = Nothing
                    }

                VaginalDelivery WithVacuumExtraction ->
                    { english = "Vaginal delivery with vacuum extraction"
                    , kinyarwanda = Nothing
                    }

                CesareanDelivery ->
                    { english = "Cesarean delivery"
                    , kinyarwanda = Nothing
                    }

        ModeOfDeliveryLabel ->
            { english = "Mode of delivery"
            , kinyarwanda = Nothing
            }

        Month ->
            { english = "Month"
            , kinyarwanda = Nothing
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

        NationalIdNumber ->
            { english = "National ID Number"
            , kinyarwanda = Nothing
            }

        Next ->
            { english = "Next"
            , kinyarwanda = Nothing
            }

        No ->
            { english = "No"
            , kinyarwanda = Nothing
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

        NumberOfChildrenUnder5 ->
            { english = "Number of Children under 5"
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

        OnceYouEndYourGroupEncounter ->
            { english = "Once you end your Group Encounter, you will no longer be able to edit or add data."
            , kinyarwanda = Nothing
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

        ParticipantDirectory ->
            { english = "Participant Directory"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        ParticipantInformation ->
            { english = "Participant Information"
            , kinyarwanda = Nothing
            }

        People ->
            { english = "People"
            , kinyarwanda = Nothing
            }

        PersistentStorage authorized ->
            if authorized then
                { english = "Persistent storage has been authorized. The browser will not delete locally cached data without your approval."
                , kinyarwanda = Nothing
                }

            else
                { english = "Persistent storage has not been authorized. The browser may delete locally cached data if storage runs low."
                , kinyarwanda = Nothing
                }

        Person ->
            { english = "Person"
            , kinyarwanda = Nothing
            }

        PersonHasBeenSaved ->
            { english = "Person has been saved"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        PlaceholderEnterWeight ->
            { english = "Enter weight here…"
            , kinyarwanda = Just "Andika ibiro hano…"
            }

        PleaseSelectGroup ->
            { english = "Please select the relevant Group for the new encounter"
            , kinyarwanda = Nothing
            }

        PreviousFloatMeasurement value ->
            { english = "Previous measurement: " ++ Debug.toString value
            , kinyarwanda = Just <| "Ibipimo by'ubushize: " ++ Debug.toString value
            }

        Profession ->
            { english = "Profession"
            , kinyarwanda = Nothing
            }

        Programs ->
            { english = "Programs"
            , kinyarwanda = Nothing
            }

        ProgressReport ->
            { english = "Progress Report"
            , kinyarwanda = Just "Raporo igaragaza imikurire y'umwana"
            }

        Province ->
            { english = "Province"
            , kinyarwanda = Nothing
            }

        Register ->
            { english = "Register"
            , kinyarwanda = Nothing
            }

        RegisterHelper ->
            { english = "Not the participant you were looking for?"
            , kinyarwanda = Nothing
            }

        RegisterNewParticipant ->
            { english = "Register a new participant"
            , kinyarwanda = Nothing
            }

        RegistratingHealthCenter ->
            { english = "Registrating Health Center"
            , kinyarwanda = Nothing
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
                    , kinyarwanda = Nothing
                    }

                _ ->
                    { english = "There are " ++ Debug.toString total ++ " participants that match your search."
                    , kinyarwanda = Nothing
                    }

        RecentAndUpcomingGroupEncounters ->
            { english = "Recent and upcoming Group Encounters"
            , kinyarwanda = Nothing
            }

        ReportCompleted { pending, completed } ->
            { english = Debug.toString completed ++ " / " ++ Debug.toString (pending + completed) ++ " Completed"
            , kinyarwanda = Just <| Debug.toString completed ++ " / " ++ Debug.toString (pending + completed) ++ " Raporo irarangiye"
            }

        ResolveMonth month ->
            translateMonth month

        Retry ->
            { english = "Retry"
            , kinyarwanda = Just "Kongera kugerageza"
            }

        Save ->
            { english = "Save"
            , kinyarwanda = Just "Kubika"
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

        SearchHelper ->
            { english = "Search to see if the participant already exists in E-Heza. If the person you are looking for does not appear in the search, please create a new record for them."
            , kinyarwanda = Nothing
            }

        SearchHelperFamilyMember ->
            { english = "Search to see if the additional family member already exists in E-Heza. If the person you are looking for does not appear in the search, please create a new record for them."
            , kinyarwanda = Nothing
            }

        SecondName ->
            { english = "Second Name"
            , kinyarwanda = Nothing
            }

        Sector ->
            { english = "Sector"
            , kinyarwanda = Nothing
            }

        SelectLanguage ->
            { english = "Select language"
            , kinyarwanda = Nothing
            }

        SelectGroup ->
            { english = "Select Group..."
            , kinyarwanda = Nothing
            }

        SelectProgram ->
            { english = "Select Program"
            , kinyarwanda = Nothing
            }

        SelectYourGroup ->
            { english = "Select your Group"
            , kinyarwanda = Nothing
            }

        SelectYourHealthCenter ->
            { english = "Select your Health Center"
            , kinyarwanda = Nothing
            }

        ServiceWorkerActive ->
            { english = "The app is installed on this device."
            , kinyarwanda = Nothing
            }

        ServiceWorkerCurrent ->
            { english = "You have the current version of the app."
            , kinyarwanda = Nothing
            }

        ServiceWorkerCheckForUpdates ->
            { english = "Check for updates"
            , kinyarwanda = Nothing
            }

        ServiceWorkerInstalling ->
            { english = "A new version of the app has been detected and is being downloaded. You can continue to work while this is in progress."
            , kinyarwanda = Nothing
            }

        ServiceWorkerInstalled ->
            { english = "A new version of the app has been downloaded."
            , kinyarwanda = Nothing
            }

        ServiceWorkerSkipWaiting ->
            { english = "Activate new version of the app"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        ServiceWorkerStatus ->
            { english = "Deployment Status"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        StopSyncing ->
            { english = "Stop Syncing"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        TakenCareOfBy ->
            { english = "Taken care of by"
            , kinyarwanda = Nothing
            }

        TelephoneNumber ->
            { english = "Telephone Number"
            , kinyarwanda = Nothing
            }

        ThisActionCannotBeUndone ->
            { english = "This action cannot be undone."
            , kinyarwanda = Nothing
            }

        ThisGroupHasNoMothers ->
            { english = "This Group has no mothers assigned to it."
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        UbudeheLabel ->
            { english = "Ubudehe: "
            , kinyarwanda = Nothing
            }

        Unknown ->
            { english = "Unknown"
            , kinyarwanda = Nothing
            }

        Update ->
            { english = "Update"
            , kinyarwanda = Just "Kuvugurura"
            }

        UpdateError ->
            { english = "Update Error"
            , kinyarwanda = Just "ikosa mwivugurura"
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

        ViewProgressReport ->
            { english = "View Progress Report"
            , kinyarwanda = Just "Garagaza uruhererekane rw'imikurire y'umwana"
            }

        Village ->
            { english = "Village"
            , kinyarwanda = Nothing
            }

        WelcomeUser name ->
            { english = "Welcome " ++ name
            , kinyarwanda = Just <| "Murakaza neza " ++ name
            }

        WhatDoYouWantToDo ->
            { english = "What do you want to do?"
            , kinyarwanda = Nothing
            }

        Year ->
            { english = "Year"
            , kinyarwanda = Nothing
            }

        Yes ->
            { english = "Yes"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        MyParent ->
            { english = "is the child of"
            , kinyarwanda = Nothing
            }

        MyCaregiven ->
            { english = "is the caregiver for"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
            }

        PinCodePage ->
            { english = "PIN Code"
            , kinyarwanda = Nothing
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
                ClinicsPage _ ->
                    { english = "Groups"
                    , kinyarwanda = Nothing
                    }

                MyAccountPage ->
                    { english = "My Account"
                    , kinyarwanda = Just "Compte"
                    }

                CreatePersonPage _ ->
                    { english = "Create Person"
                    , kinyarwanda = Nothing
                    }

                EditPersonPage _ ->
                    { english = "Edit Person"
                    , kinyarwanda = Nothing
                    }

                PersonPage id ->
                    { english = "Person"
                    , kinyarwanda = Nothing
                    }

                PersonsPage _ ->
                    { english = "Participant Directory"
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
            , kinyarwanda = Nothing
            }

        SignIn ->
            { english = "Sign In"
            , kinyarwanda = Just "Kwinjira"
            }

        SignOut ->
            { english = "Sign Out"
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
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
            , kinyarwanda = Nothing
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
