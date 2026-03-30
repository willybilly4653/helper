#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run this script with sudo.${NC}"
    exit 1
fi

# Function to run command in VT2
run_in_vt2() {
    local cmd="$1"
    local current_vt=$(fgconsole 2>/dev/null || echo "1")
    
    echo -e "${YELLOW}[*] Current VT: ${current_vt}${NC}"
    echo -e "${YELLOW}[*] Switching to VT2...${NC}"
    
    # Switch to VT2
    chvt 2
    sleep 1
    
    # Clear screen on VT2
    echo -e "\033[2J\033[H" > /dev/tty2
    
    # Display banner on VT2
    echo -e "${CYAN}==================================================${NC}" > /dev/tty2
    echo -e "${CYAN}         RUNNING VPD COMMAND                      ${NC}" > /dev/tty2
    echo -e "${CYAN}==================================================${NC}" > /dev/tty2
    echo "" > /dev/tty2
    
    # Run the command and capture output
    echo -e "${YELLOW}[*] Executing: ${cmd}${NC}" > /dev/tty2
    echo "" > /dev/tty2
    
    # Execute the command
    eval "$cmd" 2>&1 | tee /dev/tty2
    
    local exit_code=${PIPESTATUS[0]}
    
    echo "" > /dev/tty2
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}[✓] Command completed successfully!${NC}" > /dev/tty2
    else
        echo -e "${RED}[✗] Command failed with exit code: ${exit_code}${NC}" > /dev/tty2
    fi
    
    echo "" > /dev/tty2
    echo -e "${YELLOW}Press any key to return to VT${current_vt}...${NC}" > /dev/tty2
    
    # Wait for user input on VT2
    read -n 1 -s < /dev/tty2
    
    # Switch back
    echo -e "${YELLOW}[*] Returning to VT${current_vt}...${NC}" > /dev/tty2
    chvt "$current_vt"
    
    return $exit_code
}

# Main execution
clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}         VPD RE-ENROLLMENT KEY REMOVER             ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""
echo -e "${YELLOW}[!] This script will remove the re_enrollment_key${NC}"
echo -e "${YELLOW}[!] from RW_VPD by running in VT2${NC}"
echo ""
echo -e "${BLUE}Command to run:${NC}"
echo -e "  ${CYAN}vpd -i RW_VPD -d re_enrollment_key${NC}"
echo ""
echo -e "${YELLOW}[!] You will be switched to VT2 (text console)${NC}"
echo -e "${YELLOW}[!] The command will run automatically there${NC}"
echo -e "${YELLOW}[!] Press any key when done to return here${NC}"
echo ""
echo -ne "${BLUE}Continue? (y/n): ${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 0
fi

# Run the command
run_in_vt2 "vpd -i RW_VPD -d re_enrollment_key"

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ re_enrollment_key successfully removed!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[*] The device should now re-enroll on next boot${NC}"
    echo -e "${YELLOW}[*] To force immediate re-enrollment:${NC}"
    echo -e "    ${CYAN}crossystem block_devmode=1${NC}"
    echo -e "    ${CYAN}vpd -i RW_VPD -s block_devmode=1${NC}"
    echo -e "    ${CYAN}reboot${NC}"
else
    echo ""
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ Failed to remove re_enrollment_key${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[!] Possible issues:${NC}"
    echo -e "    • VPD region may be write-protected"
    echo -e "    • RW_VPD partition may not exist"
    echo -e "    • Not enough permissions"
    echo -e "    • Firmware write-protect enabled"
fi

echo ""
echo -ne "${BLUE}Press Enter to exit...${NC}"
read -r
