module DataManager.Utils exposing (determineSyncStatus)

import DataManager.Model exposing (DownloadPhotos(..), Model, SyncStatus(..))
import List.Zipper as Zipper
import RemoteData


{-| Decide on the Sync status. Either keep the exiting one, or set the next one,
according to the order `SyncStatus` is defined.
-}
determineSyncStatus : Model -> Model
determineSyncStatus model =
    let
        syncStatus =
            model.syncStatus

        syncStatusUpdated =
            case syncStatus of
                SyncIdle ->
                    SyncUpload

                SyncUpload ->
                    -- @todo: add logic
                    SyncDownloadGeneral RemoteData.NotAsked

                SyncDownloadGeneral webData ->
                    case webData of
                        RemoteData.Success data ->
                            if List.isEmpty data.backendGeneralEntities then
                                -- We tried to fetch, but there was no more data.
                                -- Next we try authorities.
                                SyncDownloadAuthority model.revisionIdPerAuthorityZipper RemoteData.NotAsked

                            else
                                -- Still have data to download.
                                syncStatus

                        _ ->
                            syncStatus

                SyncDownloadAuthority maybeZipper webData ->
                    case ( maybeZipper, webData ) of
                        ( Nothing, _ ) ->
                            -- There are no authorities, so we can set the next
                            -- status.
                            SyncDownloadPhotos model.downloadPhotos

                        ( Just zipper, RemoteData.Success data ) ->
                            if List.isEmpty data.backendGeneralEntities then
                                -- We tried to fetch, but there was no more data.
                                -- Check if this is the last element.
                                if Zipper.isLast zipper then
                                    SyncDownloadPhotos model.downloadPhotos

                                else
                                    -- Go to the next authority.
                                    SyncDownloadAuthority (Zipper.next zipper) RemoteData.NotAsked

                            else
                                -- Still have data to download.
                                syncStatus

                        _ ->
                            syncStatus

                SyncDownloadPhotos downloadPhotos ->
                    let
                        check webData_ =
                            case webData_ of
                                RemoteData.Success data ->
                                    if List.isEmpty data.backendGeneralEntities then
                                        -- We tried to fetch, but there was no more data.
                                        SyncIdle

                                    else
                                        -- Still have data to download.
                                        syncStatus

                                _ ->
                                    syncStatus
                    in
                    case downloadPhotos of
                        DownloadPhotosNone ->
                            SyncIdle

                        DownloadPhotosBatch _ webData ->
                            check webData

                        DownloadPhotosAll webData ->
                            check webData
    in
    { model | syncStatus = syncStatusUpdated }
