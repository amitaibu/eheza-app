<?php

use Robo\Tasks;
use Symfony\Component\Yaml\Yaml;

/**
 * Robo commmands.
 */
class RoboFile extends Tasks {

  /**
   * The Pantheon name.
   *
   * You need to fill this information for Robo to know what's the name of your
   * site.
   */
  const PANTHEON_NAME = 'ihangane';

  /**
   * Deploy to Pantheon.
   *
   * @param string $branchName
   *   The branch name to commit to. Default to master.
   *
   * @throws \Exception
   */
  public function deployPantheon($branchName = 'master') {
    if (empty(self::PANTHEON_NAME)) {
      throw new Exception('You need to fill the "PANTHEON_NAME" const in the Robo file. so it will know what is the name of your site.');
    }

    $pantheonDirectory = '.pantheon';

    $result = $this
      ->taskExec('git status -s')
      ->printOutput(FALSE)
      ->run();

    if ($result->getMessage()) {
      throw new Exception('The working directory is dirty. Please commit any pending changes.');
    }

    $result = $this
      ->taskExec("cd $pantheonDirectory && git status -s")
      ->printOutput(FALSE)
      ->run();

    if ($result->getMessage()) {
      throw new Exception('The Pantheon directory is dirty. Please commit any pending changes.');
    }

    // Validate pantheon.upstream.yml.
    $pantheonConfig = $pantheonDirectory . '/pantheon.upstream.yml';
    if (!file_exists($pantheonConfig)) {
      throw new Exception("pantheon.upstream.yml is missing from the Pantheon directory ($pantheonDirectory)");
    }

    $yaml = Yaml::parseFile($pantheonConfig);
    if (empty($yaml['php_version'])) {
      throw new Exception("'php_version:' directive is missing from pantheon.upstream.yml in Pantheon directory ($pantheonDirectory)");
    }

    $this->_exec("cd $pantheonDirectory && git checkout $branchName");

    $rsyncExclude = [
      '.git',
      '.circleci',
      '.ddev',
      '.idea',
      '.pantheon',
      'sites/default',
      'sites/all/vendor',
      'pantheon.yml',
      'pantheon.upstream.yml',
      'client',
    ];

    $rsyncExcludeString = '--exclude=' . implode(' --exclude=', $rsyncExclude);

    // Copy all files and folders of the Drupal installation.
    $server_sync_result = $this->_exec("rsync -az -q -L -K --delete $rsyncExcludeString www/. $pantheonDirectory")->getExitCode();
    if ($server_sync_result != 0) {
      throw new Exception('Failed to sync the server-side');
    }

    // Copy all the files and folders of the app.
    // Inside Docker, we do mount the client separately.
    $client_source = '/var/client';
    if (!file_exists($client_source)) {
      $client_source = '../client';
    }

    $client_sync_result = $this->_exec("rsync -az -q -L -K --delete $client_source/dist/. $pantheonDirectory/app")->getExitCode();
    if ($client_sync_result != 0) {
      throw new Exception('Failed to sync the client-side');
    }

    // We don't want to change Pantheon's git ignore, as we do want to commit
    // vendor and contrib directories.
    // @todo: Ignore it from rsync, but './.gitignore' didn't work.
    $this->_exec("cd $pantheonDirectory && git checkout .gitignore");

    $this->_exec("cd $pantheonDirectory && git status");

    $commitAndDeployConfirm = $this->confirm('Commit changes and deploy?', TRUE);
    if (!$commitAndDeployConfirm) {
      $this->say('Aborted commit and deploy, you can do it manually');

      // The Pantheon repo is dirty, so check if we want to clean it up before
      // exit.
      $cleanupPantheonDirectoryConfirm = $this->confirm("Revert any changes on $pantheonDirectory directory (i.e. `git checkout .`)?");
      if (!$cleanupPantheonDirectoryConfirm) {
        // Keep folder as is.
        return;
      }

      // We repeat "git clean" twice, as sometimes it seems that a single one
      // doesn't remove all directories.
      $this->_exec("cd $pantheonDirectory && git checkout . && git clean -fd && git clean -fd && git status");

      return;
    }

    $this->_exec("cd $pantheonDirectory && git pull && git add . && git commit -am 'Site update' && git push");

    $pantheonEnv = $branchName == 'master' ? 'dev' : $branchName;
    $this->deployPantheonSync($pantheonEnv, FALSE);
  }

  /**
   * Deploy site from one env to the other on Pantheon.
   *
   * @param string $env
   *   The environment to update.
   * @param bool $doDeploy
   *   Determine if a deploy should be done by terminus. That is, for example
   *   should TEST environment be updated from DEV.
   *
   * @throws \Robo\Exception\TaskException
   */
  public function deployPantheonSync(string $env = 'test', bool $doDeploy = TRUE) {
    $pantheonName = self::PANTHEON_NAME;
    $pantheonTerminusEnvironment = $pantheonName . '.' . $env;

    $task = $this->taskExecStack();

    if ($doDeploy) {
      $task->exec("terminus env:deploy $pantheonTerminusEnvironment");
    }

    $task
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cc all")
      // A second cache-clear, because Drupal...
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- cc all")
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- updb -y")
      ->exec("terminus remote:drush $pantheonTerminusEnvironment -- uli")
      ->run();
  }

}
