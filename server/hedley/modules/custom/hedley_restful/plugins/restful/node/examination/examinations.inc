<?php

/**
 * @file
 * Restful plugin.
 */

$plugin = array(
  'label' => t('Examinations'),
  'resource' => 'examinations',
  'name' => 'examinations',
  'entity_type' => 'node',
  'bundle' => 'examination',
  'description' => t('Exports the Examination bundle.'),
  'class' => 'HedleyRestfulExaminations',
  'authentication_types' => TRUE,
);