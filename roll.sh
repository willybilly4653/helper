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
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}                    RE-ENROLLING DEVICE                    ${NC}"
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Removing enrollment keys...${NC}"
            vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
            echo -e "${GREEN}[✓] re_enrollment_key removed${NC}"
            
            vpd -i RW_VPD -d block_devmode 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode removed${NC}"
            
            crossystem block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] Developer mode unlocked${NC}"
            echo ""
            
            echo -e "${GREEN}[✓] Re-enroll completed!${NC}"
            echo ""
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}                    REBOOTING IN 5 SECONDS                  ${NC}"
            echo -e "${YELLOW}              Press Ctrl+C to cancel reboot                ${NC}"
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            
            sleep 5
            echo -e "${YELLOW}[!] Rebooting now...${NC}"
            reboot
            break
            ;;
        2)
            clear
            echo ""
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}                    REMOVING ENROLLMENT                    ${NC}"
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Setting random enrollment key...${NC}"
            vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
            echo -e "${GREEN}[✓] Enrollment blocked with random key${NC}"
            
            echo -e "${YELLOW}[*] Disabling developer mode block...${NC}"
            crossystem block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] Developer mode block disabled${NC}"
            
            echo -e "${YELLOW}[*] Saving to VPD...${NC}"
            vpd -i RW_VPD -s block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] Settings saved${NC}"
            echo ""
            
            echo -e "${GREEN}[✓] Unenrollment completed!${NC}"
            echo -e "${YELLOW}[!] Next steps: Boot to developer mode${NC}"
            echo ""
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo -ne "${BLUE}Press Enter to return to menu...${NC}"
            read -r
            # After pressing Enter, loop continues to show menu again
            ;;
        e|E)
            clear
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option. Please select 1, 2, or e.${NC}"
            sleep 1.5
            ;;
    esac
done
