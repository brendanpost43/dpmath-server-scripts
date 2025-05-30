#!/bin/bash
#========CONFIG========
NAS_IP="172.17.40.87"
NAS_BASE_PATH="/users"
MOUNT_BASE="/home"
#======================

#prompt for a username
read -p "Enter username (must already exist): " username

#Get User ID (UID)
USER_ID=$(id -u "$username" 2>/dev/null)
if [ -z "$USER_ID" ]; then
  echo "User '$username' does not exist."
  exit 1
fi

#Define key paths
USER_HOME="/home/$username"
MOUNT_PATH="$USER_HOME/nas"
NAS_PATH="$NAS_BASE_PATH/$username"

#Create mount directory on server
echo "Creating $MOUNT_PATH"
mkdir -p "$MOUNT_PATH" #make the mount path
chown "$username":"$username" "$MOUNT_PATH" #change ownership so the user can access the directory

#Mount NAS folder
echo "Mounting $NAS_IP:$NAS_PATH to $MOUNT_PATH"
mount -t nfs4 "$NAS_IP:$NAS_PATH" "$MOUNT_PATH" #mount the user's NAS folder to their local mount point using NFSv4

#Check to see if the mount worked
if mountpoint -q "$MOUNT_PATH"; then
  echo "Mount Successful!"
else
  echo "Mount Failed :("
  exit 1 #stop the script if check fails
fi

#add entry to /etc/fstab (ensures the mounts persists after reboot)
FSTAB_LINE="$NAS_IP:$NAS_PATH $MOUNT_PATH nfs4 defaults,_netdev 0 0"
grep -qxf "$FSTAB_LINE" /etc/fstab || echo "$FSTAB_LINE" >> /etc/fstab

#Success Message
echo "/etc/fstab updated!"
echo "Done! $username has a private NAS mount at $MOUNT_PATH"
