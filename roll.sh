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
            vpd -i RW_VPD -d re_enrollment_key 2>/dev/null
            echo -e "${GREEN}[✓] Done${NC}"
            
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
            reboot -f
            ;;
        2)
            clear
            echo ""
            echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
            echo ""
            
            echo -e "${YELLOW}[*] Clearing enrollment keys...${NC}"
            vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)" 2>/dev/null
            vpd -i RO_VPD -s check_enrollment=0 2>/dev/null
            echo -e "${GREEN}[✓] Enrollment keys cleared${NC}"
            
            echo -e "${YELLOW}[*] Enabling Developer Mode...${NC}"
            crossystem block_devmode=0 2>/dev/null
            vpd -i RW_VPD -s block_devmode=0 2>/dev/null
            echo -e "${GREEN}[✓] Developer Mode enabled${NC}"
            
            echo -e "${YELLOW}[*] Clearing cached enterprise policies...${NC}"
            rm -rf /var/lib/enterprise* 2>/dev/null
            rm -rf /home/chronos/enterprise* 2>/dev/null
            rm -rf /mnt/stateful_partition/var/lib/enterprise* 2>/dev/null
            rm -rf /mnt/stateful_partition/var/lib/devicesettings 2>/dev/null
            rm -rf /home/chronos/Policy* 2>/dev/null
            rm -rf /var/lib/whitelist 2>/dev/null
            echo -e "${GREEN}[✓] Policies cleared${NC}"
            
            echo ""
            echo -e "${GREEN}[✓] Unenrollment completed!${NC}"
            echo -e "${YELLOW}[!] IMPORTANT NEXT STEPS:${NC}"
            echo -e "    1. Reboot the device"
            echo -e "    2. At recovery screen, press Ctrl+D to enter Developer Mode"
            echo -e "    3. When prompted, DO NOT connect to Wi-Fi yet"
            echo -e "    4. Press Ctrl+Alt+F2 to open terminal"
            echo -e "    5. Run: vpd -i RO_VPD -s check_enrollment=0"
            echo -e "    6. Then: reboot"
            echo -e "    7. Now you can connect to Wi-Fi safely"
            echo ""
            echo -e "${YELLOW}[!] If it still tries to enroll after Wi-Fi:${NC}"
            echo -e "    Immediately press Ctrl+Alt+F2 and run:"
            echo -e "    rm -rf /var/lib/enterprise* && reboot"
            echo ""
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
