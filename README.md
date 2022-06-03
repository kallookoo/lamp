# (L)inux (A)pache (M)ariaDB (P)HP

> Currently in development, use it with care and at your own risk.

## Available distros

* Debian (Tested on Debian 11 using Virtualbox and bridge mode)
* Ubuntu (It is not tested, but it should work perfectly)

## Packages

| **Packages** | **Version**           |
| ------------ | --------------------- |
| Apache       | 2.4                   |
| PHP          | Latest, 8.1, 8.0, 7.4 |
| MariaDB      | 10.8                  |
| phpMyAdmin   | Latest                |
| Mailhog      | Latest                |
| mkcert       | Latest                |
| bind9        | Latest                |

## Configurations

View and edit [config.sh](config.sh) file to customize installation.

## Commands

| **Command** | **Description**                                                          |
| ----------- | ------------------------------------------------------------------------ |
| mkcert      | For create or delete TLS certificates.                                   |
| lamp        | For create, delete, enable or disable the domain or restart any service. |

## Notes

* The Latest version of PHP is the default version of the distro.
* The phpMyAdmin, Mailhog and mkcert if installed using the custom script to get the latest version.
* The mkcert if installed in `/opt/mkcert` and the original mkcert binary if `/opt/mkcert/bin/current`.
* The bind9 only if installed when the TLD if not the localhost.
* By default when if used the bind9 the file `/etc/dhcp/dhclient.conf` is modified to add the ip in the nameservers.
