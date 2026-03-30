#!/bin/bash
# roll.sh - Corsola Enrollment Manager

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

# Header
echo -e "${CYAN}*************************************************************************************${NC}"
echo -e "${CYAN}***${NC}    ${YELLOW}Corsola Enrollment Manager${NC}"
echo -e "${CYAN}***${NC}    ${BLUE}Device: Corsola Chromebook${NC}"
echo -e "${CYAN}*************************************************************************************${NC}"
echo ""
echo -e "${CYAN}***${NC}    ${GREEN}1)${NC} Reroll (Re-enroll Device)"
echo -e "${CYAN}***${NC}    ${RED}2)${NC} Unroll (Remove Enrollment)"
echo -e "${CYAN}***${NC}    ${YELLOW}Q)${NC} Quit"
echo -e "${CYAN}*************************************************************************************${NC}"
echo ""

# Get user input
read -p "Select a numeric menu option or Q to quit: " choice

case "$choice" in
    1|reroll)
        echo ""
        echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
        vpd -i RW_VPD -d re_enrollment_key
        vpd -i RW_VPD -d block_devmode
        crossystem block_devmode=0
        echo -e "${GREEN}[✓] Done. Rebooting in 3 seconds...${NC}"
        sleep 3
        echo -e "${YELLOW}[!] Rebooting now...${NC}"
        reboot
        ;;
    2|unroll)
        echo ""
        echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
        vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)"
        crossystem block_devmode=0
        vpd -i RW_VPD -s block_devmode=0
        echo -e "${GREEN}[✓] Done. Boot to dev mode next.${NC}"
        echo -e "${YELLOW}[!] Press Enter to return to menu...${NC}"
        read -r
        exec "$0"  # Return to menu
        ;;
    q|Q)
        echo -e "${GREEN}Goodbye!${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}[✗] Invalid option.${NC}"
        sleep 2
        exec "$0"  # Return to menu
        ;;
esac
