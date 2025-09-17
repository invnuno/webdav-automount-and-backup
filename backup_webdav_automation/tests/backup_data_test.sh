#!/bin/bash
# Quick script to set up test data

# Testing the WebDAV Backup Playbook
# 1. Run `./generate_test_data.sh` to create small test files.
# 2. Dry-run: `ansible-playbook tests/backup_webdav_test.yml --check`
# 3. Full run: `ansible-playbook tests/backup_webdav_test.yml`
# 4. Verify backups in /tmp/test_external/backup_webdav/versions/

mkdir -p /tmp/test_webdav /tmp/test_external/backup_webdav
echo "Test file content" > /tmp/test_webdav/test_file.txt
echo "Test data generated at /tmp/test_webdav"