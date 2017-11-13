module Backend.Model exposing (..)

{-| The `Backend` hierarchy is for code that represents entities from the
backend. It is reponsible for fetching them, saving them, etc.

  - There shouldn't be any UI code here (except possibly some UI that
    is specifically related to fetching and saving -- we'll see).

  - There shouldn't be data here that purely relates to the local state of the
    app. If it isn't persisted to the backend, that state can go elsewhere.

The nice thing about this is that we can segregate local state (like whether
a dialog box is open etc.) from the state that persists to the backend.
That way, we can more easily have a single source of truth for the
backend data -- we're not tempted to duplicate it in various places
in the UI.

-}

import Backend.Clinic.Model exposing (Clinic)
import Backend.Entities exposing (..)
import Backend.Measurement.Model exposing (MeasurementEdits)
import Backend.Session.Model exposing (OfflineSession, Session)
import EveryDictList exposing (EveryDictList)
import Gizra.NominalDate exposing (NominalDate)
import Http exposing (Error)
import Json.Encode exposing (Value)
import RemoteData exposing (RemoteData(..), WebData)
import Restful.UpdatableData exposing (UpdatableWebData)


{-| This model basically represents things we have locally which also belong
on the backend. So, conceptually it is a kind of a local cache of some of the
things on the backend.
-}
type alias ModelBackend =
    -- For now, we fetch all the clinics from the backend at once when we need
    -- any. So, the `WebData` tracks that request, and the `DictList` tracks
    -- its result.
    { clinics : WebData (EveryDictList ClinicId Clinic)

    -- This tracks future sessions ... that is, sessions which are either
    -- available now, or will be in the future. We remember which
    -- date we asked about, so that if the date changes (i.e. it becomes
    -- tomorrow, due to the passage of time), we can know that we ought to
    -- ask again.
    --
    -- We fetch all the future sessions at once, if we need them at all.
    -- The data type is probably small enough that this is fine ... we can
    -- fetch them in smaller batches if necessary (by clinicId, probably).
    --
    -- TODO: Restful.Endpoint should eventually have a `QueryResult` type which
    -- remembers the params we supplied and a WebData for the result ...
    -- since one would really always want to remember what query the results
    -- represent. (And, eventually, one would want to remember the `count`
    -- and which pages you have etc.).
    , futureSessions : WebData ( NominalDate, EveryDictList SessionId Session )

    -- This is a flag which tracks our progress in downloading an
    -- offlineSession from the backend. We don't actually **store** the data
    -- here, because we want to use it from the cache, and only consider it
    -- **really** available if we can get if from the cache. However, it's
    -- still handy to have a flag that tells us whether a request is in
    -- progress or not. (In fact, we need to know, for the UI).
    --
    -- We do remember which sessionID we downloaded, since that helps a bit
    -- to match things up in the UI.
    , offlineSessionRequest : WebData SessionId
    }


emptyModelBackend : ModelBackend
emptyModelBackend =
    { clinics = NotAsked
    , futureSessions = NotAsked
    , offlineSessionRequest = NotAsked
    }


{-| These are all the messages related to getting things from the backend and
putting things back into the backend.
-}
type MsgBackend
    = FetchClinics
    | FetchFutureSessions NominalDate
    | FetchOfflineSessionFromBackend SessionId
    | HandleFetchedClinics (WebData (EveryDictList ClinicId Clinic))
    | HandleFetchedOfflineSessionFromBackend (Result Error ( SessionId, OfflineSession ))
    | HandleFetchedSessions NominalDate (WebData (EveryDictList SessionId Session))
    | ResetOfflineSessionRequest -- resets it to `NotAsked`


{-| This models things which we cache locally ... so, like `ModelBackend`, but
instead of saving them to the backend, we save them locally.
-}
type alias ModelCached =
    -- This tracks, if we have one, the OfflineSession which we're currently
    -- doing data entry for.
    --
    -- The `WebData` wrapper represents whether we've tried to fetch it from
    -- our local cache (and any error that may have occurred). The inner
    -- `Maybe` represents whether it was actually found. That is, if we
    -- successfully query our local cache, and find it's not there, then the
    -- `WebData` layer is a `Success`, and the `Maybe` is a `Nothing`.
    --
    -- At least at first, we'll track our "mode" by whether we have an offline
    -- session in local storage. So:
    --
    -- * We'll automatically try to load an offline session from local storage
    --   when the app starts up.
    --
    -- * If we get one, we'll automatically show that in the UI, and prevent
    --   other things from showing.
    --
    -- * If we don't, then we'll show other things.
    --
    -- Note that this assumes that:
    --
    -- * We're only allowing a single offline session at a time to be stored
    --   locally.
    --
    -- * If we have one, we're definitely using it, not doing something else.
    { offlineSession : UpdatableWebData (Maybe ( SessionId, OfflineSession ))

    -- This tracks mesaurements which we've edited, but haven't uploaded to
    -- the backend yet. These are immediately cached locally, which is what
    -- the `UpdatableData` is for ... it wraps our effort to fetch from local
    -- strorage the measurements we've taken but not uploaded yet, as well
    -- as our efforts to cache the edits in local storage.
    --
    -- It's nice to track this separately, rather than integrating into
    -- the offlineSession with `EditableWebData`, because we upload these
    -- in a batch, all at once, rather than individually. So, we don't need
    -- to track the status of each measurement separately ... we deal with
    -- them together.
    --
    -- Note that we're assuming here that we'll save all of these before
    -- switching to another session ... that is, we can't have two sessions
    -- in progress at once. (We could change that down the road if necessary).
    --
    -- The inner `Maybe` represents whether we found any editable measurements
    -- in our local storage ... we'll delete the whole thing once we successfully
    -- save it to the backend.
    , edits : UpdatableWebData (Maybe MeasurementEdits)
    }


emptyModelCached : ModelCached
emptyModelCached =
    { offlineSession = Restful.UpdatableData.notAsked
    , edits = Restful.UpdatableData.notAsked
    }


{-| These are all the messages related to getting things from the cache and
putting things back into the cache.
-}
type MsgCached
    = CacheOfflineSession SessionId OfflineSession
    | CacheOfflineSessionResult Value
    | FetchOfflineSessionFromCache
    | HandleOfflineSession String
