#!/bin/sh

GM_SCIPT_DNS_INCLUDED=yes

# Import helper functions
# ----------------
if [ "$GM_SCIPT_HELPER_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/helper.sh
fi

if [ "$GM_SCIPT_LIST_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/list.sh
fi

get_default_dns_server(){
  # get the default dns server of the router.
  _dns_server_list=$(nvram get wan_dns)
  
  for _dns_server in $_dns_server_list
  do
    if [ "$(_ipv4 $_dns_server)" = "yes" ]; then
      break
    fi
  done
  
  if [ "$_dns_server" = "" ]; then
    _dns_server=114.114.114.114
  fi

  echo $_dns_server
}

_make_dns_conf_by_blacklist(){
  _port=$GLIDER_DNS_PORT
  if [ "$_port" = "53" ]; then
    _port=""
  else
    _port="#$_port"
  fi

  for _list_file in $(_ls_files $GM_HOME_DATA "*$GM_DNS_BLACKLIST_EXT")
  do
    _conf_file_name=$(basename $_list_file $GM_DNS_BLACKLIST_EXT)
    _conf_file=$GM_HOME_ETC_DNSMASQ/$_conf_file_name.conf.black

    GLIDER_IPSET_NAME_LIST=$(_join $GLIDER_IPSET_NAME_LIST " " "gmb-$_conf_file_name")
        
    if [ "$1" != "forced" ] && [ "$(_is_sys_list $(basename $_list_file))" = "yes" ] && [ -f "$_conf_file" ]; then
      _warn "Conf file existed: $_conf_file."
      continue
    fi
    _info "Parsing $_list_file ..."
    while read -r _domain
    do
      if [ -n "_domain" ]; then
        echo "server=/$_domain/$GLIDER_DNS_HOST$_port"
        echo "ipset=/$_domain/gmb-$_conf_file_name" # IPs will be added to 'gmb-$_conf_file_name' by dnsmasq service.
      fi
    done < $_list_file >> $_conf_file
    _info "$_conf_file created."
  done
}

_make_dns_conf_by_whitelist(){
  for _list_file in $(_ls_files $GM_HOME_DATA "*$GM_DNS_WHITELIST_EXT")
  do
    _conf_file_name=$(basename $_list_file $GM_DNS_WHITELIST_EXT)
    _conf_file=$GM_HOME_ETC_DNSMASQ/$_conf_file_name.conf.white

    if [ "$1" != "forced" ] && [ "$(_is_sys_list $(basename $_list_file))" = "yes" ] && [ -f "$_conf_file" ]; then
      _warn "Conf file existed: $_conf_file."
      continue
    fi
    
    _info "Parsing $_list_file ..."
    while read -r _domain
    do
      if [ -n "_domain" ]; then
        echo "server=/$_domain/$GM_QUICK_DNS_SERVER"
      fi
    done < $_list_file >> $_conf_file
    _info "$_conf_file created."
  done
}

make_dns_conf(){
  _bold "Creating dnsmasq conf by DNS blacklist ..."
  _make_dns_conf_by_blacklist $1
  _info "Done."

  _bold "Creating dnsmasq conf by DNS whitelist ..."
  _make_dns_conf_by_whitelist $1
  _info "Done."
}

apply_dns_conf() {
  case $GM_DNS_MODE in
    quick) 
            _bold "Applying dnsmasq conf for quick mode ..."
            clear_dns_conf

            # copy '*.conf.black' files to '*.conf'
            #   All the domains in these "*.conf" files -> Glider dns server -> trusted dns servers
            for _src_conf in $(_ls_files $GM_HOME_ETC_DNSMASQ "*.conf.black")
            do
              _dest_conf=$(echo $_src_conf | sed -e "s/\(.*\)\.black$/\1/").glider
              cp $_src_conf $_dest_conf
            done

            # All the rest domains -> the default dns server of the router
            #   Nothing to do.

            _bold "Done."
            ;;
    trusted)
            _bold "Applying dnsmasq conf for trusted mode ..."
            clear_dns_conf

            # copy '*.conf.white' files to '*.conf'
            #   All the domains in these "*.conf" files -> the default dns server of the router
            for _src_conf in $(_ls_files $GM_HOME_ETC_DNSMASQ "*.conf.white")
            do
              _dest_conf=$(echo $_src_conf | sed -e "s/\(.*\)\.white$/\1/").glider
              cp $_src_conf $_dest_conf
            done

            # All the rest domains -> Glider dns server -> trusted dns servers.
            echo "server=/#/$GLIDER_DNS_HOST#$GLIDER_DNS_PORT" > $GM_HOME_ETC_DNSMASQ/ZZZZdefault.conf.glider
            _bold "Done."
            ;;
    *)
            _error "Incorrect default dns mode: $GM_DNS_MODE"
            eixt 1
  esac

  # The system dnsmasq service will use glider dns confs
  #    $DNSMASQ_CONF_DIR/*.glider
  # Run `service restart_dnsmasq` to take effect
  _dnsmasq_conf_add=/jffs/configs/dnsmasq.conf.add
  _conf_add="conf-dir=$GM_HOME_ETC_DNSMASQ/,*.glider"

  if [ -d "/jffs/configs" ]; then
    touch $_dnsmasq_conf_add
    unset _found
    while read -r _line
    do
      if [ "$_line" = "$_conf_add" ]; then
        _found=true
        break
      fi
    done < $_dnsmasq_conf_add
    if [ "$_found" != "true" ]; then
      echo $_conf_add >> $_dnsmasq_conf_add
    fi
  else
    _error "Can't update dnsmasq conf-dir without '/jffs/configs'."
    exit 1
  fi
}

clear_dns_conf(){
  # The system dnsmasq service will stop using glider dns confs
  # Run `service restart_dnsmasq` to take effect
  _dnsmasq_conf_add=/jffs/configs/dnsmasq.conf.add
  _conf_add="conf-dir=$GM_HOME_ETC_DNSMASQ/,*.glider"
 
  if [ -f "$_dnsmasq_conf_add" ]; then
    while read -r _line
    do
      if [ "$_line" != "$_conf_add" ]; then
        echo $_line
      fi
    done < $_dnsmasq_conf_add >> $_dnsmasq_conf_add.bak
    mv $_dnsmasq_conf_add.bak $_dnsmasq_conf_add
  else
    _warn "NO $_dnsmasq_conf_add file?!!"
  fi

  # Delete all the '.glider' conf files.
  _rm_files $GM_HOME_ETC_DNSMASQ "*.glider"
}