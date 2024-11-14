#!/usr/bin/env bash

set -e

DEB_URLS=(
  "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
  "https://azuredatastudio-update.azurewebsites.net/latest/linux-deb-x64/stable"
)

APT_LIST=(
  build-essential
  flatpak
  gnome-software-plugin-flatpak
  winff
  gparted
  gufw
  synaptic
  git
  wget
  ubuntu-restricted-extras
  flameshot
  libunwind8
  libffi-dev
  libyaml-dev
  libgmp-dev
  freetds-dev
  ca-certificates
  curl
)

FLATPAK_LIST=(
  org.gimp.GIMP
  org.telegram.desktop
  org.onlyoffice.desktopeditors
  org.qbittorrent.qBittorrent
  com.anydesk.Anydesk
  org.remmina.Remmina
  org.inkscape.Inkscape
  org.kde.kdenlive
  rest.insomnia.Insomnia
)

# working directory
DOWNLOADS_PATH="/tmp/postinstall_debs"

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
  sudo rm -f /var/lib/dpkg/lock-frontend
  sudo rm -f /var/cache/apt/archives/lock
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
}

extra_config() {
}

install_asdf() {
  print_message "info" "Installing asdf..."

  # get last asdf version from github
  asdf_version=$(curl -s https://api.github.com/repos/asdf-vm/asdf/releases/latest | grep tag_name | cut -d '"' -f 4)
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch $asdf_version

  # install asdf plugins
  . "$HOME/.asdf/asdf.sh"

  print_message "info" "Installing asdf plugins..."
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
  asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

  echo "legacy_version_file = yes" >~/.asdfrc
}

configure_zsh() {
  print_message "info" "Configuring Zsh..."
  git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

  # configure plugins
  sed -i 's/plugins=(git)/plugins=(git asdf zsh-autosuggestions docker)/' ~/.zshrc

  # configure theme
  sed -i 's/ZSH_THEME="robbyrussell"/# ZSH_THEME="robbyrussell\nZSH_THEME="agnoster"/' ~/.zshrc
}

install_docker() {
  print_message "info" "Installing Docker..."

  # Add Docker's official GPG key:
  sudo apt update
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  . /etc/os-release
  UBUNTU_FAMILY=$VERSION_CODENAME

  # if not Ubuntu, use UBUNTU_CODENAME variable
  if [ -z "$UBUNTU_FAMILY" ]; then
    UBUNTU_FAMILY=$UBUNTU_CODENAME
  fi

  # Add the repository to Apt sources:
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $UBUNTU_FAMILY stable" |
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  sudo groupadd docker
  sudo usermod -aG docker $USER
  newgrp docker
}

install_aws_cli() {
  print_message "info" "Installing AWS CLI..."

  sudo apt install awscli -y
}

install_sql_tools() {
  print_message "info" "Installing SQL Server tools..."

  curl https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
  curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | sudo tee /etc/apt/sources.list.d/mssql-release.list

  sudo apt update
  sudo apt install mssql-tools18 unixodbc-dev

  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >>~/.zshrc
  source ~/.zshrc
}

main() {
  check_internet
  remove_apt_lock
  apt_update
  remove_apt_lock
  add_archi386
  just_apt_update
  install_debs
  install_flatpaks
  install_debs_from_url
  extra_config
  apt_update
  system_clean
  install_asdf
  configure_zsh
  install_docker
  install_aws_cli
  install_sql_tools

  print_message "info" "Post-installation completed."
}

main
