<?php // phpcs:disable
$menu = '<ul style="list-style: none; margin: 16px 0; padding: 0; text-align: center; display: flex; justify-content: center;">';
foreach ( glob( '/etc/php/*' ) as $version ) {
	$version = substr( $version, 9 );
	$style   = 'color: #444;';
	if ( false !== strpos( PHP_VERSION, $version ) ) {
		$style .= ' font-weight: bold;';
	}
	$menu .= sprintf( '<li style="margin: 0 10px;"><a style="%2$s" href="?version=%1$s">Version %1$s</a></li>', $version, $style );
}
$menu .= '</ul>';

$meta = '
<link rel="icon" type="image/svg+xml" sizes="any" href="https://www.php.net/favicon.svg">
<link rel="icon" type="image/png" sizes="196x196" href="https://www.php.net/favicon-196x196.png">
<link rel="icon" type="image/png" sizes="32x32" href="https://www.php.net/favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="https://www.php.net/favicon-16x16.png">
<link rel="shortcut icon" href="https://www.php.net/favicon.ico">
';

ob_start();
phpinfo();
echo preg_replace(
	[ '/<body>/', '/<\/head>/' ],
	[
		sprintf( '<body>%s', $menu ),
		sprintf( '%s</head>', $meta ),
	],
	ob_get_clean(),
	1
);
