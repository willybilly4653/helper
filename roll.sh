#!/bin/bash
# roll.sh - Corsola Enrollment Manager

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}[✗] Please run with sudo: sudo ./roll.sh${NC}"
    exit 1
fi

# Function to show menu
show_menu() {
    clear
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
}

# Main loop
while true; do
    show_menu
    read -p "Select a numeric menu option or Q to quit: " choice
    
    case "$choice" in
        1|reroll|Reroll)
            echo ""
            echo -e "${YELLOW}[*] Re-enrolling device...${NC}"
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -d re_enrollment_key${NC}"
            vpd -i RW_VPD -d re_enrollment_key
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] re_enrollment_key removed${NC}"
            else
                echo -e "${RED}[✗] Failed to remove re_enrollment_key${NC}"
            fi
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -d block_devmode${NC}"
            vpd -i RW_VPD -d block_devmode
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] block_devmode removed${NC}"
            else
                echo -e "${RED}[✗] Failed to remove block_devmode${NC}"
            fi
            
            echo -e "${YELLOW}[*] Running: crossystem block_devmode=0${NC}"
            crossystem block_devmode=0
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
            else
                echo -e "${RED}[✗] Failed to set block_devmode${NC}"
            fi
            
            echo -e "${GREEN}[✓] Re-enroll completed. Rebooting in 3 seconds...${NC}"
            sleep 3
            echo -e "${YELLOW}[!] Rebooting now...${NC}"
            reboot
            break
            ;;
        2|unroll|Unroll)
            echo ""
            echo -e "${YELLOW}[*] Removing enrollment from device...${NC}"
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -s re_enrollment_key=\"\$(openssl rand -hex 32)\"${NC}"
            vpd -i RW_VPD -s re_enrollment_key="$(openssl rand -hex 32)"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] re_enrollment_key set to random value${NC}"
            else
                echo -e "${RED}[✗] Failed to set re_enrollment_key${NC}"
            fi
            
            echo -e "${YELLOW}[*] Running: crossystem block_devmode=0${NC}"
            crossystem block_devmode=0
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] block_devmode set to 0${NC}"
            else
                echo -e "${RED}[✗] Failed to set block_devmode${NC}"
            fi
            
            echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -s block_devmode=0${NC}"
            vpd -i RW_VPD -s block_devmode=0
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[✓] block_devmode saved to VPD${NC}"
            else
                echo -e "${RED}[✗] Failed to save block_devmode${NC}"
            fi
            
            echo -e "${GREEN}[✓] Unenrollment completed.${NC}"
            echo -e "${YELLOW}[!] Next: Boot to developer mode and run block-updates${NC}"
            echo ""
            read -p "Press Enter to return to menu..."
            ;;
        q|Q|quit|Quit)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[✗] Invalid option. Please enter 1, 2, or Q.${NC}"
            sleep 2
            ;;
    esac
done
