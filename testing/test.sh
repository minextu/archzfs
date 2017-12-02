#!/bin/bash

args=("$@")
script_name=$(basename $0)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! source ${script_dir}/../lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi
source_safe "${script_dir}/../conf.sh"

ssh_options="-i files/ssh.key -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o ConnectTimeout=3"
ssh="/usr/bin/ssh ${ssh_options}"
scp="/usr/bin/scp ${ssh_options}"
test_pkg_workdir="archzfs"

if [[ ${EUID} -ne 0 ]]; then
    error "This script must be run as root."
    exit 155;
fi

export vm_work_dir="${script_dir}/files/vm-work"
export base_image_output_dir="${script_dir}/files"

# Build the archiso with linux-lts if needed
archiso_build() {
    msg "Building the archiso if required"
    local build_archiso=0

    # Check the linux-lts version last used in the archiso
    msg2 "Checking for previous archiso build"

    run_cmd_no_output_no_dry_run "cat ${script_dir}/../archiso/work/iso/arch/pkglist.x86_64.txt 2> /dev/null | grep linux-lts | grep -oP '(?<=core/linux-lts-).*$'"
    if [[ ${run_cmd_return} -ne 0 ]]; then
        msg2 "Building the archiso!"
        build_archiso=1
    else
        current_archiso_lts_vers="${run_cmd_output}"
        msg2 "Checking for archiso image"
        run_cmd_no_output_no_dry_run "find ${vm_work_dir} -maxdepth 1 -name 'archlinux*.iso' -print | grep -q archlinux"
        if [[ ${run_cmd_return} -eq 1 ]]; then
            msg2 "archzfs archiso does not exist!"
            build_archiso=1
        else
            # Make sure the archiso packages in the archiso are the current version
            debug "current_archiso_lts_vers: ${current_archiso_lts_vers}"
            if ! check_webpage "https://www.archlinux.org/packages/core/x86_64/linux-lts/" "(?<=<h2>linux-lts )[\d\.-]+(?=</h2>)" "${current_archiso_lts_vers}"; then
                msg2 "Building the archiso!"
                build_archiso=1
            fi
        fi
    fi

    if [[ ${build_archiso} -eq 0 ]]; then
        msg2 "archiso is up-to-date!"
        return
    fi

    # Ensure no mounts exist in archiso output directories, exit if mounts are detected
    run_cmd_no_output_no_dry_run "mount | grep airootfs"

    if [[ ${run_cmd_return} -eq 0 ]]; then
        error "airootfs bind mounds detected! Please unmount before continuing!"
        exit 1
    fi

    # Delete the working directories since we are out-of-date
    #run_cmd_no_output_no_dry_run "rm -rf ${script_dir}/../archiso/out ${script_dir}/../archiso/work ${vm_work_dir}/*.iso"

    #run_cmd "${script_dir}/../archiso/build.sh -v"
    #msg2 "Copying archiso to vm_work_dir"
    #run_cmd "cp ${script_dir}/../archiso/out/archlinux* ${vm_work_dir}"
}

archiso_init_vars() {
    export archiso_iso_name=$(find ${vm_work_dir}/ -iname "archlinux*.iso" | xargs basename 2> /dev/null )
    export archiso_sha=$(sha1sum ${vm_work_dir}/${archiso_iso_name} 2> /dev/null | awk '{ print $1 }')
    export archiso_url="${vm_work_dir}/${archiso_iso_name}"
    debug "archiso_iso_name=${archiso_iso_name}"
    debug "archiso_sha=${archiso_sha}"
    debug "archiso_url=${archiso_url}"
}

if [[ true ]]; then

    msg "Building arch base image"

    if [[ ! -d "${vm_work_dir}" ]]; then
        run_cmd_no_output_no_dry_run "mkdir -p ${vm_work_dir}"
    fi

    if [[ ! -f "${vm_work_dir}/mirrorlist" ]]; then
        msg2 "Generating pacman mirrorlist"
        run_cmd_no_dry_run "/usr/bin/reflector -c US -l 5 -f 5 --sort rate 2>&1 > ${vm_work_dir}/mirrorlist && cat ${vm_work_dir}/mirrorlist"
    fi

    archiso_build
    archiso_init_vars

    msg "Resetting ownership"
    run_cmd "chown -R ${makepkg_nonpriv_user}: '${vm_work_dir}'"
fi

if [[ ! -d "${vm_work_dir}/current-test" ]]; then
     run_cmd_no_output_no_dry_run "mkdir -p ${vm_work_dir}/current-test"
fi
# symlink files
test_mode=dummy
# Base files
run_cmd_no_output_no_dry_run "check_symlink '${script_dir}/../lib.sh' '${vm_work_dir}/current-test/lib.sh'"
run_cmd_no_output_no_dry_run "check_symlink '${script_dir}/../conf.sh' '${vm_work_dir}/current-test/archzfs-conf.sh'"
run_cmd_no_output_no_dry_run "check_symlink '${script_dir}/files/poweroff.timer' '${vm_work_dir}/current-test/poweroff.timer'"

# Test files
run_cmd_no_output_no_dry_run "check_symlink '${script_dir}/tests/${test_mode}.sh' '${vm_work_dir}/current-test/test.sh'"
run_cmd_no_output_no_dry_run "check_symlink '${script_dir}/files/run-test.sh' '${vm_work_dir}/current-test/run-test.sh'"


msg "Allocate hdd image"
qemu-img create -f qcow2 ${script_dir}/files/vm-work/archzfs-testing.qcow2 20G

msg "Create libvirt vm"
virsh create /dev/stdin <<END
<domain type='kvm'>
  <name>archzfs-testing</name>
  <memory unit='KiB'>524288</memory>
  <currentMemory unit='KiB'>524288</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc-i440fx-2.10'>hvm</type>
  </os>
  <features>
    <acpi/>
    <apic/>
    <vmport state='off'/>
  </features>
  <cpu mode='custom' match='exact' check='partial'>
    <model fallback='allow'>Skylake-Client</model>
  </cpu>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/sbin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='${script_dir}/files/vm-work/archzfs-testing.qcow2'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x07' function='0x0'/>
      <boot order='1'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='${archiso_url}'/>
      <target dev='hda' bus='ide'/>
      <boot order='2'/>
      <readonly/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='ich9-ehci1'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x7'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci1'>
      <master startport='0'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0' multifunction='on'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci2'>
      <master startport='2'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x1'/>
    </controller>
    <controller type='usb' index='0' model='ich9-uhci3'>
      <master startport='4'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x2'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'/>
    <controller type='ide' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x1'/>
    </controller>
    <controller type='virtio-serial' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x06' function='0x0'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:d6:3d:66'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
      <address type='virtio-serial' controller='0' bus='0' port='1'/>
    </channel>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x08' function='0x0'/>
    </memballoon>
    <rng model='virtio'>
      <backend model='random'>/dev/urandom</backend>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x09' function='0x0'/>
    </rng>
  </devices>
</domain>
END

msg "Waiting for SSH..."
while :; do
  # get vm ip
  run_cmd_show_and_capture_output "virsh domifaddr archzfs-testing | awk -F'[ /]+' '{if (NR>2) print \$5}' | sed '/^\$/d' | tail -n1"
  ip=${run_cmd_output}
  if [[ ${run_cmd_return} -ne 0 ]]; then
    sleep 3
    continue
  fi

  # try to connect via ssh
  run_cmd "${ssh} root@${ip} echo &> /dev/null"
  if [[ ${run_cmd_return} -eq 0 ]]; then
    break
  fi
done

# copy bash scripts
run_cmd "${scp} -r ${vm_work_dir}/current-test root@${ip}:/root/"

# start test
run_cmd "${ssh} root@${ip} current-test/run-test.sh"
if [[ ${run_cmd_return} -ne 0 ]]; then
  error "Test failed!"
  run_cmd "${ssh} root@${ip} poweroff"
  exit 1
fi

# poweroff vm
run_cmd "${ssh} root@${ip} poweroff"
