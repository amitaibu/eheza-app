<?php

/**
 * @file
 * Contains \HedleyMigrateMothers2019053.
 */

/**
 * Class HedleyMigrateMothers2019053.
 */
class HedleyMigrateMothers2019053 extends HedleyMigrateBase {

  public $entityType = 'node';
  public $bundle = 'mother';
  public $csvPrefix = '2019-05-3/';

  public $columns = [
    0 => ['id', 'id'],
    1 => ['first_name', 'first_name'],
    2 => ['middle_name', 'middle_name'],
    3 => ['second_name', 'second_name'],
    4 => ['birth_date', 'birth_date'],
    8 => ['ubudehe', 'ubudehe'],
    9 => ['education', 'education'],
    19 => ['cell', 'cell'],
    21 => ['health_center', 'health_center'],
  ];

  public $fields = [
    'title' => 'title',
    'clinic' => 'clinic',
  ];

  /**
   * HedleyMigrateMothers2019053 constructor.
   *
   * {@inheritdoc}
   */
  public function __construct($arguments) {
    parent::__construct($arguments);

    $this->dependencies = [
      'HedleyMigrateClinics_2019_02',
    ];

    $this->addFieldMapping('title', 'title');
    $this->addFieldMapping('field_education_level', 'education');
    $this->addFieldMapping('field_ubudehe', 'ubudehe');

    $this
      ->addFieldMapping('field_date_birth', 'birth_date')
      ->callbacks([$this, 'dateProcess']);

    $this
      ->addFieldMapping('field_clinic', 'clinic')
      ->sourceMigration('HedleyMigrateClinics_2019_02');
  }

  /**
   * Calculate some values.
   */
  public function prepareRow($row) {
    if (parent::prepareRow($row) === FALSE) {
      return FALSE;
    }

    // Calculate the mother's name.
    $row->title = implode(' ', array_filter([
      trim($row->second_name),
      trim($row->first_name),
      trim($row->middle_name),
    ]));

    $row->clinic = 'MINAZI';

    $education = strtolower(trim($row->education));

    // Education.
    if ($education) {
      if ($education === 'primary') {
        $row->education = HEDLEY_PATIENT_EDUCATION_PRIMARY;
      }
      elseif ($education === 'primary school') {
        $row->education = HEDLEY_PATIENT_EDUCATION_PRIMARY;
      }
      elseif ($education === 'primary schooling') {
        $row->education = HEDLEY_PATIENT_EDUCATION_PRIMARY;
      }
      elseif ($education === 'secondary') {
        $row->education = HEDLEY_PATIENT_EDUCATION_SECONDARY;
      }
      elseif ($education === 'secondary school') {
        $row->education = HEDLEY_PATIENT_EDUCATION_SECONDARY;
      }
      elseif ($education === 'secondary schooling') {
        $row->education = HEDLEY_PATIENT_EDUCATION_SECONDARY;
      }
      elseif ($education === 'advanced diploma') {
        $row->education = HEDLEY_PATIENT_EDUCATION_ADVANCED;
      }
      elseif ($education === 'no schooling') {
        $row->education = HEDLEY_PATIENT_EDUCATION_NONE;
      }
      elseif ($education === 'ntabwoyize') {
        // Means "no education".
        $row->education = HEDLEY_PATIENT_EDUCATION_NONE;
      }
      elseif (preg_match('/^p[1-8]$/', $education)) {
        $row->education = HEDLEY_PATIENT_EDUCATION_PRIMARY;
      }
      elseif (preg_match('/^s[1-6]$/', $education)) {
        $row->education = HEDLEY_PATIENT_EDUCATION_SECONDARY;
      }
      else {
        throw new Exception("{$row->education} is not a recognized education level for {$row->id}.");
      }
    }
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
    // The source material uses several date formats.
    $trimmed = trim($date);

    if (empty($trimmed)) {
      return $trimmed;
    }

    // Some dates are year-only ... we'll make those Jan. 1.
    if (preg_match('/^\\d\\d\\d\\d$/', $trimmed)) {
      $trimmed = "$trimmed-01-01";
    }

    if (preg_match('/^\\d\\d-\\d\\d-\\d\\d$/', $trimmed)) {
      return DateTime::createFromFormat('!y-m-d', $trimmed)->getTimestamp();
    }

    if (preg_match('/^\\d\\d\\d\\d-\\d\\d-\\d\\d$/', $trimmed)) {
      return DateTime::createFromFormat('!Y-m-d', $trimmed)->getTimestamp();
    }

    if (preg_match('@^\\d\\d?/\\d\\d?/\\d\\d\\d\\d@', $trimmed)) {
      return DateTime::createFromFormat('!d/m/Y', $trimmed)->getTimestamp();
    }

    throw new Exception("$date was not a recognized date format.");
  }

}
