#!/bin/sh

GM_SCIPT_LIST_INCLUDED=yes

# Import helper functions
# ----------------
if [ "$GM_SCIPT_HELPER_INCLUDED" != "yes" ]; then
  source $GM_HOME_SCRIPT/helper.sh
fi

# Format conversion: dnsmasq conf -> domain list
# Usage: _conf2list ARGV1
#   ARGV1 - the dnsmasq conf file
_conf2list(){
  _regex_server="^server=\/\(.*\)\/.*$"
  _regex_ipset="^ipset=\/\(.*\)\/.*$"

  while read -r _line
  do
    # keep the domain only
    _line=$(echo $_line | sed -e "s/$_regex_server/\1/")
    # delete the 'ipset=' line
    _line=$(echo $_line | sed -e "s/$_regex_ipset//")

    if [ -n "$_line" ]; then
      echo $_line
    fi
  done < $1 >> $1.bak
  
  mv $1.bak $1
}

# Post processing after the remote file has been downloaded
# Usage: _post_processing ARGV1 ARGV2
#   ARGV1 - File format
#   ARGV2 - The source file
_post_processing(){
  case $1 in
    conf)
          # convert the dnsmasq conf file to the domain list
          _info "Converting the dnsmasq conf file $2 ..."
          _conf2list $2
          _info "Done."
          ;;
    txt)
          # Normal list file.
	        # Nothing to do.
          ;;
    *)
          _warn "Unknown list file extension: $1"
          ;;
  esac
}

# Usage: _download_list ARGV1 ARGV2 ARGV3 [ARGV4]
#   ATGV1 - url of the ip|domain list file
#   ARGV2 - Save the file to this directory
#   ARGV3 - Change the saved file name extension to this
#   ARGV4 - (Optional) If set to 'forced', all the system list will be download again.
#             If not, these files will be downloaded only if not existed.
_download_list(){
  if [ $# -ge 3 ]; then
    _file=$2/$(_get_filename_noext $1)$3
    _ext=$(_get_filename_ext $1)
    if [ ! -f "$_file" ] || [ "$4" = "forced" ]; then
      _info "Downloading $1 ..."
      curl $1 -o $_file
      _post_processing $_ext $_file
      _info "Saved as $_file"
    else
      _info "List file existed: '$_file'"
      _info "If you want to download the latest release, use 'forced' as the last argument of '_download_list'"
    fi
  else
    _warn "_download_list: At least three arguments required!"
  fi
}

# # well known domain|ip list
# GM_SYSTEM_DNS_BLACKLIST="https://cokebar.github.io/gfwlist2dnsmasq/gfwlist_domain.txt"
# GM_SYSTEM_DNS_WHITELIST="https://raw.githubusercontent.com/felixonmars/dnsmasq-china-list/master/accelerated-domains.china.conf"
# GM_SYSTEM_IP_WHITELIST="https://raw.githubusercontent.com/17mon/china_ip_list/master/china_ip_list.txt"

# check if this is a system list.
_is_sys_list(){
  _result=no

  _list_filename_noext=$(_get_filename_noext $1)
  _list_filename_ext=$(_get_filename_ext $1)

  case ".$_list_filename_ext" in
    $GM_DNS_BLACKLIST_EXT)
                        for _url in $GM_SYSTEM_DNS_BLACKLIST
                        do
                          _url_filename_noext=$(_get_filename_noext $_url)
                          if [ "$_list_filename_noext" = "$_url_filename_noext" ]; then
                            _result=yes
                            break
                          fi
                        done
                        ;;
    $GM_DNS_WHITELIST_EXT)
                        for _url in $GM_SYSTEM_DNS_WHITELIST
                        do
                          _url_filename_noext=$(_get_filename_noext $_url)
                          if [ "$_list_filename_noext" = "$_url_filename_noext" ]; then
                            _result=yes
                            break
                          fi
                        done
                        ;;
    $GM_IP_WHITELIST_EXT)
                        for _url in $GM_SYSTEM_IP_WHITELIST
                        do
                          _url_filename_noext=$(_get_filename_noext $_url)
                          if [ "$_list_filename_noext" = "$_url_filename_noext" ]; then
                            _result=yes
                            break
                          fi
                        done
                        ;;
    $GM_IP_BLACKLIST_EXT)
                        ;;
    *)
                        ;;
  esac
  echo $_result
}

# Download all the system IP/Domain list.
#   If ARGV1 set to 'forced', download all the latest files.
#   If NOT, download the lists only if not existed.
curl_system_list(){
  for _url in $GM_SYSTEM_DNS_BLACKLIST
  do
    _download_list $_url $GM_HOME/data $GM_DNS_BLACKLIST_EXT $1
  done
                      
  for _url in $GM_SYSTEM_DNS_WHITELIST
  do
    _download_list $_url $GM_HOME/data $GM_DNS_WHITELIST_EXT $1
  done
 
  for _url in $GM_SYSTEM_IP_WHITELIST
  do
    _download_list $_url $GM_HOME/data $GM_IP_WHITELIST_EXT $1
  done
}
