#!/bin/bash

PGM=`basename $0`

if [ `id -u` == 0 ]
then
    echo -e "$PGM should not be run as root.\n"
    exit 1
fi

bad_install()
	{
	echo "Cannot find $1 in $PWD"
	echo "Are you running $PGM in the install directory?"
	exit 1
	}

if [ ! -x $PWD/pikrellcam ]
then
	bad_install "program pikrellcam"
fi

if [ ! -d $PWD/www ]
then
	bad_install "directory www"
fi

sudo chown .www-data $PWD/www
sudo chmod 775 $PWD/www

if [ ! -d media ]
then
	mkdir media media/archive media/videos media/thumbs media/stills
	sudo chown .www-data media media/archive media/videos media/thumbs media/stills
	sudo chmod 775 media media/archive media/videos media/thumbs media/stills
fi

if [ ! -h www/media ]
then
	ln -s $PWD/media www/media
fi

if [ ! -h www/archive ]
then
	ln -s $PWD/media/archive www/archive
fi

PORT=80

AUTOSTART=no


HTPASSWD=www/.htpasswd
PASSWORD=""

echo ""
echo "Starting PiKrellCam install..."

# =============== apt install needed packages ===============
#
JESSIE=8
STRETCH=9
V=`cat /etc/debian_version`
DEB_VERSION="${V:0:1}"

PACKAGE_LIST=""

if ((DEB_VERSION >= STRETCH))
then
	PHP_PACKAGES="php7.0 php7.0-common php7.0-fpm"
else
	PHP_PACKAGES="php5 php5-common php5-fpm"
fi

for PACKAGE in $PHP_PACKAGES
do
	if ! dpkg -s $PACKAGE 2>/dev/null | grep Status | grep -q installed
	then
		PACKAGE_LIST="$PACKAGE_LIST $PACKAGE"
	fi
done

for PACKAGE in gpac libav-tools bc \
	mpack imagemagick apache2-utils libasound2 libasound2-dev \
	libmp3lame0 libmp3lame-dev
do
	if ! dpkg -s $PACKAGE 2>/dev/null | grep Status | grep -q installed
	then
		PACKAGE_LIST="$PACKAGE_LIST $PACKAGE"
	fi
done

if [ "$PACKAGE_LIST" != "" ]
then
	echo "Installing packages: $PACKAGE_LIST"
	echo "Running: apt-get update"
	sudo apt-get update
	sudo apt-get install -y --no-install-recommends $PACKAGE_LIST
else
	echo "No packages need to be installed."
fi


if ((DEB_VERSION < JESSIE))
then
	if ! dpkg -s realpath 2>/dev/null | grep Status | grep -q installed
	then
		echo "Installing package: realpath"
		sudo apt-get install -y --no-install-recommends realpath
	fi
fi


if [ ! -h /usr/local/bin/pikrellcam ]
then
    echo "Making /usr/local/bin/pikrellcam link."
	sudo rm -f /usr/local/bin/pikrellcam
    sudo ln -s $PWD/pikrellcam /usr/local/bin/pikrellcam
else
    CURRENT_BIN=`realpath /usr/local/bin/pikrellcam`
    if [ "$CURRENT_BIN" != "$PWD/pikrellcam" ]
    then
    echo "Replacing /usr/local/bin/pikrellcam link"
        sudo rm /usr/local/bin/pikrellcam
        sudo ln -s $PWD/pikrellcam /usr/local/bin/pikrellcam
    fi
fi


# =============== create initial ~/.pikrellcam configs ===============
#
./pikrellcam -quit

if [ "$USER" == "pi" ]
then
	rm -f www/user.php
else
	printf "<?php
    \$e_user = "$USER";
?>
" > www/user.php
fi

# =============== set install_dir in pikrellcam.conf ===============
#
PIKRELLCAM_CONF=$HOME/.pikrellcam/pikrellcam.conf
if [ ! -f $PIKRELLCAM_CONF ]
then
	echo "Unexpected failure to create config file $HOME/.pikrellcam/pikrellcam.conf"
	exit 1
fi

if ! grep -q "install_dir $PWD" $PIKRELLCAM_CONF
then
	echo "Setting install_dir config line in $PIKRELLCAM_CONF:"
	echo "install_dir $PWD"
	sed -i  "/install_dir/c\install_dir $PWD" $PIKRELLCAM_CONF
fi


# =============== Setup FIFO  ===============
#
fifo=$PWD/www/FIFO

if [ ! -p "$fifo" ]
then
	rm -f $fifo
	mkfifo $fifo
fi
sudo chown $USER.www-data $fifo
sudo chmod 664 $fifo



# =============== copy scripts-dist into scripts  ===============
#
if [ ! -d scripts ]
then
	mkdir scripts
fi

cd scripts-dist

for script in *
do
	if [ ! -f ../scripts/$script ] && [ "${script:0:1}" != "_" ]
	then
		cp $script ../scripts 
	fi
done

echo ""
echo "Install finished."
echo "This install script does not automatically start pikrellcam."
echo "To start pikrellcam, open a browser page to:"
if [ "$PORT" == "80" ]
then
	echo "    http://your_pi"
else
	echo "    http://your_pi:$PORT"
fi
echo "and click on the \"System\" panel and then the \"Start PiKrellCam\" button."
echo "PiKrellCam can also be run from a Pi terminal for testing purposes."
if [ "$AUTOSTART" == "yes" ]
then
	echo "Automatic pikrellcam starting at boot is enabled."
fi
echo ""
