#!/bin/bash

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to check and install necessary software
check_and_install_software() {
    local software=$1
    if ! command -v $software &> /dev/null; then
        echo -e "${RED}$software is not installed. Installing...${NC}"
        sudo apt-get install -y $software
    else
        echo -e "${GREEN}$software is already installed.${NC}"
    fi
}

# Function to run command with echo instead of dialog for simplicity
run_command() {
    local cmd=$1
    local message=$2
    echo -e "${GREEN}$message${NC}"
    eval $cmd
}

# Function to install dependencies
install_dependencies() {
    local dependencies=("libgtest-dev" "libgmock-dev" "cmake" "git" "gcc" "g++" "pkg-config" "libbrotli-dev" "liblzma-dev" "expect" "libgtk-3-dev" "libwebkit2gtk-4.0-dev" "libwpe-1.0-dev" "libwpebackend-fdo-1.0-dev")
    for dep in "${dependencies[@]}"; do
        if dpkg -l | grep -qw $dep; then
            echo -e "${GREEN}$dep is already installed.${NC}"
        else
            echo -e "${RED}$dep is not installed. Installing...${NC}"
            sudo apt-get install -y $dep
        fi
    done
    # Additional dependencies for AddressSanitizer
    sudo apt-get install -y libasan5 libubsan1
}

# Check for required software
REQUIRED_SOFTWARE=("python3" "python3-pip" "expect")
for software in "${REQUIRED_SOFTWARE[@]}"; do
    check_and_install_software $software
done

# Install dependencies
echo "Checking and installing dependencies..."
install_dependencies

# Default configurations
WEBKITGTK_VERSION="webkitgtk-2.43.4"

# Function to build WebKitGTK with AddressSanitizer
build_webkitgtk() {
    run_command "wget https://webkitgtk.org/releases/${WEBKITGTK_VERSION}.tar.xz && tar xf ${WEBKITGTK_VERSION}.tar.xz && cd ${WEBKITGTK_VERSION} && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo -DPORT=GTK -DLIB_INSTALL_DIR=/usr/lib/x86_64-linux-gnu -DENABLE_SANITIZERS='address' .. && make && sudo make install" "Building and installing WebKitGTK with AddressSanitizer"
    rm -rf ${WEBKITGTK_VERSION}*
}

# Main script execution starts here
echo -e "${GREEN}Starting the build process for WebKitGTK with AddressSanitizer...${NC}"
build_webkitgtk
echo -e "${GREEN}WebKitGTK build with AddressSanitizer completed successfully.${NC}"
