# WebDAV and HDD disk automount to backup NextCloud data

Make use of `systemd` automount feature to mount (NextCloud) WebDAV and external HDD on-demand.
Backup all the data using `rsync`.

## Requirements
**Hardware**
- RaspberryPi 3
- HDD external disk

**OS**
- Raspbian GNU/Linux 12 (bookworm)

**Packages**
- systemd
- davfs2

## Configuration
`/etc/fstab`
~~~shell
# NextCloud WebDAV automount
https://nextcloud-server.tld/remote.php/dav/files/user /home/user/nextcloud davfs ro,user,noexec,nofail,_netdev,noauto,x-systemd.automount,x-systemd.mount-timeout=2min 0 0

# HDD automount
/dev/sda1 /home/user/hdd ntfs x-systemd.automount,x-systemd.idle-timeout=2min,rw,sync 0 0
~~~

`/etc/davfs2/secrets`
~~~shell
/home/user/nextcloud <user> <generate app password in nextcloud>
~~~

## Mount
Create directories and start automount `systemd` units.
~~~shell
mkdir ~/nextcloud
mkdir ~/hdd
systemctl daemon-reload
systemctl start home-user-nextcloud.automount
systemctl start home-user-hdd.automount
~~~

## Backup
Use `rsync` to backup all the data.
~~~
rsync -avzHP --dry-run /home/user/nextcloud/ /home/user/hdd/nextcloud-backup/
~~~

## Troubleshooting
The automount unit logs will show you when the directory mountpoint was triggered. 
~~~shell
journalctl -u home-user-nextcloud.automount
journalctl -u home-user-hdd.automount
~~~

If you get an exit code of 255, review your mount options in `/etc/fstab`.
~~~shell
Oct 23 23:04:24 prusalink systemd[1]: home-user-nextcloud.mount: Mount process exited, code=exited, status=255
~~~

# References
[Automount filesystems with systemd](https://community.hetzner.com/tutorials/automount-filesystems-with-systemd)
[Creating WebDAV mount on CLI](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#creating-webdav-mounts-on-the-linux-command-line)
[NextCloud does not support locks. Use this](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#known-issues)
[systemd automount using davfs2 not working](https://discourse.osmc.tv/t/systemd-automount-using-davfs2-not-working/94200/5)
