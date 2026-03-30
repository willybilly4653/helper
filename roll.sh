#!/bin/bash
# roll.sh - Corsola Enrollment Manager

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo.${NC}"
    exit 1
fi

# Check if running in interactive mode
if [ ! -t 0 ]; then
    echo -e "${RED}[✗] This script requires interactive input.${NC}"
    echo -e "${YELLOW}Please run it as:${NC}"
    echo -e "  curl -sSL [url] -o /tmp/roll.sh && sudo bash /tmp/roll.sh"
    exit 1
fi

# Simple menu
echo ""
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}         CORSOLA ENROLLMENT MANAGER               ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo -e " ${YELLOW}1)${NC} Reroll (Re-enroll Device)"
echo -e " ${YELLOW}2)${NC} Unroll (Remove Enrollment)"
echo -e " ${YELLOW}e)${NC} Exit"
echo -e "${CYAN}--------------------------------------------------${NC}"
echo ""
printf "${BLUE}Enter your choice (1, 2, or e): ${NC}"
read -r choice

if [ "$choice" = "1" ]; then
    echo ""
    echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
    echo ""
    
    vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
    echo -e "${GREEN}[✓] re_enrollment_key removed${NC}"
    
    vpd -i RW_VPD -d block_devmode 2>/dev/null
    echo -e "${GREEN}[✓] block_devmode removed${NC}"
    
    crossystem block_devmode=0 2>/dev/null
    echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
    
    echo ""
    echo -e "${GREEN}[✓] Re-enroll completed!${NC}"
    echo -e "${YELLOW}Rebooting in 5 seconds... Press Ctrl+C to cancel${NC}"
    sleep 5
    reboot
    
elif [ "$choice" = "2" ]; then
    echo ""
    echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
    echo ""
    
    vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
    echo -e "${GREEN}[✓] re_enrollment_key set to random value${NC}"
    
    crossystem block_devmode=0 2>/dev/null
    echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
    
    vpd -i RW_VPD -s block_devmode=0 2>/dev/null
    echo -e "${GREEN}[✓] block_devmode saved to VPD${NC}"
    
    echo ""
    echo -e "${GREEN}[✓] Unenrollment completed!${NC}"
    echo -e "${YELLOW}[!] Next: Boot to developer mode${NC}"
    
elif [ "$choice" = "e" ] || [ "$choice" = "E" ]; then
    echo -e "${GREEN}Goodbye!${NC}"
    exit 0
    
else
    echo -e "${RED}[✗] Invalid option: '${choice}'${NC}"
    exit 1
fi
