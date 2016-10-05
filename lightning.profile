<?php

/**
 * @file
 * Defines the Lightning Profile install screen by modifying the install form.
 */

use Drupal\lightning\Form\ExtensionSelectForm;
use Drupal\lightning\Form\ExperimentalConfirmForm;

/**
 * Implements hook_install_tasks().
 */
function lightning_install_tasks() {
  return array(
    'lightning_select_extensions' => array(
      'display_name' => t('Choose extensions'),
      'display' => TRUE,
      'type' => 'form',
      'function' => ExtensionSelectForm::class,
    ),
    'lightning_confirm_experimental' => [
      'display_name' => t('Confirm Experimental'),
      'display' => \Drupal::state()->get('lightning_experimental', FALSE),
      'type' => 'form',
      'function' => ExperimentalConfirmForm::class,
    ],
    'lightning_install_extensions' => array(
      'display_name' => t('Install extensions'),
      'display' => TRUE,
      'type' => 'batch',
    ),
  );
}

/**
 * Implements hook_install_tasks_alter().
 */
function lightning_install_tasks_alter(array &$tasks, array $install_state) {
  $tasks['install_finished']['function'] = 'lightning_post_install_redirect';
}

/**
 * Install task callback; prepares a batch job to install Lightning extensions.
 *
 * @return array
 *   The batch job definition.
 */
function lightning_install_extensions() {
  $batch = array();
  $modules = \Drupal::state()->get('lightning_extensions');
  foreach ($modules as $module) {
    $batch['operations'][] = ['lightning_install_module', (array) $module];
  }
  \Drupal::state()->delete('lightning_extensions');
  return $batch;
}

/**
 * Batch API callback. Installs a module.
 *
 * @param string|array $module
 *   The name(s) of the module(s) to install.
 */
function lightning_install_module($module) {
  \Drupal::service('module_installer')->install((array) $module);
}

/**
 * Redirects the user to a particular URL after installation.
 *
 * @param array $install_state
 *   The current install state.
 *
 * @return array
 *   A renderable array with a success message and a redirect header, if the
 *   extender is configured with one.
 */
function lightning_post_install_redirect(array &$install_state) {
  // This is the next guaranteed step after setting the experimental bool.
  \Drupal::state()->delete('lightning_experimental');

  $redirect = \Drupal::service('lightning.extender')->getRedirect();

  $output = [
    '#title' => t('Ready to rock'),
    'info' => [
      '#markup' => t('Congratulations, you installed Lightning! If you are not redirected in 5 seconds, <a href="@url">click here</a> to proceed to your site.', [
        '@url' => $redirect,
      ]),
    ],
    '#attached' => [
      'http_header' => [
        ['Cache-Control', 'no-cache'],
      ],
    ],
  ];

  // The installer doesn't make it easy (possible?) to return a redirect
  // response, so set a redirection META tag in the output.
  $meta_redirect = [
    '#tag' => 'meta',
    '#attributes' => [
      'http-equiv' => 'refresh',
      'content' => '0;url=' . $redirect,
    ],
  ];
  $output['#attached']['html_head'][] = [$meta_redirect, 'meta_redirect'];

  return $output;
}
