#!/usr/bin/env bash
export script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if ! source ${script_dir}/lib.sh; then
    echo "!! ERROR !! -- Could not load lib.sh!"
    exit 155
fi

export debug_flag=1
export dry_run=0

# check if we are inside the vm
run_cmd_no_output "lsmod | grep virtio"
if [[ ${run_cmd_return} -ne 0 ]]; then
  error "Not running inside a VM!"
  exit 1
fi

source_safe "${script_dir}/test.sh"

run_test $1
