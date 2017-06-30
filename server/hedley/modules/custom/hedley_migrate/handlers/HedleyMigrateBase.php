<?php

/**
 * @file
 * Contains \HedleyMigrateBase.
 */

/**
 * Class HedleyMigrateBase.
 */
abstract class HedleyMigrateBase extends Migration {

  /**
   * Returns the migrate directory.
   *
   * @return string
   *   The migrate directory.
   */
  protected function getMigrateDirectory() {
    return variable_get('hedley_migrate_directory', FALSE) ? variable_get('hedley_migrate_directory') : drupal_get_path('module', 'hedley_migrate');
  }

  /**
   * Add a JPG extensions to the file name.
   *
   * @param string $name
   *   A user name.
   *
   * @return string
   *   A file name.
   */
  public function avatarProcess($name) {
    return $name . '.jpg';
  }

  /**
   * Convert a date string to a timestamp.
   *
   * @param string $date
   *   A string containing a date.
   *
   * @return int
   *   A timestamp.
   */
  public function dateProcess($date) {
    return strtotime($date);
  }

  /**
   * Add date fields.
   *
   * @param array $field_names
   *   The date related field names.
   */
  public function addDateFields(array $field_names) {
    foreach ($field_names as $field_name) {
      $this->addFieldMapping($field_name, $field_name)
        ->callbacks([$this, 'dateProcess']);
    }
  }

}
