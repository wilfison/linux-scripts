#!/usr/bin/env bash

set -e

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

BACKUP_DIR=$HOME
BACKUP_NAME="backup-$(date +%Y-%m-%d-%H-%M-%S).7z"

TEMPLATES_PATH=$(xdg-user-dir TEMPLATES)
DOCUMENTS_PATH=$(xdg-user-dir DOCUMENTS)
MUSIC_PATH=$(xdg-user-dir MUSIC)
PICTURES_PATH=$(xdg-user-dir PICTURES)
VIDEOS_PATH=$(xdg-user-dir VIDEOS)

PATHS_TO_BACKUP=(
  "$TEMPLATES_PATH"
  "$DOCUMENTS_PATH"
  "$MUSIC_PATH"
  "$PICTURES_PATH"
  "$VIDEOS_PATH"
  "$HOME/.anydesk"
  "$HOME/.ssh"
  "$HOME/.aws"
  "$HOME/.fonts"
  "$HOME/.azuredatastudio"
  "$HOME/.config/google-chrome"
  "$HOME/.config/kdeconnect"
  "$HOME/.var/app/com.anydesk.Anydesk"
  "$HOME/.var/app/com.bitwarden.desktop"
  "$HOME/.var/app/io.gitlab.news_flash.NewsFlash"
  "$HOME/.var/app/org.remmina.Remmina"
  "$HOME/.var/app/org.telegram.desktop"
  "$HOME/.var/app/rest.insomnia.Insomnia"
)

print_message "info" "Starting backup process..."

7z a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m -ms=on "$BACKUP_DIR/$BACKUP_NAME" "${PATHS_TO_BACKUP[@]}"
