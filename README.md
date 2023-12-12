# (L)inux (A)pache (M)ariaDB (P)HP

> Currently in development, use it with care and at your own risk.

## Available distros

* Debian (Tested in Virtual Maquine)
* Ubuntu (It is not tested, but it should work perfectly)

## Packages

| **Packages** | **Version**                |
| ------------ | -------------------------- |
| Apache       | Latest                     |
| PHP          | User Defined               |
| MariaDB      | User Defined               |
| phpMyAdmin   | Latest                     |
| Mailhog      | Latest                     |
| mkcert       | Latest                     |
| bind9        | System                     |

## Configurations

* Copy `config/templates/lamp.bash` file to `config/lamp.bash` and edit for customize the installation.

## Optional configurations

* Copy `config/templates/config.inc.lamp.php` to `config/config.inc.lamp.php` and edit for customize the phpMyAdmin.
* Copy `config/templates/php.ini` to `config/php.ini` and edit for customize the PHP versions.
* Copy `config/templates/php.ini` to `config/phpPHP_VERSION.ini` and edit for customize the PHP version.
> PHP_VERSION must be replaced by the version you want to customize.

## Installation

Run the `./install` with root user or sudo.


## Commands

| **Command** | **Description**                                                    |
| ----------- | ------------------------------------------------------------------ |
| mkcert      | Create or delete TLS certificates.                                 |
| lamp        | Create, delete, enable, disable the domain or restart any service. |

## Notes

* The phpMyAdmin, Mailhog and mkcert if installed using the custom script to get the latest version.
* The mkcert if installed in `/opt/mkcert` and the original mkcert binary if `/opt/mkcert/bin/current`.
* The bind9 only if installed when the TLD if not the localhost.
* By default when if used the bind9 the file `/etc/dhcp/dhclient.conf` is modified to add the ip in the nameservers.
* The "User Defined" version is declared in the configuration file (It is usually the latest) or the one declared in your installation file.
