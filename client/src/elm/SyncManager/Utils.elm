module SyncManager.Utils exposing (..)

import Backend.AcuteIllnessEncounter.Encoder
import Backend.Clinic.Encoder
import Backend.Counseling.Encoder
import Backend.Dashboard.Encoder
import Backend.HealthCenter.Encoder
import Backend.IndividualEncounterParticipant.Encoder
import Backend.Measurement.Encoder
import Backend.Measurement.Model exposing (PhotoUrl(..))
import Backend.Model exposing (Revision(..))
import Backend.Nurse.Encoder
import Backend.NutritionEncounter.Encoder
import Backend.ParticipantConsent.Encoder
import Backend.Person.Encoder
import Backend.PmtctParticipant.Encoder
import Backend.PrenatalEncounter.Encoder
import Backend.Relationship.Encoder
import Backend.Session.Encoder
import Backend.Village.Encoder
import Editable
import Json.Encode exposing (Value, object)
import List.Zipper as Zipper
import RemoteData
import Restful.Endpoint exposing (toEntityUuid)
import SyncManager.Model exposing (..)
import Utils.WebData


{-| Decide on the Sync status. Either keep the exiting one, or set the next one,
according to the order `SyncStatus` is defined.
-}
determineSyncStatus : Model -> Model
determineSyncStatus model =
    let
        syncCycleRotate =
            case model.syncCycle of
                SyncManager.Model.SyncCycleOn ->
                    True

                _ ->
                    False
    in
    if syncCycleRotate then
        let
            syncStatus =
                model.syncStatus

            syncInfoAuthorities =
                model.syncInfoAuthorities

            noChange =
                ( syncStatus, syncInfoAuthorities )

            ( syncStatusUpdated, syncInfoAuthoritiesUpdated ) =
                -- Cases are ordered by the cycle order.
                case syncStatus of
                    SyncIdle ->
                        ( SyncUploadPhotoAuthority RemoteData.NotAsked, syncInfoAuthorities )

                    SyncUploadPhotoAuthority webData ->
                        case webData of
                            RemoteData.Success maybeData ->
                                case maybeData of
                                    Just data ->
                                        -- We still have date.
                                        noChange

                                    Nothing ->
                                        -- No more photos to upload.
                                        ( SyncUploadGeneral emptyUploadRec, syncInfoAuthorities )

                            _ ->
                                noChange

                    SyncUploadGeneral record ->
                        if record.indexDbRemoteData == RemoteData.Success Nothing then
                            -- We tried to fetch entities for upload from IndexDB,
                            -- but there we non matching the query.
                            ( SyncUploadAuthority emptyUploadRec, syncInfoAuthorities )

                        else
                            noChange

                    SyncUploadAuthority record ->
                        if record.indexDbRemoteData == RemoteData.Success Nothing then
                            -- We tried to fetch entities for upload from IndexDB,
                            -- but there we non matching the query.
                            ( SyncDownloadGeneral RemoteData.NotAsked, syncInfoAuthorities )

                        else
                            noChange

                    SyncDownloadGeneral webData ->
                        case webData of
                            RemoteData.Success data ->
                                if List.isEmpty data.entities then
                                    -- We tried to fetch, but there was no more data.
                                    -- Next we try authorities.
                                    ( SyncDownloadAuthority RemoteData.NotAsked
                                    , syncInfoAuthorities
                                    )

                                else
                                    -- Still have data to download.
                                    noChange

                            _ ->
                                noChange

                    SyncDownloadAuthority webData ->
                        case ( model.syncInfoAuthorities, webData ) of
                            ( Nothing, _ ) ->
                                -- There are no authorities, so we can set the next
                                -- status, skipping statistics download.
                                ( SyncIdle
                                , syncInfoAuthorities
                                )

                            ( Just zipper, RemoteData.Success data ) ->
                                if List.isEmpty data.entities then
                                    -- We tried to fetch, but there was no more data.
                                    -- Check if this is the last element.
                                    if Zipper.isLast zipper then
                                        ( SyncDownloadAuthorityDashboardStats RemoteData.NotAsked
                                        , Just (Zipper.first zipper)
                                        )

                                    else
                                        -- Go to the next authority if there is
                                        -- otherwise, to the next status
                                        case Zipper.next zipper of
                                            Just nextZipper ->
                                                ( SyncDownloadAuthority RemoteData.NotAsked
                                                , Just nextZipper
                                                )

                                            Nothing ->
                                                -- We've reached the last element
                                                -- so reset it back, and rotate
                                                -- to the next status.
                                                ( SyncDownloadAuthorityDashboardStats RemoteData.NotAsked
                                                , Just (Zipper.first zipper)
                                                )

                                else
                                    -- Still have data to download.
                                    noChange

                            _ ->
                                noChange

                    SyncDownloadAuthorityDashboardStats webData ->
                        case ( model.syncInfoAuthorities, webData ) of
                            ( Nothing, _ ) ->
                                -- There are no authorities, so we can set the next
                                -- status.
                                ( SyncIdle
                                , syncInfoAuthorities
                                )

                            ( Just zipper, RemoteData.Success data ) ->
                                if Zipper.isLast zipper then
                                    ( SyncIdle
                                    , Just (Zipper.first zipper)
                                    )

                                else
                                    -- Go to the next authority if there is
                                    -- otherwise, to the next status
                                    case Zipper.next zipper of
                                        Just nextZipper ->
                                            ( SyncDownloadAuthorityDashboardStats RemoteData.NotAsked
                                            , Just nextZipper
                                            )

                                        Nothing ->
                                            -- We've reached the last element
                                            -- so reset it back, and rotate
                                            -- to the next status.
                                            ( SyncIdle
                                            , Just (Zipper.first zipper)
                                            )

                            _ ->
                                noChange
        in
        { model
            | syncStatus = syncStatusUpdated
            , syncInfoAuthorities = syncInfoAuthoritiesUpdated
        }

    else
        -- No change.
        model


determineDownloadPhotosStatus : Model -> Model
determineDownloadPhotosStatus model =
    let
        syncCycleRotate =
            case model.syncCycle of
                SyncManager.Model.SyncCycleOn ->
                    True

                _ ->
                    False
    in
    if syncCycleRotate then
        let
            currentStatus =
                model.downloadPhotosStatus

            statusUpdated =
                case model.syncStatus of
                    SyncIdle ->
                        -- Cases are ordered by the cycle order.
                        case currentStatus of
                            DownloadPhotosIdle ->
                                DownloadPhotosInProcess model.downloadPhotosMode

                            DownloadPhotosInProcess record ->
                                case record of
                                    DownloadPhotosNone ->
                                        DownloadPhotosIdle

                                    DownloadPhotosBatch deferredPhoto ->
                                        if deferredPhoto.indexDbRemoteData == RemoteData.Success Nothing then
                                            -- We tried to fetch deferred photos from IndexDB,
                                            -- but there we non matching the query.
                                            DownloadPhotosIdle

                                        else if deferredPhoto.batchCounter < 1 then
                                            -- We've reached the end of the batch, so we
                                            -- need to rotate.
                                            DownloadPhotosIdle

                                        else
                                            currentStatus

                                    DownloadPhotosAll deferredPhoto ->
                                        if deferredPhoto.indexDbRemoteData == RemoteData.Success Nothing then
                                            -- We tried to fetch deferred photos from IndexDB,
                                            -- but there we non matching the query.
                                            DownloadPhotosIdle

                                        else
                                            -- There are still deferred photos in IndexDB
                                            -- that match out query.
                                            currentStatus

                    -- When sync is active, we stop photos download.
                    _ ->
                        DownloadPhotosIdle
        in
        { model | downloadPhotosStatus = statusUpdated }

    else
        -- No change.
        model


resetDownloadPhotosBatchCounter : Model -> DownloadPhotosStatus
resetDownloadPhotosBatchCounter model =
    case model.downloadPhotosMode of
        DownloadPhotosBatch deferredPhoto ->
            let
                deferredPhotoUpdated =
                    { deferredPhoto | batchCounter = deferredPhoto.batchSize }
            in
            DownloadPhotosInProcess (DownloadPhotosBatch deferredPhotoUpdated)

        _ ->
            DownloadPhotosInProcess model.downloadPhotosMode


{-| Get info about an entity. `revision` would be the Drupal revision
in case of download, or the `localId` in case of upload.
-}
getBackendGeneralEntityIdentifier : BackendGeneralEntity -> BackendEntityIdentifier
getBackendGeneralEntityIdentifier backendGeneralEntity =
    let
        getIdentifier identifier type_ =
            { uuid = identifier.uuid
            , revision = identifier.revision
            , type_ = type_
            }
    in
    case backendGeneralEntity of
        BackendGeneralCatchmentArea identifier ->
            getIdentifier identifier "catchment_area"

        BackendGeneralCounselingSchedule identifier ->
            getIdentifier identifier "counseling_schedule"

        BackendGeneralCounselingTopic identifier ->
            getIdentifier identifier "counseling_topic"

        BackendGeneralHealthCenter identifier ->
            getIdentifier identifier "health_center"

        BackendGeneralNurse identifier ->
            getIdentifier identifier "nurse"

        BackendGeneralParticipantForm identifier ->
            getIdentifier identifier "participant_form"

        BackendGeneralVillage identifier ->
            getIdentifier identifier "village"


{-| Get info about an "Authority" entity. `revision` would be the Drupal revision
in case of download, or the `localId` in case of upload.
-}
getBackendAuthorityEntityIdentifier : BackendAuthorityEntity -> BackendEntityIdentifier
getBackendAuthorityEntityIdentifier backendAuthorityEntity =
    let
        getIdentifier identifier type_ =
            { uuid = identifier.uuid
            , revision = identifier.revision
            , type_ = type_
            }
    in
    case backendAuthorityEntity of
        BackendAuthorityAcuteFindings identifier ->
            getIdentifier identifier "acute_findings"

        BackendAuthorityAcuteIllnessEncounter identifier ->
            getIdentifier identifier "acute_illness_encounter"

        BackendAuthorityAcuteIllnessMuac identifier ->
            getIdentifier identifier "acute_illness_muac"

        BackendAuthorityAcuteIllnessNutrition identifier ->
            getIdentifier identifier "acute_illness_nutrition"

        BackendAuthorityAcuteIllnessVitals identifier ->
            getIdentifier identifier "acute_illness_vitals"

        BackendAuthorityAttendance identifier ->
            getIdentifier identifier "attendance"

        BackendAuthorityBreastExam identifier ->
            getIdentifier identifier "breast_exam"

        BackendAuthorityCall114 identifier ->
            getIdentifier identifier "call_114"

        BackendAuthorityClinic identifier ->
            getIdentifier identifier "clinic"

        BackendAuthorityChildFbf identifier ->
            getIdentifier identifier "child_fbf"

        BackendAuthorityCounselingSession identifier ->
            getIdentifier identifier "counseling_session"

        BackendAuthorityCorePhysicalExam identifier ->
            getIdentifier identifier "core_physical_exam"

        BackendAuthorityDangerSigns identifier ->
            getIdentifier identifier "danger_signs"

        BackendAuthorityDashboardStats identifier ->
            getIdentifier identifier "statistics"

        BackendAuthorityExposure identifier ->
            getIdentifier identifier "exposure"

        BackendAuthorityFamilyPlanning identifier ->
            getIdentifier identifier "family_planning"

        BackendAuthorityHCContact identifier ->
            getIdentifier identifier "hc_contact"

        BackendAuthorityHeight identifier ->
            getIdentifier identifier "height"

        BackendAuthorityIndividualParticipant identifier ->
            getIdentifier identifier "individual_participant"

        BackendAuthorityIsolation identifier ->
            getIdentifier identifier "isolation"

        BackendAuthorityLactation identifier ->
            getIdentifier identifier "lactation"

        BackendAuthorityLastMenstrualPeriod identifier ->
            getIdentifier identifier "last_menstrual_period"

        BackendAuthorityMalariaTesting identifier ->
            getIdentifier identifier "malaria_testing"

        BackendAuthorityMedicalHistory identifier ->
            getIdentifier identifier "medical_history"

        BackendAuthorityMedication identifier ->
            getIdentifier identifier "medication"

        BackendAuthorityMedicationDistribution identifier ->
            getIdentifier identifier "medication_distribution"

        BackendAuthorityMotherFbf identifier ->
            getIdentifier identifier "mother_fbf"

        BackendAuthorityMuac identifier ->
            getIdentifier identifier "muac"

        BackendAuthorityNutrition identifier ->
            getIdentifier identifier "nutrition"

        BackendAuthorityNutritionEncounter identifier ->
            getIdentifier identifier "nutrition_encounter"

        BackendAuthorityNutritionHeight identifier ->
            getIdentifier identifier "nutrition_height"

        BackendAuthorityNutritionMuac identifier ->
            getIdentifier identifier "nutrition_muac"

        BackendAuthorityNutritionNutrition identifier ->
            getIdentifier identifier "nutrition_nutrition"

        BackendAuthorityNutritionPhoto identifier ->
            getIdentifier identifier "nutrition_photo"

        BackendAuthorityNutritionWeight identifier ->
            getIdentifier identifier "nutrition_weight"

        BackendAuthorityObstetricHistory identifier ->
            getIdentifier identifier "obstetric_history"

        BackendAuthorityObstetricHistoryStep2 identifier ->
            getIdentifier identifier "obstetric_history_step2"

        BackendAuthorityObstetricalExam identifier ->
            getIdentifier identifier "obstetrical_exam"

        BackendAuthorityParticipantConsent identifier ->
            getIdentifier identifier "participant_consent"

        BackendAuthorityPerson identifier ->
            getIdentifier identifier "person"

        BackendAuthorityPhoto identifier ->
            getIdentifier identifier "photo"

        BackendAuthorityPrenatalPhoto identifier ->
            getIdentifier identifier "prenatal_photo"

        BackendAuthorityPmtctParticipant identifier ->
            getIdentifier identifier "pmtct_participant"

        BackendAuthorityPrenatalFamilyPlanning identifier ->
            getIdentifier identifier "prenatal_family_planning"

        BackendAuthorityPrenatalNutrition identifier ->
            getIdentifier identifier "prenatal_nutrition"

        BackendAuthorityPrenatalEncounter identifier ->
            getIdentifier identifier "prenatal_encounter"

        BackendAuthorityRelationship identifier ->
            getIdentifier identifier "relationship"

        BackendAuthorityResource identifier ->
            getIdentifier identifier "resource"

        BackendAuthoritySendToHC identifier ->
            getIdentifier identifier "send_to_hc"

        BackendAuthoritySession identifier ->
            getIdentifier identifier "session"

        BackendAuthoritySocialHistory identifier ->
            getIdentifier identifier "social_history"

        BackendAuthoritySymptomsGeneral identifier ->
            getIdentifier identifier "symptoms_general"

        BackendAuthoritySymptomsGI identifier ->
            getIdentifier identifier "symptoms_gi"

        BackendAuthoritySymptomsRespiratory identifier ->
            getIdentifier identifier "symptoms_respiratory"

        BackendAuthorityTravelHistory identifier ->
            getIdentifier identifier "travel_history"

        BackendAuthorityTreatmentReview identifier ->
            getIdentifier identifier "treatment_history"

        BackendAuthorityWeight identifier ->
            getIdentifier identifier "weight"

        BackendAuthorityVitals identifier ->
            getIdentifier identifier "vitals"


{-| Return a photo from a "Authority" entity.
-}
getPhotoFromBackendAuthorityEntity : BackendAuthorityEntity -> Maybe String
getPhotoFromBackendAuthorityEntity backendAuthorityEntity =
    let
        getPhotoFromMeasurement identifier =
            let
                (PhotoUrl url) =
                    identifier.entity.value
            in
            Just url
    in
    case backendAuthorityEntity of
        BackendAuthorityPerson identifier ->
            identifier.entity.avatarUrl

        BackendAuthorityPhoto identifier ->
            getPhotoFromMeasurement identifier

        BackendAuthorityNutritionPhoto identifier ->
            getPhotoFromMeasurement identifier

        BackendAuthorityPrenatalPhoto identifier ->
            getPhotoFromMeasurement identifier

        _ ->
            Nothing


getSyncSpeedForSubscriptions : Model -> Float
getSyncSpeedForSubscriptions model =
    let
        syncSpeed =
            model.syncSpeed
                -- Take the original values.
                |> Editable.cancel
                |> Editable.value

        syncCycle =
            if syncSpeed.cycle < 50 then
                -- Safeguard against too quick iterations, in case someone
                -- changed values directly on localStorage.
                50

            else
                toFloat syncSpeed.cycle

        checkWebData webData =
            if RemoteData.isFailure webData then
                -- We got an error, so don't hammer the server.
                if syncSpeed.offline < 10000 then
                    10000

                else
                    toFloat syncSpeed.offline

            else
                syncCycle

        checkWebDataForPhotos webData =
            case webData of
                RemoteData.Failure error ->
                    if Utils.WebData.isNetworkError error then
                        -- It's a network error, so slow things down.
                        checkWebData webData

                    else
                        syncCycle

                _ ->
                    syncCycle
    in
    case model.syncStatus of
        SyncIdle ->
            -- Rest until the next sync loop.
            if syncSpeed.idle < 3000 then
                -- Safeguard against too quick iterations.
                3000

            else
                toFloat syncSpeed.idle

        SyncUploadGeneral record ->
            checkWebData record.backendRemoteData

        SyncUploadAuthority record ->
            checkWebData record.backendRemoteData

        SyncDownloadGeneral webData ->
            checkWebData webData

        SyncDownloadAuthority webData ->
            checkWebData webData

        SyncDownloadAuthorityDashboardStats webData ->
            checkWebData webData

        _ ->
            syncCycle


getDownloadPhotosSpeedForSubscriptions : Model -> Float
getDownloadPhotosSpeedForSubscriptions model =
    let
        syncSpeed =
            model.syncSpeed
                -- Take the original values.
                |> Editable.cancel
                |> Editable.value

        syncCycle =
            if syncSpeed.cycle < 50 then
                -- Safeguard against too quick iterations, in case someone
                -- changed values directly on localStorage.
                50

            else
                toFloat syncSpeed.cycle

        checkWebData webData =
            case webData of
                RemoteData.Failure error ->
                    if Utils.WebData.isNetworkError error then
                        -- It's a network error, so slow things down.
                        if syncSpeed.offline < 10000 then
                            10000

                        else
                            toFloat syncSpeed.offline

                    else
                        syncCycle

                _ ->
                    syncCycle
    in
    case model.downloadPhotosStatus of
        DownloadPhotosIdle ->
            -- Rest until the next sync loop.
            if syncSpeed.idle < 3000 then
                -- Safeguard against too quick iterations.
                3000

            else
                toFloat syncSpeed.idle

        DownloadPhotosInProcess downloadPhotos ->
            case downloadPhotos of
                DownloadPhotosNone ->
                    syncCycle

                DownloadPhotosBatch record ->
                    checkWebData record.backendRemoteData

                DownloadPhotosAll record ->
                    checkWebData record.backendRemoteData


encode : (a -> List ( String, Value )) -> BackendEntity a -> Value
encode encoder identifier =
    object <| encoder identifier.entity ++ [ ( "uuid", Json.Encode.string identifier.uuid ) ]


encodeBackendGeneralEntity : BackendGeneralEntity -> Value
encodeBackendGeneralEntity backendGeneralEntity =
    case backendGeneralEntity of
        BackendGeneralCatchmentArea identifier ->
            encode Backend.HealthCenter.Encoder.encodeCatchmentArea identifier

        BackendGeneralCounselingSchedule identifier ->
            encode Backend.Counseling.Encoder.encodeCounselingSchedule identifier

        BackendGeneralCounselingTopic identifier ->
            encode Backend.Counseling.Encoder.encodeCounselingTopic identifier

        BackendGeneralHealthCenter identifier ->
            encode Backend.HealthCenter.Encoder.encodeHealthCenter identifier

        BackendGeneralNurse identifier ->
            encode Backend.Nurse.Encoder.encodeNurse identifier

        BackendGeneralParticipantForm identifier ->
            encode Backend.ParticipantConsent.Encoder.encodeParticipantForm identifier

        BackendGeneralVillage identifier ->
            encode Backend.Village.Encoder.encodeVillage identifier


encodeBackendAuthorityEntity : BackendAuthorityEntity -> Value
encodeBackendAuthorityEntity entity =
    case entity of
        BackendAuthorityAcuteFindings identifier ->
            encode Backend.Measurement.Encoder.encodeAcuteFindings identifier

        BackendAuthorityAcuteIllnessEncounter identifier ->
            encode Backend.AcuteIllnessEncounter.Encoder.encodeAcuteIllnessEncounter identifier

        BackendAuthorityAcuteIllnessMuac identifier ->
            encode Backend.Measurement.Encoder.encodeAcuteIllnessMuac identifier

        BackendAuthorityAcuteIllnessNutrition identifier ->
            encode Backend.Measurement.Encoder.encodeAcuteIllnessNutrition identifier

        BackendAuthorityAcuteIllnessVitals identifier ->
            encode Backend.Measurement.Encoder.encodeAcuteIllnessVitals identifier

        BackendAuthorityAttendance identifier ->
            encode Backend.Measurement.Encoder.encodeAttendance identifier

        BackendAuthorityBreastExam identifier ->
            encode Backend.Measurement.Encoder.encodeBreastExam identifier

        BackendAuthorityCall114 identifier ->
            encode Backend.Measurement.Encoder.encodeCall114 identifier

        BackendAuthorityClinic identifier ->
            encode Backend.Clinic.Encoder.encodeClinic identifier

        BackendAuthorityChildFbf identifier ->
            encode Backend.Measurement.Encoder.encodeChildFbf identifier

        BackendAuthorityCounselingSession identifier ->
            encode Backend.Measurement.Encoder.encodeCounselingSession identifier

        BackendAuthorityCorePhysicalExam identifier ->
            encode Backend.Measurement.Encoder.encodeCorePhysicalExam identifier

        BackendAuthorityDangerSigns identifier ->
            encode Backend.Measurement.Encoder.encodeDangerSigns identifier

        BackendAuthorityDashboardStats identifier ->
            encode Backend.Dashboard.Encoder.encodeDashboardStats identifier

        BackendAuthorityExposure identifier ->
            encode Backend.Measurement.Encoder.encodeExposure identifier

        BackendAuthorityFamilyPlanning identifier ->
            encode Backend.Measurement.Encoder.encodeFamilyPlanning identifier

        BackendAuthorityHCContact identifier ->
            encode Backend.Measurement.Encoder.encodeHCContact identifier

        BackendAuthorityHeight identifier ->
            encode Backend.Measurement.Encoder.encodeHeight identifier

        BackendAuthorityIndividualParticipant identifier ->
            encode Backend.IndividualEncounterParticipant.Encoder.encodeIndividualEncounterParticipant identifier

        BackendAuthorityIsolation identifier ->
            encode Backend.Measurement.Encoder.encodeIsolation identifier

        BackendAuthorityLactation identifier ->
            encode Backend.Measurement.Encoder.encodeLactation identifier

        BackendAuthorityMalariaTesting identifier ->
            encode Backend.Measurement.Encoder.encodeMalariaTesting identifier

        BackendAuthorityLastMenstrualPeriod identifier ->
            encode Backend.Measurement.Encoder.encodeLastMenstrualPeriod identifier

        BackendAuthorityMedicalHistory identifier ->
            encode Backend.Measurement.Encoder.encodeMedicalHistory identifier

        BackendAuthorityMedication identifier ->
            encode Backend.Measurement.Encoder.encodeMedication identifier

        BackendAuthorityMedicationDistribution identifier ->
            encode Backend.Measurement.Encoder.encodeMedicationDistribution identifier

        BackendAuthorityMotherFbf identifier ->
            encode Backend.Measurement.Encoder.encodeMotherFbf identifier

        BackendAuthorityMuac identifier ->
            encode Backend.Measurement.Encoder.encodeMuac identifier

        BackendAuthorityNutrition identifier ->
            encode Backend.Measurement.Encoder.encodeNutrition identifier

        BackendAuthorityNutritionEncounter identifier ->
            encode Backend.NutritionEncounter.Encoder.encodeNutritionEncounter identifier

        BackendAuthorityNutritionHeight identifier ->
            encode Backend.Measurement.Encoder.encodeNutritionHeight identifier

        BackendAuthorityNutritionMuac identifier ->
            encode Backend.Measurement.Encoder.encodeNutritionMuac identifier

        BackendAuthorityNutritionNutrition identifier ->
            encode Backend.Measurement.Encoder.encodeNutritionNutrition identifier

        BackendAuthorityNutritionPhoto identifier ->
            encode Backend.Measurement.Encoder.encodeNutritionPhoto identifier

        BackendAuthorityNutritionWeight identifier ->
            encode Backend.Measurement.Encoder.encodeNutritionWeight identifier

        BackendAuthorityObstetricHistory identifier ->
            encode Backend.Measurement.Encoder.encodeObstetricHistory identifier

        BackendAuthorityObstetricHistoryStep2 identifier ->
            encode Backend.Measurement.Encoder.encodeObstetricHistoryStep2 identifier

        BackendAuthorityObstetricalExam identifier ->
            encode Backend.Measurement.Encoder.encodeObstetricalExam identifier

        BackendAuthorityParticipantConsent identifier ->
            encode Backend.Measurement.Encoder.encodeParticipantConsent identifier

        BackendAuthorityPerson identifier ->
            encode Backend.Person.Encoder.encodePerson identifier

        BackendAuthorityPhoto identifier ->
            encode Backend.Measurement.Encoder.encodePhoto identifier

        BackendAuthorityPrenatalPhoto identifier ->
            encode Backend.Measurement.Encoder.encodePrenatalPhoto identifier

        BackendAuthorityPmtctParticipant identifier ->
            encode Backend.PmtctParticipant.Encoder.encodePmtctParticipant identifier

        BackendAuthorityPrenatalFamilyPlanning identifier ->
            encode Backend.Measurement.Encoder.encodePrenatalFamilyPlanning identifier

        BackendAuthorityPrenatalNutrition identifier ->
            encode Backend.Measurement.Encoder.encodePrenatalNutrition identifier

        BackendAuthorityPrenatalEncounter identifier ->
            encode Backend.PrenatalEncounter.Encoder.encodePrenatalEncounter identifier

        BackendAuthorityRelationship identifier ->
            encode Backend.Relationship.Encoder.encodeRelationship identifier

        BackendAuthorityResource identifier ->
            encode Backend.Measurement.Encoder.encodeResource identifier

        BackendAuthoritySession identifier ->
            encode Backend.Session.Encoder.encodeSession identifier

        BackendAuthoritySendToHC identifier ->
            encode Backend.Measurement.Encoder.encodeSendToHC identifier

        BackendAuthoritySocialHistory identifier ->
            encode Backend.Measurement.Encoder.encodeSocialHistory identifier

        BackendAuthoritySymptomsGeneral identifier ->
            encode Backend.Measurement.Encoder.encodeSymptomsGeneral identifier

        BackendAuthoritySymptomsGI identifier ->
            encode Backend.Measurement.Encoder.encodeSymptomsGI identifier

        BackendAuthoritySymptomsRespiratory identifier ->
            encode Backend.Measurement.Encoder.encodeSymptomsRespiratory identifier

        BackendAuthorityTravelHistory identifier ->
            encode Backend.Measurement.Encoder.encodeTravelHistory identifier

        BackendAuthorityTreatmentReview identifier ->
            encode Backend.Measurement.Encoder.encodeTreatmentReview identifier

        BackendAuthorityVitals identifier ->
            encode Backend.Measurement.Encoder.encodeVitals identifier

        BackendAuthorityWeight identifier ->
            encode Backend.Measurement.Encoder.encodeWeight identifier


getDataToSendGeneral : BackendGeneralEntity -> List String -> List String
getDataToSendGeneral entity accum =
    let
        identifier =
            getBackendGeneralEntityIdentifier entity
    in
    (Json.Encode.object
        [ ( "uuid", Json.Encode.string identifier.uuid )
        , ( "vid", Json.Encode.int identifier.revision )
        , ( "entity", encodeBackendGeneralEntity entity )
        ]
        |> Json.Encode.encode 0
    )
        :: accum


getDataToSendAuthority : BackendAuthorityEntity -> List String -> List String
getDataToSendAuthority entity accum =
    let
        identifier =
            getBackendAuthorityEntityIdentifier entity
    in
    (Json.Encode.object
        [ ( "uuid", Json.Encode.string identifier.uuid )
        , ( "vid", Json.Encode.int identifier.revision )
        , ( "entity", encodeBackendAuthorityEntity entity )
        ]
        |> Json.Encode.encode 0
    )
        :: accum


getSyncedHealthCenters : Model -> List String
getSyncedHealthCenters model =
    model.syncInfoAuthorities
        |> Maybe.map (Zipper.toList >> List.map .uuid)
        |> Maybe.withDefault []


syncInfoStatusToString : SyncInfoStatus -> String
syncInfoStatusToString status =
    case status of
        Downloading ->
            "Downloading"

        Error ->
            "Error"

        NotAvailable ->
            "Not NotAvailable"

        Success ->
            "Success"

        Uploading ->
            "Uploading"


syncInfoStatusFromString : String -> Maybe SyncInfoStatus
syncInfoStatusFromString status =
    case status of
        "Downloading" ->
            Just Downloading

        "Error" ->
            Just Error

        "Not NotAvailable" ->
            Just NotAvailable

        "Success" ->
            Just Success

        "Uploading" ->
            Just Uploading

        _ ->
            Nothing


syncInfoGeneralForPort : SyncInfoGeneral -> SyncInfoGeneralForPort
syncInfoGeneralForPort info =
    SyncInfoGeneralForPort
        info.lastFetchedRevisionId
        info.lastSuccesfulContact
        info.remainingToUpload
        info.remainingToDownload
        info.deviceName
        (syncInfoStatusToString info.status)


syncInfoAuthorityForPort : SyncInfoAuthority -> SyncInfoAuthorityForPort
syncInfoAuthorityForPort info =
    SyncInfoAuthorityForPort
        info.uuid
        info.lastFetchedRevisionId
        info.lastSuccesfulContact
        info.remainingToUpload
        info.remainingToDownload
        info.statsCacheHash
        (syncInfoStatusToString info.status)


syncInfoGeneralFromPort : SyncInfoGeneralForPort -> SyncInfoGeneral
syncInfoGeneralFromPort info =
    SyncInfoGeneral
        info.lastFetchedRevisionId
        info.lastSuccesfulContact
        info.remainingToUpload
        info.remainingToDownload
        info.deviceName
        (syncInfoStatusFromString info.status |> Maybe.withDefault NotAvailable)


syncInfoAuthorityFromPort : SyncInfoAuthorityForPort -> SyncInfoAuthority
syncInfoAuthorityFromPort info =
    SyncInfoAuthority
        info.uuid
        info.lastFetchedRevisionId
        info.lastSuccesfulContact
        info.remainingToUpload
        info.remainingToDownload
        info.statsCacheHash
        (syncInfoStatusFromString info.status |> Maybe.withDefault NotAvailable)


backendGeneralEntityToRevision : BackendGeneralEntity -> Revision
backendGeneralEntityToRevision backendGeneralEntity =
    case backendGeneralEntity of
        BackendGeneralCatchmentArea identifier ->
            CatchmentAreaRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralCounselingSchedule identifier ->
            CounselingScheduleRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralCounselingTopic identifier ->
            CounselingTopicRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralHealthCenter identifier ->
            HealthCenterRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralNurse identifier ->
            NurseRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralParticipantForm identifier ->
            ParticipantFormRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendGeneralVillage identifier ->
            VillageRevision (toEntityUuid identifier.uuid) identifier.entity


backendAuthorityEntityToRevision : BackendAuthorityEntity -> Revision
backendAuthorityEntityToRevision backendAuthorityEntity =
    case backendAuthorityEntity of
        BackendAuthorityAcuteFindings identifier ->
            AcuteFindingsRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityAcuteIllnessEncounter identifier ->
            AcuteIllnessEncounterRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityAcuteIllnessMuac identifier ->
            AcuteIllnessMuacRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityAcuteIllnessNutrition identifier ->
            AcuteIllnessNutritionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityAcuteIllnessVitals identifier ->
            AcuteIllnessVitalsRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityAttendance identifier ->
            AttendanceRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityBreastExam identifier ->
            BreastExamRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityCall114 identifier ->
            Call114Revision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityClinic identifier ->
            ClinicRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityChildFbf identifier ->
            ChildFbfRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityCounselingSession identifier ->
            CounselingSessionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityCorePhysicalExam identifier ->
            CorePhysicalExamRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityDangerSigns identifier ->
            DangerSignsRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityDashboardStats identifier ->
            DashboardStatsRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityExposure identifier ->
            ExposureRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityFamilyPlanning identifier ->
            FamilyPlanningRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityHCContact identifier ->
            HCContactRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityHeight identifier ->
            HeightRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityIndividualParticipant identifier ->
            IndividualEncounterParticipantRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityIsolation identifier ->
            IsolationRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityLactation identifier ->
            LactationRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityLastMenstrualPeriod identifier ->
            LastMenstrualPeriodRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMalariaTesting identifier ->
            MalariaTestingRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMedicalHistory identifier ->
            MedicalHistoryRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMedication identifier ->
            MedicationRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMedicationDistribution identifier ->
            MedicationDistributionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMotherFbf identifier ->
            MotherFbfRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityMuac identifier ->
            MuacRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutrition identifier ->
            ChildNutritionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionEncounter identifier ->
            NutritionEncounterRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionHeight identifier ->
            NutritionHeightRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionMuac identifier ->
            NutritionMuacRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionNutrition identifier ->
            NutritionNutritionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionPhoto identifier ->
            NutritionPhotoRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityNutritionWeight identifier ->
            NutritionWeightRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityObstetricHistory identifier ->
            ObstetricHistoryRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityObstetricHistoryStep2 identifier ->
            ObstetricHistoryStep2Revision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityObstetricalExam identifier ->
            ObstetricalExamRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityParticipantConsent identifier ->
            ParticipantConsentRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPerson identifier ->
            PersonRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPhoto identifier ->
            PhotoRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPrenatalPhoto identifier ->
            PrenatalPhotoRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPmtctParticipant identifier ->
            PmtctParticipantRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPrenatalFamilyPlanning identifier ->
            PrenatalFamilyPlanningRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPrenatalNutrition identifier ->
            PrenatalNutritionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityPrenatalEncounter identifier ->
            PrenatalEncounterRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityRelationship identifier ->
            RelationshipRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityResource identifier ->
            ResourceRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySendToHC identifier ->
            SendToHCRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySession identifier ->
            SessionRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySocialHistory identifier ->
            SocialHistoryRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySymptomsGeneral identifier ->
            SymptomsGeneralRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySymptomsGI identifier ->
            SymptomsGIRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthoritySymptomsRespiratory identifier ->
            SymptomsRespiratoryRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityTravelHistory identifier ->
            TravelHistoryRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityTreatmentReview identifier ->
            TreatmentReviewRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityWeight identifier ->
            WeightRevision (toEntityUuid identifier.uuid) identifier.entity

        BackendAuthorityVitals identifier ->
            VitalsRevision (toEntityUuid identifier.uuid) identifier.entity