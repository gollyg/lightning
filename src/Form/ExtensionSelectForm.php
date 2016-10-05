<?php

namespace Drupal\lightning\Form;

use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\lightning\Extender;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Defines a form for selecting which Lightning extensions to install.
 */
class ExtensionSelectForm extends FormBase {

  /**
   * Path to the site's directory (e.g. sites/default)
   *
   * @var string
   */
  protected $extender;

  /**
   * ExtensionSelectForm constructor.
   *
   * @param Extender $extender
   *   The extender configuration object.
   */
  public function __construct(Extender $extender) {
    $this->extender = $extender;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('lightning.extender')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'lightning_select_extensions';
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state, array &$install_state = NULL) {
    $form['#title'] = $this->t('Extensions');

    $form_disabled = FALSE;
    $lightning_extensions = [
      'lightning_media',
      'lightning_layout',
      'lightning_workflow',
      FALSE,
    ];

    $description = $this->t("You can choose to disable some of Lightning's functionality above. However, it is not recommended.");

    $yml_lightning_extensions = $this->extender->getLightningExtensions();
    if (is_array($yml_lightning_extensions)) {
      // Lightning Extensions are defined in the Extender so we set default
      // values according to the Extender, disable the checkboxes, and inform
      // the user.
      $lightning_extensions = $yml_lightning_extensions;
      $form_disabled = TRUE;
      $description = $this->t('Lightning Extensions have been set by the lightning.extend.yml file in your sites directory and are disabled here as a result.');
    }

    $form['extensions'] = [
      '#type' => 'checkboxes',
      '#description' => $description,
      '#disabled' => $form_disabled,
      '#options' => [
        'lightning_media' => $this->t('Lightning Media'),
        'lightning_layout' => $this->t('Lightning Layout'),
        'lightning_workflow' => $this->t('Lightning Workflow'),
        'lightning_preview_experimental' => $this->t('Lightning Preview (Experimental)'),
      ],
      '#default_value' => $lightning_extensions,
    ];

    $form['actions'] = [
      'continue' => [
        '#type' => 'submit',
        '#value' => $this->t('Continue'),
      ],
      '#type' => 'actions',
    ];

    return $form;
  }

  /**
   * Builds and categorizes the list of modules to be enabled.
   *
   * @param \Drupal\Core\Form\FormStateInterface $form_state
   *   The form state.
   *
   * @return array
   *   The list of modules to be enabled.
   */
  public function buildModuleList(FormStateInterface $form_state) {
    $extensions = $form_state->getValue('extensions');
    $module_list = [
      'install' => [],
      'dependencies' => [],
      'experimental' => [],
    ];
    foreach ($extensions as $extension) {
      if (substr($extension, -strlen('_experimental')) == '_experimental') {
        // Remove `_experimental` which is just used as a flag.
        $extension = substr($extension, 0, -strlen('_experimental'));
        $module_list['experimental'][] = $extension;
      }
      elseif ($extension == 'lightning_media') {
        $module_list['install'][] = $extension;
        // Lightning Media has additional dependencies that aren't a hard
        // requirement but should be installed by default.
        $module_list['dependencies'][] = 'lightning_media_document';
        $module_list['dependencies'][] = 'lightning_media_image';
        $module_list['dependencies'][] = 'lightning_media_instagram';
        $module_list['dependencies'][] = 'lightning_media_twitter';
        $module_list['dependencies'][] = 'lightning_media_video';
      }
      else {
        $module_list['install'][] = $extension;
      }
    }
    if (!empty($module_list['experimental'])) {
      \Drupal::state()->set('lightning_experimental', TRUE);
    }
    return $module_list;
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $module_list = $this->buildModuleList($form_state);
    $modules = [];
    foreach ($module_list as $category) {
      foreach ($category as $module) {
        $modules[] = $module;
      }
    }
    \Drupal::state()->set('lightning_extensions', $modules);
  }

}
