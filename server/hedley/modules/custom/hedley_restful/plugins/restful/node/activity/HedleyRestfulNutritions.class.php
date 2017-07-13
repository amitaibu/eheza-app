<?php

/**
 * @file
 * Contains HedleyRestfulNutritions.
 */

/**
 * Class HedleyRestfulNutritions.
 */
class HedleyRestfulNutritions extends HedleyRestfulActivityBase {

  /**
   * Return the type of the activity.
   *
   * @return string
   *   The type name.
   */
  protected static function getType() {
    return 'nutrition';
  }

  /**
   * {@inheritdoc}
   */
  public function publicFieldsInfo() {
    $public_fields = parent::publicFieldsInfo();

    $public_fields['examination'] = [
      'property' => 'field_examination',
      'resource' => [
        // Bundle name.
        'examination' => [
          // Resource name.
          'name' => 'examinations',
          'full_view' => TRUE,
        ],
      ],
    ];

    $public_fields['nutrition_signs'] = [
      'property' => 'field_nutrition_signs',
    ];

    return $public_fields;
  }

}