#!/usr/bin/env bash

set -e

DIR="$(dirname "$(readlink -f "$0")")"

cd "$DIR" || exit 3

# filename: commandLine.sh
# author: @theBuzzyCoder

showHelp() {
    # `cat << EOF` This means that cat should stop reading when EOF is detected
    cat <<EOF
Usage: ./qemu/run.sh [-d|--distro <distro>] [-hcdnsV]
Run Qemu image with cloud init through qemu-system-*

-h, -help,          --help                      Display help
-r, -reuse,         --reuse                     Reuse previous qcow image
-d, -distro,        --distro <distro>           Which distro to use jammy,bionic,buster
-n, -name,          --name <name>               Name to use for the VM
-s, -size,          --size <size>               Size of vm eg: 20G
-c, -cloud-init,    --cloud-init <filename>     Cloud init file location
                    --vnc                       Use vnc


-V, -verbose,       --verbose                   Run script in verbose mode. Will print out each step of execution.

EOF
    # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
}

export distro=
export verbose=0
export recreate=0
export vnc=
export vm_size=
export cloud_init_file=
# $@ is all command line parameters passed to the script.
# -o is for short options like -v
# -l is for long options with double dash like --version
# the comma separates different long options
# -a is for long options with single dash like -version
options=$(getopt -l "help,recreate,distro:,cloud-init:,size:,name:,vnc,verbose," -o "hrd:n:s:c:V" -a -- "$@")

# set --:
# If no arguments follow this option, then the positional parameters are unset. Otherwise, the positional parameters
# are set to the arguments, even if some of them begin with a ‘-’.
eval set -- "$options"

while true; do
    case $1 in
    -h | --help)
        showHelp
        exit 0
        ;;
    -V | --verbose)
        export verbose=1
        echo "===> Enabling verbose mode"
        set -x
        # set -v # Set xtrace and verbose mode.
        ;;
    -d | --distro)
        shift
        export distro=$1
        ;;
    -c | --cloud-init)
        shift
        export cloud_init_file="$1"
        ;;
    -f | --recreate)
        export recreate=1
        ;;
    -s | --size)
        shift
        export vm_size="$1"
        ;;
    -n | --name)
        shift
        export vm_name="$1"
        ;;
    --vnc)
        export vnc=1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

qemu_args=

cloud_image=
cloud_image_type=
if [[ "$distro" = 'jammy' ]]; then
    cloud_image=https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
    cloud_image_type=img
elif [[ "$distro" = 'focal' ]]; then
    cloud_image=https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    cloud_image_type=img
elif [[ "$distro" = 'buster' ]]; then
    cloud_image=https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2
elif [[ "$distro" = 0 ]] && [[ "$recreate" = 1 ]]; then
    echo "Cannot recreate when no distro name is given" >&2
    exit 3
fi

original_name=
if [[ "$vm_name" = '' ]]; then
    original_name="$vm_name"
    vm_name="$distro"
fi

disk_image_path="disk-images/${vm_name}.qcow2"

if [[ "$recreate" ]]; then
    rm -f "$disk_image_path"
fi


mkdir -p disk-images cache

if [[ "$distro" ]]; then
    download_location="$DIR/cache/${distro}.qcow2"
    if [[ "$cloud_image" != '' ]] && [[ ! -f "cache/${distro}.qcow2" ]]; then
        echo "==> Downloading ${distro}"
        temp_download_location="${download_location}~temp"
        curl -SL "$cloud_image" -o "$temp_download_location"
        # if [[ "$cloud_image_type" = 'img' ]]; then
        #     qemu-img convert -f raw -O qcow2 "${temp_download_location}" "${download_location/.img/.qcow2}"
        #     rm "${temp_download_location}"
        # else
            mv "${temp_download_location}" "${download_location}"
        # fi
    
        cp "${download_location}" "$disk_image_path"
    else
        if [[ ! -f "$disk_image_path" ]]; then
            cp "${download_location}" "$disk_image_path"
        fi
    fi
fi


if [[ ! -f "${disk_image_path}" ]]; then
    echo "No disk image path found for distro '${distro}' with name: '${vm_name}'" >&2
    exit 4
fi

if [[ "$vm_size" != '' ]]; then
    echo "==> Resizing disk image with +${vm_size}"
    qemu-img resize "$disk_image_path"  "+${vm_size}"
fi


echo "==> Building cloud-image-disk"

if [[ "$cloud_init_file" != '' ]] && [[ ! -f "$cloud_init_file" ]]; then
    echo "Cloud init file not found at '$cloud_init_file'" >&2
    exit 5
fi

if [[ "$cloud_init_file" = '' ]]; then
    echo "===> Using minimal cloud init"
    cloud_init_file="$DIR/../cloud-init/minimal.yml"
fi


rm -rf cache/cidata
mkdir -p cache/cidata
(cd cache/cidata && cp "$cloud_init_file" user-data && echo "instance-id: $$(uuidgen || echo i-abcdefg)" > meta-data)
cloud-localds cache/cidata/cidata.iso cache/cidata/user-data cache/cidata/meta-data
qemu_args+="-cdrom cache/cidata/cidata.iso "



# @todo port forwarding ,hostfwd=tcp::5555-:22,hostfwd=tcp::8123-:8123


# @todo make VNC port configurable
if [[ "$vnc" != '' ]]; then
    echo "===> Using VNC '$vnc'"
    qemu_args+="-vnc :0 " #  -nographic -device sga
    /usr/share/novnc/utils/launch.sh &>/dev/null &

fi

# if [[ "$DISPLAY" = '' ]] && [[ "$vnc" = '' ]]; then
#     qemu_args+="-nographic "
# fi


machine_type="-machine type=q35"
if [[ -c /dev/kvm ]]; then
    machine_type="-machine type=q35,accel=kvm -cpu host"
    echo "===> Using KVM!"
fi

# @todo make it configurable
vm_memory=4000

echo "==> Running qemu!"
qemu-system-x86_64 -smp cores=2 -m ${vm_memory} \
    ${machine_type} \
    -drive file="$disk_image_path",format=qcow2,if=virtio \
    -device e1000,netdev=net0 -netdev user,id=net0,ipv6=off ${qemu_args}
