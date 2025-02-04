<?php

/**
 * @file
 * Drush commands collection.
 */

/**
 * Implements hook_drush_command().
 */
function hedley_patient_drush_command() {
  $items = [];
  $items['patient-measurements'] = [
    'callback' => 'hedley_patient_patient_measurements_report',
    'description' => 'Patient report of number of measurements and their type.',
    'options' => [
      'patient' => 'Node ID of the patient.',
    ],
    'aliases' => ['ptnt-msmnts'],
  ];
  $items['consolidate-patients'] = [
    'callback' => 'hedley_patient_consolidate_patients',
    'description' => 'Consolidates data of 2 patient - used when there are duplicate instances of same patient.',
    'options' => [
      'original' => 'Node ID of the patient to which all data is consolidated.',
      'duplicate' => 'Node ID of the patient which data is moved to the original patient.',
    ],
    'aliases' => ['cns-ptnts'],
  ];

  return $items;
}

/**
 * Command callback for 'drush patient-measurements'.
 *
 * For each type of encounter, reports the number of measurement patient has.
 */
function hedley_patient_patient_measurements_report() {
  $patient = drush_get_option('patient');
  if (empty($patient)) {
    drush_print('You have to specify --patient parameter.');
    return;
  }

  $wrapper = entity_metadata_wrapper('node', $patient);
  if ($wrapper->getBundle() !== 'person') {
    drush_print('ERROR! Patient node type is not of a person. Please fix and try again.');
    return;
  }

  // Get all measurements that belong to duplicate patient.
  $measurements = hedley_general_get_person_measurements($patient);
  // If no measurements found, mark duplicate patient as 'Deleted'.
  if (count($measurements) == 0) {
    drush_print('Patient got no measurements.');
    return;
  }

  list(
    $group_measurements,
    $antenatal_measurements,
    $nutrition_measurements,
    $acute_illness_measurements,
    $home_visit_measurements,
    $well_child_measurements
    ) = _group_measurements_by_encounter_type($measurements);

  $count = count($group_measurements);
  drush_print("Patient got $count Group measurements.");
  $count = count($antenatal_measurements);
  drush_print("Patient got $count Antenatal measurements.");
  $count = count($nutrition_measurements);
  drush_print("Patient got $count Nutrition measurements.");
  $count = count($acute_illness_measurements);
  drush_print("Patient got $count Acute Illness measurements.");
  $count = count($home_visit_measurements);
  drush_print("Patient got $count Home Visit measurements.");
  $count = count($well_child_measurements);
  drush_print("Patient got $count Well Child measurements.");
}

/**
 * Command callback for 'drush consolidate-patients'.
 *
 * Validates, then executes consolidation process.
 *
 * @throws \EntityMetadataWrapperException
 */
function hedley_patient_consolidate_patients() {
  drush_print('Running validations ...');
  drush_print('');
  $success = _consolidate_patients_validate();
  if ($success) {
    drush_print('Executing consolidation ...');
    drush_print('');

    _consolidate_patients_execute();
  }
}

/**
 * Runs validations before executing consolidation process.
 *
 * @return bool
 *   True, if all validations passed.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_patients_validate() {
  $original = drush_get_option('original');
  $duplicate = drush_get_option('duplicate');

  if (empty($original) || empty($duplicate)) {
    drush_print('ERROR! You have to specify both --original and --duplicate parameter.');
    return FALSE;
  }

  $wrapper_original = entity_metadata_wrapper('node', $original);
  $wrapper_duplicate = entity_metadata_wrapper('node', $duplicate);

  if ($wrapper_original->getBundle() !== 'person') {
    drush_print('ERROR! Original patient node type is not of a person. Please fix and try again.');
    return FALSE;
  }

  if ($wrapper_duplicate->getBundle() !== 'person') {
    drush_print('ERROR! Duplicate patient node type is not of a person. Please fix and try again.');
    return FALSE;
  }

  $health_center_original = $wrapper_original->field_health_center->getIdentifier();
  $health_center_duplicate = $wrapper_duplicate->field_health_center->getIdentifier();
  // Do not allow consolidation, if patients are assigned to
  // different health centers.
  if ($health_center_original !== $health_center_duplicate) {
    drush_print('ERROR! Patients do not belong to same Health Center.');
    return FALSE;
  }

  // Get all measurements that belong to duplicate patient.
  $measurements_of_duplicate = hedley_general_get_person_measurements($duplicate);

  list(
    $group_measurements,
    $antenatal_measurements,
    $nutrition_measurements,
    $acute_illness_measurements,
    $home_visit_measurements,
    $well_child_measurements
    ) = _group_measurements_by_encounter_type($measurements_of_duplicate);

  // Validation before consolidating group encounters content.
  $success = _consolidate_group_content_validate($group_measurements, $original);
  // If consolidation failed, we make no changes, so that a fix could be
  // applied, and command could be executed again.
  if (!$success) {
    return FALSE;
  }

  // Validation before consolidating Nutrition encounters content.
  $success = _consolidate_nutrition_content_validate($nutrition_measurements, $original, $duplicate);
  if (!$success) {
    return FALSE;
  }

  // Validation before consolidating Home Visit encounters content.
  $success = _consolidate_home_visit_content_validate($home_visit_measurements, $original, $duplicate);
  if (!$success) {
    return FALSE;
  }
  // Validation before consolidating Well Child encounters content.
  $success = _consolidate_well_child_content_validate($well_child_measurements, $original, $duplicate);
  if (!$success) {
    return FALSE;
  }

  // Validation before consolidating Antenatal encounters content.
  $success = _consolidate_antenatal_content_validate($antenatal_measurements, $original, $duplicate);
  if (!$success) {
    return FALSE;
  }

  // Validation before consolidating Acute Illness encounters content.
  $success = _consolidate_acute_illness_content_validate($acute_illness_measurements, $original, $duplicate);
  if (!$success) {
    return FALSE;
  }

  drush_print('');
  drush_print('SUCCESS! All validations passed!');
  drush_print('');

  return TRUE;
}

/**
 * Executes consolidation process.
 *
 * All content is relocated from 'duplicate' patient to 'original' patient.
 * Once completed, marks 'duplicate' patient as deleted.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_patients_execute() {
  $original = drush_get_option('original');
  $duplicate = drush_get_option('duplicate');

  $wrapper_duplicate = entity_metadata_wrapper('node', $duplicate);

  // Get all measurements that belong to duplicate patient.
  $measurements_of_duplicate = hedley_general_get_person_measurements($duplicate);

  list(
    $group_measurements,
    $antenatal_measurements,
    $nutrition_measurements,
    $acute_illness_measurements,
    $home_visit_measurements,
    $well_child_measurements
    ) = _group_measurements_by_encounter_type($measurements_of_duplicate);

  // Execute consolidations.
  _consolidate_group_content_execute($group_measurements, $original);
  _consolidate_nutrition_content_execute($nutrition_measurements, $original, $duplicate);
  _consolidate_home_visit_content_execute($home_visit_measurements, $original, $duplicate);
  _consolidate_well_child_content_execute($well_child_measurements, $original, $duplicate);
  _consolidate_antenatal_content_execute($antenatal_measurements, $original, $duplicate);
  _consolidate_acute_illness_content_execute($acute_illness_measurements, $original, $duplicate);

  // Mark duplicate patient as Deleted.
  $wrapper_duplicate->field_deleted->set(TRUE);
  $wrapper_duplicate->save();

  drush_print('');
  drush_print('SUCCESS! All consolidations completed!');
  drush_print('');
}

/**
 * Performs validations before consolidation of group encounters content.
 *
 * @param array $measurements
 *   A list of group measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 *
 * @return bool
 *   True, if consolidation was successful.
 */
function _consolidate_group_content_validate(array $measurements, $original) {
  $count = count($measurements);
  drush_print("Duplicate got $count group measurements.");

  $clinics_duplicate = [];
  // Generate a list of Groups to which measurements (of the duplicate) belong.
  foreach ($measurements as $measurement) {
    $wrapper = entity_metadata_wrapper('node', $measurement);
    // Resolve the ID of Group encounter, at which measurement was taken.
    $session = $wrapper->field_session->getIdentifier();
    $wrapper_session = entity_metadata_wrapper('node', $session);
    // Resolve the ID of Group of that Group encounter.
    $clinic = $wrapper_session->field_clinic->getIdentifier();
    // Store the ID of Group.
    if (!in_array($clinic, $clinics_duplicate)) {
      $clinics_duplicate[] = $clinic;
    }
  }

  $list = implode(',', $clinics_duplicate);
  $count = count($clinics_duplicate);
  drush_print("Measurements belong to $count clinics: $list");

  $participants_original = hedley_person_pmtct_participants_for_person($original);
  $clinics_original = [];
  // Generate a list of Groups which the 'original' patient attends.
  foreach ($participants_original as $participant) {
    $wrapper_participant = entity_metadata_wrapper('node', $participant);
    $clinics_original[] = $wrapper_participant->field_clinic->getIdentifier();
  }

  $list = implode(',', $clinics_original);
  $count = count($clinics_original);
  drush_print("Original participates in $count groups: $list");

  // Verify that the 'original' patient participates in all the groups
  // to which measurements of the duplicate belong.
  foreach ($clinics_duplicate as $clinic) {
    if (!in_array($clinic, $clinics_original)) {
      drush_print("ERROR! Original is not participating in clinic $clinic. Please fix and try again.");
      return FALSE;
    }
  }

  return TRUE;
}

/**
 * Performs consolidation of group encounters content.
 *
 * @param array $measurements
 *   A list of group measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_group_content_execute(array $measurements, $original) {
  _associate_content_by_field($measurements, 'field_person', $original);

  drush_print("Consolidation of Group encounters content is completed.");
  drush_print('');
}

/**
 * Performs validations before consolidation of Prenatal encounters content.
 *
 * For now, it only prints some data. No failure option.
 *
 * @param array $measurements
 *   A list of Nutrition measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @return bool
 *   True, if validation was successful.
 */
function _consolidate_antenatal_content_validate(array $measurements, $original, $duplicate) {
  $count = count($measurements);
  drush_print("Duplicate got $count Prenatal measurements.");

  $participants_original = hedley_person_individual_participants_for_person($original, 'antenatal', 'DESC');
  $count = count($participants_original);
  drush_print("Original got $count Prenatal Participants.");

  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, 'antenatal', 'DESC');
  $count = count($participants_duplicate);
  drush_print("Duplicate got $count Prenatal Participants.");

  return TRUE;
}

/**
 * Performs consolidation of Antenatal encounters content.
 *
 * There may be multiple participants (represent pregnancy) while only one
 * (latest) can be in process. Others are completed (or should
 * be treated as such).
 *
 * Algorithm:
 *
 * 1. Closed participants are associated fully (participant itself, encounters
 *    of that participant, measurements taken at encounters).
 * 2. Ongoing participant:
 *   - If target person has ongoing participant:
 *      - Associate all encounters with target participant.
 *      - Associate measurements of those encounters with target person.
 *      - Mark source participants as deleted.
 *   - If not, associated fully (same as step 1).
 *
 * @param array $measurements
 *   A list of group measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_antenatal_content_execute(array $measurements, $original, $duplicate) {
  $participants_original = hedley_person_individual_participants_for_person($original, 'antenatal', 'DESC');
  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, 'antenatal', 'DESC');

  // Search for ongoing participant (pregnancy) of original patient.
  // If found, record it's ID.
  $participant_original_ongoing = FALSE;
  foreach ($participants_original as $participant) {
    $wrapper_participant = entity_metadata_wrapper('node', $participant);
    if (empty($wrapper_participant->field_date_concluded->value())) {
      $participant_original_ongoing = $participant;
      // There can be only one ongoing pregnancy, therefore, there's not
      // point to continue.
      break;
    }
  }

  // If original patient does not have an ongoing pregnancy, associate
  // participants and measurements of duplicate with the original patient.
  if (!$participant_original_ongoing) {
    _associate_content_by_field($participants_duplicate, 'field_person', $original);
    _associate_content_by_field($measurements, 'field_person', $original);

    drush_print("Consolidation of Prenatal encounters content is completed.");
    drush_print('');
    return;
  }

  // If we got here, we know that original patient has an ongoing pregnancy.
  // We search for ongoing pregnancy of duplicate patient.
  // If it exists, we want to associate all it's encounters with ongoing
  // pregnancy of original patient.
  $participant_duplicate_ongoing = FALSE;
  foreach ($participants_duplicate as $index => $participant) {
    $wrapper_participant = entity_metadata_wrapper('node', $participant);
    if (empty($wrapper_participant->field_date_concluded->value())) {
      // We found ongoing pregnancy of duplicate patient. We record it and
      // remove from the list of total pregnancies of the duplicate,
      // because it requires different handling.
      $participant_duplicate_ongoing = $participant;
      unset($participants_duplicate[$index]);
      break;
    }
  }

  // If duplicate patient got an ongoing pregnancy, associate all it's
  // encounters with ongoing pregnancy of original patient.
  // Afterwards, mark ongoing pregnancy of duplicate as deleted.
  if ($participant_duplicate_ongoing) {
    $encounters = hedley_person_encounters_for_individual_participant($participant_duplicate_ongoing);
    _associate_content_by_field($encounters, 'field_individual_participant', $participant_original_ongoing);

    $wrapper_participant = entity_metadata_wrapper('node', $participant_duplicate_ongoing);
    $wrapper_participant->field_deleted->set(TRUE);
    $wrapper_participant->save();
  }

  // Associate remaining  participants and measurements of duplicate,
  // with the original patient.
  _associate_content_by_field($participants_duplicate, 'field_person', $original);
  _associate_content_by_field($measurements, 'field_person', $original);

  drush_print("Consolidation of Prenatal encounters content is completed.");
  drush_print('');
}

/**
 * Performs validations before consolidation of Nutrition encounters content.
 *
 * @param array $measurements
 *   A list of Nutrition measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_validate()
 *
 * @return bool
 *   True, if validation was successful.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_nutrition_content_validate(array $measurements, $original, $duplicate) {
  return _consolidate_nutritionlike_content_validate($measurements, $original, $duplicate, 'nutrition');
}

/**
 * Performs consolidation of Nutrition encounters content.
 *
 * @param array $measurements
 *   A list of Nutrition measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_execute()
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_nutrition_content_execute(array $measurements, $original, $duplicate) {
  _consolidate_nutritionlike_content_execute($measurements, $original, $duplicate, 'nutrition');
}

/**
 * Performs validation before consolidation of Home Visit encounters content.
 *
 * @param array $measurements
 *   A list of Home Visit measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_validate()
 *
 * @return bool
 *   True, if validation was successful.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_home_visit_content_validate(array $measurements, $original, $duplicate) {
  return _consolidate_nutritionlike_content_validate($measurements, $original, $duplicate, 'home-visit');
}

/**
 * Performs consolidation of Home Visit encounters content.
 *
 * @param array $measurements
 *   A list of Home Visit measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_execute()
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_home_visit_content_execute(array $measurements, $original, $duplicate) {
  _consolidate_nutritionlike_content_execute($measurements, $original, $duplicate, 'home-visit');
}

/**
 * Performs validations before consolidation of Well Child encounters content.
 *
 * @param array $measurements
 *   A list of Well Child measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_validate()
 *
 * @return bool
 *   True, if validation was successful.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_well_child_content_validate(array $measurements, $original, $duplicate) {
  return _consolidate_nutritionlike_content_validate($measurements, $original, $duplicate, 'well-child');
}

/**
 * Performs consolidation of Well Child encounters content.
 *
 * @param array $measurements
 *   A list of Well Child measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @see: _consolidate_nutritionlike_content_execute()
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_well_child_content_execute(array $measurements, $original, $duplicate) {
  _consolidate_nutritionlike_content_execute($measurements, $original, $duplicate, 'well-child');
}

/**
 * Performs validations before consolidation for Nutrition like use case.
 *
 * This is a case where we have single participant, with multiple encounters.
 *
 *
 * Original patient must not have multiple participants, since we would not
 * know to which content should be transferred.
 * Duplicate patient may have multiple participants (though should not, per
 * system design), because all content is to be transferred. If measurements
 * exist, it should have at least one participant, because otherwise we can't
 * transfer encounters, to which measurements are associated.
 *
 * Supported encounter types:
 *  - Nutrition
 *  - Home Visit
 *  - Well Child
 *
 * @param array $measurements
 *   A list of measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 * @param string $encounter_type
 *   The type of encounter.
 *
 * @return bool
 *   True, if validation was successful.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_nutritionlike_content_validate(array $measurements, $original, $duplicate, $encounter_type) {
  if (!in_array($encounter_type, ['nutrition', 'home-visit', 'well-child'])) {
    drush_print('Error: Allowed encounter types: nutrition, home-visit, well-child');
    return FALSE;
  }

  $count_measurements = count($measurements);
  drush_print("Duplicate got $count_measurements $encounter_type measurements.");

  $participants_original = hedley_person_individual_participants_for_person($original, $encounter_type, 'DESC');
  $count_original = count($participants_original);
  if ($count_original > 1) {
    drush_print('Error: There are multiple participants for original, while only one is allowed.');
    drush_print('Can not determine with which participant to consolidate.');
    return FALSE;
  }

  $list = implode(',', $participants_original);
  drush_print("Original got $count_original $encounter_type Participants: $list");

  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, $encounter_type, 'DESC');
  $count_duplicate = count($participants_duplicate);
  if ($count_duplicate == 0 && $count_measurements > 0) {
    drush_print("Error: Duplicate got 0 $encounter_type participants. Can not pull encounters data for duplicate.");
    return FALSE;
  }

  return TRUE;
}

/**
 * Performs consolidation for Nutrition like use case.
 *
 * This is a case where we have single participant, with multiple encounters.
 * So, in case original got a participant, we associate all encounters
 * of duplicate with that participant. If not, we associate the participant
 * as well.
 * In both cases, we associate all measurements of duplicate with the original.
 *
 * Supported encounter types:
 *  - Nutrition
 *  - Home Visit
 *  - Well Child
 *
 * @param array $measurements
 *   A list of measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 * @param string $encounter_type
 *   The type of encounter.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_nutritionlike_content_execute(array $measurements, $original, $duplicate, $encounter_type) {
  $participants_original = hedley_person_individual_participants_for_person($original, $encounter_type, 'DESC');
  $count_original = count($participants_original);
  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, $encounter_type, 'DESC');

  if ($count_original == 0) {
    // If original patient does not have a participant, associate
    // one (last, if multiple) participant with the original patient.
    $original_participant = array_pop($participants_duplicate);
    // If there's no such participant, we can skip - validation has passed,
    // so there are no more measurements.
    if (empty($original_participant)) {
      drush_print("Consolidation of $encounter_type encounters content is completed.");
      drush_print('');
      return;
    }

    _associate_content_by_field([$original_participant], 'field_person', $original);
  }
  else {
    // We know there is single participant.
    $original_participant = $participants_original[0];
  }

  // Associate all encounters of the duplicate with participant of
  // original patient. The participants of the duplicate are marked as deleted.
  foreach ($participants_duplicate as $participant) {
    $encounters = hedley_person_encounters_for_individual_participant($participant);
    _associate_content_by_field($encounters, 'field_individual_participant', $original_participant);

    $wrapper_participant = entity_metadata_wrapper('node', $participant);
    $wrapper_participant->field_deleted->set(TRUE);
    $wrapper_participant->save();
  }

  // Associate all the measurements with the 'original' patient.
  _associate_content_by_field($measurements, 'field_person', $original);

  drush_print("Consolidation of $encounter_type encounters content is completed.");
  drush_print('');
}

/**
 * Performs validations before consolidation of Acute Illness content.
 *
 * For now, it only prints some data. No failure option.
 *
 * @param array $measurements
 *   A list of Nutrition measurements that belong to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @return bool
 *   True, if validation was successful.
 */
function _consolidate_acute_illness_content_validate(array $measurements, $original, $duplicate) {
  $count = count($measurements);
  drush_print("Duplicate got $count Acute Illness measurements.");

  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, 'acute_illness', 'DESC');
  $count = count($participants_duplicate);
  drush_print("Duplicate got $count  Acute Illness Participants.");

  return TRUE;
}

/**
 * Performs consolidation of Acute Illness encounters content.
 *
 * In this case we allow having multiple participants (illnesses) ongoing
 * in parallel. Therefore, we can only transfer the complete content, without
 * any additional logic.
 *
 * @param array $measurements
 *   A list of Acute Illness measurements belonging to the 'duplicate' patient.
 * @param int $original
 *   Node ID of the 'original' patient.
 * @param int $duplicate
 *   Node ID of the 'duplicate' patient.
 *
 * @throws \EntityMetadataWrapperException
 */
function _consolidate_acute_illness_content_execute(array $measurements, $original, $duplicate) {
  $participants_duplicate = hedley_person_individual_participants_for_person($duplicate, 'acute_illness', 'DESC');

  // Associate all  participants and measurements of duplicate,
  // with the original patient.
  _associate_content_by_field($participants_duplicate, 'field_person', $original);
  _associate_content_by_field($measurements, 'field_person', $original);

  drush_print("Consolidation of Acute Illness encounters content is completed.");
  drush_print('');
}

/**
 * Groups inputs measurements by the type of encounter to which they belong.
 *
 * Encounter types:
 *   - Group.
 *   - Antenatal.
 *   - Nutrition.
 *   - Acute Illness.
 *   - Home visit.
 *
 * @param array $measurements
 *   A list of measurements IDs.
 *
 * @return array[]
 *   List of measurements, grouped by encounter type.
 */
function _group_measurements_by_encounter_type(array $measurements) {
  $group_measurements = [];
  $antenatal_measurements = [];
  $nutrition_measurements = [];
  $acute_illness_measurements = [];
  $home_visit_measurements = [];
  $well_child_measurements = [];

  // Group the measurements using encounter type indicator field.
  foreach ($measurements as $measurement) {
    $wrapper = entity_metadata_wrapper('node', $measurement);

    if ($wrapper->__isset('field_session')) {
      $group_measurements[] = $measurement;
      continue;
    }

    if ($wrapper->__isset('field_prenatal_encounter')) {
      $antenatal_measurements[] = $measurement;
      continue;
    }

    if ($wrapper->__isset('field_nutrition_encounter')) {
      $nutrition_measurements[] = $measurement;
      continue;
    }

    if ($wrapper->__isset('field_acute_illness_encounter')) {
      $acute_illness_measurements[] = $measurement;
      continue;
    }

    if ($wrapper->__isset('field_home_visit_encounter')) {
      $home_visit_measurements[] = $measurement;
      continue;
    }

    if ($wrapper->__isset('field_well_child_encounter')) {
      $well_child_measurements[] = $measurement;
    }
  }

  return [
    $group_measurements,
    $antenatal_measurements,
    $nutrition_measurements,
    $acute_illness_measurements,
    $home_visit_measurements,
    $well_child_measurements,
  ];
}

/**
 * Makes the association of content, using the 'associating' field.
 *
 * For example, associates measurement with a person, using 'field' person.
 *
 * @param array $content_ids
 *   A list of Node IDs of the content we wish to associate.
 * @param string $field
 *   The 'association' field.
 * @param int $target_id
 *   Node ID to which we associate the content.
 *
 * @throws \EntityMetadataWrapperException
 */
function _associate_content_by_field(array $content_ids, $field, $target_id) {
  foreach ($content_ids as $id) {
    $wrapper = entity_metadata_wrapper('node', $id);
    $wrapper->{$field}->set($target_id);
    $wrapper->save();
  }
}
