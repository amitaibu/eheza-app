module Fixtures exposing (exampleAccessToken, exampleBackendUrl, exampleChildA, exampleChildB, exampleMother, exampleUser)

import Backend.Person.Model exposing (EducationLevel(..), Gender(..), Person, Ubudehe(..))
import EverySet
import Restful.Endpoint exposing (toEntityId)
import Time.Date exposing (date)
import User.Model exposing (User)


{-| } An example access token.
-}
exampleAccessToken : String
exampleAccessToken =
    "some-access-token"


{-| } An example backend URL.
-}
exampleBackendUrl : String
exampleBackendUrl =
    "https://example.com"


{-| } An example user.
-}
exampleUser : User
exampleUser =
    { id = 35
    , name = "aya"
    , avatarUrl = "http://example.com/avatar.jpg"
    , clinics = []
    , roles = EverySet.empty
    }


{-| An example child.
-}
exampleChildA : Person
exampleChildA =
    { name = "Michelle Kelly"
    , firstName = "Michelle"
    , secondName = "Kelly"
    , nationalIdNumber = Just "324324232"
    , avatarUrl = Just "http://lorempixel.com/output/people-q-c-640-480-8.jpg"
    , birthDate = Just <| date 2016 8 28
    , educationLevel = Nothing
    , maritalStatus = Nothing
    , isDateOfBirthEstimated = False
    , gender = Male
    , ubudehe = Nothing
    , province = Nothing
    , district = Nothing
    , sector = Nothing
    , cell = Nothing
    , village = Nothing
    , telephoneNumber = Nothing
    , healthCenterId = Nothing
    }


{-| Another example child.
-}
exampleChildB : Person
exampleChildB =
    { name = "Habimana Hakizimana"
    , firstName = "Habimana"
    , secondName = "Hakizimana"
    , nationalIdNumber = Just "232324232"
    , avatarUrl = Just "http://lorempixel.com/output/people-q-c-640-480-8.jpg"
    , birthDate = Just <| date 2016 11 17
    , isDateOfBirthEstimated = True
    , educationLevel = Nothing
    , maritalStatus = Nothing
    , gender = Female
    , ubudehe = Nothing
    , province = Nothing
    , district = Nothing
    , sector = Nothing
    , cell = Nothing
    , village = Nothing
    , telephoneNumber = Nothing
    , healthCenterId = Nothing
    }


{-| An example mother.
-}
exampleMother : Person
exampleMother =
    { name = "Sebabive Gahiji"
    , firstName = "Sebabive"
    , secondName = "Gahiji"
    , nationalIdNumber = Just "192324232"
    , avatarUrl = Just "http://lorempixel.com/output/people-q-c-640-480-8.jpg"
    , birthDate = Just <| date 2016 8 28
    , isDateOfBirthEstimated = False
    , gender = Female
    , ubudehe = Just Ubudehe1
    , educationLevel = Just NoSchooling
    , maritalStatus = Nothing
    , province = Nothing
    , district = Nothing
    , sector = Nothing
    , cell = Nothing
    , village = Nothing
    , telephoneNumber = Nothing
    , healthCenterId = Nothing
    }
