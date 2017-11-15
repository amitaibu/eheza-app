module Activity.Utils
    exposing
        ( childHasAnyPendingActivity
        , childHasCompletedActivity
        , childHasPendingActivity
        , decodeActivityTypeFromString
        , defaultActivityType
        , encodeActivityTypeAsString
        , getActivityList
        , getActivityTypeList
        , getActivityIcon
        , getAllChildActivities
        , getAllMotherActivities
        , getTotalsNumberPerActivity
        , hasAnyPendingChildActivity
        , hasAnyPendingMotherActivity
        , hasCompletedChildActivity
        , hasCompletedMotherActivity
        , isCheckedIn
        , motherHasCompletedActivity
        , motherHasAnyPendingActivity
        , motherHasPendingActivity
        , motherOrAnyChildHasAnyCompletedActivity
        , motherOrAnyChildHasAnyPendingActivity
        )

import Activity.Model exposing (ActivityListItem, ActivityType(..), ChildActivityType(..), MotherActivityType(..))
import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (..)
import Backend.Measurement.Utils exposing (applyEdit)
import Backend.Session.Model exposing (..)
import Backend.Session.Utils exposing (getMother, getMotherMeasurementData, getChildMeasurementData)
import EveryDict
import EveryDictList
import Maybe.Extra exposing (isJust, isNothing)
import Participant.Model exposing (Participant(..), ParticipantId(..), ParticipantTypeFilter(..))


{-| Used for URL etc., not for display in the normal UI
(since we'd translate for that).
-}
encodeActivityTypeAsString : ActivityType -> String
encodeActivityTypeAsString activityType =
    case activityType of
        ChildActivity activity ->
            case activity of
                ChildPicture ->
                    "picture"

                Height ->
                    "height"

                Muac ->
                    "muac"

                NutritionSigns ->
                    "nutrition"

                ProgressReport ->
                    "progress"

                Weight ->
                    "weight"

        MotherActivity activity ->
            case activity of
                FamilyPlanning ->
                    "family-planning"


{-| The inverse of encodeActivityTypeAsString
-}
decodeActivityTypeFromString : String -> Maybe ActivityType
decodeActivityTypeFromString s =
    case s of
        "picture" ->
            Just <| ChildActivity ChildPicture

        "height" ->
            Just <| ChildActivity Height

        "muac" ->
            Just <| ChildActivity Muac

        "nutrition" ->
            Just <| ChildActivity NutritionSigns

        "progress" ->
            Just <| ChildActivity ProgressReport

        "weight" ->
            Just <| ChildActivity Weight

        "family-planning" ->
            Just <| MotherActivity FamilyPlanning

        _ ->
            Nothing


{-| An activity type to use if we need to start somewhere.
-}
defaultActivityType : ActivityType
defaultActivityType =
    ChildActivity Height


{-| Note that `ProgressReport` isn't included for now, as it is
handled specially in the UI.
-}
getActivityTypeList : ParticipantTypeFilter -> List ActivityType
getActivityTypeList participantTypeFilter =
    let
        childrenActivities =
            List.map ChildActivity getAllChildActivities

        mothersActivities =
            List.map MotherActivity getAllMotherActivities
    in
        case participantTypeFilter of
            All ->
                childrenActivities ++ mothersActivities

            Children ->
                childrenActivities

            Mothers ->
                mothersActivities


{-| Get the pending and completed activities.
-}
getActivityList : ParticipantTypeFilter -> EditableSession -> List ActivityListItem
getActivityList participantTypeFilter session =
    List.map
        (\activityType ->
            { activityType = activityType
            , totals = getTotalsNumberPerActivity activityType session
            }
        )
        (getActivityTypeList participantTypeFilter)


{-| Returns a string representing an icon for the activity, for use in a "class" attribute.
-}
getActivityIcon : ActivityType -> String
getActivityIcon activityType =
    case activityType of
        ChildActivity childActivityType ->
            case childActivityType of
                ChildPicture ->
                    "photo"

                Height ->
                    "height"

                Weight ->
                    "weight"

                Muac ->
                    "muac"

                NutritionSigns ->
                    "nutrition"

                ProgressReport ->
                    "bar chart"

        MotherActivity motherActivityType ->
            case motherActivityType of
                FamilyPlanning ->
                    "planning"


{-| Note that, for now, we're leaving out `ProgressReport` because that is handled
specially in the UI at the moment ... that may change in future.
-}
getAllChildActivities : List ChildActivityType
getAllChildActivities =
    [ ChildPicture, Height, Muac, NutritionSigns, Weight ]


getAllMotherActivities : List MotherActivityType
getAllMotherActivities =
    [ FamilyPlanning ]


{-| Given an activity, how many of those measurements should we expect, and how
many are still pending?

TODO: We'll need to modify this to take into account which people are actually present,
once we've got that in the data model.

-}
getTotalsNumberPerActivity : ActivityType -> EditableSession -> { pending : Int, total : Int }
getTotalsNumberPerActivity activityType session =
    case activityType of
        ChildActivity childType ->
            let
                -- Until we have data about who is actually present, the total would be
                -- everyone who is in the session. (Eventually, we may filter this).
                total =
                    EveryDict.size session.offlineSession.children

                completed =
                    session.offlineSession.children
                        |> EveryDict.filter (\childId _ -> hasCompletedChildActivity childType (getChildMeasurementData childId session))
                        |> EveryDict.size
            in
                { pending = total - completed
                , total = total
                }

        MotherActivity motherType ->
            let
                -- Until we have data about who is actually present, the total would be
                -- everyone who is in the session. (Eventually, we may filter this).
                total =
                    EveryDictList.size session.offlineSession.mothers

                -- It's actually eaiser to count the completed ones, so we do that and
                -- just subtract to get pending.
                completed =
                    session.offlineSession.mothers
                        |> EveryDictList.filter (\motherId _ -> hasCompletedMotherActivity motherType (getMotherMeasurementData motherId session))
                        |> EveryDictList.size
            in
                { pending = total - completed
                , total = total
                }


hasCompletedChildActivity : ChildActivityType -> MeasurementData ChildMeasurements ChildEdits -> Bool
hasCompletedChildActivity activityType measurements =
    case activityType of
        ChildPicture ->
            isCompleted measurements.edits.photo (Maybe.map Tuple.second measurements.current.photo)

        Height ->
            isCompleted measurements.edits.height (Maybe.map Tuple.second measurements.current.height)

        Weight ->
            isCompleted measurements.edits.weight (Maybe.map Tuple.second measurements.current.weight)

        Muac ->
            isCompleted measurements.edits.muac (Maybe.map Tuple.second measurements.current.muac)

        NutritionSigns ->
            isCompleted measurements.edits.nutrition (Maybe.map Tuple.second measurements.current.nutrition)

        ProgressReport ->
            -- Hmm. This isn't really a measurement, so if we get it, we'll say
            -- it's not "completed".
            --
            -- TODO: I suppose that if we're tracking "activities" for UI purposes,
            -- perhaps the activity here is just looking at the progress report?
            -- So, that would imply some local data that tracks whether we've looked
            -- at the progress report?
            False


childHasCompletedActivity : ChildId -> ChildActivityType -> EditableSession -> Bool
childHasCompletedActivity childId activityType session =
    getChildMeasurementData childId session
        |> hasCompletedChildActivity activityType


childHasPendingActivity : ChildId -> ChildActivityType -> EditableSession -> Bool
childHasPendingActivity childId activityType session =
    childHasCompletedActivity childId activityType session
        |> not


hasCompletedMotherActivity : MotherActivityType -> MeasurementData MotherMeasurements MotherEdits -> Bool
hasCompletedMotherActivity activityType measurements =
    case activityType of
        FamilyPlanning ->
            isCompleted measurements.edits.familyPlanning (Maybe.map Tuple.second measurements.current.familyPlanning)


motherHasCompletedActivity : MotherId -> MotherActivityType -> EditableSession -> Bool
motherHasCompletedActivity motherId activityType session =
    getMotherMeasurementData motherId session
        |> hasCompletedMotherActivity activityType


motherHasPendingActivity : MotherId -> MotherActivityType -> EditableSession -> Bool
motherHasPendingActivity motherId activityType session =
    motherHasCompletedActivity motherId activityType session
        |> not


{-| Should some measurement be considered completed? Note that this means that it has
been entered locally, not that it has been saved to the backend.
-}
isCompleted : Edit value -> Maybe value -> Bool
isCompleted edit =
    applyEdit edit >> isJust


isPending : Edit value -> Maybe value -> Bool
isPending edit =
    applyEdit edit >> isNothing


hasAnyPendingMotherActivity : MeasurementData MotherMeasurements MotherEdits -> Bool
hasAnyPendingMotherActivity measurements =
    getAllMotherActivities
        |> List.any ((flip hasCompletedMotherActivity) measurements >> not)


hasAnyCompletedMotherActivity : MeasurementData MotherMeasurements MotherEdits -> Bool
hasAnyCompletedMotherActivity measurements =
    getAllMotherActivities
        |> List.any ((flip hasCompletedMotherActivity) measurements)


hasAnyPendingChildActivity : MeasurementData ChildMeasurements ChildEdits -> Bool
hasAnyPendingChildActivity measurements =
    getAllChildActivities
        |> List.any ((flip hasCompletedChildActivity) measurements >> not)


hasAnyCompletedChildActivity : MeasurementData ChildMeasurements ChildEdits -> Bool
hasAnyCompletedChildActivity measurements =
    getAllChildActivities
        |> List.any ((flip hasCompletedChildActivity) measurements)


{-| See whether either the mother, or any of her children, has a pending activity.

If we can't find the mother, we return False.

-}
motherOrAnyChildHasAnyPendingActivity : MotherId -> EditableSession -> Bool
motherOrAnyChildHasAnyPendingActivity motherId session =
    let
        motherHasOne =
            motherHasAnyPendingActivity motherId session

        anyChildHasOne =
            getMother motherId session.offlineSession
                |> Maybe.map
                    (\mother ->
                        mother.children
                            |> List.any (\childId -> childHasAnyPendingActivity childId session)
                    )
                |> Maybe.withDefault False
    in
        motherHasOne || anyChildHasOne


{-| See whether either the mother, or any of her children, has any completed activity.

If we can't find the mother, we return False.

-}
motherOrAnyChildHasAnyCompletedActivity : MotherId -> EditableSession -> Bool
motherOrAnyChildHasAnyCompletedActivity motherId session =
    let
        motherHasOne =
            motherHasAnyCompletedActivity motherId session

        anyChildHasOne =
            getMother motherId session.offlineSession
                |> Maybe.map
                    (\mother ->
                        mother.children
                            |> List.any (\childId -> childHasAnyCompletedActivity childId session)
                    )
                |> Maybe.withDefault False
    in
        motherHasOne || anyChildHasOne


{-| Has the mother been marked as checked in?

We'll return true if the mother has been explicitly checked-in in the UI, or
has a completed activity ... that way, we can freely change the explicit
check-in (and activities) without worrying about synchronizing the two.

-}
isCheckedIn : MotherId -> EditableSession -> Bool
isCheckedIn motherId session =
    let
        explicitlyCheckedIn =
            getMotherMeasurementData motherId session
                |> (.edits >> .explicitlyCheckedIn)

        hasCompletedActivity =
            motherOrAnyChildHasAnyCompletedActivity motherId session
    in
        explicitlyCheckedIn || hasCompletedActivity


{-| Does the mother herself have any pending activity?
-}
motherHasAnyPendingActivity : MotherId -> EditableSession -> Bool
motherHasAnyPendingActivity motherId session =
    getMotherMeasurementData motherId session
        |> hasAnyPendingMotherActivity


{-| Does the mother herself have any completed activity?
-}
motherHasAnyCompletedActivity : MotherId -> EditableSession -> Bool
motherHasAnyCompletedActivity motherId session =
    getMotherMeasurementData motherId session
        |> hasAnyCompletedMotherActivity


{-| Does the child have any pending activity?
-}
childHasAnyPendingActivity : ChildId -> EditableSession -> Bool
childHasAnyPendingActivity childId session =
    getChildMeasurementData childId session
        |> hasAnyPendingChildActivity


{-| Does the child have any completed activity?
-}
childHasAnyCompletedActivity : ChildId -> EditableSession -> Bool
childHasAnyCompletedActivity childId session =
    getChildMeasurementData childId session
        |> hasAnyCompletedChildActivity
