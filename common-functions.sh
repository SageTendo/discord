#!/bin/bash
# Author: TheElectronWill
# Various functions used by the scripts of https://github.com/RPM-Outpost
# This script requires terminal-colors.sh

# Initializes $installer and $distrib
if hash dnf 2>/dev/null; then
	# Fedora, CentOS with dnf installed
	installer="dnf install --allowerasing"
	distrib="redhat"
elif hash yum 2>/dev/null; then
	# CentOS
	installer="yum install"
	distrib="redhat"
elif hash zypper 2>/dev/null; then
	# OpenSUSE
	installer="zypper install"
	distrib="suse"
elif hash urpmi 2>/dev/null; then
	# Mageia
	installer="urpmi"
	distrib="mageia"
else
	# Unknown
	installer="exit"
	distrib="unknown"
fi

# Initializes $wget_progress: detects if the option --show-progress is available
wget --help | grep -q '\--show-progress' && wget_progress="-q --show-progress" || wget_progress=""

# remove_dir directory
## Remove the specified directory
remove_dir() {
	if [[ -d "$1" ]]; then
		rm -r "$1"
		echo "Directory removed."
	 else
		echo "Directory $1 does not exist, skipping removal."
fi
}

# manage_dir directory directory_short_name
## Removes the specified directory if it exists.
manage_dir() {
	echo "The $2 directory already exists."
	remove_dir "$1"
	mkdir -p "$1"
}

# installpkg [all]
## Install the newly created package.
installpkg() {
	cd "$rpm_dir/$arch"
	
	local arg="${1:-}"  # default empty string if $1 unset
	
	if [[ "$arg" == "all" ]]; then
		rpm_filename=$(find -type f -name '*.rpm' -printf '%P\n')
	else
		rpm_filename=$(find -maxdepth 1 -type f -name '*.rpm' -printf '%P\n' -quit)
	fi

	sudo_install "$PWD/$rpm_filename" -y
}

# sudo_install pkg [options]
sudo_install() {
  if rpm -q discord >/dev/null 2>&1; then
    current_version=$(rpm -q discord)
    echo "Removing current Discord package: $current_version"
    sudo dnf remove -y discord || { echo "Failed to remove current package"; return 1; }
  else
    echo "Discord package not installed, skipping removal."
  fi

  echo "Installing package(s): $*"
  sudo $installer "$@" || { echo "Failed to install package(s)"; return 1; }
}

# extract archive_file destination [option1 [option2]]
extract() {
	echo "Extracting \"$1\"..."
	if [[ "$1" == *.tar.gz ]]; then
		command="tar -xzf \"$1\" -C \"$2\""
	elif [[ "$1" == *.tar.xz ]];then
		command="tar -xJf \"$1\" -C \"$2\""
	elif [[ "$1" == *.tar.bz2 ]];then
		command="tar -xjf \"$1\" -C \"$2\""
	elif [[ "$1" == *.tar ]];then
		command="tar -xf \"$1\" -C \"$2\""
	elif [[ "$1" == *.zip ]]; then
		command="unzip -q \"$1\" -d \"$2\""
	else
		disp "${red}Unsupported archive type for $1"
		return 10
	fi
	if [ $# -eq 3 ]; then
		eval $command $3 # Custom options
	elif [ $# -eq 4 ]; then
		eval $command $3 $4 # Custom options
	else
		eval $command
	fi
}
