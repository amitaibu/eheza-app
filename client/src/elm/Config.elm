module Config exposing (configs, ***REMOVED***, livePantheon, ***REMOVED***, ***REMOVED***, ***REMOVED***)

import AssocList as Dict exposing (Dict)
import Config.Model as Config exposing (Model)
import LocalConfig exposing (localConfigs)
import Pusher.Model exposing (Cluster(..), PusherAppKey)
import Rollbar


***REMOVED*** : Model
***REMOVED*** =
    { backendUrl = "https://***REMOVED***"
    , name = "***REMOVED***"
    , pusherKey = PusherAppKey "***REMOVED***" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


***REMOVED*** : Model
***REMOVED*** =
    { backendUrl = "https://***REMOVED***"
    , name = "***REMOVED***"
    , pusherKey = PusherAppKey "***REMOVED***" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


livePantheon : Model
livePantheon =
    { backendUrl = "https://***REMOVED***"
    , name = "livePantheon"
    , pusherKey = PusherAppKey "***REMOVED***" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


ehezaGlobal : Model
ehezaGlobal =
    { backendUrl = "https://***REMOVED***"
    , name = "eheza-global"
    , pusherKey = PusherAppKey "***REMOVED***" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


***REMOVED*** : Model
***REMOVED*** =
    { backendUrl = "https://***REMOVED***"
    , name = "***REMOVED***"
    , pusherKey = PusherAppKey "" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


***REMOVED*** : Model
***REMOVED*** =
    { backendUrl = "https://***REMOVED***"
    , name = "***REMOVED***"

    -- We're not actually using Pusher at the moment, so just filling in a
    -- blank key for now.
    , pusherKey = PusherAppKey "" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = True
    }


elm19Pantheon : Model
elm19Pantheon =
    { backendUrl = "https://elm19-ihangane.pantheonsite.io"
    , name = "elm19Pantheon"
    , pusherKey = PusherAppKey "" UsEast1
    , debug = False
    , rollbarToken = Rollbar.token "***REMOVED***"
    , sandbox = False
    }


configs : Dict String Model
configs =
    Dict.fromList
        [ ( "***REMOVED***", ***REMOVED*** )
        , ( "***REMOVED***", ***REMOVED*** )
        , ( "***REMOVED***", livePantheon )
        , ( "***REMOVED***", ***REMOVED*** )
        , ( "***REMOVED***", ehezaGlobal )
        , ( "***REMOVED***", ***REMOVED*** )
        , ( "elm-19-ihangane.pantheonsite.io", elm19Pantheon )
        ]
        |> Dict.union localConfigs
