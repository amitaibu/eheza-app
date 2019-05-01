module Activity.Utils exposing
    ( decodeActivityFromString
    , defaultActivity
    , encodeActivityAsString
    , expectCounselingActivity
    , expectParticipantConsent
    , getActivityCountForMother
    , getActivityIcon
    , getAllActivities
    , getCheckedIn
    , getParticipantCountForActivity
    , motherIsCheckedIn
    , summarizeByActivity
    , summarizeByParticipant
    , summarizeChildActivity
    , summarizeChildParticipant
    , summarizeMotherActivity
    , summarizeMotherParticipant
    )

{-| Various utilities that deal with "activities". An activity represents the
need for a nurse to do something with respect to a person who is checked in.

Just as a matter of terminology, we use "completed" to mean the obvious thing
-- that is, the action has been performed. The word "pending" is not precisely
the opposite of "completed", because the action is only "pending" if it is
expected (and not completed).

-}

import Activity.Model exposing (..)
import Backend.Counseling.Model exposing (CounselingTiming(..))
import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (..)
import Backend.Measurement.Utils exposing (currentValue, currentValues, mapMeasurementData)
import Backend.ParticipantConsent.Model exposing (ParticipantForm)
import Backend.Person.Model exposing (Person)
import Backend.PmtctParticipant.Model exposing (AdultActivities(..))
import Backend.Session.Model exposing (..)
import Backend.Session.Utils exposing (getChild, getChildHistoricalMeasurements, getChildMeasurementData, getChildren, getMother, getMotherHistoricalMeasurements, getMotherMeasurementData, getMyMother)
import EveryDict exposing (EveryDict)
import EveryDictList exposing (EveryDictList)
import EverySet
import Gizra.NominalDate exposing (diffDays)
import Maybe.Extra exposing (isJust, isNothing)


{-| Used for URL etc., not for display in the normal UI (since we'd translate
for that).
-}
encodeActivityAsString : Activity -> String
encodeActivityAsString activity =
    case activity of
        ChildActivity childActivity ->
            case childActivity of
                ChildPicture ->
                    "picture"

                -- Counseling ->
                --   "counseling"
                Height ->
                    "height"

                Muac ->
                    "muac"

                NutritionSigns ->
                    "nutrition"

                Weight ->
                    "weight"

        MotherActivity motherActivity ->
            case motherActivity of
                FamilyPlanning ->
                    "family_planning"



-- ParticipantConsent ->
-- "participants_consent"


{-| The inverse of encodeActivityTypeAsString
-}
decodeActivityFromString : String -> Maybe Activity
decodeActivityFromString s =
    case s of
        "picture" ->
            Just <| ChildActivity ChildPicture

        -- "counseling" ->
        --  Just <| ChildActivity Counseling
        "height" ->
            Just <| ChildActivity Height

        "muac" ->
            Just <| ChildActivity Muac

        "nutrition" ->
            Just <| ChildActivity NutritionSigns

        "weight" ->
            Just <| ChildActivity Weight

        "family_planning" ->
            Just <| MotherActivity FamilyPlanning

        -- "participants_consent" ->
        --    Just <| MotherActivity ParticipantConsent
        _ ->
            Nothing


{-| An activity type to use if we need to start somewhere.
-}
defaultActivity : Activity
defaultActivity =
    ChildActivity Height


{-| Returns a string representing an icon for the activity, for use in a
"class" attribute.
-}
getActivityIcon : Activity -> String
getActivityIcon activity =
    case activity of
        ChildActivity childActivity ->
            case childActivity of
                ChildPicture ->
                    "photo"

                -- Counseling ->
                --    "counseling"
                Height ->
                    "height"

                Weight ->
                    "weight"

                Muac ->
                    "muac"

                NutritionSigns ->
                    "nutrition"

        MotherActivity motherActivity ->
            case motherActivity of
                FamilyPlanning ->
                    "planning"



-- ParticipantConsent ->
--    "forms"


getAllActivities : List Activity
getAllActivities =
    List.concat
        [ List.map ChildActivity getAllChildActivities
        , List.map MotherActivity getAllMotherActivities
        ]


getAllChildActivities : List ChildActivity
getAllChildActivities =
    [ {- Counseling, -} Height, Muac, NutritionSigns, Weight, ChildPicture ]


getAllMotherActivities : List MotherActivity
getAllMotherActivities =
    [ FamilyPlanning

    -- , ParticipantConsent
    ]


{-| Do we expect this activity to be performed in this session for this child?
Note that we don't consider whether the child is checked in here -- just
whether we would expect to perform this action if checked in.
-}
expectChildActivity : EditableSession -> PersonId -> ChildActivity -> Bool
expectChildActivity session childId activity =
    case activity of
        {- Counseling ->
           Maybe.Extra.isJust <|
               expectCounselingActivity session childId
        -}
        _ ->
            -- In all other cases, we expect each ativity each time.
            True


{-| Whether to expect a counseling activity is not just a yes/no question,
since we'd also like to know **which** sort of counseling activity to expect.
I suppose we could parameterize the `Counseling` activity by
`CounselingTiming`. However, that would be awkward in its own way, since we
also don't want more than one in each session.

So, we'll try it this way for now. We'll return `Nothing` if no kind of
counseling activity is expected, and `Just CounselingTiming` if one is
expected.

-}
expectCounselingActivity : EditableSession -> PersonId -> Maybe CounselingTiming
expectCounselingActivity session childId =
    let
        -- First, we check our current value. If we have a counseling session
        -- stored in the backend, or we've already got a local edit, then we
        -- use that.  This has two benefits. First, its a kind of optimization,
        -- since we're basically caching our conclusion about whether to
        -- showing the counseling activity or not. Second, it provides some UI
        -- stability ...  once we show the counseling activity and the user
        -- checks some boxes, it ensures that we'll definitely keep showing
        -- that one, and not switch to something else.
        cachedTiming =
            getChildMeasurementData childId session
                |> mapMeasurementData .counselingSession
                |> currentValue
                |> Maybe.map (.value >> Tuple.first)

        -- All the counseling session records from the past
        historical =
            getChildHistoricalMeasurements childId session.offlineSession
                |> .counselingSessions

        -- Have we ever completed a counseling session of the specified type?
        completed timing =
            EveryDictList.any
                (\_ counseling -> Tuple.first counseling.value == timing)
                historical

        -- How long ago did we complete a session of the specified type?
        completedDaysAgo timing =
            historical
                |> EveryDictList.filter (\_ counseling -> Tuple.first counseling.value == timing)
                |> EveryDictList.head
                |> Maybe.map (\( _, counseling ) -> diffDays counseling.dateMeasured session.offlineSession.session.scheduledDate.start)

        -- How old will the child be as of the scheduled date of the session?
        -- (All of our date calculations are in days here).
        --
        -- It simplifies the rest of the calculation if we avoid making this a
        -- `Maybe`. We've got bigger problems if the session doesn't actually
        -- contain the child, so it should be safe to default the age to 0.
        age =
            getChild childId session.offlineSession
                |> Maybe.andThen
                    (\child ->
                        Maybe.map
                            (\birthDate -> diffDays birthDate session.offlineSession.session.scheduledDate.start)
                            child.birthDate
                    )
                |> Maybe.withDefault 0

        -- We don't necessarily know when the next session will be scheduled,
        -- so we work on the assumption that it will be no more than 6 weeks
        -- from this session (so, 42 days).
        maximumSessionGap =
            42

        -- For the reminder, which isn't as critical, we apply the normal
        -- session gap of 32 days. This reduces the frequence of cases where we
        -- issue the reminder super-early, at the cost of some cases where we
        -- might issue no reminder (which is less serious).
        normalSessionGap =
            32

        -- To compute a two-month gap, we use one normal and one maximum
        twoMonthGap =
            normalSessionGap + maximumSessionGap

        -- To compute a three month gap, we use two normals and one maximum
        threeMonthGap =
            (normalSessionGap * 2) + maximumSessionGap

        -- In how many days (from the session date) will the child be 2 years
        -- old?
        daysUntilTwoYearsOld =
            (365 * 2) - age

        -- In how many days (from the session date) will the child be 1 year
        -- old?
        daysUntilOneYearOld =
            365 - age

        -- If we don't have a value already, we apply our basic logic, but
        -- lazily, so we make this a function. Here's a summary of our design
        -- goals, which end up having a number of parts.
        --
        -- - Definitely show the counseling activity before the relevant
        --   anniversary, using the assumption that the next session will be no
        --   more than 6 weeks away.
        --
        -- - Try to avoid showing counseling activities with no reminders, but
        --   do it without a reminder if necessary.
        --
        -- - Once we show a reminder, always show the counseling activity in
        --   the next session, even if it now seems a bit early (to avoid double
        --   reminders).
        --
        -- - Always show the entry counseling if it hasn't been done, unless
        --   we've already reached exit counseling.
        --
        -- - Make sure that there is a bit of a delay between entry counseling
        --   and midpoint counseling (for cases where a baby starts late).
        checkTiming _ =
            if completed Exit then
                -- If exit counseling has been done, then we need no more
                -- counseling
                Nothing

            else if completed BeforeExit then
                -- If we've given the exit reminder, then show the exit
                -- counseling now, even if it seems a bit early.
                Just Exit

            else if daysUntilTwoYearsOld < maximumSessionGap then
                -- If we can't be sure we'll have another session before the
                -- baby is two, then show the exit counseling
                Just Exit

            else if not (completed Entry) then
                -- If we haven't done entry counseling, then we always need to
                -- do it
                Just Entry

            else if completed MidPoint then
                -- If we have already done the MidPoint counseling, then the
                -- only thing left to consider is whether to show the Exit
                -- reminder
                if daysUntilTwoYearsOld < twoMonthGap then
                    Just BeforeExit

                else
                    Nothing

            else if completed BeforeMidpoint then
                -- If we've given the midpoint warning, then show it, even if
                -- it seems a bit early now.
                Just MidPoint

            else if daysUntilOneYearOld < maximumSessionGap then
                -- If we can't be sure we'll have another session before the
                -- baby is one year old, we show the exit counseling. Except,
                -- we also check to see whether we've done entry counseling
                -- recently ...  so that we'll always have a bit of a gap.
                case completedDaysAgo Entry of
                    Just daysAgo ->
                        if daysAgo < threeMonthGap then
                            -- We're forcing the midpoint counseling to be
                            -- roungly 3 months after the entry counseling. So,
                            -- the ideal sequence would be:
                            --
                            -- entry -> Nothing -> Rminder MidPoint -> MidPoint
                            if daysAgo < twoMonthGap then
                                Nothing

                            else
                                Just BeforeMidpoint

                        else
                            Just MidPoint

                    Nothing ->
                        Just MidPoint

            else if daysUntilOneYearOld < twoMonthGap then
                -- If we think we'll do the midpoint counseling at the next
                -- session, show the reminder. Except, again, we try to force a
                -- bit of separation between Entry and the Midpoint.
                case completedDaysAgo Entry of
                    Just daysAgo ->
                        if daysAgo < twoMonthGap then
                            -- We're forcing the reminder for midpoint
                            -- counseling to be roughtly 2 months after the
                            -- entry counseling.
                            Nothing

                        else
                            Just BeforeMidpoint

                    Nothing ->
                        Just BeforeMidpoint

            else
                Nothing
    in
    cachedTiming
        |> Maybe.Extra.orElseLazy checkTiming


{-| Do we expect this activity to be performed in this session for this mother?
Note that we don't consider whether the mother is checked in here -- just
whether we would expect to perform this action if checked in.
-}
expectMotherActivity : EditableSession -> PersonId -> MotherActivity -> Bool
expectMotherActivity session motherId activity =
    session.offlineSession.participants
        |> EveryDictList.values
        |> List.filter (\value -> value.adult == motherId)
        |> List.head
        |> Maybe.map
            (\participant ->
                case activity of
                    FamilyPlanning ->
                        case participant.adultActivities of
                            MotherActivities ->
                                True

                            CaregiverActivities ->
                                False
             {- ParticipantConsent ->
                expectParticipantConsent session motherId
                    |> EveryDictList.isEmpty
                    |> not
             -}
            )
        |> Maybe.withDefault False


{-| Which participant forms would we expect this mother to consent to in this session?
-}
expectParticipantConsent : EditableSession -> PersonId -> EveryDictList ParticipantFormId ParticipantForm
expectParticipantConsent session motherId =
    let
        previouslyConsented =
            getMotherHistoricalMeasurements motherId session.offlineSession
                |> .consents
                |> EveryDictList.map (\_ consent -> consent.value.formId)
                |> EveryDictList.values
                |> EverySet.fromList
    in
    session.offlineSession.allParticipantForms
        |> EveryDictList.filter (\id _ -> not (EverySet.member id previouslyConsented))


{-| For a particular child activity, figure out which children have completed
the activity and have the activity pending. (This may not add up to all the
children, because we only consider a child "pending" if they are checked in and
the activity is expected.
-}
summarizeChildActivity : ChildActivity -> EditableSession -> CompletedAndPending (EveryDictList PersonId Person)
summarizeChildActivity activity session =
    getCheckedIn session
        |> .children
        |> EveryDictList.filter (\childId _ -> expectChildActivity session childId activity)
        |> EveryDictList.partition (\childId _ -> childHasCompletedActivity childId activity session)
        |> (\( completed, pending ) -> { completed = completed, pending = pending })


{-| For a particular mother activity, figure out which mothers have completed
the activity and have the activity pending. (This may not add up to all the
mothers, because we only consider a mother "pending" if they are checked in and
the activity is expected.
-}
summarizeMotherActivity : MotherActivity -> EditableSession -> CompletedAndPending (EveryDictList PersonId Person)
summarizeMotherActivity activity session =
    -- For participant consent, we only consider the activity to be completed once
    -- all expected consents have been saved.
    getCheckedIn session
        |> .mothers
        |> EveryDictList.filter (\motherId _ -> expectMotherActivity session motherId activity)
        |> EveryDictList.partition (\motherId _ -> motherHasCompletedActivity motherId activity session)
        |> (\( completed, pending ) -> { completed = completed, pending = pending })


{-| Summarize our data for the editable session in a way that is useful
for our UI, when we're focused on activities. This only considers children &
mothers who are checked in to the session.
-}
summarizeByActivity : EditableSession -> SummaryByActivity
summarizeByActivity session =
    let
        children =
            getAllChildActivities
                |> List.map
                    (\activity ->
                        ( activity
                        , summarizeChildActivity activity session
                        )
                    )
                |> EveryDict.fromList

        mothers =
            getAllMotherActivities
                |> List.map
                    (\activity ->
                        ( activity
                        , summarizeMotherActivity activity session
                        )
                    )
                |> EveryDict.fromList
    in
    { children = children
    , mothers = mothers
    }


{-| This summarizes our summary, by counting, for the given activity, how many
participants are completed or pending.
-}
getParticipantCountForActivity : SummaryByActivity -> Activity -> CompletedAndPending Int
getParticipantCountForActivity summary activity =
    case activity of
        ChildActivity childActivity ->
            summary.children
                |> EveryDict.get childActivity
                |> Maybe.map
                    (\{ completed, pending } ->
                        { completed = EveryDictList.size completed
                        , pending = EveryDictList.size pending
                        }
                    )
                |> Maybe.withDefault
                    { completed = 0
                    , pending = 0
                    }

        MotherActivity motherActivity ->
            summary.mothers
                |> EveryDict.get motherActivity
                |> Maybe.map
                    (\{ completed, pending } ->
                        { completed = EveryDictList.size completed
                        , pending = EveryDictList.size pending
                        }
                    )
                |> Maybe.withDefault
                    { completed = 0
                    , pending = 0
                    }


{-| For a particular child, figure out which activities are completed
and which are pending. (This may not add up to all the activities, because some
activities may not be expected for this child).
-}
summarizeChildParticipant : PersonId -> EditableSession -> CompletedAndPending (List ChildActivity)
summarizeChildParticipant id session =
    getAllChildActivities
        |> List.filter (expectChildActivity session id)
        |> List.partition (\activity -> childHasCompletedActivity id activity session)
        |> (\( completed, pending ) -> { completed = completed, pending = pending })


{-| For a particular mother, figure out which activities are completed
and which are pending. (This may not add up to all the activities, because some
activities may not be expected for this mother).
-}
summarizeMotherParticipant : PersonId -> EditableSession -> CompletedAndPending (List MotherActivity)
summarizeMotherParticipant id session =
    getAllMotherActivities
        |> List.filter (expectMotherActivity session id)
        |> List.partition (\activity -> motherHasCompletedActivity id activity session)
        |> (\( completed, pending ) -> { completed = completed, pending = pending })


{-| Summarize our data for the editable session in a way that is useful
for our UI, when we're focused on participants. This only considers children &
mothers who are checked in to the session.
-}
summarizeByParticipant : EditableSession -> SummaryByParticipant
summarizeByParticipant session =
    let
        checkedIn =
            getCheckedIn session

        children =
            EveryDictList.map
                (\childId _ -> summarizeChildParticipant childId session)
                checkedIn.children

        mothers =
            EveryDictList.map
                (\motherId _ -> summarizeMotherParticipant motherId session)
                checkedIn.mothers
    in
    { children = children
    , mothers = mothers
    }


{-| This summarizes our summary, by counting how many activities have been
completed for the given mother.

It includes ativities for children of the mother, since we navigate from mother
to child.

-}
getActivityCountForMother : EditableSession -> PersonId -> Person -> SummaryByParticipant -> CompletedAndPending Int
getActivityCountForMother session id mother summary =
    let
        motherCount =
            EveryDictList.get id summary.mothers
                |> Maybe.map
                    (\activities ->
                        { pending = List.length activities.pending
                        , completed = List.length activities.completed
                        }
                    )
                |> Maybe.withDefault
                    { pending = 0
                    , completed = 0
                    }
    in
    List.foldl
        (\( childId, _ ) accum ->
            EveryDictList.get childId summary.children
                |> Maybe.map
                    (\activities ->
                        { pending = accum.pending + List.length activities.pending
                        , completed = accum.completed + List.length activities.completed
                        }
                    )
                |> Maybe.withDefault accum
        )
        motherCount
        (getChildren id session.offlineSession)


hasCompletedChildActivity : ChildActivity -> MeasurementData ChildMeasurements -> Bool
hasCompletedChildActivity activityType measurements =
    case activityType of
        ChildPicture ->
            isCompleted (Maybe.map Tuple.second measurements.current.photo)

        -- Counseling ->
        --    isCompleted (Maybe.map Tuple.second measurements.current.counselingSession)
        Height ->
            isCompleted (Maybe.map Tuple.second measurements.current.height)

        Weight ->
            isCompleted (Maybe.map Tuple.second measurements.current.weight)

        Muac ->
            isCompleted (Maybe.map Tuple.second measurements.current.muac)

        NutritionSigns ->
            isCompleted (Maybe.map Tuple.second measurements.current.nutrition)


childHasCompletedActivity : PersonId -> ChildActivity -> EditableSession -> Bool
childHasCompletedActivity childId activityType session =
    getChildMeasurementData childId session
        |> hasCompletedChildActivity activityType


hasCompletedMotherActivity : EditableSession -> PersonId -> MotherActivity -> MeasurementData MotherMeasurements -> Bool
hasCompletedMotherActivity session motherId activityType measurements =
    case activityType of
        FamilyPlanning ->
            isCompleted (Maybe.map Tuple.second measurements.current.familyPlanning)



{-
   ParticipantConsent ->
       -- We only consider this activity completed if all expected
       -- consents have been saved.
       let
           current =
               mapMeasurementData .consent measurements
                   |> currentValues
                   |> List.map (Tuple.second >> .value >> .formId)
                   |> EverySet.fromList
       in
       expectParticipantConsent session motherId
           |> EveryDictList.all (\id _ -> EverySet.member id current)
-}


motherHasCompletedActivity : PersonId -> MotherActivity -> EditableSession -> Bool
motherHasCompletedActivity motherId activityType session =
    getMotherMeasurementData motherId session
        |> hasCompletedMotherActivity session motherId activityType


{-| Should some measurement be considered completed? Note that this means that it has
been entered locally, not that it has been saved to the backend.
-}
isCompleted : Maybe value -> Bool
isCompleted =
    isJust


hasAnyCompletedMotherActivity : EditableSession -> PersonId -> MeasurementData MotherMeasurements -> Bool
hasAnyCompletedMotherActivity session motherId measurements =
    getAllMotherActivities
        |> List.any (\activity -> hasCompletedMotherActivity session motherId activity measurements)


hasAnyCompletedChildActivity : MeasurementData ChildMeasurements -> Bool
hasAnyCompletedChildActivity measurements =
    getAllChildActivities
        |> List.any (flip hasCompletedChildActivity measurements)


{-| See whether either the mother, or any of her children, has any completed activity.

If we can't find the mother, we return False.

-}
motherOrAnyChildHasAnyCompletedActivity : PersonId -> EditableSession -> Bool
motherOrAnyChildHasAnyCompletedActivity motherId session =
    let
        motherHasOne =
            motherHasAnyCompletedActivity motherId session

        anyChildHasOne =
            getChildren motherId session.offlineSession
                |> List.any (\( childId, _ ) -> childHasAnyCompletedActivity childId session)
    in
    motherHasOne || anyChildHasOne


{-| Has the mother been marked as checked in?

We'll return true if the mother has been explicitly checked-in in the UI, or
has a completed activity ... that way, we can freely change the explicit
check-in (and activities) without worrying about synchronizing the two.

-}
motherIsCheckedIn : PersonId -> EditableSession -> Bool
motherIsCheckedIn motherId session =
    let
        explicitlyCheckedIn =
            getMotherMeasurementData motherId session
                |> (.current >> .attendance >> Maybe.map (Tuple.second >> .value) >> (==) (Just True))

        hasCompletedActivity =
            motherOrAnyChildHasAnyCompletedActivity motherId session
    in
    explicitlyCheckedIn || hasCompletedActivity


childIsCheckedIn : PersonId -> EditableSession -> Bool
childIsCheckedIn childId session =
    getMyMother childId session.offlineSession
        |> Maybe.map Tuple.first
        |> Maybe.map (\motherId -> motherIsCheckedIn motherId session)
        |> Maybe.withDefault False


{-| Who is checked in, considering both explicit check in and anyone who has
any completed activity?
-}
getCheckedIn : EditableSession -> { mothers : EveryDictList PersonId Person, children : EveryDictList PersonId Person }
getCheckedIn session =
    let
        -- A mother is checked in if explicitly checked in or has any completed
        -- activites.
        mothers =
            EveryDictList.filter
                (\motherId _ ->
                    motherIsCheckedIn motherId session
                        || motherOrAnyChildHasAnyCompletedActivity motherId session
                )
                session.offlineSession.mothers

        -- A child is checked in if the mother is checked in.
        children =
            EveryDictList.filter
                (\childId _ ->
                    getMyMother childId session.offlineSession
                        |> Maybe.map (\( motherId, _ ) -> EveryDictList.member motherId mothers)
                        |> Maybe.withDefault False
                )
                session.offlineSession.children
    in
    { mothers = mothers
    , children = children
    }


{-| Does the mother herself have any completed activity?
-}
motherHasAnyCompletedActivity : PersonId -> EditableSession -> Bool
motherHasAnyCompletedActivity motherId session =
    getMotherMeasurementData motherId session
        |> hasAnyCompletedMotherActivity session motherId


{-| Does the child have any completed activity?
-}
childHasAnyCompletedActivity : PersonId -> EditableSession -> Bool
childHasAnyCompletedActivity childId session =
    getChildMeasurementData childId session
        |> hasAnyCompletedChildActivity


{-| Is there any completed activity of any kind?
-}
hasAnyCompletedActivity : EditableSession -> Bool
hasAnyCompletedActivity session =
    let
        forChildren =
            session.offlineSession.children
                |> EveryDictList.toList
                |> List.any (\( id, _ ) -> childHasAnyCompletedActivity id session)

        forMothers =
            session.offlineSession.mothers
                |> EveryDictList.toList
                |> List.any (\( id, _ ) -> motherHasAnyCompletedActivity id session)
    in
    forChildren || forMothers
