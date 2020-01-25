# Mount an EBS volume to EC2 Linux

In this tutorial, we will teach you how to  attach and mount an EBS volume to ec2 linux instances. Follow the steps given below carefully for the setup.

**Step 1:** Head over to EC2 
–> Volumes and create a new volume of your preferred size and type.

**Step 2:** Select the created volume, right click and select the "attach volume" option. 
**Step 3:** Select the instance from the instance text box as shown below.
[![attach ebs volume](https://devopscube.com/wp-content/uploads/2016/08/ebs-volume.jpg)](https://devopscube.com/wp-content/uploads/2016/08/ebs-volume.jpg) 
**Step 4:** Now, login to your ec2 instance and list the available disks using the following command.
```
lsblk
```
The above command will list the disk you attached to your instance.

**Step 5:** Check if the volume has any data using the following command.
```bash
sudo file -s /dev/xvdf
```
If the above command output shows "/dev/xvdf: data", it means your volume is empty.

**Step 6:** Format the volume to ext4 filesystem  using the following command.
```bash
sudo mkfs -t ext4 /dev/xvdf
```

 **Step 7:** Create a directory of your choice to mount our new ext4 volume. I am using the name "newvolume"
```
sudo mkdir /newvolume
```

 **Step 8:** Mount the volume to "newvolume" directory using the following command.
 ```
sudo mount /dev/xvdf /newvolume/
```


**Step 9:** cd into newvolume directory and check the disk space for confirming the volume mount.
```
cd /newvolume 
df -h .
```

The above command would show the free space in the newvolume directory.

To unmount the volume, you have to use the following command.
```
umount /dev/xvdf
```
### EBS Automount on Reboot

By default on every reboot the  EBS volumes other than root volume will get unmounted. To enable automount, you need to make an entry in the /etc/fstab file.

1.  Back up the /etc/fstab file.
```
sudo cp /etc/fstab /etc/fstab.bak
```

2. Open /etc/fstab file and make an entry in the following format.
```
device_name mount_point file_system_type fs_mntops fs_freq fs_passno
```

For example,
```
/dev/xvdf       /newvolume   ext4    defaults,nofail        0       0
```

3. Execute the following command to check id the fstab file has any error.
```
sudo mount -a
```

If the above command shows no error, it means your fstab entry is good.

Now, on every reboot the extra EBS volumes will get mounted automatically.

That's how you mount and unmount EBS volumes in your ec2 instances. If you get any error during the setup, please feel free to contact us in the comment section.

// ref: https://devopscube.com/mount-ebs-volume-ec2-instance/