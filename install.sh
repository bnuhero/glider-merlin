#!/bin/sh

# Helper functions
# ----------------

# print colorful message.
ansi_red="\033[1;31m"
ansi_green="\033[1;32m"
ansi_yellow="\033[1;33m"
ansi_std="\033[m"

_warn(){ # YELLOW
  echo -e "$ansi_yellow WARNING: $1 $ansi_std"
}

_error(){ # RED
  echo -e "$ansi_red ERROR: $1 $ansi_std"
}

_bold(){ # GREEN
  echo -e "$ansi_green $1 $ansi_std"
}

_info(){ # WHITE
  echo -e "$ansi_std $1 $ansi_std"
}

# Usage: _assign ARGV1 ARGV2
#   if ARGV1 is unset, set ARGV1=ARGV2
_assign(){
  if [ $# -eq 2 ]; then
    eval "_value=\${$1}"
    if [ "$_value" = "" ]; then
      eval "$1=$2"
    fi
  fi
}

# Change text case to upper case.
_uppercase(){
  echo $(echo $1 | tr [a-z] [A-Z])
}

# Change text case to upper case.
_lowercase(){
  echo $(echo $1 | tr [A-Z] [a-z])
}

# Usage: _join ARG1 ARG2 ARG3
#   Join ARG1 and ARG3 with the delimiter ARG2
_join(){
  if [ "$#" = "3" ]; then
    if [ "$1" = "" ]; then
      echo "$3"
    else
      echo "$1$2$3"
    fi
  fi
}

# check_requirements
# ----------------
# Check the system requirements for using Glider-Merlin.
#   1) ASUSWRT_MERLIN
#   2) Entware installed
#   3) JFFS partitions enabled.
check_requirements() {
  ASUSWRT_MERLIN="ASUSWRT-MERLIN"
  _router_os=$(uname -o)

  if [ "$(_uppercase $_router_os)" != $ASUSWRT_MERLIN ]; then
    _error "$ASUSWRT_MERLIN required, but your router OS is $_router_os!"
    _info "Abort"
    exit 1
  else
    _router_buildno=$(nvram get buildno)
    _info "ASUSWRT-MERLIN $_router_buildno found."
  fi

  if ! opkg --version 2>/dev/null; then
    _error "NO opkg found. Please install entware first."
    _info "https://github.com/RMerl/asuswrt-merlin/wiki/Entware"
    _info "Abort"
    exit 1
  fi

  if [[ ! -d /jffs ]]; then
    _error "NO JFFS partition found. Please enable it first!"
    _info "https://github.com/RMerl/asuswrt-merlin/wiki/JFFS"
    _info "Abort"
    exit 1
  else
    _info "JFFS partition enabled."
  fi
}

# install_packages
# ----------------
# Install the required packages.
#   ca-certificates git git-http haveged ipset iptables
install_packages() {
  _need_packages=""

  for _pkg in $1
  do
    if [ "$(opkg list-installed $_pkg)" = "" ]; then
      _need_packages=$(_join "$_need_packages" " " $_pkg)
    fi
  done

  if [ "$_need_packages" = "" ]; then
    _info "All installed: $_packages"
  else
    opkg update
    opkg upgrade
    opkg install $_need_packages
  fi  
}

# clone_gm_repo
# ----------------
# Clone the glider-merlin repo ($1) to the destination directory ($2).
#
clone_gm_repo(){
  # The destination directory must be empty.
  if [ -d "$2" ]; then
    _error "The destination Directory '$2' is NOT empty."
    _info "Abort"
    exit 1
  fi

  # cloning...
  git clone --depth=1 $1 "$2" || {
    _error "Failed to clone '$1' to '$2'"
    _info "Abort"
    exit 1
  }  
}

# Main
# ----

_bold "Checking the system requirements ..."
check_requirements

_bold "Installing required packages ..."
_packages="ca-certificates git git-http haveged ipset iptables"
install_packages "$_packages"

# Start the high precision random number generation service
/opt/etc/init.d/S02haveged start

# Clone the glider-merlin repository to '$GM_HOME' directory.
_assign GM_REPO_URL "https://github.com/bnuhero/glider-merlin.git"
_assign GM_HOME "/opt/share/glider-merlin"

_bold "Cloning glider-merlin repo ..."
clone_gm_repo $GM_REPO_URL $GM_HOME

# Add shorcut to the glider-merlin.sh
_gm=/opt/sbin/glider-merlin
_gm_shell=$GM_HOME/script/glider-merlin.sh

if [ -e "$_gm" ]; then
  _warn "Original '$_gm' deleted!"
  rm $_gm
fi

if [ ! -f "$_gm_shell" ]; then
  _error "$_gm_shell missed."
  _info "Installation abort."
  exit 1
fi
ln -s $_gm_shell $_gm

# Initalization
#   1) Download the well known IP|DNS list if NOT existed.
#   2) Generate the dnsmasq configration files using IP|DNS whitelist|blacklist if NOT existed.
#   3) Create the corresponding ipsets.
# glider-merlin config

_bold "glider-merlin installed in '$GM_HOME' successfully!"