module Pages.Dashboard.Model exposing
    ( Card
    , CardValueSeverity(..)
    , FamilyPlanningSignsCounter
    , FilterCharts(..)
    , FilterGender(..)
    , FilterPeriod(..)
    , FilterType(..)
    , Model
    , Msg(..)
    , StatsCard
    , emptyModel
    , filterCharts
    , filterGenders
    , filterPeriods
    , filterPeriodsForStatsPage
    )

{-| Filtering by period
-}

import AssocList exposing (Dict)
import Backend.Measurement.Model exposing (FamilyPlanningSign)
import Backend.Person.Model exposing (Gender)
import Gizra.NominalDate exposing (NominalDate)
import Pages.Page exposing (DashboardPage(..), Page(..))


type FilterPeriod
    = ThisMonth
    | LastMonth
    | ThreeMonths
    | OneYear


filterPeriods : List FilterPeriod
filterPeriods =
    [ OneYear ]


filterPeriodsForStatsPage : List FilterPeriod
filterPeriodsForStatsPage =
    [ ThisMonth
    , LastMonth
    ]


{-| We don't use the existing `Gender`, as we want to have an `All` option as-well
-}
type FilterGender
    = Boys
    | Girls


filterGenders : List FilterGender
filterGenders =
    [ Boys
    , Girls
    ]


{-| Define the charts filters.
-}
type FilterCharts
    = Stunting
    | Underweight
    | Wasting
    | MUAC


filterCharts : List FilterCharts
filterCharts =
    [ Stunting
    , Underweight
    , Wasting
    , MUAC
    ]


type alias ParticipantStats =
    { name : String
    , gender : Gender
    , birthDate : NominalDate
    , motherName : String
    , phoneNumber : Maybe String
    , dates : List NominalDate
    }


type alias Model =
    { period : FilterPeriod
    , beneficiariesGender : FilterGender
    , currentTotalChartsFilter : FilterCharts
    , currentTotalIncidenceChartsFilter : FilterCharts
    , currentCaseManagementFilter : FilterCharts
    , latestPage : DashboardPage
    , modalTable : List ParticipantStats
    , modalTitle : String
    , modalState : Bool
    }


emptyModel : Model
emptyModel =
    { period = OneYear
    , beneficiariesGender = Boys
    , currentTotalChartsFilter = Stunting
    , currentTotalIncidenceChartsFilter = Stunting
    , currentCaseManagementFilter = Stunting
    , latestPage = MainPage
    , modalTable = []
    , modalTitle = ""
    , modalState = False
    }


{-| A record to hold the count of total signs used.
-}
type alias FamilyPlanningSignsCounter =
    Dict FamilyPlanningSign Int


{-| This will define what color the `value` from a `Card` will appear in.
-}
type CardValueSeverity
    = Neutral
    | Good
    | Moderate
    | Severe


{-| A `Card` that will appear in the dashboard.
-}
type alias Card =
    { title : String
    , value : Int
    , valueSeverity : CardValueSeverity
    }


{-| A `Stat Card` that will appear in the dashboard and display a certain statistic with difference from last year.
-}
type alias StatsCard =
    { title : String
    , cardClasses : String
    , cardAction : Maybe Msg
    , value : Int
    , valueSeverity : CardValueSeverity
    , valueIsPercentage : Bool
    , previousPercentage : Int
    , previousPercentageLabel : FilterPeriod
    , newCases : Maybe Int
    }


type FilterType
    = FilterTotalsChart
    | FilterCaseManagement


type Msg
    = ModalToggle Bool (List ParticipantStats) String
    | SetFilterGender FilterGender
    | SetFilterPeriod FilterPeriod
    | SetFilterTotalsChart FilterCharts
    | SetFilterCaseManagement FilterCharts
    | SetActivePage Page
