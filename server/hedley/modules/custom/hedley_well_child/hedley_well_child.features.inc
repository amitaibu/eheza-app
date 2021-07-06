<?php

/**
 * @file
 * hedley_well_child.features.inc
 */

/**
 * Implements hook_ctools_plugin_api().
 */
function hedley_well_child_ctools_plugin_api($module = NULL, $api = NULL) {
  if ($module == "strongarm" && $api == "strongarm") {
    return array("version" => "1");
  }
}

/**
 * Implements hook_node_info().
 */
function hedley_well_child_node_info() {
  $items = array(
    'well_child_contributing_factors' => array(
      'name' => t('Well Child Contributing Factors'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_ecd' => array(
      'name' => t('Well Child ECD'),
      'base' => 'node_content',
      'description' => t('Early Childhood Development'),
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_encounter' => array(
      'name' => t('Well Child Encounter'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_follow_up' => array(
      'name' => t('Well Child Follow Up'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_health_education' => array(
      'name' => t('Well Child Health Education'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_height' => array(
      'name' => t('Well Child Height'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_muac' => array(
      'name' => t('Well Child MUAC'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_nutrition' => array(
      'name' => t('Well Child Nutrition'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_photo' => array(
      'name' => t('Well Child Photo'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_send_to_hc' => array(
      'name' => t('Well Child Send to HC'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
    'well_child_weight' => array(
      'name' => t('Well Child Weight'),
      'base' => 'node_content',
      'description' => '',
      'has_title' => '1',
      'title_label' => t('Title'),
      'help' => '',
    ),
  );
  drupal_alter('node_info', $items);
  return $items;
}