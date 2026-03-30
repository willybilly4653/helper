#!/bin/bash
# corsola-helper.sh - Quick enrollment/unenrollment tool

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Corsola Enrollment Helper${NC}"
echo ""

case "$1" in
    unenroll)
        echo "[*] Unenrolling..."
        vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)"
        crossystem block_devmode=0
        vpd -i RW_VPD -s block_devmode=0
        echo -e "${GREEN}Done. Boot to dev mode next.${NC}"
        ;;
    reenroll)
        echo "[*] Re-enrolling..."
        vpd -i RW_VPD -d re_enrollment_key
        vpd -i RW_VPD -d block_devmode
        crossystem block_devmode=0
        echo -e "${GREEN}Done. Reboot to recovery.${NC}"
        ;;
    block-updates)
        echo "[*] Blocking updates..."
        mount -o remount,rw / 2>/dev/null || true
        if [ -w /etc/lsb-release ]; then
            sed -i 's|CHROMEOS_AUSERVER=.*|CHROMEOS_AUSERVER=http://127.0.0.1/noupdate|' /etc/lsb-release
            stop update-engine 2>/dev/null || true
            rm -rf /var/lib/update_engine/prefs/* 2>/dev/null || true
            mount -o remount,ro / 2>/dev/null || true
            start update-engine 2>/dev/null || true
            echo -e "${GREEN}Updates blocked.${NC}"
        else
            echo -e "${RED}Error: Cannot modify /etc/lsb-release. Run make_dev_ssd first.${NC}"
            exit 1
        fi
        ;;
    *)
        echo "Usage: corsola-helper.sh [unenroll|reenroll|block-updates]"
        exit 1
        ;;
esac
