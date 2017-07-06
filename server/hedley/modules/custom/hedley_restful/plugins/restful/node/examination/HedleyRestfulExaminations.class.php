<?php

/**
 * @file
 * Contains \HedleyRestfulExaminations.
 */

/**
 * Class HedleyRestfulExaminations.
 */
class HedleyRestfulExaminations extends HedleyRestfulEntityBaseNode {

  /**
   * {@inheritdoc}
   */
  public function publicFieldsInfo() {
    $public_fields = parent::publicFieldsInfo();

    $public_fields['group'] = [
      'property' => 'field_group',
      'resource' => [
        // Bundle name.
        'group' => [
          // Resource name.
          'name' => 'groups',
        ],
      ],
    ];

    $public_fields['last_assessment'] = [
      'property' => 'field_last_assessment',
      'process_callbacks' => [
        [$this, 'convertTimestampToIso8601'],
      ],
    ];

    return $public_fields;
  }

}