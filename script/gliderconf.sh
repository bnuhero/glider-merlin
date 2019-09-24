#!/bin/sh

GM_SCIPT_GLIDERCONF_INCLUDED=yes

# Import helper functions
# ----------------
if [ "$GM_SCIPT_HELPER_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/helper.sh
fi

_parse_glider_listen(){
  _parse_glider_listen_IFS=$IFS; IFS=","

  for _url in $1
  do
    _scheme=`_parse_url_part $_url scheme`
    _host=`_parse_url_part $_url host`
    _port=`_parse_url_part $_url port`

    if [ "$_scheme" = "redir" ]; then
      GLIDER_REDIRECT_HOST=$_host
      if [ -z "$GLIDER_REDIRECT_HOST" ]; then
        GLIDER_REDIRECT_HOST="127.0.0.1"
      fi

      GLIDER_REDIRECT_PORT=$_port
      #_info "REDIR proxy found: $GLIDER_REDIRECT_HOST:$GLIDER_REDIRECT_PORT"
    else
      _info "Listener found: $_scheme://$_host:$_port"
    fi
  done

  IFS=$_parse_glider_listen_IFS
}

_parse_glider_forward(){
  _parse_glider_forward_IFS=$IFS; IFS=","
  unset _host_list
  for url in $1
  do
    _host=`_parse_url_part $url host`
    _host_list=$(_join "$_host_list" "," "$_host")
  done
  IFS=$_parse_glider_forward_IFS
  echo $_host_list
}

_parse_glider_dns(){
  GLIDER_DNS_HOST=$(_parse_url_part $1 host)
  if [ "$GLIDER_DNS_HOST" = "" ]; then
    GLIDER_DNS_HOST="127.0.0.1"
  fi

  GLIDER_DNS_PORT=$(_parse_url_part $1 port)
  if [ "$GLIDER_DNS_PORT" = "" ]; then
    GLIDER_DNS_PORT="53"
  fi
}

_is_port_used(){
  netstat -pltun | grep ":$1\s" >/dev/null
  if [ $? -eq 0 ]; then
    echo yes
  else
    echo no
  fi
}

_validate_glider_conf(){
  if [ "$GLIDER_REDIRECT_HOST" = "" ] || [ "$GLIDER_REDIRECT_PORT" = "" ]; then
    _error "NO transparent proxy defined in '$1'"
    _info "Abort"
    exit 1
  else
    _info "Transparent proxy: $GLIDER_REDIRECT_HOST:$GLIDER_REDIRECT_PORT"
  fi

  if [ "$GLIDER_DNS_HOST" = "" ] || [ "$GLIDER_DNS_PORT" = "" ]; then
    _error "NO dns server ('dns') defined in '$1'"
    _info "Abort"
    exit 1
  else
    _info "DNS Server: $GLIDER_DNS_HOST:$GLIDER_DNS_PORT"
  fi

  if [ "$GLIDER_DNSSERVER_LIST" = "" ]; then
    _error "NO trusted dns forwarder ('dnssserver') defined in '$1'"
    _info "Abort"
    exit 1
  else
    _info "Available trusted dns servers: $GLIDER_DNSSERVER_LIST"
  fi
}

parse_glider_conf(){
  if [ ! -f "$1" ]; then
    _error "No required Glider configuration file: '$1'"
    _info "Just copy 'glider.sample.conf' to 'glider.conf' and modify the 'forward' setting."
    _info "That's all."
    _info "See https://github.com/nadoo/glider/tree/master/config for complete reference."
    exit 1
  fi

  parese_glider_conf_IFS=$IFS; IFS="="

  while read -r name value
  do
    if [ "$value" = "" ]; then
      continue
    fi

    case $name in
      listen)
                  # Find the transparent proxy（redirect://)
                  # GLIDER_REDIRECT_HOST - host 
                  # GLIDER_REDIRECT_PORT - port
                  _parse_glider_listen $value
                  ;;
      forward)
                  # All the forwader proxy host
                  GLIDER_FORWARD_HOST_LIST=$(_join "$GLIDER_FORWARD_HOST_LIST" " " "$(_parse_glider_forward $value)")
                  ;;
      dns)
                  # Glider DNS Server
                  # GLIDER_DNS_HOST - host
                  # GLIDER_DNS_PORT - port
                  _parse_glider_dns $value
                  ;;
      dnsserver)
                  # All the trusted dns servers
                  GLIDER_DNSSERVER_LIST=$(_join "$GLIDER_DNSSERVER_LIST" " " "$(_parse_url_part $value host)")
                  ;;
      *)
                  ;;
    esac
  done < $1

  IFS=$parese_glider_conf_IFS

  #
  _validate_glider_conf $1
}