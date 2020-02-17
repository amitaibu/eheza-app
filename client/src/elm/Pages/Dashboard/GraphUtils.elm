module Pages.Dashboard.GraphUtils exposing (barChartHeight, barChartWidth, colors, column, familyPlanningSignToColor, gridXScale, gridYScale, padding, pieChartHeight, pieChartWidth, radius, xAxis, xGridLine, xScale, yAxis, yGridLine, yScale)

import AssocList as Dict exposing (Dict)
import Axis
import Backend.Dashboard.Model exposing (DashboardStats, GoodNutrition, Nutrition, Periods)
import Backend.Measurement.Model exposing (FamilyPlanningSign(..))
import Color exposing (Color)
import Scale exposing (BandConfig, BandScale, ContinuousScale, defaultBandConfig)
import Time exposing (Month(..))
import TypedSvg exposing (g, line, rect)
import TypedSvg.Attributes as Explicit
import TypedSvg.Attributes.InPx exposing (height, rx, ry, strokeWidth, x, x1, x2, y, y1, y2)
import TypedSvg.Core exposing (Svg, attribute)
import TypedSvg.Types exposing (AnchorAlignment(..), Fill(..), Transform(..), percent)


column : BandScale Month -> Float -> ( Month, Nutrition ) -> Svg msg
column scale yScaleMax ( date, nutrition ) =
    g []
        [ g [ Explicit.class [ "column moderate" ] ]
            [ rect
                [ x <| Scale.convert scale date + (Scale.bandwidth scale / 4)
                , y <| Scale.convert (yScale yScaleMax) (toFloat nutrition.moderateNutrition)
                , rx 2
                , ry 2
                , height <| barChartHeight - Scale.convert (yScale yScaleMax) (toFloat nutrition.moderateNutrition) - 2 * padding
                ]
                []
            ]
        , g [ Explicit.class [ "column severe" ] ]
            [ rect
                [ x <| Scale.convert scale date + (Scale.bandwidth scale / 2)
                , y <| Scale.convert (yScale yScaleMax) (toFloat nutrition.severeNutrition)
                , rx 2
                , ry 2
                , height <| barChartHeight - Scale.convert (yScale yScaleMax) (toFloat nutrition.severeNutrition) - 2 * padding
                ]
                []
            ]
        ]


xGridLine : Int -> Float -> Svg msg
xGridLine index tick =
    line
        [ y1 30
        , Explicit.y2 (percent 95)
        , x1 (Scale.convert gridXScale tick)
        , x2 (Scale.convert gridXScale tick)
        , strokeWidth (Basics.max (toFloat (modBy 2 index)) 0.5)
        , attribute "stroke-dasharray" "5,5"
        ]
        []


yGridLine : Int -> Float -> Svg msg
yGridLine index tick =
    line
        [ x1 30
        , Explicit.x2 (percent 100)
        , y1 (Scale.convert gridYScale tick)
        , y2 (Scale.convert gridYScale tick)
        , strokeWidth (Basics.max (toFloat (modBy 2 index)) 0.5)
        , attribute "stroke-dasharray" "5,5"
        ]
        []


padding : Float
padding =
    30


gridXScale : ContinuousScale Float
gridXScale =
    Scale.linear ( padding, barChartWidth - padding ) ( 0, 2 )


gridYScale : ContinuousScale Float
gridYScale =
    Scale.linear ( barChartHeight - padding, padding ) ( 0, 1 )


xScale : List ( Month, Nutrition ) -> BandScale Month
xScale data =
    List.map Tuple.first data
        |> Scale.band { defaultBandConfig | paddingInner = 0.1, paddingOuter = 0.2 } ( 0, barChartWidth - 2 * padding )


yScale : Float -> ContinuousScale Float
yScale yScaleMax =
    Scale.linear ( barChartHeight - 2 * padding, 0 ) ( 0, yScaleMax )


xAxis : List ( Month, Nutrition ) -> Svg msg
xAxis data =
    Axis.bottom [] (Scale.toRenderable Debug.toString (xScale data))


yAxis : Float -> Svg msg
yAxis yScaleMax =
    Axis.left [ Axis.tickCount 5 ] <| yScale yScaleMax


barChartWidth : Float
barChartWidth =
    940


barChartHeight : Float
barChartHeight =
    400


pieChartWidth : Float
pieChartWidth =
    1000


pieChartHeight : Float
pieChartHeight =
    1000


familyPlanningSignToColor : FamilyPlanningSign -> Color
familyPlanningSignToColor sign =
    case sign of
        AutoObservation ->
            Color.blue

        Condoms ->
            Color.lightOrange

        CycleBeads ->
            Color.orange

        CycleCounting ->
            Color.purple

        Hysterectomy ->
            Color.lightPurple

        Implants ->
            Color.black

        Injectables ->
            Color.lightGreen

        NoFamilyPlanning ->
            Color.grey

        IUD ->
            Color.darkGreen

        LactationAmenorrhea ->
            Color.darkOrange

        OralContraceptives ->
            Color.darkPurple

        Spermicide ->
            Color.darkBlue

        TubalLigatures ->
            Color.lightRed

        Vasectomy ->
            Color.lightGreen


colors : Dict FamilyPlanningSign Color
colors =
    Dict.fromList
        [ ( AutoObservation, familyPlanningSignToColor AutoObservation )
        , ( Condoms, familyPlanningSignToColor Condoms )
        , ( CycleBeads, familyPlanningSignToColor CycleBeads )
        , ( CycleCounting, familyPlanningSignToColor CycleCounting )
        , ( Hysterectomy, familyPlanningSignToColor Hysterectomy )
        , ( Implants, familyPlanningSignToColor Implants )
        , ( Injectables, familyPlanningSignToColor Injectables )
        , ( NoFamilyPlanning, familyPlanningSignToColor NoFamilyPlanning )
        , ( IUD, familyPlanningSignToColor IUD )
        , ( LactationAmenorrhea, familyPlanningSignToColor LactationAmenorrhea )
        , ( OralContraceptives, familyPlanningSignToColor OralContraceptives )
        , ( Spermicide, familyPlanningSignToColor Spermicide )
        , ( TubalLigatures, familyPlanningSignToColor TubalLigatures )
        , ( Vasectomy, familyPlanningSignToColor Vasectomy )
        ]


radius : Float
radius =
    min (pieChartWidth / 2) pieChartHeight / 2 - 10
