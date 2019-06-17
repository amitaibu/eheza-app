<?php

/**
 * @file
 * Contains HedleyRestfulAttendances.
 */

/**
 * Class HedleyRestfulAttendances.
 */
class HedleyRestfulAttendances extends HedleyRestfulMotherActivityBase {

  /**
   * {@inheritdoc}
   */
  public function publicFieldsInfo() {
    $public_fields = parent::publicFieldsInfo();

    $public_fields['attended'] = [
      'property' => 'field_attended',
    ];

    return $public_fields;
  }

}