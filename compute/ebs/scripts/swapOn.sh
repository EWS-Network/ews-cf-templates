#!/usr/bin/env bash"
"# Script to put disk / partition to swap pool"

if ! [ "$#" -eq 1 ]; then
    echo No disk specified
    exit 1
fi

while true ; do
    if [ `fdisk -l | grep $1 | wc -l` -gt 0 ]; then
	parted -a optimal -s -- /dev/$1 mklabel gpt mkpart primary 0% 100%;
	break
    fi
    sleep 5
    echo Disk $1 not yet found on the system
done

function turnOnSwap
{
    mkswap /dev/\$1\1
    swapon /dev/\$1\1
}

echo Swapping on !
turnOnSwap $1 && exit 0 || echo failed to turn on swap for $1 && exit 1
