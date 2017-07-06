module Pages.Patients.View exposing (view)

import Activity.Model exposing (ActivityType)
import Activity.Utils exposing (getPendingNumberPerActivity)
import Activity.View exposing (viewActivityTypeFilter)
import App.PageType exposing (Page(..))
import Date exposing (Date)
import Dict
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (on, onClick, onInput, onWithOptions)
import Pages.Patients.Model exposing (Model, Msg(..))
import Patient.Model exposing (Patient, PatientId, PatientType(..), PatientTypeFilter(..), PatientsDict)
import Patient.Utils exposing (getPatientAvatarThumb, getPatientName)
import Patient.View exposing (viewPatientTypeFilter)
import Table exposing (..)
import Translate as Trans exposing (translate, Language)
import User.Model exposing (User)


view : Language -> Date -> User -> PatientsDict -> Model -> Html Msg
view language currentDate currentUser patients model =
    let
        lowerQuery =
            String.toLower model.query

        acceptablePatients =
            Dict.filter
                (\patientId patient ->
                    let
                        validName =
                            String.contains lowerQuery (String.toLower <| getPatientName patient)

                        validType =
                            case model.patientTypeFilter of
                                All ->
                                    True

                                Children ->
                                    case patient.info of
                                        PatientChild _ ->
                                            True

                                        _ ->
                                            False

                                Mothers ->
                                    case patient.info of
                                        PatientMother _ ->
                                            True

                                        _ ->
                                            False

                        validActivityTypeFilter =
                            List.foldl
                                (\activityType accum ->
                                    if
                                        accum == True
                                        -- We already have found an existing pending activity.
                                    then
                                        True
                                    else
                                        getPendingNumberPerActivity currentDate activityType (Dict.insert patientId patient Dict.empty) > 0
                                )
                                False
                                model.activityTypeFilter
                    in
                        validName && validType && validActivityTypeFilter
                )
                patients
                |> Dict.toList

        searchResult =
            if List.isEmpty acceptablePatients then
                if Dict.isEmpty patients then
                    -- No patients are present, so it means we are fethcing
                    -- them.
                    div [] []
                else
                    div [ class "ui segment" ] [ text <| translate language Trans.NoPatientsFound ]
            else
                Table.view config model.tableState acceptablePatients
    in
        div []
            [ h1 [] [ text <| translate language Trans.Patients ]
            , div [ class "ui input" ]
                [ input
                    [ placeholder <| translate language Trans.SearchByName
                    , onInput SetQuery
                    ]
                    []
                , viewPatientTypeFilter language SetPatientTypeFilter model.patientTypeFilter
                ]
            , viewActivityTypeFilterWrapper language model.patientTypeFilter model.activityTypeFilter
            , searchResult
            ]


viewActivityTypeFilterWrapper : Language -> PatientTypeFilter -> List ActivityType -> Html Msg
viewActivityTypeFilterWrapper language patientTypeFilter activityTypeFilter =
    let
        childTypeFilters =
            [ div [ class "six wide column" ]
                [ h3 [] [ text <| translate language Trans.Children ]
                , viewActivityTypeFilter SetActivityTypeFilter Children activityTypeFilter
                ]
            ]

        motherTypeFilters =
            [ div [ class "six wide column" ]
                [ h3 [] [ text <| translate language Trans.Mothers ]
                , viewActivityTypeFilter SetActivityTypeFilter Mothers activityTypeFilter
                ]
            ]

        wrapperClasses =
            class "ui grid activity-type-filter"
    in
        case patientTypeFilter of
            All ->
                div [ wrapperClasses ] (childTypeFilters ++ motherTypeFilters)

            Children ->
                div [ wrapperClasses ] childTypeFilters

            Mothers ->
                div [ wrapperClasses ] motherTypeFilters


config : Table.Config ( PatientId, Patient ) Msg
config =
    Table.customConfig
        { toId = \( patientId, _ ) -> patientId
        , toMsg = SetTableState
        , columns =
            [ Table.veryCustomColumn
                { name = "Name"
                , viewData =
                    \( patientId, patient ) ->
                        Table.HtmlDetails []
                            [ a [ href "#", onClick <| SetRedirectPage <| App.PageType.Patient patientId ]
                                [ img [ src <| getPatientAvatarThumb patient, class "ui avatar image" ] []
                                , text <| getPatientName patient
                                ]
                            ]
                , sorter = Table.increasingOrDecreasingBy <| Tuple.second >> getPatientName
                }
            ]
        , customizations = { defaultCustomizations | tableAttrs = [ class "ui celled table" ] }
        }