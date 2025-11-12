# WebDAV Backup with Ansible

Backup a systemd-automounted WebDAV mount (e.g., NextCloud) to an external HDD using Ansible. Tested on Raspberry Pi running Raspbian Bookworm.

## Environment

**Hardware**:
- Raspberry Pi 3+ or compatible.
- External HDD (NTFS).

**OS**:
- Debian-based (e.g., Raspbian GNU/Linux 12).

**Packages**:
- systemd
- davfs2
- ansible
- rsync
- ansible.posix (collection)

## Configuration

### `/etc/fstab`

Automount NextCloud WebDAV and HDD:

```shell
# NextCloud WebDAV automount - read-only, user-mountable
https://nextcloud-server.tld/remote.php/dav/files/user /mnt/webdav davfs ro,user,noexec,nofail,_netdev,noauto,x-systemd.automount,x-systemd.mount-timeout=2min 0 0

# External HDD automount - NTFS, user-mountable
/dev/sda1 /mnt/external ntfs user,x-systemd.automount,x-systemd.idle-timeout=2min,rw,sync 0 0
```

### `/etc/davfs2/secrets`

Securely store WebDAV creds:

```shell
/mnt/webdav user <app-password>
```

### `/etc/davfs2/davfs2.conf`

Disable locks and adjust cache:

```shell
use_locks 0
cache_size 300
```

### Mount

Create directories, reload systemd:

```shell
sudo mkdir /mnt/webdav /mnt/external
sudo systemctl daemon-reload
sudo systemctl start mnt-webdav.automount mnt-external.automount
```

## Running the Playbook

1. Clone repo and cd to `ansible` folder.
2. Install Ansible collection: `ansible-galaxy collection install ansible.posix`.
3. Adjust variables in the playbook (e.g., paths, services).
4. Run: `ansible-playbook backup_webdav.yml --inventory localhost,`
5. For tags: `--tags verify` or `--tags backup`.

Features:
- Verifies mounts and automounts.
- Rsyncs WebDAV to compressed .tar.gz on external disk (keeps 3 versions).
- Ignores sync errors (logs only).

Automate via cron: `0 2 * * * /usr/bin/ansible-playbook /path/to/backup_webdav.yml --inventory localhost,`

## Troubleshooting

Check systemd logs: `journalctl -u mnt-webdav.automount -u mnt-external.automount`

Common:
- Mount fails (err 255): Check fstab URLs/network.
- Rsync I/O errors: Inactive files/corruption—ignore with task options.
- Permissions: Ensure user can mount (fstab `user` option).

## Known Issues

- Davfs2 cache limits: Increase `cache_size` for large files (monitor RAM).
- No locks on NextCloud WebDAV.

## References

- [Automount filesystems with systemd](https://community.hetzner.com/tutorials/automount-filesystems-with-systemd)
- [Creating WebDAV mounts on the Linux command line](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#creating-webdav-mounts-on-the-linux-command-line)
- [NextCloud does not support locks](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html#known-issues)
- [systemd automount using davfs2 not working](https://discourse.osmc.tv/t/systemd-automount-using-davfs2-not-working/94200/5)
- [Use curl instead of rsync to stream files and not use davfs2 cache](https://unix.stackexchange.com/questions/354026/disable-davfs2-caching)
- [Ansible posix.synchronize](https://docs.ansible.com/ansible/latest/collections/ansible/posix/synchronize_module.html)
- [Systemd automount with WebDAV](https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html)
- [Davfs2 config](https://linux.die.net/man/5/davfs2)