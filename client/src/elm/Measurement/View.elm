module Measurement.View
    exposing
        ( viewChild
        , viewMother
        , muacIndication
        , viewMuacIndication
        )

import Activity.Encoder exposing (encodeChildNutritionSign)
import Activity.Model
    exposing
        ( ActivityType(..)
        , ChildActivityType(..)
        , ChildNutritionSign(..)
        , FamilyPlanningSign(..)
        , ChildActivityType(..)
        , MotherActivityType(..)
        )
import Child.Model exposing (Child, ChildId)
import EverySet exposing (EverySet)
import Examination.Model exposing (ExaminationChild)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (on, onClick, onInput, onWithOptions)
import Maybe.Extra exposing (isJust)
import Measurement.Model
    exposing
        ( FileId
        , FloatInput
        , FloatMeasurements(..)
        , Model
        , MuacIndication(..)
        , Msg(..)
        , Photo
        , PhotoId
        , getInputConstraintsHeight
        , getInputConstraintsMuac
        , getInputConstraintsWeight
        )
import RemoteData exposing (RemoteData(..), isFailure, isLoading)
import Translate as Trans exposing (Language(..), TranslationId, translate)
import Utils.Html exposing (divider, emptyNode, showIf, showMaybe)


viewChild : Language -> ( ChildId, Child ) -> Maybe ExaminationChild -> Maybe ActivityType -> Model -> Html Msg
viewChild language ( childId, child ) maybePreviousExamination selectedActivity model =
    showMaybe <|
        Maybe.map
            (\activity ->
                case activity of
                    Child childActivity ->
                        case childActivity of
                            ChildPicture ->
                                viewPhoto language ( childId, child ) model

                            Height ->
                                viewFloatForm language HeightFloat ( childId, child ) maybePreviousExamination model

                            Muac ->
                                viewFloatForm language MuacFloat ( childId, child ) maybePreviousExamination model

                            NutritionSigns ->
                                viewNutritionSigns language ( childId, child ) model

                            Weight ->
                                viewFloatForm language WeightFloat ( childId, child ) maybePreviousExamination model

                            _ ->
                                emptyNode

                    _ ->
                        emptyNode
            )
            selectedActivity


viewFloatForm : Language -> FloatMeasurements -> ( ChildId, Child ) -> Maybe ExaminationChild -> Model -> Html Msg
viewFloatForm language floatMeasurement ( childId, child ) maybePreviousExamination model =
    let
        ( blockName, headerText, helpText, labelText, placeholderText, constraints, measurementValue, measurementType, ( updateMsg, saveMsg ) ) =
            case floatMeasurement of
                HeightFloat ->
                    ( "height"
                    , Trans.ActivitiesHeightTitle
                    , Trans.ActivitiesHeightHelp
                    , Trans.ActivitiesHeightLabel
                    , Trans.PlaceholderEnterHeight
                    , getInputConstraintsHeight
                    , model.height
                    , Trans.CentimeterShorthand
                    , ( HeightUpdate, HeightSave )
                    )

                MuacFloat ->
                    ( "muac"
                    , Trans.ActivitiesMuacTitle
                    , Trans.ActivitiesMuacHelp
                    , Trans.ActivitiesMuacLabel
                    , Trans.PlaceholderEnterMUAC
                    , getInputConstraintsMuac
                    , model.muac
                    , Trans.CentimeterShorthand
                    , ( MuacUpdate, MuacSave )
                    )

                WeightFloat ->
                    ( "weight"
                    , Trans.ActivitiesWeightTitle
                    , Trans.ActivitiesWeightHelp
                    , Trans.ActivitiesWeightLabel
                    , Trans.PlaceholderEnterWeight
                    , getInputConstraintsWeight
                    , model.weight
                    , Trans.KilogramShorthand
                    , ( WeightUpdate, WeightSave )
                    )

        viewDiff =
            case ( floatMeasurement, measurementValue ) of
                ( MuacFloat, Just value ) ->
                    viewMuacIndication language (muacIndication value)

                _ ->
                    viewFloatDiff language floatMeasurement maybePreviousExamination measurementType model

        defaultAttr =
            Maybe.map (\val -> [ value <| toString val ]) measurementValue
                |> Maybe.withDefault []

        inputAttrs =
            [ type_ "text"
            , placeholder <| translate language placeholderText
            , name blockName
            , Attr.min <| toString constraints.minVal
            , Attr.max <| toString constraints.maxVal
            , onInput <| (\v -> updateMsg <| Result.withDefault 0.0 <| String.toFloat v)
            ]
                ++ defaultAttr
    in
        div
            [ class <| "ui full segment " ++ blockName ]
            [ div [ class "content" ]
                [ h3
                    [ class "ui header" ]
                    [ text <| translate language headerText
                    ]
                , p
                    []
                    [ text <| translate language helpText ]
                , div
                    [ class "ui form" ]
                    [ div [ class "ui grid" ]
                        [ div [ class "eleven wide column" ]
                            [ div [ class "ui right labeled input" ]
                                [ input inputAttrs []
                                , div [ class "ui basic label" ] [ text <| translate language measurementType ]
                                ]
                            ]
                        , div [ class "five wide column" ] [ viewDiff ]
                        ]
                    , viewPreviousMeasurement language floatMeasurement maybePreviousExamination measurementType
                    ]
                , div
                    [ class "ui large header" ]
                    [ text <| translate language Trans.ZScore
                    , span
                        [ class "sub header" ]
                        [ text "Requires implementation" ]
                    ]
                ]
            , div
                [ class "actions" ]
              <|
                saveButton
                    language
                    saveMsg
                    model
                    (isJust measurementValue)
                    Nothing
            ]


{-| Given a MUAC in cm, classify according to the measurement tool shown
at <https://github.com/Gizra/ihangane/issues/282>
-}
muacIndication : Float -> MuacIndication
muacIndication value =
    if value <= 11.5 then
        MuacRed
    else if value <= 12.5 then
        MuacYellow
    else
        MuacGreen


muacColor : MuacIndication -> Attribute any
muacColor muac =
    class <|
        case muac of
            MuacRed ->
                "label-red"

            MuacYellow ->
                "label-yellow"

            MuacGreen ->
                "label-green"


viewMuacIndication : Language -> MuacIndication -> Html any
viewMuacIndication language muac =
    p
        [ muacColor muac
        , class "label-form"
        ]
        [ translate language (Trans.MuacIndication muac)
            |> String.toUpper
            |> text
        ]


{-| Show a photo thumbnail, if it exists.
-}
viewPhotoThumb : ( Maybe FileId, Maybe ( PhotoId, Photo ) ) -> Html Msg
viewPhotoThumb maybePhoto =
    showMaybe <|
        Maybe.map
            (\( _, photo ) ->
                div []
                    [ img [ src photo.url, class "ui small image" ] []
                    ]
            )
            (Tuple.second maybePhoto)


viewPreviousMeasurement : Language -> FloatMeasurements -> Maybe ExaminationChild -> TranslationId -> Html Msg
viewPreviousMeasurement language floatMeasurement maybePreviousExamination measurementType =
    case maybePreviousExamination of
        Nothing ->
            emptyNode

        Just previousExamination ->
            let
                maybePreviousValue =
                    case floatMeasurement of
                        HeightFloat ->
                            previousExamination.height

                        MuacFloat ->
                            previousExamination.muac

                        WeightFloat ->
                            previousExamination.weight
            in
                Maybe.map
                    (\previousValue ->
                        div []
                            [ text <|
                                (translate language <| Trans.PreviousFloatMeasurement previousValue)
                                    ++ " "
                                    ++ (translate language measurementType)
                            ]
                    )
                    maybePreviousValue
                    |> Maybe.withDefault emptyNode


{-| Show a diff of values, if they were gained or lost.
-}
viewFloatDiff : Language -> FloatMeasurements -> Maybe ExaminationChild -> TranslationId -> Model -> Html Msg
viewFloatDiff language floatMeasurement maybePreviousExamination measurementType model =
    let
        maybePreviousValue =
            case maybePreviousExamination of
                Just previousExamination ->
                    case floatMeasurement of
                        HeightFloat ->
                            previousExamination.height

                        MuacFloat ->
                            previousExamination.muac

                        WeightFloat ->
                            previousExamination.weight

                Nothing ->
                    Nothing

        maybeCurrentValue =
            case floatMeasurement of
                HeightFloat ->
                    model.height

                MuacFloat ->
                    model.muac

                WeightFloat ->
                    model.weight
    in
        case ( maybePreviousValue, maybeCurrentValue ) of
            ( Just previousValue, Just currentValue ) ->
                let
                    diff =
                        toString <| abs (currentValue - previousValue)

                    viewMessage isGain =
                        let
                            classSuffix =
                                if isGain then
                                    "up"
                                else
                                    "down"
                        in
                            p
                                [ class <| "label-with-icon label-form" ]
                                [ span [ class <| "icon-" ++ classSuffix ] []
                                , text <| diff ++ " " ++ translate language measurementType
                                ]
                in
                    if currentValue == previousValue then
                        -- No change in the values.
                        emptyNode
                    else if currentValue > previousValue then
                        viewMessage True
                    else
                        viewMessage False

            _ ->
                emptyNode


viewPhoto : Language -> ( ChildId, Child ) -> Model -> Html Msg
viewPhoto language ( childId, child ) model =
    let
        hasFileId =
            isJust <| Tuple.first model.photo

        handleClick =
            if hasFileId then
                [ onClick ResetDropZone ]
            else
                []
    in
        div
            [ class "ui full segment photo" ]
            [ div [ class "content" ]
                [ h3 [ class "ui header" ]
                    [ text <| translate language Trans.ActivitiesPhotoTitle ]
                , p [] [ text <| translate language Trans.ActivitiesPhotoHelp ]
                , viewPhotoThumb model.photo
                , div [ class "dropzone" ] []
                ]
            , div [ class "actions" ] <|
                saveButton language PhotoSave model hasFileId (Just "column")
            ]


{-| Helper function to create a Save button.

Button will also take care of preventing double submission,
and showing success and error indications.

-}
saveButton : Language -> Msg -> Model -> Bool -> Maybe String -> List (Html Msg)
saveButton language msg model hasInput maybeDivClass =
    let
        isLoading =
            model.status == Loading

        isSuccess =
            RemoteData.isSuccess model.status

        isFailure =
            RemoteData.isFailure model.status

        saveAttr =
            if isLoading || not hasInput then
                []
            else
                [ onClick msg ]
    in
        [ button
            ([ classList
                [ ( "ui fluid primary button", True )
                , ( "loading", isLoading )
                , ( "negative", isFailure )
                , ( "disabled", not hasInput )
                ]
             , id "save-form"
             ]
                ++ saveAttr
            )
            [ text <| translate language Trans.Save
            ]
        , showIf isFailure <| div [] [ text <| translate language Trans.SaveError ]
        ]


viewNutritionSigns : Language -> ( ChildId, Child ) -> Model -> Html Msg
viewNutritionSigns language ( childId, child ) model =
    div
        [ class "ui full segment nutrition"
        , id "nutritionSignsEntryForm"
        ]
        [ div [ class "content" ]
            [ h3 [ class "ui header" ]
                [ text <| translate language Trans.ActivitiesNutritionSignsTitle
                ]
            , p [] [ text <| translate language Trans.ActivitiesNutritionSignsHelp ]
            , div [ class "ui form" ] <|
                p [] [ text <| translate language Trans.ActivitiesNutritionSignsLabel ]
                    :: viewNutritionSignsSelector language model.nutritionSigns
            ]
        , div [ class "actions" ] <|
            saveButton
                language
                NutritionSignsSave
                model
                (not (EverySet.isEmpty model.nutritionSigns))
                Nothing
        ]


viewNutritionSignsSelector : Language -> EverySet ChildNutritionSign -> List (Html Msg)
viewNutritionSignsSelector language nutritionSigns =
    let
        nutrionSignsAndTranslationIdsFirst =
            [ Edema, AbdominalDisortion, DrySkin ]

        nutrionSignsAndTranslationIdsSecond =
            [ Apathy, PoorAppetite, BrittleHair ]
    in
        [ div [ class "ui grid" ]
            [ div [ class "eight wide column" ]
                (List.map
                    (viewNutritionSignsSelectorItem language nutritionSigns)
                    nutrionSignsAndTranslationIdsFirst
                )
            , div [ class "eight wide column" ]
                (List.map
                    (viewNutritionSignsSelectorItem language nutritionSigns)
                    nutrionSignsAndTranslationIdsSecond
                )
            ]
        , div [ class "ui divider" ] []
        , viewNutritionSignsSelectorItem language nutritionSigns None
        ]


{-| Helper function to return a tuples of checkbox label and attributes value.

For each nutrition sign the function will return a the translaed label of the
checkbox and a value for the id and for attributes.

-}
viewNutritionSignsSelectorItem : Language -> EverySet ChildNutritionSign -> ChildNutritionSign -> Html Msg
viewNutritionSignsSelectorItem language nutritionSigns sign =
    let
        ( body, attributeValue ) =
            case sign of
                Edema ->
                    ( Trans.ActivitiesNutritionSignsEdemaLabel, "edema" )

                AbdominalDisortion ->
                    ( Trans.ActivitiesNutritionSignsAbdominalDisortionLabel, "abdominal-distrortion" )

                DrySkin ->
                    ( Trans.ActivitiesNutritionSignsDrySkinLabel, "dry-skin" )

                PoorAppetite ->
                    ( Trans.ActivitiesNutritionSignsPoorAppetiteLabel, "poor-appetites" )

                Apathy ->
                    ( Trans.ActivitiesNutritionSignsApathyLabel, "apathy" )

                BrittleHair ->
                    ( Trans.ActivitiesNutritionSignsBrittleHairLabel, "brittle-hair" )

                None ->
                    ( Trans.ActivitiesNutritionSignsNoneLabel, "none-of-these" )
    in
        div [ class "ui checkbox" ]
            [ input
                [ type_ "checkbox"
                , id attributeValue
                , name <| encodeChildNutritionSign sign
                , onClick <| NutritionSignsToggle sign
                , checked <| EverySet.member sign nutritionSigns
                ]
                []
            , label [ for attributeValue ]
                [ text <| translate language body ]
            ]


viewMother : Language -> Maybe ActivityType -> Model -> Html Msg
viewMother language selectedActivity model =
    showMaybe <|
        Maybe.map
            (\activity ->
                case activity of
                    Mother motherActivity ->
                        case motherActivity of
                            FamilyPlanning ->
                                viewFamilyPlanning language model

                    _ ->
                        emptyNode
            )
            selectedActivity


viewFamilyPlanning : Language -> Model -> Html Msg
viewFamilyPlanning language model =
    div
        [ class "ui full segment family-planning"
        , id "familyPlanningEntryForm"
        ]
        [ div [ class "content" ]
            [ h3
                [ class "ui header" ]
                [ text <| translate language Trans.ActivitiesFamilyPlanningSignsTitle
                ]
            , p [] [ text <| translate language Trans.ActivitiesFamilyPlanningSignsHelp ]
            , div [ class "ui form" ] <|
                p [] [ text <| translate language Trans.ActivitiesFamilyPlanningSignsLabel ]
                    :: viewFamilyPlanningSelector language model.familyPlanningSigns
            ]
        , div [ class "actions" ] <|
            saveButton language FamilyPlanningSignsSave model (not (EverySet.isEmpty model.familyPlanningSigns)) Nothing
        ]


viewFamilyPlanningSelector : Language -> EverySet FamilyPlanningSign -> List (Html Msg)
viewFamilyPlanningSelector language familyPlanningSigns =
    let
        familyPlanningSignFirst =
            [ Pill, Condoms, IUD ]

        familyPlanningSignSecond =
            [ Injection, Necklace ]
    in
        [ div [ class "ui grid" ]
            [ div [ class "eight wide column" ] <|
                List.map
                    (viewFamilyPlanningSelectorItem language familyPlanningSigns)
                    familyPlanningSignFirst
            , div [ class "eight wide column" ] <|
                List.map
                    (viewFamilyPlanningSelectorItem language familyPlanningSigns)
                    familyPlanningSignSecond
            ]
        , div [ class "ui divider" ] []
        , viewFamilyPlanningSelectorItem language familyPlanningSigns NoFamilyPlanning
        ]


viewFamilyPlanningSelectorItem : Language -> EverySet FamilyPlanningSign -> FamilyPlanningSign -> Html Msg
viewFamilyPlanningSelectorItem language familyPlanningSigns sign =
    let
        ( body, attributeValue ) =
            case sign of
                Condoms ->
                    ( Trans.ActivitiesFamilyPlanningSignsCondomsLabel, "condoms" )

                IUD ->
                    ( Trans.ActivitiesFamilyPlanningSignsIUDLabel, "iud" )

                Injection ->
                    ( Trans.ActivitiesFamilyPlanningSignsInjectionLabel, "injection" )

                Necklace ->
                    ( Trans.ActivitiesFamilyPlanningSignsNecklaceLabel, "necklace" )

                NoFamilyPlanning ->
                    ( Trans.ActivitiesFamilyPlanningSignsNoneLabel, "no-family-planning-sign" )

                Pill ->
                    ( Trans.ActivitiesFamilyPlanningSignsPillLabel, "pill" )
    in
        div [ class "ui checkbox" ]
            [ input
                [ type_ "checkbox"
                , id attributeValue

                --, name <| encodeChildNutritionSign sign
                , onClick <| FamilyPlanningSignsToggle sign
                , checked <| EverySet.member sign familyPlanningSigns
                ]
                []
            , label [ for attributeValue ]
                [ text <| translate language body ]
            ]
