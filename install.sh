#!/bin/bash
# Teamcity installation wrapper

#
# Currently Supported Operating Systems:
#
#  CentOS 7
#

# Am I root?
if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

# Check admin user account
if [ ! -z "$(grep ^admin: /etc/passwd)" ] && [ -z "$1" ]; then
    echo "Error: user admin exists"
    echo
    echo 'Please remove admin user account before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

# Check teamcity user account
if [ ! -z "$(grep ^teamcity: /etc/group)" ] && [ -z "$1" ]; then
    echo "Error: group admin exists"
    echo
    echo 'Please remove teamcity user account before proceeding.'
    echo 'If you want to do it automatically run installer with -f option:'
    echo "Example: bash $0 --force"
    exit 1
fi

# Detect OS
case $(head -n1 /etc/issue | cut -f 1 -d ' ') in
    Debian)     type="debian" ;;
    Ubuntu)     type="ubuntu" ;;
    *)          type="rhel" ;;
esac

# Check wget
if [ -e '/usr/bin/wget' ]; then
    wget https://raw.githubusercontent.com/stasisha/teamcity-centos/master/teamcity-install-$type.sh -O teamcity-install-$type.sh
    if [ "$?" -eq '0' ]; then
        bash teamcity-install-$type.sh $*
        exit
    else
        echo "Error: vst-install-$type.sh download failed."
        exit 1
    fi
fi

# Check curl
if [ -e '/usr/bin/curl' ]; then
    curl -O http://vestacp.com/pub/vst-install-$type.sh
    if [ "$?" -eq '0' ]; then
        bash vst-install-$type.sh $*
        exit
    else
        echo "Error: vst-install-$type.sh download failed."
        exit 1
    fi
fi

exit
