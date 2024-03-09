#!/bin/bash

# Request sudo access at the beginning
clear
echo "Requesting administrative access for initial setup..."
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Function to execute commands within dialog boxes, showing output in a progress box
execute_command() {
    local cmd=$1
    local title=$2
    dialog --title "$title" --infobox "Preparing execution..." 10 70
    eval "$cmd" 2>&1 | dialog --title "$title" --progressbox 50 100
}

# Function to display welcome message using dialog
welcome_message() {
    dialog --clear --title "Welcome" --msgbox "Welcome to the Setup Wizard. This will guide you through setting up the environment." 10 50
}

# Function to get WebKitGTK version from the user
get_webkitgtk_version() {
    WEBKITGTK_VERSION=$(dialog --title "WebKitGTK Version" --inputbox "Enter the version of WebKitGTK you want to build (e.g., 2.42.5):" 8 40 2>&1 >/dev/tty)
}

# Function to show build options menu and capture selections
show_build_options_menu() {
    BUILD_OPTIONS=$(dialog --checklist "Choose build options:" 20 70 12 \
    "DEVELOPER_MODE" "Developer Mode" OFF \
    "ENABLE_API_TESTS" "API Tests" OFF \
    "ENABLE_BUBBLEWRAP_SANDBOX" "Bubblewrap Sandbox" OFF \
    "ENABLE_GAMEPAD" "Gamepad Support" ON \
    "ENABLE_GLES2" "GLES2 Support" OFF \
    "ENABLE_GTKDOC" "GTK Documentation" OFF \
    "ENABLE_MINIBROWSER" "Mini Browser" ON \
    "ENABLE_SPELLCHECK" "Spellcheck" ON \
    "USE_LIBNOTIFY" "Libnotify" OFF \
    "USE_LIBSECRET" "Libsecret" OFF \
    "USE_OPENGL_OR_ES" "OpenGL or ES" ON \
    "USE_SYSTEMD" "Systemd" OFF \
    "USE_WPE_RENDERER" "WPE Renderer" OFF 2>&1 >/dev/tty)
}

# Install all required packages at once, silently, with no user interaction
install_packages() {
    packages="libgcrypt20 libgcrypt20-dev libtasn1-6 libtasn1-6-dev unifdef libwebp-dev libgtk-4-dev libsoup3-dev libsoup3 libsoup-3.0-dev libmanette-0.2-dev libxslt1-dev libsecret-1-dev libdrm-dev libgbm-dev libenchant-2-dev libjxl-dev afl++ libstdc++-11-dev build-essential clang llvm-17 libstdc++-12-dev libhyphen-dev libwoff-dev libavif-dev libsystemd-dev liblcms2-dev libgcc-11-dev libseccomp-dev libgstreamer-plugins-base1.0-dev gstreamer1.0-plugins-base gstreamer1.0-plugins-good libgstreamer1.0-dev gstreamer1.0-libav gstreamer1.0-plugins-bad libgstreamer-plugins-bad1.0-dev gstreamer1.0-plugins-good libgstrtspserver-1.0-dev gperf gettext libxt-dev libopenjp2-7-dev gi-docgen"
    execute_command "sudo apt-get update && sudo apt-get install -y $packages" "Installing required packages"
}

# Function to clone, build, and install dependencies
git_clone_and_setup() {
    local git_url=$1
    local folder_name=$2
    local setup_commands=$3
    local title=$4
    execute_command "rm -rf $folder_name && git clone $git_url $folder_name --recursive --shallow-submodules && cd $folder_name && $setup_commands" "$title"
}

# Welcome the user and get necessary input
welcome_message
get_webkitgtk_version
show_build_options_menu

# Convert dialog output to CMake options
CONVERTED_OPTIONS=""
for option in $BUILD_OPTIONS; do
    CONVERTED_OPTIONS+="-D $option=ON "
done

# Install essential packages
install_packages

# Clone and setup libjxl
git_clone_and_setup "https://github.com/libjxl/libjxl.git" "libjxl" "sudo apt install -y cmake pkg-config libbrotli-dev libgif-dev libjpeg-dev libopenexr-dev libpng-dev libwebp-dev clang && export CC=clang CXX=clang++ && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF .. && cmake --build . -- -j\$(nproc) && sudo cmake --install ." "Setting up libjxl"

# Clone and setup libbacktrace
git_clone_and_setup "https://github.com/ianlancetaylor/libbacktrace" "libbacktrace" "./configure && make && sudo make install" "Installing libbacktrace"

# Build and install WebKitGTK
execute_command "wget https://webkitgtk.org/releases/webkitgtk-${WEBKITGTK_VERSION}.tar.xz && tar xf webkitgtk-${WEBKITGTK_VERSION}.tar.xz && cd webkitgtk-${WEBKITGTK_VERSION} && mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release -DPORT=GTK -DLIB_INSTALL_DIR=/usr/lib -DENABLE_SANITIZERS='address' $CONVERTED_OPTIONS .. && make -j\$(nproc) && sudo make install" "Building and installing WebKitGTK ${WEBKITGTK_VERSION}"

# Final message to indicate completion
dialog --clear --title "Completion" --msgbox "All steps completed successfully. Your environment is now set up." 10 50

clear
