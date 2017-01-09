<?php
/**
 * @file
 * hedley_activity.features.inc
 */

/**
 * Implements hook_ctools_plugin_api().
 */
function hedley_activity_ctools_plugin_api($module = NULL, $api = NULL) {
  if ($module == "strongarm" && $api == "strongarm") {
    return array("version" => "1");
  }
}

/**
 * Implements hook_node_info().
 */
function hedley_activity_node_info() {
  $items = array(
    'weight' => array(
      'name' => t('Weight'),
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