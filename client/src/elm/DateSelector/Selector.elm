module DateSelector.Selector exposing
    ( view
    , viewPopup
    )

{-| Create a user interface for selecting dates.

@docs view

-}

import Date exposing (Date, Interval(..), Unit(..), day, month, numberToMonth, year)
import Gizra.NominalDate exposing (allMonths)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode
import Json.Encode
import Maybe.Extra exposing (isNothing)
import Time exposing (Month(..), Weekday(..))
import Translate exposing (Language, translate)


viewPopup : Language -> Date -> Date -> Maybe Date -> Html Date
viewPopup language minimum maximum maybeSelected =
    let
        yearSection =
            div [ class "year" ]
                [ p [] [ text <| translate language Translate.Year ]
                , viewYearSelectList minimum maximum maybeSelected
                ]

        monthSection =
            div [ class "month" ] <|
                p [] [ text <| translate language Translate.Month ]
                    :: [ Maybe.map (viewMonthSelectList language minimum maximum) maybeSelected
                            |> Maybe.withDefault viewMonthSelectListDisabled
                       ]

        daysSection =
            div [ class "days" ]
                [ Maybe.map (viewDateTable minimum maximum) maybeSelected
                    |> Maybe.withDefault (viewDateTableDisabled minimum)
                ]
    in
    div [ class "calendar" ]
        [ yearSection
        , monthSection
        , daysSection
        ]
        |> Html.map (Date.clamp minimum maximum)


viewYearSelectList : Date -> Date -> Maybe Date -> Html Date
viewYearSelectList minimum maximum maybeSelected =
    let
        isInvertedMinMax =
            Date.compare minimum maximum == GT

        years =
            if isInvertedMinMax then
                [ maybeSelected |> Maybe.withDefault minimum |> year ]

            else
                List.range (year minimum) (year maximum)

        options_ =
            List.reverse years
                |> List.map
                    (\year ->
                        option
                            [ value <| String.fromInt year
                            , selected <| isSelectedYear year
                            ]
                            [ text <| String.fromInt year ]
                    )

        options =
            if isNothing maybeSelected then
                option
                    [ value ""
                    , selected True
                    ]
                    [ text "" ]
                    :: options_

            else
                options_

        isSelectedYear =
            Maybe.map (\selected -> (==) (year selected)) maybeSelected
                |> Maybe.withDefault (always False)
    in
    select
        [ on "input" <|
            Json.Decode.map
                (\s ->
                    let
                        selectedYear =
                            String.toInt s
                                |> -- We'll never get here, as we place only
                                   -- valid numeric values at select options.
                                   Maybe.withDefault 2000
                    in
                    dateWithYear (Maybe.withDefault (Date.fromCalendarDate (year minimum) Jan 1) maybeSelected) selectedYear
                )
                (Json.Decode.at [ "target", "value" ] Json.Decode.string)
        , class "form-input select"
        ]
        options


viewMonthSelectList : Language -> Date -> Date -> Date -> Html Date
viewMonthSelectList language minimum maximum selectedDate =
    let
        isInvertedMinMax =
            Date.compare minimum maximum == GT

        first =
            if year selectedDate == year minimum then
                Date.monthNumber minimum

            else
                1

        last =
            if year selectedDate == year maximum then
                Date.monthNumber maximum

            else
                12

        months =
            if isInvertedMinMax then
                []

            else
                List.filter
                    (\month ->
                        let
                            monthNumber =
                                Date.monthToNumber month
                        in
                        monthNumber >= first && monthNumber <= last
                    )
                    allMonths

        options =
            List.map
                (\month ->
                    let
                        monthNumber =
                            Date.monthToNumber month
                    in
                    option
                        [ value <| String.fromInt monthNumber
                        , selected <| Date.monthNumber selectedDate == monthNumber
                        ]
                        [ text <| translate language <| Translate.ResolveMonth False month ]
                )
                months
    in
    select
        [ on "input" <|
            Json.Decode.map
                (\s ->
                    let
                        selectedMonths =
                            String.toInt s
                                |> -- We'll never get here, as we place only
                                   -- valid numeric values at select options.
                                   Maybe.withDefault 1
                    in
                    numberToMonth selectedMonths
                        |> dateWithMonth selectedDate
                )
                (Json.Decode.at [ "target", "value" ] Json.Decode.string)
        ]
        options


viewMonthSelectListDisabled : Html a
viewMonthSelectListDisabled =
    select [] [ option [ value "" ] [ text "" ] ]


groupsOf : Int -> List a -> List (List a)
groupsOf n list =
    if List.isEmpty list then
        []

    else
        List.take n list :: groupsOf n (List.drop n list)


isBetween : comparable -> comparable -> comparable -> Bool
isBetween a b x =
    a <= x && x <= b || b <= x && x <= a


monthDates : Int -> Month -> List Date
monthDates y m =
    let
        start =
            Date.floor Monday <| Date.fromCalendarDate y m 1
    in
    Date.range Day 1 start <| Date.add Days 42 start


dateWithYear : Date -> Int -> Date
dateWithYear date y =
    let
        m =
            month date

        d =
            day date
    in
    if m == Feb && d == 29 && not (isLeapYear y) then
        Date.fromCalendarDate y Feb 28

    else
        Date.fromCalendarDate y m d


dateWithMonth : Date -> Month -> Date
dateWithMonth date m =
    let
        y =
            year date

        d =
            day date
    in
    Date.fromCalendarDate y m <| Basics.min d (daysInMonth y m)


isLeapYear : Int -> Bool
isLeapYear y =
    modBy 4 y == 0 && modBy 100 y /= 0 || modBy 400 y == 0


daysInMonth : Int -> Month -> Int
daysInMonth y m =
    case m of
        Jan ->
            31

        Feb ->
            if isLeapYear y then
                29

            else
                28

        Mar ->
            31

        Apr ->
            30

        May ->
            31

        Jun ->
            30

        Jul ->
            31

        Aug ->
            31

        Sep ->
            30

        Oct ->
            31

        Nov ->
            30

        Dec ->
            31



-- view


type State
    = Normal
    | Dimmed
    | Disabled
    | Selected


isSelectable : State -> Bool
isSelectable state =
    state == Normal || state == Dimmed


classNameFromState : State -> String
classNameFromState state =
    case state of
        Normal ->
            ""

        Dimmed ->
            "date-selector--dimmed"

        Disabled ->
            "date-selector--disabled"

        Selected ->
            "date-selector--selected"


{-| Create a date selector by providing the minimum and maximum selectable
dates, and a selected date if there is one.

    DateSelector.view
        minimum
        maximum
        selected

The resulting `Html` produces `Date` messages when the user selects a date. The
`Date` values produced will always be within the bounds provided.

-}
view : Date -> Date -> Maybe Date -> Html Date
view minimum maximum maybeSelected =
    div
        [ classList
            [ ( "date-selector", True )
            , ( "date-selector--scrollable-year", year maximum - year minimum >= 12 )
            ]
        ]
        [ div []
            [ viewYearList minimum maximum maybeSelected ]
        , div []
            [ maybeSelected
                |> Maybe.map (viewMonthList minimum maximum)
                |> Maybe.withDefault viewMonthListDisabled
            ]
        , div []
            [ case maybeSelected of
                Just selected ->
                    viewDateTable minimum maximum selected

                Nothing ->
                    viewDateTableDisabled minimum
            ]
        ]
        |> Html.map (Date.clamp minimum maximum)


viewYearList : Date -> Date -> Maybe Date -> Html Date
viewYearList minimum maximum maybeSelected =
    let
        isInvertedMinMax =
            Date.compare minimum maximum == GT

        years =
            if isInvertedMinMax then
                [ maybeSelected |> Maybe.withDefault minimum |> year ]

            else
                List.range (year minimum) (year maximum)

        isSelectedYear : Int -> Bool
        isSelectedYear =
            maybeSelected
                |> Maybe.map (\selected -> (==) (year selected))
                |> Maybe.withDefault (\_ -> False)
    in
    ol
        [ on "click" <|
            Json.Decode.map
                (dateWithYear (maybeSelected |> Maybe.withDefault (Date.fromCalendarDate (year minimum) Jan 1)))
                (Json.Decode.at [ "target", "year" ] Json.Decode.int)
        ]
        (years
            |> List.reverse
            |> List.map
                (\y ->
                    let
                        state =
                            if isSelectedYear y then
                                Selected

                            else if isInvertedMinMax then
                                Disabled

                            else
                                Normal
                    in
                    li
                        [ class <| classNameFromState state
                        , property "year" <|
                            if isSelectable state then
                                Json.Encode.int y

                            else
                                Json.Encode.null
                        ]
                        [ text (String.fromInt y) ]
                )
        )


monthNames : List String
monthNames =
    [ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" ]


viewMonthList : Date -> Date -> Date -> Html Date
viewMonthList minimum maximum selected =
    let
        isInvertedMinMax =
            Date.compare minimum maximum == GT

        first =
            if year selected == year minimum then
                Date.monthNumber minimum

            else
                1

        last =
            if year selected == year maximum then
                Date.monthNumber maximum

            else
                12
    in
    ol
        [ on "click" <|
            Json.Decode.map
                (dateWithMonth selected << numberToMonth)
                (Json.Decode.at [ "target", "monthNumber" ] Json.Decode.int)
        ]
        (monthNames
            |> List.indexedMap
                (\i name ->
                    let
                        n =
                            i + 1

                        state =
                            if n == Date.monthNumber selected then
                                Selected

                            else if not (isBetween first last n) || isInvertedMinMax then
                                Disabled

                            else
                                Normal
                    in
                    li
                        [ class <| classNameFromState state
                        , property "monthNumber" <|
                            if isSelectable state then
                                Json.Encode.int n

                            else
                                Json.Encode.null
                        ]
                        [ text name ]
                )
        )


viewMonthListDisabled : Html a
viewMonthListDisabled =
    ol []
        (monthNames
            |> List.map
                (\name ->
                    li
                        [ class <| classNameFromState Disabled ]
                        [ text name ]
                )
        )


dayOfWeekNames : List String
dayOfWeekNames =
    [ "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" ]


viewDayOfWeekHeader : Html a
viewDayOfWeekHeader =
    thead []
        [ tr []
            (dayOfWeekNames
                |> List.map
                    (\name ->
                        th [] [ text name ]
                    )
            )
        ]


viewDateTable : Date -> Date -> Date -> Html Date
viewDateTable minimum maximum selected =
    let
        isInvertedMinMax =
            Date.compare minimum maximum == GT

        weeks =
            monthDates (year selected) (month selected) |> groupsOf 7
    in
    table []
        [ viewDayOfWeekHeader
        , tbody
            [ on "click" <|
                Json.Decode.map
                    Date.fromRataDie
                    (Json.Decode.at [ "target", "time" ] Json.Decode.int)
            ]
            (weeks
                |> List.map
                    (\week ->
                        tr []
                            (week
                                |> List.map
                                    (\date ->
                                        let
                                            equalByDay date1 date2 =
                                                (day date1 == day date2)
                                                    && (month date1 == month date2)
                                                    && (year date1 == year date2)

                                            state =
                                                if equalByDay date selected then
                                                    Selected

                                                else if not (Date.isBetween minimum maximum date) || isInvertedMinMax then
                                                    Disabled

                                                else if month date /= month selected then
                                                    Dimmed

                                                else
                                                    Normal
                                        in
                                        td
                                            [ class <| classNameFromState state
                                            , property "time" <|
                                                if isSelectable state then
                                                    Json.Encode.int (Date.toRataDie date)

                                                else
                                                    Json.Encode.null
                                            ]
                                            [ text (day date |> String.fromInt) ]
                                    )
                            )
                    )
            )
        ]


viewDateTableDisabled : Date -> Html a
viewDateTableDisabled date =
    let
        weeks =
            monthDates (year date) (month date) |> groupsOf 7

        disabled =
            classNameFromState Disabled
    in
    table []
        [ viewDayOfWeekHeader
        , tbody []
            (weeks
                |> List.map
                    (\week ->
                        tr []
                            (week
                                |> List.map
                                    (\date_ ->
                                        td
                                            [ class disabled ]
                                            [ text (day date_ |> String.fromInt) ]
                                    )
                            )
                    )
            )
        ]
