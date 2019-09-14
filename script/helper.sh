#!/bin/sh

GM_SCIPT_HELPER_INCLUDED=yes

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
_info() { # WHITE
  echo -e "$ansi_std $1 $ansi_std"
}

# Change text case to upper case.
_uppercase(){
  echo $(echo $1 | tr [a-z] [A-Z])
}

# Change text case to upper case.
_lowercase(){
  echo $(echo $1 | tr [A-Z] [a-z])
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

# Get the directory where the script file located.
_pwd(){
  echo $( cd -P "$( dirname "$0" )" >/dev/null 2>&1 && pwd )
}

# Get the directory where the script file located.
# If the directory is a symlink, it is resolved to the real path.
_pwd_real(){
  SOURCE="$0"
  # resolve $SOURCE until the file is no longer a symlink
  while [ -h "$SOURCE" ]; do 
    DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    # if $SOURCE was a relative symlink,
    # we need to resolve it relative to the path where the symlink file was located
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
  done
  echo "$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
}

# Join all the arguments with the delimiter `\|`
_ror(){
  unset _result
  for part in "$@"
  do
    if [ -z "$_result" ]; then
      _result=$part
    else
      _result="$_result\|$part"
    fi
  done
  echo $_result
}

# Join all the arguments.
_rjoin(){
  unset _result
  for part in "$@"
  do
    if [ -z "$_result" ]; then
      _result=$part
    else
      _result="$_result$part"
    fi
  done
  echo $_result
}

# Join all the arguments and surround the rersult between `\(` and `\)`
_rgroup(){
  unset _result
  _result=$(_rjoin $@)
  _result="\($_result\)"
  echo $_result
}

set -f # make sure '*' will NOT replaced by the shell.
RSCHEME="$(_rgroup ".*")"
RSCHEME="$(_rgroup $RSCHEME ":" "\/" "\/")\?"
RUSERPASSWD="$(_rgroup $(_rgroup ".*") ":" $(_rgroup ".*") "@")\?"
RHOSTPORT="$(_rgroup "[a-zA-Z0-9\.]\+")\?:$(_rgroup "[0-9]\+")"
REXTRA="$(_rgroup ".*$")"
RURL=$RSCHEME$RUSERPASSWD$RHOSTPORT$REXTRA
set +f

# Usage: _parse_url_part ARGV1 ARGV2
#   ARGV1 - the url
#   ARGV2 - name of the url part. MUST be one of the following values:
#             scheme, user|method, passwd, host, port
_parse_url_part(){
  unset _pos
  case $2 in
    scheme)
        _pos="\2"
        ;;
    user|method)
        _pos="\4"
        ;;
    passwd)
        _pos="\5"
        ;;
    host)
        _pos="\6"
        ;;
    port)
        _pos="\7"
        ;;
    extra)
        _pos="\8"
        ;;
    *)
        ;;
  esac
  if [ -n "_pos" ]; then
    echo $(echo $1 | sed -e "s/$RURL/$_pos/g")
  else
    echo
  fi
}

# check if ARGV1 is a valid IPv4 address
_ipv4(){
  _regex="\([0-9]\{1,3\}\.\)\{3,3\}[0-9]\{1,3\}"

  echo "$1" | grep -q  ^$_regex$
  if [ $? -eq 0 ]; then
    echo "yes"
  else
    echo
  fi
}

# Usage: _host2ip ARGV1
#   ARGV1 - the hostname
_host2ip(){
  # ping one time and set timeout to 2s
  _result=$(ping -c 1 -W 2 $1 | sed -ne "/^PING\s/{s/.*(\(.*\)):.*/\1/;p;}")
  echo $_result

  # if [ "$_result" = "" ]; then # $1 is invalid, or a domain name or IP address that can't connect
  # elif [ "$_result" = "$1" ]; then # $1 is an IP address
  # else # $1 is a domain name
  # fi
}

# delete all the files matching the ARGV2 pattern in the ARGV1 directory. 
_rm_files() {
  find "$1" -maxdepth 1 -type f -name "$2" -delete
}

# list all the files matching the ARGV2 pattern in the ARGV1 directory. 
_ls_files(){
  find "$1" -maxdepth 1 -type f -name "$2"
}

# return the file basename without the extension part.
_get_filename_noext(){
  _file_basename=$(basename $1)
  echo "${_file_basename%.*}"
}

# get the file name extension
_get_filename_ext(){
  _file_basename=$(basename $1)
  echo "${_file_basename##*.}"
}