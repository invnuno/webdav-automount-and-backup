#!/bin/bash

# Define directories and backup settings
LOCAL_USER="user"
NEXTCLOUD_MOUNT="/home/$LOCAL_USER/nextcloud"
HDD_MOUNT="/home/$LOCAL_USER/hdd"
BACKUP_DIR="$HDD_MOUNT/nextcloud-backup"
ARCHIVE_DIR="$HDD_MOUNT/nextcloud-backup-archive"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
MAX_BACKUPS=3

# Log file
LOGFILE="/home/$LOCAL_USER/nextcloud-to-hdd-backup.log"
exec > >(tee -a "$LOGFILE") 2>&1

# Log the start time
echo "Backup process started at: $(date)"

# Ensure mount points are available
if ! mountpoint -q "$NEXTCLOUD_MOUNT"; then
  echo "Mounting NextCloud WebDAV..."
  systemctl start home-$LOCAL_USER-nextcloud.automount
  sleep 5
  if ! mountpoint -q "$NEXTCLOUD_MOUNT"; then
    echo "Error: Failed to mount NextCloud WebDAV."
    exit 1
  fi
fi

if ! mountpoint -q "$HDD_MOUNT"; then
  echo "Mounting external HDD..."
  systemctl start home-$LOCAL_USER-hdd.automount
  sleep 5
  if ! mountpoint -q "$HDD_MOUNT"; then
    echo "Error: Failed to mount external HDD."
    exit 1
  fi
fi

# Ensure archive directory exists
mkdir -p "$ARCHIVE_DIR"

# Archive previous backup
if [ -d "$BACKUP_DIR" ]; then
  echo "Archiving the previous backup..."
  tar -czf "$ARCHIVE_DIR/nextcloud-backup-$TIMESTAMP.tar.gz" -C "$BACKUP_DIR" .
  
  # Log if the archiving process was successful
  if [ $? -eq 0 ]; then
    echo "Successfully archived backup: nextcloud-backup-$TIMESTAMP.tar.gz"
  else
    echo "Error: Archiving previous backup failed."
    exit 1
  fi
else
  echo "No previous backup to archive."
fi

# Clean up old backups and keep only the 3 most recent ones
echo "Cleaning up old backups..."
ls -1t "$ARCHIVE_DIR" | grep 'nextcloud-backup-' | tail -n +$(($MAX_BACKUPS + 1)) | xargs -I {} rm -f "$ARCHIVE_DIR/{}"

# Perform rsync backup
echo "Starting new backup from NextCloud to HDD..."
rsync -az --delete --partial "$NEXTCLOUD_MOUNT/" "$BACKUP_DIR/"

# Log the backup completion status
if [ $? -eq 0 ]; then
  echo "Backup completed successfully."
else
  echo "Error: Backup failed."
  exit 1
fi

# Log the end time
echo "Backup process ended at: $(date)"
