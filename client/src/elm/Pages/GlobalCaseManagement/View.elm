module Pages.GlobalCaseManagement.View exposing (generateAcuteIllnessFollowUpEntries, generateNutritionFollowUpEntries, generatePrenatalFollowUpEntries, view)

import AssocList as Dict exposing (Dict)
import Backend.AcuteIllnessEncounter.Model exposing (AcuteIllnessDiagnosis(..))
import Backend.Entities exposing (..)
import Backend.IndividualEncounterParticipant.Model exposing (IndividualEncounterType(..))
import Backend.Measurement.Model exposing (FollowUpMeasurements, NutritionAssessment(..), PrenatalAssesment(..))
import Backend.Model exposing (ModelIndexedDb)
import Backend.NutritionEncounter.Utils exposing (sortEncounterTuplesDesc)
import Backend.Person.Model
import Backend.PrenatalEncounter.Model exposing (PrenatalEncounterType(..))
import Backend.Utils exposing (resolveIndividualParticipantForPerson)
import Date exposing (Month, Unit(..), isBetween, numberToMonth)
import EverySet
import Gizra.Html exposing (emptyNode, showMaybe)
import Gizra.NominalDate exposing (NominalDate)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import List.Extra
import Maybe exposing (Maybe)
import Maybe.Extra exposing (isJust, isNothing)
import Pages.AcuteIllnessEncounter.Utils exposing (compareAcuteIllnessEncounterDataDesc)
import Pages.GlobalCaseManagement.Model exposing (..)
import Pages.GlobalCaseManagement.Utils exposing (..)
import Pages.Page exposing (Page(..), UserPage(..))
import Pages.PageNotFound.View
import Pages.PrenatalEncounter.Utils
import RemoteData exposing (RemoteData(..))
import Translate exposing (Language, TranslationId, translate, translateText)
import Utils.Html exposing (spinner, viewModal)
import Utils.WebData exposing (viewWebData)


view : Language -> NominalDate -> ( HealthCenterId, Maybe VillageId ) -> Bool -> Model -> ModelIndexedDb -> Html Msg
view language currentDate ( healthCenterId, maybeVillageId ) isChw model db =
    let
        header =
            div
                [ class "ui basic head segment" ]
                [ h1 [ class "ui header" ]
                    [ translateText language Translate.CaseManagement ]
                , a
                    [ class "link-back"
                    , onClick <| SetActivePage PinCodePage
                    ]
                    [ span [ class "icon-back" ] [] ]
                ]

        followUps =
            Dict.get healthCenterId db.followUpMeasurements
                |> Maybe.withDefault NotAsked

        content =
            if isChw then
                viewWebData language (viewContentForChw language currentDate ( healthCenterId, maybeVillageId ) model db) identity followUps

            else
                viewWebData language (viewContentForNurse language currentDate healthCenterId model db) identity followUps
    in
    div [ class "wrap wrap-alt-2 page-case-management" ]
        [ header
        , content
        , viewModal <|
            viewEntryPopUp language
                currentDate
                model.dialogState
        ]


viewContentForChw : Language -> NominalDate -> ( HealthCenterId, Maybe VillageId ) -> Model -> ModelIndexedDb -> FollowUpMeasurements -> Html Msg
viewContentForChw language currentDate ( healthCenterId, maybeVillageId ) model db followUps =
    Maybe.map
        (\villageId ->
            let
                nutritionFollowUps =
                    generateNutritionFollowUps db followUps
                        |> filterVillageResidents villageId identity db

                nutritionFollowUpsPane =
                    viewNutritionPane language currentDate nutritionFollowUps db model

                acuteIllnessFollowUps =
                    generateAcuteIllnessFollowUps db followUps
                        |> filterVillageResidents villageId Tuple.second db

                acuteIllnessFollowUpsPane =
                    viewAcuteIllnessPane language currentDate acuteIllnessFollowUps db model

                prenatalFollowUps =
                    generatePrenatalFollowUps db followUps
                        |> filterVillageResidents villageId Tuple.second db

                prenatalFollowUpsPane =
                    viewPrenatalPane language currentDate prenatalFollowUps db model

                panes =
                    [ ( AcuteIllnessEncounter, acuteIllnessFollowUpsPane ), ( AntenatalEncounter, prenatalFollowUpsPane ), ( NutritionEncounter, nutritionFollowUpsPane ) ]
                        |> List.filterMap
                            (\( type_, pane ) ->
                                if isNothing model.encounterTypeFilter || model.encounterTypeFilter == Just type_ then
                                    Just pane

                                else
                                    Nothing
                            )
            in
            div [ class "ui unstackable items" ] <|
                viewFilters language model
                    :: panes
        )
        maybeVillageId
        |> Maybe.withDefault (Pages.PageNotFound.View.viewPage language (SetActivePage PinCodePage) (UserPage GlobalCaseManagementPage))


viewContentForNurse : Language -> NominalDate -> HealthCenterId -> Model -> ModelIndexedDb -> FollowUpMeasurements -> Html Msg
viewContentForNurse language currentDate healthCenterId model db followUps =
    text "viewContentForNurse"


viewEntryPopUp : Language -> NominalDate -> Maybe FollowUpEncounterDataType -> Maybe (Html Msg)
viewEntryPopUp language currentDate dialogState =
    dialogState
        |> Maybe.map
            (\dataType ->
                case dataType of
                    FollowUpPrenatal data ->
                        viewStartFollowUpPrenatalEncounterDialog language currentDate data

                    _ ->
                        viewStartFollowUpEncounterDialog language dataType
            )


viewStartFollowUpEncounterDialog : Language -> FollowUpEncounterDataType -> Html Msg
viewStartFollowUpEncounterDialog language dataType =
    let
        ( encounterType, personName ) =
            case dataType of
                FollowUpNutrition data ->
                    ( HomeVisitEncounter, data.personName )

                FollowUpAcuteIllness data ->
                    ( AcuteIllnessEncounter, data.personName )

                -- We should never get here, since Prenatal got
                -- it's own dialog.
                FollowUpPrenatal data ->
                    ( AntenatalEncounter, data.personName )
    in
    div [ class "ui active modal" ]
        [ div [ class "content" ]
            [ text <| translate language <| Translate.EncounterTypeFollowUpQuestion encounterType
            , text " "
            , span [ class "person-name" ] [ text personName ]
            , text "?"
            ]
        , div [ class "actions" ]
            [ div [ class "two ui buttons" ]
                [ button
                    [ class "ui primary fluid button"
                    , onClick <| StartFollowUpEncounter dataType
                    ]
                    [ text <| translate language Translate.Yes ]
                , button
                    [ class "ui fluid button"
                    , onClick <| SetDialogState Nothing
                    ]
                    [ text <| translate language Translate.No ]
                ]
            ]
        ]


viewStartFollowUpPrenatalEncounterDialog : Language -> NominalDate -> FollowUpPrenatalData -> Html Msg
viewStartFollowUpPrenatalEncounterDialog language currentDate data =
    let
        ( content, actions ) =
            if data.dateMeasured == currentDate then
                ( [ text <| translate language Translate.CannotStartEncounterLabel
                  , text " "
                  , span [ class "person-name" ] [ text data.personName ]
                  , text "."
                  ]
                , [ div [ class "two ui buttons" ]
                        [ button
                            [ class "ui primary fluid button"
                            , onClick <| SetDialogState Nothing
                            ]
                            [ text <| translate language Translate.Close ]
                        ]
                  ]
                )

            else
                let
                    subsequentEncounterButton =
                        Pages.PrenatalEncounter.Utils.getSubsequentEncounterType data.encounterType
                            |> Maybe.map
                                (\subsequentEncounterType ->
                                    button
                                        [ class "ui primary fluid stacked button"
                                        , onClick <| StartPrenatalFollowUpEncounter data.participantId data.hasNurseEncounter subsequentEncounterType
                                        ]
                                        [ text <| translate language Translate.SubsequentEncounter ]
                                )
                            |> Maybe.withDefault emptyNode
                in
                ( [ p []
                        [ text <| translate language <| Translate.EncounterTypeFollowUpQuestion AntenatalEncounter
                        , text " "
                        , span [ class "person-name" ] [ text data.personName ]
                        , text "?"
                        ]
                  , subsequentEncounterButton
                  , button
                        [ class "ui primary fluid stacked button"
                        , onClick <| StartPrenatalFollowUpEncounter data.participantId data.hasNurseEncounter ChwPostpartumEncounter
                        ]
                        [ text <| translate language Translate.PostpartumEncounter ]
                  , button
                        [ class "ui primary fluid stacked button"
                        , onClick <| SetDialogState Nothing
                        ]
                        [ text <| translate language Translate.Cancel ]
                  ]
                , []
                )
    in
    div [ class "ui active modal prenatal-follow-up-popup" ]
        [ div [ class "content" ] content
        , div [ class "actions" ] actions
        ]


viewFilters : Language -> Model -> Html Msg
viewFilters language model =
    let
        filters =
            allEncounterTypes
                |> List.map Just
                |> List.append [ Nothing ]

        renderButton maybeFilter =
            let
                label =
                    Maybe.map Translate.EncounterTypeFileterLabel maybeFilter
                        |> Maybe.withDefault Translate.All
            in
            button
                [ classList
                    [ ( "active", model.encounterTypeFilter == maybeFilter )
                    , ( "primary ui button", True )
                    ]
                , onClick <| SetEncounterTypeFilter maybeFilter
                ]
                [ translateText language label ]
    in
    div [ class "ui segment filters" ] <|
        List.map renderButton filters


viewItemHeading : Language -> IndividualEncounterType -> Html Msg
viewItemHeading language encounterType =
    div [ class "pane-heading" ]
        [ text <| translate language <| Translate.EncounterTypeFollowUpLabel encounterType ]


viewNutritionPane : Language -> NominalDate -> Dict PersonId NutritionFollowUpItem -> ModelIndexedDb -> Model -> Html Msg
viewNutritionPane language currentDate itemsDict db model =
    let
        limitDate =
            -- Set limit date for tomorrow, so that we
            -- load all available follow ups.
            Date.add Days 1 currentDate

        entries =
            generateNutritionFollowUpEntries language currentDate limitDate itemsDict db

        content =
            if List.isEmpty entries then
                [ translateText language Translate.NoMatchesFound ]

            else
                List.map (viewNutritionFollowUpEntry language currentDate) entries
    in
    div [ class "pane" ]
        [ viewItemHeading language NutritionEncounter
        , div [ class "pane-content" ] content
        ]


generateNutritionFollowUpEntries : Language -> NominalDate -> NominalDate -> Dict PersonId NutritionFollowUpItem -> ModelIndexedDb -> List NutritionFollowUpEntry
generateNutritionFollowUpEntries language currentDate limitDate itemsDict db =
    Dict.map (generateNutritionFollowUpEntryData language currentDate limitDate db) itemsDict
        |> Dict.values
        |> Maybe.Extra.values


generateNutritionFollowUpEntryData : Language -> NominalDate -> NominalDate -> ModelIndexedDb -> PersonId -> NutritionFollowUpItem -> Maybe NutritionFollowUpEntry
generateNutritionFollowUpEntryData language currentDate limitDate db personId item =
    let
        lastHomeVisitEncounter =
            resolveIndividualParticipantForPerson personId HomeVisitEncounter db
                |> Maybe.map
                    (\participantId ->
                        Dict.get participantId db.homeVisitEncountersByParticipant
                            |> Maybe.andThen RemoteData.toMaybe
                            |> Maybe.map
                                (Dict.values
                                    >> List.filter (\encounter -> Date.compare encounter.startDate limitDate == LT)
                                )
                            |> Maybe.withDefault []
                    )
                |> Maybe.withDefault []
                -- Sort DESC
                |> List.sortWith (\e1 e2 -> Date.compare e2.startDate e1.startDate)
                |> List.head
    in
    lastHomeVisitEncounter
        |> Maybe.map
            (\encounter ->
                -- Last Home Visitit encounter occurred before follow up was scheduled.
                if Date.compare encounter.startDate item.dateMeasured == LT then
                    Just <| NutritionFollowUpEntry personId item

                else
                    Nothing
            )
        |> -- No Home Visitit encounter found.
           Maybe.withDefault
            (Just <| NutritionFollowUpEntry personId item)


viewNutritionFollowUpEntry : Language -> NominalDate -> NutritionFollowUpEntry -> Html Msg
viewNutritionFollowUpEntry language currentDate entry =
    let
        item =
            entry.item

        dueOption =
            followUpDueOptionByDate currentDate item.dateMeasured item.value.options

        assessments =
            EverySet.toList item.value.assesment
                |> List.reverse
                |> List.map (\assessment -> p [] [ translateAssement assessment ])

        translateAssement assessment =
            case assessment of
                AssesmentMalnutritionSigns signs ->
                    let
                        translatedSigns =
                            List.map (Translate.ChildNutritionSignLabel >> translate language) signs
                                |> String.join ", "
                    in
                    text <| translate language (Translate.NutritionAssessment assessment) ++ ": " ++ translatedSigns

                _ ->
                    text <| translate language <| Translate.NutritionAssessment assessment

        popupData =
            FollowUpNutrition <| FollowUpNutritionData entry.personId item.personName
    in
    viewFollowUpEntry language dueOption item.personName popupData assessments


viewDueClass : FollowUpDueOption -> String
viewDueClass dueOption =
    "due "
        ++ (case dueOption of
                OverDue ->
                    "overdue"

                DueToday ->
                    "today"

                DueThisWeek ->
                    "this-week"

                DueThisMonth ->
                    "this-month"

                DueNextMonth ->
                    "next-month"
           )


viewAcuteIllnessPane :
    Language
    -> NominalDate
    -> Dict ( IndividualEncounterParticipantId, PersonId ) AcuteIllnessFollowUpItem
    -> ModelIndexedDb
    -> Model
    -> Html Msg
viewAcuteIllnessPane language currentDate itemsDict db model =
    let
        limitDate =
            -- Set limit date for tomorrow, so that we
            -- load all available follow ups.
            Date.add Days 1 currentDate

        entries =
            generateAcuteIllnessFollowUpEntries language currentDate limitDate itemsDict db

        content =
            if List.isEmpty entries then
                [ translateText language Translate.NoMatchesFound ]

            else
                List.map (viewAcuteIllnessFollowUpEntry language currentDate) entries
    in
    div [ class "pane" ]
        [ viewItemHeading language AcuteIllnessEncounter
        , div [ class "pane-content" ]
            content
        ]


generateAcuteIllnessFollowUpEntries :
    Language
    -> NominalDate
    -> NominalDate
    -> Dict ( IndividualEncounterParticipantId, PersonId ) AcuteIllnessFollowUpItem
    -> ModelIndexedDb
    -> List AcuteIllnessFollowUpEntry
generateAcuteIllnessFollowUpEntries language currentDate limitDate itemsDict db =
    Dict.map (generateAcuteIllnessFollowUpEntryData language currentDate limitDate db) itemsDict
        |> Dict.values
        |> Maybe.Extra.values


generateAcuteIllnessFollowUpEntryData :
    Language
    -> NominalDate
    -> NominalDate
    -> ModelIndexedDb
    -> ( IndividualEncounterParticipantId, PersonId )
    -> AcuteIllnessFollowUpItem
    -> Maybe AcuteIllnessFollowUpEntry
generateAcuteIllnessFollowUpEntryData language currentDate limitDate db ( participantId, personId ) item =
    let
        dateConcludedCriteria =
            Dict.get participantId db.individualParticipants
                |> Maybe.andThen RemoteData.toMaybe
                |> Maybe.andThen .dateConcluded
                |> Maybe.map (\dateConcluded -> Date.compare dateConcluded limitDate)
    in
    if dateConcludedCriteria == Just LT then
        -- Illness was concluded before limit date, so we do not need to follow up on it.
        Nothing

    else
        let
            allEncountersWithIds =
                Dict.get participantId db.acuteIllnessEncountersByParticipant
                    |> Maybe.andThen RemoteData.toMaybe
                    |> Maybe.map
                        (Dict.toList
                            >> List.filter (\( _, encounter ) -> Date.compare encounter.startDate limitDate == LT)
                        )
                    |> Maybe.withDefault []
                    -- Sort DESC, by date and sequence number.
                    |> List.sortWith (\( _, e1 ) ( _, e2 ) -> compareAcuteIllnessEncounterDataDesc e1 e2)

            allEncounters =
                List.map Tuple.second allEncountersWithIds

            lastEncounterWithId =
                List.head allEncountersWithIds
        in
        lastEncounterWithId
            |> Maybe.andThen
                (\( encounterId, encounter ) ->
                    -- The follow up was issued at last encounter for the illness,
                    -- so we know we still need to follow up on that.
                    if item.encounterId == Just encounterId then
                        let
                            diagnosis =
                                allEncounters
                                    |> List.filter
                                        -- We filters out encounters that got no diagnosis set,
                                        -- to get most recent diagnosis made for the illness.
                                        (.diagnosis >> (/=) NoAcuteIllnessDiagnosis)
                                    |> List.head
                                    |> Maybe.map .diagnosis

                            encounterSequenceNumber =
                                allEncounters
                                    |> List.filter (.startDate >> (==) currentDate)
                                    |> List.sortBy .sequenceNumber
                                    |> List.reverse
                                    |> List.head
                                    |> Maybe.map (.sequenceNumber >> (+) 1)
                                    |> Maybe.withDefault 1
                        in
                        diagnosis
                            |> Maybe.map (AcuteIllnessFollowUpEntry participantId personId item encounterSequenceNumber)

                    else
                        Nothing
                )


viewAcuteIllnessFollowUpEntry :
    Language
    -> NominalDate
    -> AcuteIllnessFollowUpEntry
    -> Html Msg
viewAcuteIllnessFollowUpEntry language currentDate entry =
    let
        item =
            entry.item

        dueOption =
            followUpDueOptionByDate currentDate item.dateMeasured item.value

        assessment =
            [ p [] [ text <| translate language <| Translate.AcuteIllnessDiagnosis entry.diagnosis ] ]

        popupData =
            FollowUpAcuteIllness <| FollowUpAcuteIllnessData entry.personId item.personName entry.participantId entry.newEncounterSequenceNumber
    in
    viewFollowUpEntry language dueOption item.personName popupData assessment


viewPrenatalPane :
    Language
    -> NominalDate
    -> Dict ( IndividualEncounterParticipantId, PersonId ) PrenatalFollowUpItem
    -> ModelIndexedDb
    -> Model
    -> Html Msg
viewPrenatalPane language currentDate itemsDict db model =
    let
        limitDate =
            -- Set limit date for tomorrow, so that we
            -- load all available follow ups.
            Date.add Days 1 currentDate

        entries =
            generatePrenatalFollowUpEntries language currentDate limitDate itemsDict db

        content =
            if List.isEmpty entries then
                [ translateText language Translate.NoMatchesFound ]

            else
                List.map (viewPrenatalFollowUpEntry language currentDate) entries
    in
    div [ class "pane" ]
        [ viewItemHeading language AntenatalEncounter
        , div [ class "pane-content" ]
            content
        ]


generatePrenatalFollowUpEntries :
    Language
    -> NominalDate
    -> NominalDate
    -> Dict ( IndividualEncounterParticipantId, PersonId ) PrenatalFollowUpItem
    -> ModelIndexedDb
    -> List PrenatalFollowUpEntry
generatePrenatalFollowUpEntries language currentDate limitDate itemsDict db =
    Dict.map (generatePrenatalFollowUpEntryData language currentDate limitDate db) itemsDict
        |> Dict.values
        |> Maybe.Extra.values


generatePrenatalFollowUpEntryData :
    Language
    -> NominalDate
    -> NominalDate
    -> ModelIndexedDb
    -> ( IndividualEncounterParticipantId, PersonId )
    -> PrenatalFollowUpItem
    -> Maybe PrenatalFollowUpEntry
generatePrenatalFollowUpEntryData language currentDate limitDate db ( participantId, personId ) item =
    let
        dateConcludedCriteria =
            Dict.get participantId db.individualParticipants
                |> Maybe.andThen RemoteData.toMaybe
                |> Maybe.andThen .dateConcluded
                |> Maybe.map (\dateConcluded -> Date.compare dateConcluded limitDate)
    in
    if dateConcludedCriteria == Just LT then
        -- Pregnancy was concluded before limit date, so we do not need to follow up on it.
        Nothing

    else
        let
            allEncountersWithIds =
                Dict.get participantId db.prenatalEncountersByParticipant
                    |> Maybe.andThen RemoteData.toMaybe
                    |> Maybe.map
                        (Dict.toList
                            >> List.filter (\( _, encounter ) -> Date.compare encounter.startDate limitDate == LT)
                        )
                    |> Maybe.withDefault []
                    -- Sort DESC
                    |> List.sortWith sortEncounterTuplesDesc

            allChwEncountersWithIds =
                List.filter (Tuple.second >> .encounterType >> (/=) NurseEncounter) allEncountersWithIds
        in
        List.head allChwEncountersWithIds
            |> Maybe.andThen
                (\( encounterId, encounter ) ->
                    -- Follow up belongs to last encounter, which indicates that
                    -- there was no other encounter that has resolved this follow up.
                    if item.encounterId == Just encounterId then
                        let
                            hasNurseEncounter =
                                List.length allChwEncountersWithIds < List.length allEncountersWithIds
                        in
                        if encounter.encounterType == ChwPostpartumEncounter then
                            -- We do not show follow ups taken at Postpartum encounter.
                            Nothing

                        else
                            PrenatalFollowUpEntry
                                participantId
                                personId
                                item
                                encounter.encounterType
                                hasNurseEncounter
                                |> Just

                    else
                        -- Last encounter has not originated the follow up.
                        -- Therefore, we know that follow up is resolved.
                        Nothing
                )


viewPrenatalFollowUpEntry : Language -> NominalDate -> PrenatalFollowUpEntry -> Html Msg
viewPrenatalFollowUpEntry language currentDate entry =
    let
        item =
            entry.item

        dueOption =
            followUpDueOptionByDate currentDate item.dateMeasured item.value.options

        assessment =
            [ p [] [ text <| translate language <| Translate.PrenatalAssesment item.value.assesment ] ]

        popupData =
            FollowUpPrenatal <|
                FollowUpPrenatalData
                    entry.personId
                    item.personName
                    entry.participantId
                    entry.encounterType
                    entry.hasNurseEncounter
                    item.dateMeasured
    in
    viewFollowUpEntry language dueOption item.personName popupData assessment


viewFollowUpEntry :
    Language
    -> FollowUpDueOption
    -> String
    -> FollowUpEncounterDataType
    -> List (Html Msg)
    -> Html Msg
viewFollowUpEntry language dueOption personName popupData assessment =
    let
        dueLabel =
            Translate.FollowUpDueOption dueOption
                |> translateText language

        dueClass =
            viewDueClass dueOption
    in
    div [ class "follow-up-entry" ]
        [ div [ class "name" ] [ text personName ]
        , div [ class dueClass ] [ dueLabel ]
        , div [ class "assesment" ] assessment
        , div
            [ class "icon-forward"
            , onClick <| SetDialogState <| Just popupData
            ]
            []
        ]
