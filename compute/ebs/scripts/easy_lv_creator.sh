#!/usr/bin/env bash
#
# GPLv3
#

function checkArg
{
    if [ `parted -sm /dev/$1 print | grep "unrecognised disk label" | wc -l` -eq 1 ] ; then
        echo 0
    elif [ `parted -sm /dev/$1 print | grep -v BYT | wc -l ` -eq 1 ] ; then
        echo 1
    elif [ `parted -sm /dev/$1 print | grep -v BYT | wc -l ` -gt 1 ] ; then
        echo 2
    fi
}

function lvmConfigure
{
    echo "LVM Configure"
    partition="$1"1
    echo $1 $2 $3

    date=`date +%Y%m%d-%H%M%S`
    echo pvcreate $partition
    pvcreate /dev/$partition

    echo "VG Configuration"
    case "$2" in
        ?*[a-zA-Z0-9_])
            echo "Creating VG $vg with partition $partition"
            vg=$2
            vgcreate $vg /dev/$partition
            ;;
        *)
            echo "No VG specified - using `hostname -s` and $partition"
            vg=`hostname -s | sed 's/\-//g'`-`echo $((1 + RANDOM % 100))`
            vgcreate $vg /dev/$partition
    esac
    case "$3" in
        ?*[a-zA-Z0-9_])
            echo "Creating LV $lv"
            lvcreate $2 -l+100%FREE -n $3
            ;;
        *)
            echo "No LV name specificed - using lv_$date"
            lvcreate $2 -l+100%FREE -n lv_$date
    esac
}

options_found=0
while getopts ":d:v:l:" opt; do
    case $opt in
        d)
            echo "-d was found, vlaue: $OPTARG" >&2
            options_found=$((options_found + 1))
            DEVICE=$OPTARG
            ;;
        l|--lvm-name)
            echo "-l was found, value: $OPTARG" >&2
            LVNAME=$OPTARG
            options_found=$((options_found + 1))
            ;;
        v|--vg-name)
            echo "-v was found, value: $OPTARG" >&2
            options_found=$((options_found + 1))
            VGNAME=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

if [ $options_found -ne 3 ]; then
    echo "Usage: `basename $0` options (-d disk) (-l lvm_name) (-v vg_name) for help";
    exit 1
fi

DEVICEIS=`checkArg $DEVICE`

if [[ $DEVICEIS -eq 0 ]]; then
    echo "$DEVICE is a RAW device"
    exit 1
elif [[ $DEVICEIS -eq 1 ]]; then
    echo $DEVICE has a label but no partition
    exit 1
elif [[ $DEVICEIS -eq 2 ]]; then
    lvmConfigure $DEVICE $VGNAME $LVNAME
fi
