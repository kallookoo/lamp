#
# Declare the Apache Repository
#

if [ ! -f /etc/apt/sources.list.d/apache2.list ]
then
  wget -q https://packages.sury.org/apache2/apt.gpg -O /etc/apt/trusted.gpg.d/apache2.gpg
  echo "deb https://packages.sury.org/apache2/ $LAMP_DISTRO_CODENAME main" > /etc/apt/sources.list.d/apache2.lisl
fi
