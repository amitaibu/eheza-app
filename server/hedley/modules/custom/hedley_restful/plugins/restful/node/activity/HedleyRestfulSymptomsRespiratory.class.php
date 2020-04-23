<?php

/**
 * @file
 * Contains HedleyRestfulSymptomsRespiratory.
 */

/**
 * Class HedleyRestfulSymptomsRespiratory.
 */
class HedleyRestfulSymptomsRespiratory extends HedleyRestfulAcuteIllnessActivityBase {

  /**
   * {@inheritdoc}
   */
  protected $fields = [
    'field_cough_period',
    'field_shortness_of_breath_period',
    'field_nasal_congestion_period',
    'field_blood_in_sputum_period',
    'field_sore_throat_period',
  ];

}
