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

show_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${CYAN}         CORSOLA ENROLLMENT MANAGER               ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " ${YELLOW}1)${NC} Reroll (Re-enroll Device)"
    echo -e " ${YELLOW}2)${NC} Unroll (Remove Enrollment)"
    echo -e " ${YELLOW}e)${NC} Exit"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -ne "${BLUE}Select an option: ${NC}"
}

while true; do
    show_menu
    read -r choice
    
    case "$choice" in
        1)
            clear
            echo ""
            echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -d re_enrollment_key${NC}"
            vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
            echo -e "${GREEN}[✓] re_enrollment_key removed${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -d block_devmode${NC}"
            vpd -i RW_VPD -d block_devmode 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode removed${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: crossystem block_devmode=0${NC}"
            crossystem block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
            echo ""
            
            echo -e "${GREEN}[✓] Re-enroll completed. Rebooting in 5 seconds...${NC}"
            echo -e "${YELLOW}Press Ctrl+C to cancel reboot...${NC}"
            sleep 5
            echo -e "${YELLOW}[!] Rebooting now...${NC}"
            reboot
            ;;
        2)
            clear
            echo ""
            echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -s re_enrollment_key=\"\$(openssl rand -hex 32)\"${NC}"
            vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
            echo -e "${GREEN}[✓] re_enrollment_key set to random value${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: crossystem block_devmode=0${NC}"
            crossystem block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -s block_devmode=0${NC}"
            vpd -i RW_VPD -s block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode saved to VPD${NC}"
            echo ""
            
            echo -e "${GREEN}[✓] Unenrollment completed.${NC}"
            echo -e "${YELLOW}[!] Next: Boot to developer mode and run block-updates${NC}"
            echo -ne "${BLUE}Press Enter to continue...${NC}"
            read -r
            ;;
        e|E)
            echo -e "\n${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option.${NC}"
            sleep 1
            ;;
    esac
done
