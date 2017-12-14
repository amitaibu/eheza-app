module Backend.Session.Decoder exposing (..)

import Backend.Child.Decoder exposing (decodeChild)
import Backend.Child.Model exposing (Child)
import Backend.Clinic.Decoder exposing (decodeClinic)
import Backend.Entities exposing (..)
import Backend.Measurement.Decoder exposing (decodeHistoricalMeasurements)
import Backend.Measurement.Model exposing (Measurement, emptyMeasurements, MotherMeasurementList, MotherMeasurements, ChildMeasurementList, ChildMeasurements)
import Backend.Mother.Decoder exposing (decodeMother)
import Backend.Mother.Model exposing (Mother)
import Backend.Session.Model exposing (..)
import EveryDict exposing (EveryDict)
import EveryDictList exposing (EveryDictList)
import Gizra.NominalDate exposing (decodeDrupalRange, decodeYYYYMMDD)
import Json.Decode exposing (Decoder, bool, andThen, dict, fail, field, int, list, map, map2, nullable, string, succeed, at, oneOf)
import Json.Decode.Pipeline exposing (custom, decode, hardcoded, optional, optionalAt, required, requiredAt)
import Restful.Endpoint exposing (decodeEntityId)
import Time.Date


{-| Decodes the JSON sent by /api/sessions
-}
decodeSession : Decoder Session
decodeSession =
    decode Session
        |> required "scheduled_date" (decodeDrupalRange decodeYYYYMMDD)
        |> custom
            (oneOf
                -- Work with "full_view" true or false, or with the
                -- structure we encode for the cache.
                [ field "clinic" decodeEntityId
                , field "clinic_id" decodeEntityId
                , at [ "clinic", "id" ] decodeEntityId
                ]
            )
        |> optional "closed" bool False


{-| Decodes the JSON sent by /api/offline_sessions
-}
decodeOfflineSession : Decoder OfflineSession
decodeOfflineSession =
    -- We need the ID in order to know which measurements belong to the current session.
    field "id" decodeEntityId
        |> andThen
            (\id ->
                decode OfflineSession
                    -- For the "basic" session data, we can reuse the decoder
                    |> custom decodeSession
                    -- We get **all** the basic clinic information, as a convenience for
                    -- presenting the UI while offline
                    |> required "clinics" (EveryDictList.decodeArray2 (field "id" decodeEntityId) decodeClinic)
                    |> requiredAt [ "participants", "mothers" ] decodeMothers
                    |> requiredAt [ "participants", "children" ] decodeChildren
                    |> custom decodeHistoricalMeasurements
                    -- We start with empty stuff for the `previousMeasurements`
                    -- and `currentMeasurements` ... then we map to fill them in.
                    |> hardcoded emptyMeasurements
                    |> hardcoded emptyMeasurements
                    |> map (splitHistoricalMeasurements id)
            )


{-| Takes the historical measurements and populates `previousMeasurements`
and `currentMeasurements` as appropriate.
-}
splitHistoricalMeasurements : SessionId -> OfflineSession -> OfflineSession
splitHistoricalMeasurements sessionId session =
    -- There should be a more elegant way to do this, but this will do for now.
    -- Actually, I suppose I should change the data model so that all the
    -- per-mother and per-child info is in one dictionary ... but not now.
    let
        mothers =
            splitMotherMeasurements sessionId session.historicalMeasurements.mothers

        children =
            splitChildMeasurements sessionId session.historicalMeasurements.children

        currentMeasurements =
            { mothers = EveryDict.map (always .current) mothers
            , children = EveryDict.map (always .current) children
            }

        previousMeasurements =
            { mothers = EveryDict.map (always .previous) mothers
            , children = EveryDict.map (always .previous) children
            }
    in
        { session
            | currentMeasurements = currentMeasurements
            , previousMeasurements = previousMeasurements
        }


splitMotherMeasurements : SessionId -> EveryDict MotherId MotherMeasurementList -> EveryDict MotherId { current : MotherMeasurements, previous : MotherMeasurements }
splitMotherMeasurements sessionId =
    EveryDict.map
        (\_ list ->
            let
                familyPlanning =
                    getCurrentAndPrevious sessionId list.familyPlannings
            in
                { current =
                    { familyPlanning = familyPlanning.current
                    }
                , previous =
                    { familyPlanning = familyPlanning.previous
                    }
                }
        )


splitChildMeasurements : SessionId -> EveryDict ChildId ChildMeasurementList -> EveryDict ChildId { current : ChildMeasurements, previous : ChildMeasurements }
splitChildMeasurements sessionId =
    EveryDict.map
        (\_ list ->
            let
                height =
                    getCurrentAndPrevious sessionId list.heights

                weight =
                    getCurrentAndPrevious sessionId list.weights

                muac =
                    getCurrentAndPrevious sessionId list.muacs

                nutrition =
                    getCurrentAndPrevious sessionId list.nutritions

                photo =
                    getCurrentAndPrevious sessionId list.photos
            in
                { current =
                    { height = height.current
                    , weight = weight.current
                    , muac = muac.current
                    , nutrition = nutrition.current
                    , photo = photo.current
                    }
                , previous =
                    { height = height.previous
                    , weight = weight.previous
                    , muac = muac.previous
                    , nutrition = nutrition.previous
                    , photo = photo.previous
                    }
                }
        )


{-| Picks out a current and previous value from a list of measurements.
-}
getCurrentAndPrevious : SessionId -> List ( id, Measurement a b ) -> { current : Maybe ( id, Measurement a b ), previous : Maybe ( id, Measurement a b ) }
getCurrentAndPrevious sessionId =
    let
        -- This is designed to iterate through each list only once, to get both
        -- the current and previous value
        go measurement acc =
            if .sessionId (Tuple.second measurement) == Just sessionId then
                -- If it's got our session ID, then it's current
                { acc | current = Just measurement }
            else
                case acc.previous of
                    -- Otherwise, it might be previous
                    Nothing ->
                        { acc | previous = Just measurement }

                    Just ( _, previousValue ) ->
                        if Time.Date.compare (.dateMeasured (Tuple.second measurement)) previousValue.dateMeasured == GT then
                            { acc | previous = Just measurement }
                        else
                            acc
    in
        List.foldl go
            { current = Nothing
            , previous = Nothing
            }


decodeMothers : Decoder (EveryDictList MotherId Mother)
decodeMothers =
    EveryDictList.decodeArray2 (field "id" decodeEntityId) decodeMother


decodeChildren : Decoder (EveryDict ChildId Child)
decodeChildren =
    map2 (,) (field "id" decodeEntityId) decodeChild
        |> list
        |> map EveryDict.fromList