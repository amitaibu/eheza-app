module Pages.PatientRegistration.Model exposing
    ( DialogState(..)
    , Model
    , Msg(..)
    , ParticipantsData
    , PatientType(..)
    , RegistrationForm
    , RegistrationPhase(..)
    , RegistrationStep(..)
    , emptyModel
    , initModel
    , validateRegistrationForm
    )

-- import Pages.PatientRegistration.Utils exposing (generateUuid)

import Backend.Child.Model exposing (Child)
import Backend.Measurement.Model exposing (PhotoValue)
import Backend.Mother.Model exposing (Mother)
import Backend.Patient.Model exposing (Gender(..))
import EveryDict exposing (EveryDict)
import Form exposing (Form)
import Form.Error exposing (ErrorValue(..))
import Form.Validate exposing (Validation, andMap, andThen, bool, emptyString, field, format, mapError, oneOf, string, succeed)
import Measurement.Model exposing (DropZoneFile)
import Pages.Page exposing (Page)
import Random.Pcg exposing (initialSeed, step)
import Regex exposing (Regex)
import Time exposing (Time)
import Time.Date exposing (date)
import Uuid exposing (Uuid, uuidGenerator)


type alias Model =
    { photo : Maybe PhotoValue
    , registrationForm : Form () RegistrationForm
    , registrationPhase : RegistrationPhase
    , previousPhases : List RegistrationPhase
    , participantsData : ParticipantsData
    , relationPatient : Maybe PatientType
    , submittedSearch : Maybe String
    , dialogState : Maybe DialogState
    }


type alias ParticipantsData =
    { mothersToRegister : EveryDict Uuid Mother
    , childrenToRegister : EveryDict Uuid Child
    }


emptyModel : Model
emptyModel =
    { photo = Nothing
    , registrationForm = Form.initial [] validateRegistrationForm
    , registrationPhase = ParticipantSearch Nothing
    , previousPhases = []
    , participantsData = dummyParticipantsData
    , relationPatient = Nothing
    , submittedSearch = Nothing
    , dialogState = Nothing
    }


initModel : Model -> Model
initModel model =
    { emptyModel | participantsData = model.participantsData }


dummyParticipantsData : ParticipantsData
dummyParticipantsData =
    { mothersToRegister = EveryDict.fromList [ ( mother1Uuid, mother1 ), ( mother2Uuid, mother2 ), ( mother3Uuid, mother3 ), ( mother4Uuid, mother4 ) ]
    , childrenToRegister = EveryDict.fromList [ ( child1Uuid, child1 ), ( child2Uuid, child2 ), ( child3Uuid, child3 ), ( child4Uuid, child4 ) ]
    }


emptyParticipantsData : ParticipantsData
emptyParticipantsData =
    { mothersToRegister = EveryDict.empty
    , childrenToRegister = EveryDict.empty
    }


type RegistrationPhase
    = ParticipantSearch (Maybe String)
    | ParticipantRegistration RegistrationStep
    | ParticipantView PatientType


type RegistrationStep
    = First
    | Second
    | Third


type PatientType
    = PatientMother Uuid Mother
    | PatientChild Uuid Child


type Msg
    = AddNewPatient (Maybe Uuid)
    | DropZoneComplete DropZoneFile
    | GoBack
    | MsgRegistrationForm Form.Msg
    | Reset
    | SearchForParticipant String
    | SetActivePage Page
    | SetDialogState (Maybe DialogState)
    | SetRegistrationPhase RegistrationPhase
    | SetRelationPatient (Maybe PatientType)
    | Submit


type DialogState
    = ConfirmSubmision
    | SuccessfulSubmision


type alias RegistrationForm =
    { firstName : String
    , middleName : String
    , secondName : String
    , nationalIdNumber : String
    , dayOfBirth : String
    , monthOfBirth : String
    , yearOfBirth : String
    , isDateOfBirthEstimated : Bool
    , gender : String
    , levelOfEducation : String
    , profession : String
    , maritalStatus : String
    , hivStatus : String
    , modeOfDelivery : String
    , familyUbudehe : String
    , householdSize : String
    , numberOfChildren : String
    , motherName : String
    , motherNationalId : String
    , fatherName : String
    , fatherNationalId : String
    , caregiverName : String
    , caregiverNationalId : String
    , district : String
    , sector : String
    , cell : String
    , village : String
    , telephoneNumber : String
    , healthCenterName : String
    }


validateRegistrationForm : Validation () RegistrationForm
validateRegistrationForm =
    succeed RegistrationForm
        |> andMap (field "firstName" string)
        |> andMap (field "middleName" string)
        |> andMap (field "secondName" string)
        |> andMap (field "nationalIdNumber" (oneOf [ emptyString, validateAlphanumeric ]))
        |> andMap (field "dayOfBirth" string)
        |> andMap (field "monthOfBirth" string)
        |> andMap (field "yearOfBirth" string)
        |> andMap (field "isDateOfBirthEstimated" bool)
        |> andMap (field "gender" string)
        |> andMap (field "levelOfEducation" string)
        |> andMap (field "profession" string)
        |> andMap (field "maritalStatus" string)
        |> andMap (field "hivStatus" string)
        |> andMap (field "modeOfDelivery" string)
        |> andMap (field "familyUbudehe" string)
        |> andMap (field "householdSize" string)
        |> andMap (field "numberOfChildren" string)
        |> andMap (field "motherName" string)
        |> andMap (field "motherNationalId" (oneOf [ emptyString, validateAlphanumeric ]))
        |> andMap (field "fatherName" string)
        |> andMap (field "fatherNationalId" (oneOf [ emptyString, validateAlphanumeric ]))
        |> andMap (field "caregiverName" string)
        |> andMap (field "caregiverNationalId" (oneOf [ emptyString, validateAlphanumeric ]))
        |> andMap (field "district" string)
        |> andMap (field "sector" string)
        |> andMap (field "cell" string)
        |> andMap (field "village" string)
        |> andMap (field "telephoneNumber" string)
        |> andMap (field "healthCenterName" string)


validateAlphanumeric : Validation e String
validateAlphanumeric =
    string
        |> andThen
            (\s ->
                format alphanumericPattern s
                    |> mapError (\_ -> Form.Error.value InvalidFormat)
            )


alphanumericPattern : Regex
alphanumericPattern =
    Regex.regex "^[a-zA-Z0-9]*$"



-- Temporary copy of function from Utils to solve cyclic dependency.


generateUuid : Time -> Uuid
generateUuid currentTime =
    let
        ( uuid, _ ) =
            step uuidGenerator (initialSeed <| round currentTime)
    in
    uuid


child1Uuid : Uuid
child1Uuid =
    generateUuid 21


child2Uuid : Uuid
child2Uuid =
    generateUuid 22


child3Uuid : Uuid
child3Uuid =
    generateUuid 23


child4Uuid : Uuid
child4Uuid =
    generateUuid 24


mother1Uuid : Uuid
mother1Uuid =
    generateUuid 11


mother2Uuid : Uuid
mother2Uuid =
    generateUuid 12


mother3Uuid : Uuid
mother3Uuid =
    generateUuid 13


mother4Uuid : Uuid
mother4Uuid =
    generateUuid 14


child1 : Child
child1 =
    Child "child1 child1"
        "child1"
        Nothing
        "child1"
        Nothing
        Nothing
        Nothing
        (Just mother1Uuid)
        (date 2016 1 1)
        False
        Male
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Murumbu"
        )
        Nothing
        Nothing


child2 : Child
child2 =
    Child "child2 child2"
        "child2"
        Nothing
        "child2"
        Nothing
        Nothing
        Nothing
        (Just mother1Uuid)
        (date 2014 2 2)
        True
        Female
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Zurumbu"
        )
        Nothing
        Nothing


child3 : Child
child3 =
    Child "child3 child3"
        "child3"
        Nothing
        "child3"
        Nothing
        Nothing
        Nothing
        (Just mother2Uuid)
        (date 2013 3 3)
        True
        Male
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Purumbu"
        )
        Nothing
        Nothing


child4 : Child
child4 =
    Child "child4 child4"
        "child4"
        Nothing
        "child4"
        Nothing
        Nothing
        Nothing
        Nothing
        (date 2011 4 4)
        False
        Female
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Kurumbu"
        )
        Nothing
        Nothing


mother1 : Mother
mother1 =
    Mother "mother1 mother1"
        "mother1"
        Nothing
        "mother1"
        Nothing
        Nothing
        []
        [ child1Uuid, child2Uuid ]
        (date 2001 1 1)
        False
        Female
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Wurumbu"
        )
        Nothing
        Nothing


mother2 : Mother
mother2 =
    Mother "mother2 mother2"
        "mother2"
        Nothing
        "mother2"
        Nothing
        Nothing
        []
        [ child3Uuid ]
        (date 2002 2 2)
        True
        Female
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Durumbu"
        )
        Nothing
        Nothing


mother3 : Mother
mother3 =
    Mother "mother3 mother3"
        "mother3"
        Nothing
        "mother3"
        Nothing
        Nothing
        []
        []
        (date 2003 3 3)
        True
        Female
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Urumbu"
        )
        Nothing
        Nothing


mother4 : Mother
mother4 =
    Mother "mother4 mother4"
        "mother4"
        Nothing
        "mother4"
        Nothing
        Nothing
        []
        []
        (date 2004 4 4)
        False
        Male
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        Nothing
        (Just
            "Gurumbu"
        )
        Nothing
        Nothing
