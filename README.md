# Automounting WebDAV and HDD for NextCloud Backup with `systemd` and `rsync` on Raspberry Pi

This guide demonstrates how to use the `systemd` automount feature to mount the NextCloud WebDAV and an external HDD on-demand. It also covers how to back up all the data using `rsync`. This setup is ideal for Raspberry Pi environments and similar devices.

*Note*:  
Be sure to replace `user` with your local system username where appropriate.

## Environment Used

**Hardware**:
- Raspberry Pi 3
- External HDD

**OS**:
- Raspbian GNU/Linux 12 (Bookworm)

**Packages**:
- systemd
- davfs2

## Configuration

### `/etc/fstab`

Add the following entries to your `/etc/fstab` to configure automounting for the NextCloud WebDAV and HDD:

```shell
# NextCloud WebDAV automount - read-only, no execution, automatic mount with systemd
https://nextcloud-server.tld/remote.php/dav/files/user /home/user/nextcloud davfs ro,user,noexec,nofail,_netdev,noauto,x-systemd.automount,x-systemd.mount-timeout=2min 0 0

# External HDD automount - NTFS filesystem, read-write with systemd auto-mount and timeout
/dev/sda1 /home/user/hdd ntfs x-systemd.automount,x-systemd.idle-timeout=2min,rw,sync 0 0
```

### `/etc/davfs2/secrets`

Ensure that the following entry is present to store your WebDAV credentials securely. Replace `<user>` with your NextCloud username and generate an app password in NextCloud’s security settings.

```shell
/home/user/nextcloud <user> <generate app password in nextcloud>
```

### `/etc/davfs2/davfs2.conf`

### Disable Locks

To disable file locking in `davfs2`, which can be necessary if you're facing issues with file locks in NextCloud (as it does not fully support WebDAV locking), add the following to your configuration:

```shell
use_locks 0
```

Disabling locks can help avoid problems with stale or conflicting file locks when using WebDAV. However, be aware that this can also lead to issues in multi-user environments where multiple clients are modifying the same files.


### Mount

After adding the configurations to `/etc/fstab`, create the directories for the mount points and reload `systemd` to start automounting:

```shell
mkdir ~/nextcloud
mkdir ~/hdd
systemctl daemon-reload
systemctl start home-user-nextcloud.automount
systemctl start home-user-hdd.automount
```

## Backup

### Bash Script

You can either use the bash script available in the repository to back up all the data from the WebDAV mountpoint to the external HDD using `rsync` (`nextcloud-to-hdd-backup.sh`), or create your own with a similar command:

```shell
rsync -az --delete --partial "/home/user/nextcloud/" "/home/user/hdd/nextcloud-backup/"
```

This command will:

- **`-a`**: Archive mode (preserves permissions, symlinks, etc.)
- **`-z`**: Compress the data during transfer
- **`--delete`**: Remove files from the backup directory that no longer exist in the source
- **`--partial`**: Allows for resuming incomplete transfers

It synchronizes the content from the NextCloud WebDAV mount to your external HDD, ensuring that the backup stays up to date and any deleted files are removed.

### Automate the Backup

To automate the backup, you can schedule the script to run periodically using cron. For example, to back up on the 1st day of each month at 2:00 AM, edit your crontab with `crontab -e` and add the following line:

```shell
# Backup at the 1st day of each month
0 2 1 * * /home/user/nextcloud-to-hdd-backup.sh
```

## Troubleshooting

You can view the automount unit logs to check when the directory mountpoints were triggered:

```shell
journalctl -u home-user-nextcloud.automount
journalctl -u home-user-hdd.automount
```

If you encounter an error with exit code 255, review your mount options in `/etc/fstab`:

```shell
Oct 23 23:04:24 prusalink systemd[1]: home-user-nextcloud.mount: Mount process exited, code=exited, status=255
```

Common causes of this issue include incorrect WebDAV URLs or network connectivity problems.

## Known Issues

### WebDAV Cache Size

When backing up large files, `davfs2` caches each file to be read or written. By default, the cache size is set to 50 MB, which may impact performance. If your system has sufficient memory available, consider increasing the cache size for better performance:

#### `/etc/davfs2/davfs2.conf`

```shell
cache_size 300
```

From the `davfs2` man pages:

```shell
cache_size
    The amount of disk space in MiByte that may be used. mount.davfs will always
    take enough space to cache open files, ignoring this value if necessary.
    Default: 50
```

Make sure to monitor your system's available memory before adjusting this value.

## References

- [Automount filesystems with systemd](https://community.hetzner.com/tutorials/automount-filesystems-with-systemd)
- [Creating WebDAV mounts on the Linux command line](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#creating-webdav-mounts-on-the-linux-command-line)
- [NextCloud does not support locks](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#known-issues)
- [systemd automount using davfs2 not working](https://discourse.osmc.tv/t/systemd-automount-using-davfs2-not-working/94200/5)
