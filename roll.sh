#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Ensure we're root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root. Use: curl ... | sudo bash${NC}"
    exit 1
fi

clear
echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}         VPD RE-ENROLLMENT KEY REMOVER             ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""

# Function to run command in VT2
run_vpd_in_vt2() {
    local current_vt=$(fgconsole 2>/dev/null || echo "1")
    
    echo -e "${YELLOW}[*] Current VT: ${current_vt}${NC}"
    echo -e "${YELLOW}[*] Switching to VT2 to run VPD command...${NC}"
    echo ""
    
    # Switch to VT2
    chvt 2
    sleep 1
    
    # Clear and show banner on VT2
    echo -e "\033[2J\033[H" > /dev/tty2
    echo -e "${CYAN}================================================${NC}" > /dev/tty2
    echo -e "${CYAN}         VPD OPERATION                          ${NC}" > /dev/tty2
    echo -e "${CYAN}================================================${NC}" > /dev/tty2
    echo "" > /dev/tty2
    
    # Run the VPD command
    echo -e "${YELLOW}[*] Running: vpd -i RW_VPD -d re_enrollment_key${NC}" > /dev/tty2
    echo "" > /dev/tty2
    
    vpd -i RW_VPD -d re_enrollment_key 2>&1 | tee /dev/tty2
    local exit_code=${PIPESTATUS[0]}
    
    echo "" > /dev/tty2
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}[✓] SUCCESS: re_enrollment_key removed${NC}" > /dev/tty2
    else
        echo -e "${RED}[✗] FAILED: Exit code ${exit_code}${NC}" > /dev/tty2
    fi
    
    echo "" > /dev/tty2
    echo -e "${YELLOW}Press ENTER to return to VT${current_vt}...${NC}" > /dev/tty2
    read -r < /dev/tty2
    
    # Switch back
    chvt "$current_vt"
    
    return $exit_code
}

# Confirm before proceeding
echo -e "${YELLOW}[!] This will remove the re_enrollment_key from RW_VPD${NC}"
echo -e "${YELLOW}[!] The device will need to re-enroll on next boot${NC}"
echo ""
echo -e "${BLUE}Command to run:${NC}"
echo -e "  ${CYAN}vpd -i RW_VPD -d re_enrollment_key${NC}"
echo ""
echo -ne "${BLUE}Continue? (y/n): ${NC}"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 0
fi

# Run the operation
run_vpd_in_vt2
result=$?

echo ""
if [ $result -eq 0 ]; then
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✓ re_enrollment_key successfully removed!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[*] Next steps to force re-enrollment:${NC}"
    echo -e "    ${CYAN}crossystem block_devmode=1${NC}"
    echo -e "    ${CYAN}vpd -i RW_VPD -s block_devmode=1${NC}"
    echo -e "    ${CYAN}reboot${NC}"
else
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}✗ Failed to remove re_enrollment_key${NC}"
    echo -e "${RED}════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}[!] Check if:${NC}"
    echo -e "    • Firmware write-protect is disabled"
    echo -e "    • RW_VPD partition exists"
    echo -e "    • You're in developer mode"
fi

echo ""
echo -e "${BLUE}Press Enter to exit...${NC}"
read -r
