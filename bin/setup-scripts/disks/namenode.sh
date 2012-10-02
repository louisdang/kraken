#!/bin/bash
set -e

hadoop_name_directory="/var/lib/hadoop/name"

# HDFS namenode sde and sdf

# sd{e,f}1 become 100G Linux RAID partitions

for disk in /dev/sd{e,f}; do sudo fdisk $disk <<EOF
n
p
1

+100G
t
fd
w
EOF

done

sleep 1

# If we have had a RAID array on these disks before,
# mdadm may have created the old array automatically.
# If it exists, then stop it.
if [ -e /dev/md2 ]; then
    sudo mdadm --stop /dev/md2
fi
if [ -e /dev/md_d2 ]; then
    sudo mdadm --stop /dev/md_d2
fi

# create mirrored RAID 1 on sde1 and sdf1 ext3
sudo mdadm --create /dev/md2 --level 1 --raid-devices=2 /dev/sde1 /dev/sdf1 <<EOF
y
EOF
sudo mkfs.ext3 /dev/md2

# mount it at $hadoop_name_directory
sudo mkdir -p $hadoop_name_directory && sudo chown hdfs:hadoop $hadoop_name_directory && sudo chmod 700 $hadoop_name_directory
grep -q "$hadoop_name_directory" /etc/fstab || echo -e "# Hadoop namenode partition\n/dev/md2\t$hadoop_name_directory\text3\tdefaults,noatime\t0\t2" | sudo tee -a /etc/fstab

