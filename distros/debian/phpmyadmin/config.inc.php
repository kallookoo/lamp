<?php // phpcs:disable WordPress
/**
 * All directives are explained at <https://docs.phpmyadmin.net/>.
 *
 * @package PhpMyAdmin
 */

/**
 * Global phpMyAdmin configurations
 */
$cfg['TempDir']     = '/tmp/';
$cfg['DefaultLang'] = '__PMA_LANG__';

/**
 * Servers configuration
 */

/** Set to one because not exists another server. */
$i = 1;

/** Authentication type */
$cfg['Servers'][ $i ]['auth_type'] = 'config';
$cfg['Servers'][ $i ]['user']      = 'root';
$cfg['Servers'][ $i ]['password']  = 'root';

/**
 * Configuration storage settings.
 */

/** User used to manipulate with storage */
$cfg['Servers'][ $i ]['controluser'] = 'pma';
$cfg['Servers'][ $i ]['controlpass'] = '__PMA_PASSWORD__';

/** Storage database and tables */
$cfg['Servers'][ $i ]['pmadb']             = 'phpmyadmin';
$cfg['Servers'][ $i ]['bookmarktable']     = 'pma__bookmark';
$cfg['Servers'][ $i ]['relation']          = 'pma__relation';
$cfg['Servers'][ $i ]['table_info']        = 'pma__table_info';
$cfg['Servers'][ $i ]['table_coords']      = 'pma__table_coords';
$cfg['Servers'][ $i ]['pdf_pages']         = 'pma__pdf_pages';
$cfg['Servers'][ $i ]['column_info']       = 'pma__column_info';
$cfg['Servers'][ $i ]['history']           = 'pma__history';
$cfg['Servers'][ $i ]['table_uiprefs']     = 'pma__table_uiprefs';
$cfg['Servers'][ $i ]['tracking']          = 'pma__tracking';
$cfg['Servers'][ $i ]['userconfig']        = 'pma__userconfig';
$cfg['Servers'][ $i ]['recent']            = 'pma__recent';
$cfg['Servers'][ $i ]['favorite']          = 'pma__favorite';
$cfg['Servers'][ $i ]['users']             = 'pma__users';
$cfg['Servers'][ $i ]['usergroups']        = 'pma__usergroups';
$cfg['Servers'][ $i ]['navigationhiding']  = 'pma__navigationhiding';
$cfg['Servers'][ $i ]['savedsearches']     = 'pma__savedsearches';
$cfg['Servers'][ $i ]['central_columns']   = 'pma__central_columns';
$cfg['Servers'][ $i ]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][ $i ]['export_templates']  = 'pma__export_templates';

/**
 * Custom configurations.
 */
if ( is_readable( __DIR__ . '/config.inc.lamp.php' ) ) {
	include __DIR__ . '/config.inc.lamp.php';
}
