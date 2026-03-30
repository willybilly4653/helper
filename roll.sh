#!/bin/bash
# roll.sh - Corsola Enrollment Manager

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo.${NC}"
    exit 1
fi

case "$1" in
    reroll)
        echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
        vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
        vpd -i RW_VPD -d block_devmode 2>/dev/null
        crossystem block_devmode=0 2>/dev/null
        echo -e "${GREEN}[✓] Re-enroll completed! Rebooting in 5 seconds...${NC}"
        sleep 5
        reboot
        ;;
    unroll)
        echo -e "${YELLOW}[*] Removing enrollment...${NC}"
        vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
        crossystem block_devmode=0 2>/dev/null
        vpd -i RW_VPD -s block_devmode=0 2>/dev/null
        echo -e "${GREEN}[✓] Unenrollment completed! Boot to dev mode next.${NC}"
        ;;
    *)
        # If no argument or invalid, just show error and exit
        echo -e "${RED}[✗] Invalid. Use: reroll or unroll${NC}"
        exit 1
        ;;
esac
