module Pusher.Test exposing (all)

import Activity.Model exposing (emptyChildActivityDates)
import Date
import Expect
import Json.Decode exposing (decodeString)
import Participant.Model exposing (ParticipantType(..))
import Pusher.Decoder exposing (..)
import Pusher.Model exposing (..)
import RemoteData exposing (RemoteData(NotAsked))
import Test exposing (Test, describe, test)


decodeTest : Test
decodeTest =
    describe "Decode Pusher"
        [ test "valid json" <|
            \() ->
                let
                    json =
                        """
{
    "eventType" : "patient__update",
    "data" : {
      "type" : "child",
      "id" : "100",
      "label" : "new-patient",
      "mother": "7",
      "date_picture": null,
      "date_height" : null,
      "date_muac" : null,
      "date_progress_report" : null,
      "date_weight" : null,
      "date_birth" : "2016-08-28T10:39:49+02:00"
    }

}
            """

                    expectedResult =
                        { participantId = 100
                        , data =
                            ParticipantUpdate
                                { info =
                                    ParticipantChild
                                        { name = "new-patient"
                                        , image = "https://placehold.it/200x200"
                                        , motherId = Just 7
                                        , examinations = NotAsked
                                        , selectedExamination = Nothing
                                        , activityDates = emptyChildActivityDates
                                        , birthDate = Date.fromTime 1472373589000
                                        }
                                }
                        }
                in
                    Expect.equal (Ok expectedResult) (decodeString decodePusherEvent json)
        ]


all : Test
all =
    describe "Pusher tests"
        [ decodeTest
        ]
