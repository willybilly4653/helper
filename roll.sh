#!/bin/bash
# roll.sh - Quick enrollment/unenrollment tool for Corsola Chromebooks

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${YELLOW}Corsola Enrollment Helper${NC}"
    echo ""
    echo -e "${BLUE}Usage:${NC} roll.sh [command]"
    echo ""
    echo -e "${BLUE}Commands:${NC}"
    echo "  unenroll    - Remove enrollment from the device"
    echo "  reenroll    - Re-enroll the device (also accepts 'reroll')"
    echo "  reroll      - Same as reenroll"
    echo "  block-updates - Block Chrome OS updates"
    echo ""
    echo -e "${BLUE}Examples:${NC}"
    echo "  sudo ./roll.sh unenroll"
    echo "  sudo ./roll.sh reroll"
    echo ""
}

case "$1" in
    unenroll)
        echo -e "${YELLOW}[*] Unenrolling device...${NC}"
        vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)"
        crossystem block_devmode=0
        vpd -i RW_VPD -s block_devmode=0
        echo -e "${GREEN}[✓] Done. Boot to developer mode next.${NC}"
        echo -e "${YELLOW}[!] Next steps: Boot into dev mode and run: sudo ./roll.sh block-updates${NC}"
        ;;
    reenroll|reroll)
        echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
        vpd -i RW_VPD -d re_enrollment_key
        vpd -i RW_VPD -d block_devmode
        crossystem block_devmode=0
        echo -e "${GREEN}[✓] Done.${NC}"
        echo -e "${YELLOW}[!] Next steps:${NC}"
        echo "  1. Press ${BLUE}Refresh + Power${NC} to reboot"
        echo "  2. You should see enrollment screen"
        echo "  3. If not, press ${BLUE}Esc + Refresh + Power${NC} and use recovery USB"
        ;;
    block-updates)
        echo -e "${YELLOW}[*] Blocking updates...${NC}"
        mount -o remount,rw / 2>/dev/null || true
        if [ -w /etc/lsb-release ]; then
            sed -i 's|CHROMEOS_AUSERVER=.*|CHROMEOS_AUSERVER=http://127.0.0.1/noupdate|' /etc/lsb-release
            stop update-engine 2>/dev/null || true
            rm -rf /var/lib/update_engine/prefs/* 2>/dev/null || true
            mount -o remount,ro / 2>/dev/null || true
            start update-engine 2>/dev/null || true
            echo -e "${GREEN}[✓] Updates blocked successfully.${NC}"
        else
            echo -e "${RED}[✗] Error: Cannot modify /etc/lsb-release.${NC}"
            echo -e "${YELLOW}[!] You need to remove rootfs verification first:${NC}"
            echo "  sudo /usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification --force"
            echo "  Then reboot and run this command again"
            exit 1
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}[✗] Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
