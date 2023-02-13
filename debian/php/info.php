<?php // phpcs:disable
ob_start();
?>
<ul style="list-style: none; margin: 16px 0; padding: 0; text-align: center; display: flex; justify-content: center;">
<?php
foreach ( glob( '/etc/php/*' ) as $version ) {
	?>
	<li style="margin: 0 10px;">
	<?php
	$version = basename( $version );
	$style   = 'color: #444;';
	if ( false !== strpos( PHP_VERSION, $version ) ) {
		$style .= ' font-weight: bold;';
	}
	printf( '<a style="%2$s" href="?version=%1$s">Version %1$s</a></li>', $version, $style );
}
?>
</ul>
<?php
$menu = ob_get_clean();
ob_start();
phpinfo();
echo str_replace( '<body>', "<body>{$menu}", ob_get_clean() );
