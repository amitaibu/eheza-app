<?php

/**
 * @file
 * Contains HedleyRestfulActivities.
 */

/**
 * Class HedleyRestfulActivities.
 */
class HedleyRestfulActivities extends RestfulEntityBaseMultipleBundles {

  /**
   * {@inheritdoc}
   */
  public function publicFieldsInfo() {
    $public_fields = parent::publicFieldsInfo();

    $public_fields['child'] = [
      'property' => 'field_child',
      'resource' => [
        // Bundle name.
        'child' => [
          // Resource name.
          'name' => 'children',
          'full_view' => TRUE,
        ],
      ],
    ];

    $public_fields['examination'] = [
      'property' => 'field_examination',
      'resource' => [
        // Bundle name.
        'examination' => [
          // Resource name.
          'name' => 'examinations',
          'full_view' => FALSE,
        ],
      ],
    ];

    $public_fields['status'] = [
      'property' => 'field_activity_status',
    ];

    return $public_fields;
  }

}
