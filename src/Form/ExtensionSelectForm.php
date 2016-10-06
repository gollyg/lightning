<?php

namespace Drupal\lightning\Form;

use Drupal\Core\Extension\ExtensionDiscovery;
use Drupal\Core\Extension\InfoParserInterface;
use Drupal\Core\Form\FormBase;
use Drupal\Core\Form\FormStateInterface;
use Drupal\Core\StringTranslation\TranslationInterface;
use Drupal\lightning\Extender;
use Symfony\Component\DependencyInjection\ContainerInterface;

/**
 * Defines a form for selecting which Lightning extensions to install.
 */
class ExtensionSelectForm extends FormBase {

  /**
   * The Lightning extender configuration object.
   *
   * @var \Drupal\lightning\Extender
   */
  protected $extender;

  /**
   * An extension discovery helper.
   *
   * @var \Drupal\Core\Extension\ExtensionDiscovery
   */
  protected $extensionDiscovery;

  /**
   * The info parser service.
   *
   * @var \Drupal\Core\Extension\InfoParserInterface
   */
  protected $infoParser;

  /**
   * ExtensionSelectForm constructor.
   *
   * @param \Drupal\lightning\Extender $extender
   *   The Lightning extender configuration object.
   * @param string $root
   *   The Drupal application root.
   * @param \Drupal\Core\Extension\InfoParserInterface $info_parser
   *   The info parser service.
   * @param \Drupal\Core\StringTranslation\TranslationInterface $translator
   *   The string translation service.
   */
  public function __construct(Extender $extender, $root, InfoParserInterface $info_parser, TranslationInterface $translator) {
    $this->extender = $extender;
    $this->extensionDiscovery = new ExtensionDiscovery($root);
    $this->infoParser = $info_parser;
    $this->stringTranslation = $translator;
  }

  /**
   * {@inheritdoc}
   */
  public static function create(ContainerInterface $container) {
    return new static(
      $container->get('lightning.extender'),
      $container->get('app.root'),
      $container->get('info_parser'),
      $container->get('string_translation')
    );
  }

  /**
   * {@inheritdoc}
   */
  public function getFormId() {
    return 'lightning_select_extensions';
  }

  /**
   * Extracts a set of elements from an array by key.
   *
   * @param array $keys
   *   The keys to extract.
   * @param array $values
   *   The array from which to extract the elements.
   *
   * @return array
   *   The extracted elements.
   */
  protected function pluck(array $keys, array $values) {
    return array_intersect_key($values, array_combine($keys, $keys));
  }

  /**
   * {@inheritdoc}
   */
  public function buildForm(array $form, FormStateInterface $form_state, array &$install_state = NULL) {
    $form['#title'] = $this->t('Extensions');

    $form['extensions'] = [
      '#type' => 'checkboxes',
      '#description' => $this->t("You can choose to disable some of Lightning's functionality above. However, it is not recommended."),
    ];
    $form['experimental'] = [
      '#type' => 'fieldset',
      '#title' => $this->t('Experimental'),
      '#tree' => TRUE,
      'extensions' => [
        '#type' => 'checkboxes',
      ],
    ];
    $form['actions'] = [
      'continue' => [
        '#type' => 'submit',
        '#value' => $this->t('Continue'),
      ],
      '#type' => 'actions',
    ];

    $extensions = $this->pluck(
      [
        'lightning_media',
        'lightning_layout',
        'lightning_workflow',
        'lightning_preview',
      ],
      $this->extensionDiscovery->scan('module')
    );
    /** @var \Drupal\Core\Extension\Extension $extension */
    foreach ($extensions as $key => $extension) {
      $info = $this->infoParser->parse($extension->getPathname());

      if (empty($info['experimental'])) {
        $form['extensions']['#options'][$key] = $info['name'];
        $form['extensions']['#default_value'][] = $key;
      }
      else {
        $form['experimental']['extensions']['#options'][$key] = $info['name'];
      }
    }

    // Don't show the experimental extensions if there aren't any (duh).
    $form['experimental']['#access'] = (boolean) $form['experimental']['extensions']['#options'];

    $chosen_ones = $this->extender->getLightningExtensions();
    if (is_array($chosen_ones)) {
      $form['extensions']['#disabled'] = TRUE;
      $form['experimental']['extensions']['#disabled'] = TRUE;

      $form['extensions']['#default_value'] = array_intersect(
        array_keys($form['extensions']['#options']),
        $chosen_ones
      );
      $form['experimental']['extensions']['#default_value'] = array_intersect(
        array_keys($form['experimental']['extensions']['#options']),
        $chosen_ones
      );

      $form['extensions']['#description'] = $this->t('Lightning Extensions have been set by the lightning.extend.yml file in your sites directory and are disabled here as a result.');
    }

    return $form;
  }

  /**
   * {@inheritdoc}
   */
  public function submitForm(array &$form, FormStateInterface $form_state) {
    $modules = array_merge(
      $form_state->getValue('extensions'),
      $form_state->getValue(['experimental', 'extensions'])
    );
    $modules = array_filter($modules);

    if (in_array('lightning_media', $modules)) {
      $modules[] = 'lightning_media_document';
      $modules[] = 'lightning_media_image';
      $modules[] = 'lightning_media_instagram';
      $modules[] = 'lightning_media_twitter';
      $modules[] = 'lightning_media_video';
    }

    $GLOBALS['install_state']['lightning']['modules'] = array_merge($modules, $this->extender->getModules());
  }

}
