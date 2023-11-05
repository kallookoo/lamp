<?php // phpcs:disable WordPress
/**
 * All directives are explained at <https://docs.phpmyadmin.net/>.
 *
 * @package phpMyAdmin
 */

/**
 * Global configurations
 */
$cfg['ThemeManager']                  = false;
$cfg['MaxRows']                       = 50;
$cfg['SendErrorReports']              = 'never';
$cfg['TitleDefault']                  = '@HTTP_HOST@';
$cfg['TitleServer']                   = '@HTTP_HOST@';
$cfg['TitleDatabase']                 = '@HTTP_HOST@ : @DATABASE@';
$cfg['TitleTable']                    = '@HTTP_HOST@ : @DATABASE@ : @TABLE@';
$cfg['ShowDatabasesNavigationAsTree'] = false;
$cfg['VersionCheck']                  = false;
$cfg['QueryHistoryDB']                = true;
$cfg['Export']['method']              = 'custom-no-form';
$cfg['Console']['Height']             = 300;

/**
 * Servers configuration
 */

/* Server parameters */
$cfg['Servers'][ $i ]['hide_db'] = '^((information|performance)_schema|mysql|phpmyadmin|sys)$';
