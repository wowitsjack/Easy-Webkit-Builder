#!/bin/bash

# Clear the screen initially for sudo password request
clear
echo "Requesting administrative access for installation..."
# Ask for the sudo password upfront
sudo -v
# Keep-alive: update existing sudo time stamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Define a function to show dialogs for executing commands
execute_command() {
    local cmd=$1
    local title=$2
    {
        echo "$title"
        eval "$cmd"
    } | dialog --title "$title" --progressbox 30 100
}

# Welcome message
dialog --clear --title "Welcome" --msgbox "Welcome to the Setup Wizard. This will guide you through setting up the environment." 10 50

# Update system packages
execute_command "sudo apt-get update" "Updating System Packages"

# Install essential packages
packages=(
    libgcrypt20 libgcrypt20-dev
    libtasn1-6 libtasn1-6-dev
    unifdef
    libwebp-dev
    libgtk-4-dev
    libsoup3-dev libsoup3
    libsoup-3.0-dev
    libmanette-0.2-dev
    libxslt1-dev
    libsecret-1-dev
    libdrm-dev
    libgbm-dev
    libenchant-2-dev
    libjxl-dev
    afl++
    libstdc++-11-dev
    build-essential
    clang
    libllvm-17-ocaml-dev libllvm17 llvm-17 llvm-17-dev llvm-17-doc llvm-17-examples llvm-17-runtime
    libstdc++-12-dev
    libhyphen-dev
    libwoff-dev
    libavif-dev
    libsystemd-dev
    liblcms2-dev
    libgcc-11-dev
    libseccomp-dev
    libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good libgstreamer1.0-dev gstreamer1.0-libav gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-good libgstrtspserver-1.0-dev
    gperf
    gettext
    libxt-dev
    libopenjp2-7-dev
    gi-docgen
)

for package in "${packages[@]}"; do
    execute_command "sudo apt-get install -y $package" "Installing $package"
done

# Function to execute git clone and setup operations within dialog
git_clone_and_setup() {
    local git_url=$1
    local folder_name=$2
    local setup_commands=$3
    local title=$4
    {
        echo "Cloning $folder_name..."
        rm -rf "$folder_name" && git clone "$git_url" "$folder_name" --recursive --shallow-submodules
        cd "$folder_name"
        eval "$setup_commands"
    } | dialog --title "$title" --progressbox 30 100
}


# Clone and setup libjxl
git_clone_and_setup "https://github.com/libjxl/libjxl.git" "libjxl" "sudo apt install -y cmake pkg-config libbrotli-dev libgif-dev libjpeg-dev libopenexr-dev libpng-dev libwebp-dev clang && export CC=clang CXX=clang++ && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && cmake --build . -- -j\$(nproc) && sudo cmake --install ." "Setting up libjxl"

# Clone and install libbacktrace for backtrace support
git_clone_and_setup "https://github.com/ianlancetaylor/libbacktrace" "libbacktrace" "./configure && make && sudo make install" "Installing libbacktrace"

# Finalization and cleanup
dialog --clear --title "Completion" --msgbox "All steps completed successfully. Your environment is now set up." 10 50

clear
