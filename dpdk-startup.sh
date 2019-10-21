#!/bin/bash
# Path to SDK sources
export RTE_SDK=/home/vmware/dpdk-stable-18.11.2
export RTE_TARGET=x86_64-native-linuxapp-gcc
# USE "/usertools/dpdk-devbind.py --status" to find PCI address of the adptaer
export PORT0_PCI_ADDRESS=0000:03:00.0
export PORT1_PCI_ADDRESS=0000:0b:00.0
#Creating /mnt/huge and mounting as hugetlbfs"
# Creating 512 x 2Mb hugepages. Considering non-NUMA aware system
echo 512 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
sudo mkdir -p /mnt/huge
grep -s '/mnt/huge' /proc/mounts > /dev/null
if [ $? -ne 0 ] ; then
   sudo mount -t hugetlbfs nodev /mnt/huge
fi

# Unload existing uio momodule and load compiled one
/sbin/lsmod | grep -s igb_uio > /dev/null
if [ $? -eq 0 ] ; then
   sudo /sbin/rmmod igb_uio
fi
/sbin/modprobe uio
/sbin/insmod $RTE_SDK/$RTE_TARGET/kmod/igb_uio.ko
if [ $? -ne 0 ] ; then
   echo "## ERROR: Could not load kmod/igb_uio.ko."
   exit 1
fi
# Assigning adpters to be managed by DPDK-enabled drivers
if [ -d /sys/module/igb_uio ]; then
   ${RTE_SDK}/usertools/dpdk-devbind.py -b igb_uio $PORT0_PCI_ADDRESS && echo "PORT0_PCI_ADDRESS inserted"
   ${RTE_SDK}/usertools/dpdk-devbind.py -b igb_uio $PORT1_PCI_ADDRESS && echo "PORT1_PCI_ADDRESS inserted"
fi
