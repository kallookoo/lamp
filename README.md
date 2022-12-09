# (L)inux (A)pache (M)ariaDB (P)HP

> Currently in development, use it with care and at your own risk.

## Available distros

* Debian (Tested on Debian 11 installed in Virtual Maquine and using bridge mode)
* Ubuntu (It is not tested, but it should work perfectly)

## Packages

| **Packages** | **Version**                |
| ------------ | -------------------------- |
| Apache       | 2.4                        |
| PHP          | default and 7.4 and above. |
| MariaDB      | 10.10                      |
| phpMyAdmin   | Latest                     |
| Mailhog      | Latest                     |
| mkcert       | Latest                     |
| bind9        | Latest                     |

## Configurations

Copy [config-example.sh](config-example.sh) file to config.sh and edit for customize installation.

## Commands

| **Command** | **Description**                                                        |
| ----------- | ---------------------------------------------------------------------- |
| mkcert      | For create or delete TLS certificates.                                 |
| lamp        | For create, delete, enable, disable the domain or restart any service. |

## Notes

* The phpMyAdmin, Mailhog and mkcert if installed using the custom script to get the latest version.
* The mkcert if installed in `/opt/mkcert` and the original mkcert binary if `/opt/mkcert/bin/current`.
* The bind9 only if installed when the TLD if not the localhost.
* By default when if used the bind9 the file `/etc/dhcp/dhclient.conf` is modified to add the ip in the nameservers.
