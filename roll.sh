#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ADD THIS FUNCTION
run_vpd_in_vt2() {
    local current_vt=$(fgconsole 2>/dev/null || echo "1")
    
    echo -e "${YELLOW}[*] Switching to VT2 to remove re_enrollment_key...${NC}"
    
    chvt 2
    sleep 1
    vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
    sleep 2
    chvt "$current_vt"
    
    echo -e "${GREEN}[✓] Done${NC}"
}

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo.${NC}"
    exit 1
fi

show_menu() {
    clear
    echo -e "${CYAN}==================================================${NC}"
    echo -e "${CYAN}         CORSOLA ENROLLMENT MANAGER               ${NC}"
    echo -e "${CYAN}==================================================${NC}"
    echo -e " ${YELLOW}1)${NC} Reroll (Re-enroll Device - Remove Dev Mode)"
    echo -e " ${YELLOW}2)${NC} Unroll (Remove Enrollment)"
    echo -e " ${YELLOW}e)${NC} Exit"
    echo -e "${CYAN}--------------------------------------------------${NC}"
    echo -ne "${BLUE}Select an option: ${NC}"
}

while true; do
    show_menu
    read -r choice < /dev/tty
    case "$choice" in
        1)
            clear
            echo ""
            echo -e "${YELLOW}[*] Re-enrolling device - Removing developer mode...${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Removing re_enrollment_key...${NC}"
            # CHANGE THIS LINE
            run_vpd_in_vt2
            # OLD LINE WAS: vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
            
            echo -e "${YELLOW}[*] Removing block_devmode from VPD...${NC}"
            vpd -i RW_VPD -d block_devmode 2>/dev/null
            echo -e "${GREEN}[✓] Done${NC}"
            
            echo -e "${YELLOW}[*] Disabling developer mode...${NC}"
            crossystem block_devmode=1 2>/dev/null
            crossystem dev_boot_usb=0 2>/dev/null
            crossystem dev_boot_legacy=0 2>/dev/null
            crossystem dev_boot_signed_only=1 2>/dev/null
            echo -e "${GREEN}[✓] Developer mode disabled${NC}"
            
            echo -e "${YELLOW}[*] Removing developer mode flags...${NC}"
            vpd -i RW_VPD -s block_devmode=1 2>/dev/null
            echo -e "${GREEN}[✓] Secure mode enabled${NC}"
            
            echo ""
            echo -e "${GREEN}[✓] Re-enroll completed! Device is now in secure mode${NC}"
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo -e "${YELLOW}Device will now:${NC}"
            echo -e "  • Boot in verified/secure mode"
            echo -e "  • Show enrollment screen on next boot"
            echo -e "  • Developer mode disabled"
            echo -e "${YELLOW}════════════════════════════════════════════════════════${NC}"
            echo ""
            echo -e "${YELLOW}Rebooting in 5 seconds... Press Ctrl+C to cancel${NC}"
            sleep 5
            reboot
            ;;
        2)
            # Your existing Option 2 stays exactly the same
            clear
            echo ""
            echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Setting random re_enrollment_key...${NC}"
            vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
            echo -e "${GREEN}[✓] re_enrollment_key set to random value${NC}"
            
            echo -e "${YELLOW}[*] Setting crossystem block_devmode=0...${NC}"
            crossystem block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] crossystem block_devmode set to 0${NC}"
            
            echo -e "${YELLOW}[*] Saving block_devmode to VPD...${NC}"
            vpd -i RW_VPD -s block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] block_devmode saved to VPD${NC}"
            
            echo ""
            echo -e "${GREEN}[✓] Unenrollment completed!${NC}"
            echo -e "${YELLOW}[!] Next: Boot to developer mode (Esc+Refresh+Power, then Ctrl+D)${NC}"
            echo -ne "${BLUE}Press Enter to continue...${NC}"
            read -r < /dev/tty
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
