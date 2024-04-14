#!/usr/bin/env bash

set -e

DEB_URLS=(
  https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  https://azuredatastudio-update.azurewebsites.net/latest/linux-deb-x64/stable
  https://code.visualstudio.com/sha/download?build=stable\&os=linux-deb-x64
)

APT_LIST=(
  flatpak
  gnome-software-plugin-flatpak
  winff
  gparted
  gufw
  synaptic
  vlc
  gnome-sushi
  git
  wget
  ubuntu-restricted-extras
  flameshot
  libunwind8
)

FLATPAK_LIST=(
  org.gimp.GIMP
  com.bitwarden.desktop
  org.telegram.desktop
  org.onlyoffice.desktopeditors
  org.qbittorrent.qBittorrent
  com.anydesk.Anydesk
  org.remmina.Remmina
  io.bassi.Amberol
  io.github.Soundux
  io.gitlab.news_flash.NewsFlash
  org.audacityteam.Audacity
  org.inkscape.Inkscape
  org.kde.kdenlive
  rest.insomnia.Insomnia
)

# working directory
DOWNLOADS_PATH="/tmp/postinstall_debs"
FILE_BOOKMARK="$HOME/.config/gtk-3.0/bookmarks"

print_message() {
  local message_type=$1
  local message=$2

  case $message_type in
  "error")
    echo -e "\n\e[1;91m [ERROR] - $message \e[0m\n"
    ;;
  "info")
    echo -e "\n\e[1;92m [INFO] - $message \e[0m\n"
    ;;
  esac
}

apt_update() {
  print_message "info" "Updating system..."

  sudo apt update && sudo apt dist-upgrade -y
}

just_apt_update() {
  sudo apt update -y
}

check_internet() {
  if ! ping -c 1 8.8.8.8 -q &>/dev/null; then
    print_message "error" "You're not connected to the internet."
    exit 1
  else
    print_message "info" "Internet connection is OK."
  fi
}

remove_apt_lock() {
  sudo rm /var/lib/dpkg/lock-frontend
  sudo rm /var/cache/apt/archives/lock
}

add_archi386() {
  sudo dpkg --add-architecture i386
}

install_debs_from_url() {
  print_message "info" "Installing .deb packages..."

  mkdir -p "$DOWNLOADS_PATH"

  # Downloading .deb packages
  for url in ${DEB_URLS[@]}; do
    print_message "info" "Downloading: $url"
    wget -c "$url" -P "$DOWNLOADS_PATH" &>/dev/null

    if [ $? -ne 0 ]; then
      print_message "error" "Failed to download $url"
      exit 1
    fi
  done

  print_message "info" "Installing .deb packages..."
  for deb_file in $DOWNLOADS_PATH/*; do
    package_name=$(dpkg -I "$deb_file" | grep Package | awk '{print $2}')

    print_message "info" "Installing $package_name..."

    sudo dpkg -i "$deb_file"
  done
}

install_debs() {
  print_message "info" "Installing packages from apt..."

  for package_name in ${APT_LIST[@]}; do
    if ! dpkg -l | grep -q $package_name; then
      print_message "info" "Installing $package_name..."

      sudo apt install "$package_name" -y
    else
      print_message "info" "$package_name is already installed."
    fi
  done

}
install_flatpaks() {
  print_message "info" "Adding Flathub repository..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  print_message "info" "Installing flatpaks..."
  for flatpak_name in ${FLATPAK_LIST[@]}; do
    if ! flatpak list | grep -q $flatpak_name; then
      print_message "info" "Installing $flatpak_name..."

      flatpak install flathub "$flatpak_name" -y
    else
      print_message "info" "$flatpak_name is already installed."
    fi
  done
}

system_clean() {
  apt_update
  flatpak update -y
  sudo apt autoclean -y
  sudo apt autoremove -y
  nautilus -q
}

extra_config() {
  mkdir $HOME/backups
  mkdir $HOME/dev

  # Add Nautilus bookmarks
  if test -f "$FILE_BOOKMARK"; then
    print_message "info" "$FILE_BOOKMARK already exists, adding bookmarks..."
  else
    print_message "info" "Creating $FILE_BOOKMARK..."
    touch $HOME/.config/gkt-3.0/bookmarks
  fi

  echo "file://$HOME/backups 🔵 Backups" >>$FILE_BOOKMARK
}

main() {
  check_internet
  remove_apt_lock
  apt_update
  remove_apt_lock
  add_archi386
  just_apt_update
  install_debs
  install_debs_from_url
  install_flatpaks
  extra_config
  apt_update
  system_clean

  print_message "info" "Post-installation completed."
}

main
