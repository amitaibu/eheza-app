module NutritionActivity.Utils exposing (decodeActivityFromString, encodeActivityAsString, getActivityIcon, getAllActivities)

{-| Various utilities that deal with "activities". An activity represents the
need for a nurse to do something with respect to a person who is checked in.

Just as a matter of terminology, we use "completed" to mean the obvious thing
-- that is, the action has been performed. The word "pending" is not precisely
the opposite of "completed", because the action is only "pending" if it is
expected (and not completed).

-}

import NutritionActivity.Model exposing (..)
import Translate exposing (Language, translate)


{-| Used for URL etc., not for display in the normal UI (since we'd translate
for that).
-}
encodeActivityAsString : NutritionActivity -> String
encodeActivityAsString activity =
    case activity of
        Muac ->
            "nutrition-muac"

        Height ->
            "nutrition-height"

        Nutrition ->
            "nutrition-nutrition"

        Photo ->
            "nutrition-photo"

        Weight ->
            "nutrition-weight"


{-| The inverse of encodeActivityTypeAsString
-}
decodeActivityFromString : String -> Maybe NutritionActivity
decodeActivityFromString s =
    case s of
        "nutrition-muac" ->
            Just Muac

        "nutrition-height" ->
            Just Height

        "nutrition-nutrition" ->
            Just Nutrition

        "nutrition-photo" ->
            Just Photo

        "nutrition-weight" ->
            Just Weight

        _ ->
            Nothing


{-| An activity type to use if we need to start somewhere.
-}
defaultActivity : NutritionActivity
defaultActivity =
    Muac


{-| Returns a string representing an icon for the activity, for use in a
"class" attribute.
-}
getActivityIcon : NutritionActivity -> String
getActivityIcon activity =
    case activity of
        Muac ->
            "muac"

        Height ->
            "height"

        Nutrition ->
            "nutrition"

        Photo ->
            "photo"

        Weight ->
            "weight"


getAllActivities : Bool -> List NutritionActivity
getAllActivities isChw =
    if isChw then
        [ Muac, Nutrition, Weight, Photo ]

    else
        [ Height, Muac, Nutrition, Weight, Photo ]