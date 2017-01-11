module Pages.Activities.View exposing (view)

import Activity.Model exposing (ActivityListItem)
import Activity.Utils exposing (getActivityList)
import Date exposing (Date)
import Html exposing (..)
import Html.Attributes exposing (..)
import List as List
import Patient.Model exposing (PatientsDict)
import User.Model exposing (User)


view : Date -> User -> PatientsDict -> Html a
view currentDate user patients =
    let
        allActivityList =
            getActivityList currentDate patients

        pendingActivities =
            List.filter (\activity -> activity.remaining > 0) allActivityList

        noPendingActivities =
            List.filter (\activity -> activity.remaining == 0) allActivityList

        pendingActivitiesView =
            if List.isEmpty pendingActivities then
                div [] []
            else
                div [] (List.map viewActivity pendingActivities)

        noPendingActivitiesView =
            if List.isEmpty noPendingActivities then
                div [] []
            else
                div []
                    [ h2 [ class "ui header" ] [ text "Activities completed" ]
                    , div [ class "ui cards activities activities_complete" ] (List.map viewActivity noPendingActivities)
                    ]
    in
        div []
            [ h2 [ class "ui header" ] [ text "Activities to complete" ]
            , div [ class "ui cards activities activities_todo" ] [ pendingActivitiesView ]
            , noPendingActivitiesView
            ]


viewActivity : ActivityListItem -> Html a
viewActivity report =
    div [ class "ui card activities__item" ]
        [ a [ href "#" ] [ i [ class (report.activity.icon ++ " icon") ] [] ]
        , div [ class "content" ]
            [ a [ class "header activities__item__title" ] [ text report.activity.name ]
            , div [ class "meta" ] [ text <| toString report.remaining ++ " remaining" ]
            ]
        ]
