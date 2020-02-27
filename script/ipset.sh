#!/bin/sh

GM_SCRIPT_IPSET_INCLUDED=yes

if [ "$GM_SCIPT_HELPER_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/helper.sh
fi

PRIVATE_IP_LIST="0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16 172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.31.196.0/24 192.52.193.0/24 192.88.99.0/24 192.168.0.0/16 192.175.48.0/24 198.18.0.0/15 198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4 255.255.255.255"

_check_ipset(){
  modprobe ip_set
  modprobe ip_set_hash_net
  modprobe ip_set_hash_ip
  modprobe xt_set
}

_create_ipset_by_blacklist(){
  # create a ipset for every domain blacklist
  #   name: start with 'gmb-'
  #   type: hash:ip
  for _ipset_name in $(ipset list -n)
  do
    echo $_ipset_name | grep -q "^gmb-.*$"
    if [ $? -eq 0 ]; then
      ipset -! create $_ipset_name hash:ip
      _bold "IPSET $_ipset_name hash:ip created."
    fi
  done

  # create a ipset for every ip blacklist
  #   name: start with 'gmb-'
  #   type: hash:net # to support CIDR address
  for _list_file in $(_ls_files $GM_HOME_DATA "*$GM_IP_BLACKLIST_EXT")
  do
    _list_file_name=$(basename $_list_file $GM_IP_BLACKLIST_EXT)
    if [ -z "$_list_file_name" ]; then
      continue
    fi

    ipset -! create "gmb-$_list_file_name" hash:net
    _bold "IPSET gmb-$_list_file_name hash:net created."
   
    _info "Adding ip addrs ..."
    while read -r _ipaddr
    do
      if [ -n "$_ipaddr" ]; then
        # TODO: check if total numer of elements in the ipset is larger 65536.
        #       If YES, SHOULD NOT add new element anymore
        ipset -! add "gmb-$_list_file_name" $_ipaddr
      fi
    done < $_list_file
    _info "Done."
  done
}
_create_ipset_by_whitelist(){
  # create a ipset for every domain whitelist
  #   name: start with 'gmw-'
  #   type: hash:ip
  for _ipset_name in $(ipset list -n)
  do
    echo $_ipset_name | grep -q "^gmw-.*$"
    if [ $? -eq 0 ]; then
      ipset -! create $_ipset_name hash:ip
      _bold "IPSET $_ipset_name hash:ip created."
    fi
  done

  # Create a ipset for every IP whitelist
  #   name: start with 'gmw-'
  #   type: hash:net # to support CIDR addresses
  for _list_file in $(_ls_files $GM_HOME_DATA "*$GM_IP_WHITELIST_EXT")
  do
    _list_file_name=$(basename $_list_file $GM_IP_WHITELIST_EXT)
    if [ -z "$_list_file_name" ]; then
      continue
    fi

    ipset -! create "gmw-$_list_file_name" hash:net
    _bold "IPSET gmw-$_list_file_name hash:net created."

    _info "Adding ip addres ..."
    while read -r _ipaddr
    do
      if [ -n "$_ipaddr" ]; then
        # TODO: check if total numer of elements in the ipset is larger 65536.
        #       If YES, SHOULD NOT add new element anymore
        ipset -! add "gmw-$_list_file_name" $_ipaddr
      fi
    done < $_list_file
    _info "Done."
  done

  # Create a ipset for private IP addresses
  if [ "$PRIVATE_IP_LIST" != "" ]; then
    ipset -! create "gmw-private" hash:net
    _bold "IPSET gmw-private hash:net created."

    _info "Adding ip addres ..."
    for _ip in $PRIVATE_IP_LIST
    do
      ipset -! add gmw-private $_ip
    done
    _info "Done."
  fi

  # Create a ipset for all the glider forward hosts.
  ipset -! create "gmw-glider" hash:net
  _bold "IPSET gmw-glider hash:ip created."
  _info "Adding ip addrs ..."
  for _host in $GLIDER_FORWARD_HOST_LIST
  do
    _ip=$(_host2ip $_host)
    if [ $(_ipv4 $_ip) = "yes" ]; then
      ipset -! add gmw-glider $_ip
    fi
  done
  _info "Done."
}

create_ipset(){
  _check_ipset

  case $GM_IP_MODE in
    direct) # Blacklist ipset -> Glider transparent proxy -> Internet
            # All the rest IPs -> Internet
            _create_ipset_by_blacklist
            ;;
    proxy)  # Whitelist ipset -> Internet
            # All the rest IPs -> glider transparent proxy -> Internet
            _create_ipset_by_whitelist
            ;;
    *)
            _error "Not supported routing mode: $GM_IP_MODE"
            exit 1
            ;;
  esac
}

destroy_ipset(){
  for _ipset_name in $(ipset list -n)
  do
    echo $_ipset_name | grep -q "^gmb-.*$\|^gmw-.*$"
    if [ $? -eq 0 ]; then
      ipset -! destroy $_ipset_name
    fi
  done
}
