module Backend.Utils exposing (mapMotherMeasurements)

import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (MotherMeasurementList)
import Backend.Model exposing (..)
import EveryDict
import RemoteData exposing (RemoteData(..))


mapMotherMeasurements : MotherId -> (MotherMeasurementList -> MotherMeasurementList) -> ModelIndexedDb -> ModelIndexedDb
mapMotherMeasurements motherId func model =
    let
        motherMeasurements =
            EveryDict.get motherId model.motherMeasurements
                |> Maybe.withDefault NotAsked
                |> RemoteData.map func
    in
    { model | motherMeasurements = EveryDict.insert motherId motherMeasurements model.motherMeasurements }
