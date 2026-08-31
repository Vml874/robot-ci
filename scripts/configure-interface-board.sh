#!/bin/bash

# Neurobionics Interface Board Configuration Script
# Runs on first boot to configure hardware interfaces

set -euo pipefail

CONFIG_FILE="/boot/firmware/config.txt"
MARKER="# Neurobionics Interface Board Configuration"

# Never create this file: an absent config.txt means the boot partition is not
# mounted where we expect, and writing a fresh one would mask that
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found, refusing to create it" >&2
    exit 1
fi

# Check if configuration already exists
if grep -q "$MARKER" "$CONFIG_FILE"; then
    echo "Neurobionics Interface Board configuration already present in $CONFIG_FILE"
else
    echo "Adding Neurobionics Interface Board configuration to $CONFIG_FILE"

    # Add configuration to config.txt
    cat << 'EOF' >> "$CONFIG_FILE"

# [all] resets any conditional filter the base image's config.txt may end in.
# Without it this block would silently inherit a trailing [cm4]/[pi4]/[none]
# section and every overlay below would be ignored with no error.
[all]

# Neurobionics Interface Board Configuration

# UART
dtoverlay=uart1-pi5
dtoverlay=uart2-pi5

# I2C
dtparam=i2c_arm=on,i2c_arm_baudrate=400000
dtoverlay=i2c1-pi5,pins_2_3,baudrate=400000
dtoverlay=i2c3-pi5,pins_22_23,baudrate=400000

# SPI
dtparam=spi=on
dtoverlay=spi0-2cs,cs0_pin=8,cs1_pin=7
dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16
dtoverlay=spi5-1cs,cs0_pin=12

# Enable CAN Bus on SPI0-0
dtoverlay=mcp2515-can0,oscillator=16000000,interrupt=26

# Fan
dtparam=cooling_fan=on
dtparam=fan_temp0=40000
EOF

    echo "Configuration added successfully. Reboot required for changes to take effect."
fi

# Disable this service last, so that an interrupted run is retried on the next
# boot instead of leaving the board half configured with no way to recover.
# can0.service is installed and enabled at image build time by interface.Pifile.
systemctl disable configure-interface-board.service

echo "Service disabled. Configuration complete."
