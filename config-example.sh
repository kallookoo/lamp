# shellcheck disable=SC2034

# Available configurations
#
# Empty values use the defaults
# Uncomment the variable and define the valid value.
# When the value is of type boolean the possible values would be:
# - yes, y, on or 0 for the true value.
# - no, n, off or 1 for the false value.
# Note: Support insensitive case

# Fully Qualified Domain Name (FQDN) for lamp
# LAMP_CONFIG_FQDN=""

# TLD used instead of extracting it from the OS
# Note: Not used if the LAMP_CONFIG_FQDN is set.
# LAMP_CONFIG_TLD=""

# Define the IP v4 to use to configure the bind9
# Note: Only used if the TLD is not localhost
# LAMP_CONFIG_IP_ADDRESS=""

# Bind9 forwarders
# Note: By default is disabled it.
# LAMP_CONFIG_BIND_FORWARDERS=()

# Default version of PHP
# LAMP_CONFIG_PHP_VERSION=""

# Additional PHP extensions
# See the distro-name/php/install.sh file to view the predefined extensions.
# Note: If the prefix php- is specified, it will be understood that it is
#       the same package for all versions, as is the case with php-pear.
#       Otherwise any numerical prefix will be removed.
# LAMP_CONFIG_PHP_EXTENSIONS=()

# Directory to use for all domains ( virtualhosts )
# LAMP_CONFIG_VIRTUALHOSTS_DIRECTORY=""
# Default language for phpMyAdmin
# LAMP_CONFIG_PMA_LANG=""

# phpMyAdmin Cron type to execute the auto update.
# Possible values: hourly, daily, weekly, monthly, disabled
# Default value is monthly
# LAMP_CONFIG_PMA_CRON_UPGRADE=""

# MariaDB version
# See available version in https://mariadb.org
# Default value is 11.1 ( checked in November 2023 )
# LAMP_CONFIG_MARIADB_VERSION=""

# Enable the Apache h5bp configuration
# Default value is: yes
# LAMP_CONFIG_APACHE_ENABLE_H5BP=""

# Enable Apache EnableMMAP
# See: https://httpd.apache.org/docs/current/mod/core.html#enablemmap
# Default value is: no

# LAMP_CONFIG_APACHE_ENABLE_MMAP=""
# Enable Apache EnableSendfile
# See: https://httpd.apache.org/docs/current/mod/core.html#enablemmap
# Default value is: no
# LAMP_CONFIG_APACHE_ENABLE_SENDFILE=""
