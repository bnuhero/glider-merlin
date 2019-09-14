#!/bin/sh

GM_SCRIPT_IPTABLES_INCLUDED=yes

if [ "$GM_SCIPT_HELPER_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/helper.sh
fi

apply_iptables() {
  # avoid to add the same rules multiple times.
  clear_iptables

  # only support TCP
  iptables -t nat -N GLIDER_TCP
  iptables -t nat -N GLIDER_OUTPUT
  iptables -t nat -N GLIDER_PREROUTING

  iptables -t nat -A OUTPUT -j GLIDER_OUTPUT
  iptables -t nat -A PREROUTING -j GLIDER_PREROUTING

  if [ "$GM_IP_MODE" = "proxy" ]; then
    # 1) All the ipsets whose name start with 'gmw-*' -> Internet
    for _ipset_name in $(ipset list -n)
    do
      echo $_ipset_name | grep -q "^gmw-.*$"
      if [ $? -eq 0 ]; then
        iptables -t nat -A GLIDER_TCP -m set --match-set $_ipset_name dst -j RETURN
      fi
    done

    # 2) All the rest ips -> glider transparent proxy
    iptables -t nat -A GLIDER_TCP -p tcp -j REDIRECT --to-ports $GLIDER_REDIRECT_PORT

  else # "direct"
    # 1) All the ipsets whose name start with 'gmb-*' -> Glider transparent proxy
    for _ipset_name in $(ipset list -n)
    do
      echo $_ipset_name | grep -q "^gmb-.*$"
      if [ $? -eq 0 ]; then
        iptables -t nat -A GLIDER_TCP -m set --match-set $_ipset_name dst -j REDIRECT --to-ports $GLIDER_REDIRECT_PORT
      fi
    done

    # 2) All the rest ips -> Internet
    #   Nothing to do
  fi

  # Apply iptables rules
  iptables -t nat -A GLIDER_OUTPUT -p tcp -j GLIDER_TCP
  # TODO: check if the lan ip range is 192.168.0.0/16
  iptables -t nat -A GLIDER_PREROUTING -p tcp -s 192.168.0.0/16 -j GLIDER_TCP 
}

clear_iptables() {
  iptables -t nat -D OUTPUT -j GLIDER_OUTPUT 2>/dev/null
  iptables -t nat -D PREROUTING -j GLIDER_PREROUTING 2>/dev/null

  iptables -t nat -F GLIDER_OUTPUT 2>/dev/null
  iptables -t nat -X GLIDER_OUTPUT 2>/dev/null

  iptables -t nat -F GLIDER_PREROUTING 2>/dev/null
  iptables -t nat -X GLIDER_PREROUTING 2>/dev/null
  
  iptables -t nat -F GLIDER_TCP 2>/dev/null
  iptables -t nat -X GLIDER_TCP 2>/dev/null
}