port module App.Update exposing (init, update, subscriptions)

import App.Model exposing (..)
import Backend.Update
import Config
import Date
import Dict
import Gizra.NominalDate exposing (fromLocalDateTime)
import Json.Decode exposing (decodeValue, bool)
import Json.Decode exposing (oneOf)
import Maybe.Extra
import Pages.Login.Model
import Pages.Login.Update
import Pages.Page exposing (Page(..))
import Pages.Update
import Pages.Update
import Pusher.Model
import Pusher.Utils exposing (getClusterName)
import RemoteData exposing (RemoteData(..), WebData)
import Restful.Endpoint exposing (decodeSingleEntity)
import Restful.Login exposing (LoginStatus(..), Login, Credentials, checkCachedCredentials)
import Task
import Time exposing (minute)
import Update.Extra exposing (sequence)
import User.Decoder exposing (decodeUser)
import User.Encoder exposing (encodeUser)
import User.Model exposing (..)


loginConfig : Restful.Login.Config User LoggedInModel Msg
loginConfig =
    -- The `oneOf` below is necessary because how the backend sends the user is
    -- a little different from how we encode it for local storage ... this
    -- could possibly be solved another way.
    Restful.Login.drupalConfig
        { decodeUser = oneOf [ decodeSingleEntity decodeUser, decodeUser ]
        , encodeUser = encodeUser
        , initialData = \_ -> emptyLoggedInModel
        , cacheCredentials = curry cacheCredentials
        , tag = MsgLogin
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    case Dict.get flags.hostname Config.configs of
        Just config ->
            let
                ( loginStatus, loginCmd ) =
                    -- We kick off the process of checking the cached credentials which
                    -- we were provided.
                    checkCachedCredentials loginConfig config.backendUrl flags.credentials

                cmd =
                    Cmd.batch
                        [ pusherKey
                            ( config.pusherKey.key
                            , getClusterName config.pusherKey.cluster
                            , Pusher.Model.eventNames
                            )
                        , Task.perform Tick Time.now
                        , loginCmd
                        ]

                configuredModel =
                    { config = config
                    , loginPage = Pages.Login.Model.emptyModel
                    , login = loginStatus
                    }
            in
                ( { emptyModel | configuration = Success configuredModel }
                , cmd
                )

        Nothing ->
            ( { emptyModel | configuration = Failure <| "No config found for: " ++ flags.hostname }
            , Cmd.none
            )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MsgLoggedIn loggedInMsg ->
            updateLoggedIn
                (\credentials data ->
                    case loggedInMsg of
                        MsgBackend subMsg ->
                            let
                                ( backend, cmd ) =
                                    Backend.Update.update credentials.backendUrl credentials.accessToken subMsg data.backend
                            in
                                ( { data | backend = backend }
                                , Cmd.map (MsgLoggedIn << MsgBackend) cmd
                                , []
                                )

                        MsgSession subMsg ->
                            let
                                ( subModel, subCmd, redirect ) =
                                    Pages.Update.updateSession subMsg data.pages

                                extraMsgs =
                                    redirect
                                        |> Maybe.Extra.toList
                                        |> List.map (SetActivePage << SessionPage)
                            in
                                ( { data | pages = subModel }
                                , Cmd.map (MsgLoggedIn << MsgSession) subCmd
                                , extraMsgs
                                )
                )
                model

        MsgLogin subMsg ->
            updateConfigured
                (\configured ->
                    let
                        ( subModel, cmd ) =
                            Restful.Login.update loginConfig subMsg configured.login
                    in
                        ( { configured | login = subModel }
                        , cmd
                        , []
                        )
                )
                model

        MsgPageLogin subMsg ->
            updateConfigured
                (\configured ->
                    let
                        ( subModel, subCmd, outMsg ) =
                            Pages.Login.Update.update subMsg configured.loginPage

                        extraMsgs =
                            outMsg
                                |> Maybe.Extra.toList
                                |> List.map
                                    (\out ->
                                        case out of
                                            Pages.Login.Model.TryLogin name pass ->
                                                Restful.Login.tryLogin configured.config.backendUrl name pass
                                                    |> MsgLogin

                                            Pages.Login.Model.Logout ->
                                                MsgLogin Restful.Login.logout

                                            Pages.Login.Model.SetActivePage page ->
                                                SetActivePage page
                                    )
                    in
                        ( { configured | loginPage = subModel }
                        , Cmd.map MsgPageLogin subCmd
                        , extraMsgs
                        )
                )
                model

        SetActivePage page ->
            -- TODO: There may be some additinoal logic needed here ... we'll see.
            ( { model | activePage = page }
            , Cmd.none
            )

        SetLanguage language ->
            ( { model | language = language }
            , Cmd.none
            )

        SetOffline offline ->
            ( { model | offline = offline }
            , Cmd.none
            )

        Tick time ->
            let
                nominalDate =
                    fromLocalDateTime (Date.fromTime time)
            in
                -- We don't update the model at all if the date hasn't
                -- changed ...  this should be a small optimization, since
                -- the new model will be referentially equal to the
                -- previous one.
                if nominalDate == model.currentDate then
                    ( model, Cmd.none )
                else
                    ( { model | currentDate = nominalDate }
                    , Cmd.none
                    )


{-| Convenience function to process a msg which depends on having a configuration.

The function you supply returns a third parameter, which is a list of additional messages to process.

-}
updateConfigured : (ConfiguredModel -> ( ConfiguredModel, Cmd Msg, List Msg )) -> Model -> ( Model, Cmd Msg )
updateConfigured func model =
    model.configuration
        |> RemoteData.map
            (\configured ->
                let
                    ( subModel, cmd, extraMsgs ) =
                        func configured
                in
                    sequence update
                        extraMsgs
                        ( { model | configuration = Success subModel }
                        , cmd
                        )
            )
        |> RemoteData.withDefault ( model, Cmd.none )


{-| Convenience function to process a msg which depends on being logged in.

TODO: Put a version of this in `Restful.Login`.

-}
updateLoggedIn : (Credentials User -> LoggedInModel -> ( LoggedInModel, Cmd Msg, List Msg )) -> Model -> ( Model, Cmd Msg )
updateLoggedIn func model =
    updateConfigured
        (\configured ->
            -- TODO: Perhaps we should Debug.log some errors in cases where we get
            -- messages we can't handle ...
            case configured.login of
                Anonymous _ ->
                    ( configured, Cmd.none, [] )

                CheckingCachedCredentials ->
                    ( configured, Cmd.none, [] )

                LoggedIn login ->
                    let
                        ( subModel, cmd, extraMsgs ) =
                            func login.credentials login.data
                    in
                        ( { configured | login = LoggedIn { login | data = subModel } }
                        , cmd
                        , extraMsgs
                        )
        )
        model


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Time.every minute Tick
        , offline SetOffline
        ]


{-| Saves credentials provided by `Restful.Login`.
-}
port cacheCredentials : ( String, String ) -> Cmd msg


{-| Send Pusher key and cluster to JS.
-}
port pusherKey : ( String, String, List String ) -> Cmd msg


{-| Get a signal if internet connection is lost or regained.
-}
port offline : (Bool -> msg) -> Sub msg
