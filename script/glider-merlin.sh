#!/bin/sh

# Glider-Merlin - A transparent proxy for ASUSWRT-MERLIN with glider
# ================

# check directory structure
# ----------------

if [ "$GM_HOME" = "" ]; then
  GM_HOME=/opt/share/glider-merlin
fi

_subdir_list="bin data etc/glider etc/dnsmasq.d script"
for _dir in $_subdir_list
do
  if [ ! -d "$_dir" ]; then
    echo "Subdir missed in Glider-Merlin home directory: '$_dir'"
    echo "Abort"
    exit 1
  fi
done

GM_HOME_BIN=$GM_HOME/bin
GM_HOME_DATA=$GM_HOME/data
GM_HOME_ETC=$GM_HOME/etc
GM_HOME_ETC_GLIDER=$GM_HOME_ETC/glider
GM_HOME_ETC_DNSMASQ=$GM_HOME_ETC/dnsmasq.d
GM_HOME_SCRIPT=$GM_HOME/script

# Load all the modules in the $GM_HOME_SCRIPT direcotry
# ----------------

_load() {
  if [ ! -f "$1" ]; then
    echo "Required script file missed: '$1'"
    echo "Abort"
    exit 1
  fi

  _basename=$(basename $1)
  _basename_noext=${_basename%.*}
  _basename_noext=$(echo $_basename_noext | tr [a-z] [A-Z])

  eval "_loaded=\$GM_SCRIPT_${_basename_noext}_INCLUDED"

  if [ -z "$loaded" ]; then
    source $1
  fi
}

_load $GM_HOME_SCRIPT/helper.sh
_load $GM_HOME_SCRIPT/gliderconf.sh
_load $GM_HOME_SCRIPT/list.sh
_load $GM_HOME_SCRIPT/dns.sh
_load $GM_HOME_SCRIPT/ipset.sh
_load $GM_HOME_SCRIPT/iptables.sh

# Glider-Merlin Configuration
# ----------------
source $GM_HOME/etc/glider-merlin.conf

if [ "$GM_QUICK_DNS_SERVER" = "" ]; then
  GM_QUICK_DNS_SERVER=$(get_default_dns_server)
fi

# Glider Configuration
# ----------------
_bold "Parsing glider.conf ..."
parse_glider_conf "$GM_HOME_ETC_GLIDER/glider.conf"
_info "Done."

# Main program
# ----------------
_usage(){
  _bold "Usage: glider-merlin config|fullconfig|start|stop|restart|update|remove"
}

# Upodate configurations: glider, domain/IP list, dnsmasq
_gmc_config(){
  _bold "Downloading the well known domain/IP lists ..."
  curl_system_list $1
  _info "Done."

  make_dns_conf $1
  
  create_ipset
}
_enable_autostart_glider(){
  _service_start=/jffs/scripts/service-start
  _start_glider_service="nohup $GM_HOME_BIN/glider -config $GM_HOME_ETC_GLIDER/glider.conf >/dev/null 2>&1 &"

  if [ -d "/jffs/scripts" ]; then
    touch $_service_start
    unset _found

    while read -r _line
    do
      if [ "$_line" = "$_start_glider_service" ]; then
        _found=true
        break
      fi
    done < $_service_start

    if [ "$_found" != "true" ]; then
      echo $_start_glider_service >> $_service_start
    fi
  else
    _error "Can't enbale auto-start glider service on boot for no '/jffs/scripts' directory!"
  fi
}

_disable_autostart_glider(){
  _service_start=/jffs/scripts/service-start
  _start_glider_service="nohup $GM_HOME_BIN/glider -config $GM_HOME_ETC_GLIDER/glider.conf >/dev/null 2>&1 &"

  if [ -f "$_service_start" ]; then
    while read -r _line
    do
      if [ "$_line" != "$_start_glider_service" ]; then
        echo $_line
      fi
    done < $_service_start >> $_service_start.bak

    mv $_service_start.bak $_service_start
  fi
}

_gmc_start(){
  if [ ! -f "$GM_HOME_ETC_GLIDER/glider.conf" ]; then
    _error "NO Glider configuration file: $GM_HOME_ETC_GLIDER/glider.conf"
    _info "$GM_HOME_ETC_GLIDER/glider.template.conf is an example."
    exit 1
  fi

  if [ ! -f "$GM_HOME_BIN/glider" ]; then
    _error "Glider program not found: $GM_HOME_BIN/glider"
  fi
  chmod 755 $GM_HOME_BIN/glider

  # start glider service
  killall glider
  nohup $GM_HOME_BIN/glider -config $GM_HOME_ETC_GLIDER/glider.conf >/dev/null 2>&1 &

  apply_iptables
  apply_dns_conf
  
  service restart_dnsmasq

  # Enable auto-start glider service on boot
  _enable_autostart_glider
}

_gmc_stop(){
  clear_dns_conf
  clear_iptables

  service restart_dnsmasq
  killall glider

  # disable auto-start glider service on boot
  _disable_autostart_glider
}

_gmc_remove(){
  _gmc_stop

  destroy_ipset
  rm /opt/sbin/glider-merlin
}


case $1 in
  config)
              _gmc_config
              ;;
  fullconfig)
              _gmc_config forced
              ;;
  start)
              _gmc_start
              _info "Glider-merlin started."
              ;;
  stop)
              _gmc_stop
              _info "Glider-merlin stopped."
              ;;
  restart)
              _gmc_stop
              _gmc_start
              ;;
  update)
              _warn "NOT implemented: glider-merlin update"
              ;;
  remove)
              _gmc_remove
              _info "Glider-merlin removed."
              ;;
  *)
              _usage
              ;;
esac

