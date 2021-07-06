<?php

/**
 * @file
 * hedley_well_child.features.user_permission.inc
 */

/**
 * Implements hook_user_default_permissions().
 */
function hedley_well_child_user_default_permissions() {
  $permissions = array();

  // Exported permission: 'create well_child_contributing_factors content'.
  $permissions['create well_child_contributing_factors content'] = array(
    'name' => 'create well_child_contributing_factors content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_ecd content'.
  $permissions['create well_child_ecd content'] = array(
    'name' => 'create well_child_ecd content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_encounter content'.
  $permissions['create well_child_encounter content'] = array(
    'name' => 'create well_child_encounter content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_follow_up content'.
  $permissions['create well_child_follow_up content'] = array(
    'name' => 'create well_child_follow_up content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_health_education content'.
  $permissions['create well_child_health_education content'] = array(
    'name' => 'create well_child_health_education content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_height content'.
  $permissions['create well_child_height content'] = array(
    'name' => 'create well_child_height content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_muac content'.
  $permissions['create well_child_muac content'] = array(
    'name' => 'create well_child_muac content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_nutrition content'.
  $permissions['create well_child_nutrition content'] = array(
    'name' => 'create well_child_nutrition content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_photo content'.
  $permissions['create well_child_photo content'] = array(
    'name' => 'create well_child_photo content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_send_to_hc content'.
  $permissions['create well_child_send_to_hc content'] = array(
    'name' => 'create well_child_send_to_hc content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'create well_child_weight content'.
  $permissions['create well_child_weight content'] = array(
    'name' => 'create well_child_weight content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_contributing_factors content'.
  $permissions['delete any well_child_contributing_factors content'] = array(
    'name' => 'delete any well_child_contributing_factors content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_ecd content'.
  $permissions['delete any well_child_ecd content'] = array(
    'name' => 'delete any well_child_ecd content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_encounter content'.
  $permissions['delete any well_child_encounter content'] = array(
    'name' => 'delete any well_child_encounter content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_follow_up content'.
  $permissions['delete any well_child_follow_up content'] = array(
    'name' => 'delete any well_child_follow_up content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_health_education content'.
  $permissions['delete any well_child_health_education content'] = array(
    'name' => 'delete any well_child_health_education content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_height content'.
  $permissions['delete any well_child_height content'] = array(
    'name' => 'delete any well_child_height content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_muac content'.
  $permissions['delete any well_child_muac content'] = array(
    'name' => 'delete any well_child_muac content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_nutrition content'.
  $permissions['delete any well_child_nutrition content'] = array(
    'name' => 'delete any well_child_nutrition content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_photo content'.
  $permissions['delete any well_child_photo content'] = array(
    'name' => 'delete any well_child_photo content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_send_to_hc content'.
  $permissions['delete any well_child_send_to_hc content'] = array(
    'name' => 'delete any well_child_send_to_hc content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete any well_child_weight content'.
  $permissions['delete any well_child_weight content'] = array(
    'name' => 'delete any well_child_weight content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_contributing_factors content'.
  $permissions['delete own well_child_contributing_factors content'] = array(
    'name' => 'delete own well_child_contributing_factors content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_ecd content'.
  $permissions['delete own well_child_ecd content'] = array(
    'name' => 'delete own well_child_ecd content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_encounter content'.
  $permissions['delete own well_child_encounter content'] = array(
    'name' => 'delete own well_child_encounter content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_follow_up content'.
  $permissions['delete own well_child_follow_up content'] = array(
    'name' => 'delete own well_child_follow_up content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_health_education content'.
  $permissions['delete own well_child_health_education content'] = array(
    'name' => 'delete own well_child_health_education content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_height content'.
  $permissions['delete own well_child_height content'] = array(
    'name' => 'delete own well_child_height content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_muac content'.
  $permissions['delete own well_child_muac content'] = array(
    'name' => 'delete own well_child_muac content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_nutrition content'.
  $permissions['delete own well_child_nutrition content'] = array(
    'name' => 'delete own well_child_nutrition content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_photo content'.
  $permissions['delete own well_child_photo content'] = array(
    'name' => 'delete own well_child_photo content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_send_to_hc content'.
  $permissions['delete own well_child_send_to_hc content'] = array(
    'name' => 'delete own well_child_send_to_hc content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'delete own well_child_weight content'.
  $permissions['delete own well_child_weight content'] = array(
    'name' => 'delete own well_child_weight content',
    'roles' => array(
      'administrator' => 'administrator',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_contributing_factors content'.
  $permissions['edit any well_child_contributing_factors content'] = array(
    'name' => 'edit any well_child_contributing_factors content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_ecd content'.
  $permissions['edit any well_child_ecd content'] = array(
    'name' => 'edit any well_child_ecd content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_encounter content'.
  $permissions['edit any well_child_encounter content'] = array(
    'name' => 'edit any well_child_encounter content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_follow_up content'.
  $permissions['edit any well_child_follow_up content'] = array(
    'name' => 'edit any well_child_follow_up content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_health_education content'.
  $permissions['edit any well_child_health_education content'] = array(
    'name' => 'edit any well_child_health_education content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_height content'.
  $permissions['edit any well_child_height content'] = array(
    'name' => 'edit any well_child_height content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_muac content'.
  $permissions['edit any well_child_muac content'] = array(
    'name' => 'edit any well_child_muac content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_nutrition content'.
  $permissions['edit any well_child_nutrition content'] = array(
    'name' => 'edit any well_child_nutrition content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_photo content'.
  $permissions['edit any well_child_photo content'] = array(
    'name' => 'edit any well_child_photo content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_send_to_hc content'.
  $permissions['edit any well_child_send_to_hc content'] = array(
    'name' => 'edit any well_child_send_to_hc content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit any well_child_weight content'.
  $permissions['edit any well_child_weight content'] = array(
    'name' => 'edit any well_child_weight content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_contributing_factors content'.
  $permissions['edit own well_child_contributing_factors content'] = array(
    'name' => 'edit own well_child_contributing_factors content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_ecd content'.
  $permissions['edit own well_child_ecd content'] = array(
    'name' => 'edit own well_child_ecd content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_encounter content'.
  $permissions['edit own well_child_encounter content'] = array(
    'name' => 'edit own well_child_encounter content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_follow_up content'.
  $permissions['edit own well_child_follow_up content'] = array(
    'name' => 'edit own well_child_follow_up content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_health_education content'.
  $permissions['edit own well_child_health_education content'] = array(
    'name' => 'edit own well_child_health_education content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_height content'.
  $permissions['edit own well_child_height content'] = array(
    'name' => 'edit own well_child_height content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_muac content'.
  $permissions['edit own well_child_muac content'] = array(
    'name' => 'edit own well_child_muac content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_nutrition content'.
  $permissions['edit own well_child_nutrition content'] = array(
    'name' => 'edit own well_child_nutrition content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_photo content'.
  $permissions['edit own well_child_photo content'] = array(
    'name' => 'edit own well_child_photo content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_send_to_hc content'.
  $permissions['edit own well_child_send_to_hc content'] = array(
    'name' => 'edit own well_child_send_to_hc content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  // Exported permission: 'edit own well_child_weight content'.
  $permissions['edit own well_child_weight content'] = array(
    'name' => 'edit own well_child_weight content',
    'roles' => array(
      'administrator' => 'administrator',
      'sync' => 'sync',
    ),
    'module' => 'node',
  );

  return $permissions;
}