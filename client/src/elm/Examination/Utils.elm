module Examination.Utils exposing (getLastExaminationFromChild, mapExaminationChild, mapExaminationMother, supplyMeasurement, toMeasurements, toExaminationChild, toExaminationMother)

import Backend.Child.Model exposing (Child)
import EverySet
import Examination.Model exposing (ExaminationChild, ExaminationMother, Examination(..), emptyExaminationChild, emptyExaminationMother)
import Measurement.Model
import StorageKey exposing (StorageKey(..))


{-| For now, we're just returning a mocked version. Eventually
we'll need to do something different, once we can have more than
one examination. (To make things easy for now, we show the previous
examination as being unsaved, which I suppose is possible).
-}
getLastExaminationFromChild : Child -> Maybe ExaminationChild
getLastExaminationFromChild child =
    Just
        { height = Just ( New, 50.0 )
        , muac = Just ( New, 13.0 )
        , nutrition = ( New, EverySet.empty )
        , photo = Nothing
        , weight = Just ( New, 4.0 )
        }


{-| Extracts an `ExaminationChild` from an `Examination`, or `Nothing`
if it is a `MotherExamination`. (The need to use this suggests our data
modeling could be a bit better).
-}
toExaminationChild : Examination -> Maybe ExaminationChild
toExaminationChild ex =
    case ex of
        ChildExamination childEx ->
            Just childEx

        MotherExamination _ ->
            Nothing


toExaminationMother : Examination -> Maybe ExaminationMother
toExaminationMother ex =
    case ex of
        MotherExamination motherEx ->
            Just motherEx

        ChildExamination _ ->
            Nothing


{-| This is a convenience for cases in which we've got an `Examination` and
we want to modify it if it is an `ExaminationChild` and leave it alone
otherwise. Using this probably indicates that we could do our data modelling a
bit better, but perhaps not.
-}
mapExaminationChild : (ExaminationChild -> ExaminationChild) -> Examination -> Examination
mapExaminationChild func examination =
    case examination of
        ChildExamination examinationChild ->
            ChildExamination (func examinationChild)

        MotherExamination _ ->
            examination


{-| Like mapExaminationChild, but for mothers.
-}
mapExaminationMother : (ExaminationMother -> ExaminationMother) -> Examination -> Examination
mapExaminationMother func examination =
    case examination of
        MotherExamination examinationMother ->
            MotherExamination (func examinationMother)

        ChildExamination _ ->
            examination


{-| Our measurements are typed as

    Maybe (StorageKey key, value )

Now, when the user actually edits a value, we want to do
a couple of things to this, depending the initial state.
So, this is a helper for that.

-}
supplyMeasurement : v -> Maybe ( StorageKey k, v ) -> ( StorageKey k, v )
supplyMeasurement value storage =
    case storage of
        Nothing ->
            -- If it was `Nothing`, then we hadn't entered or retrieved
            -- anything at all. So, logically, now it is a 'new' value.
            ( New, value )

        Just ( key, _ ) ->
            -- Otherwise, we can just replace the value and keep the key
            ( key, value )


{-| Extracts the measurements from an examination.
-}
toMeasurements : Examination -> Measurement.Model.Model
toMeasurements examination =
    let
        emptyModel =
            Measurement.Model.emptyModel
    in
        case examination of
            MotherExamination exam ->
                { emptyModel
                    | familyPlanningSigns = Tuple.second exam.familyPlanning
                }

            ChildExamination exam ->
                { emptyModel
                    | height = Maybe.map (Tuple.second >> toString) exam.height
                    , weight = Maybe.map (Tuple.second >> toString) exam.weight
                    , muac = Maybe.map (Tuple.second >> toString) exam.muac
                    , nutritionSigns = Tuple.second exam.nutrition
                }
