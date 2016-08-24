#!/bin/bash

# default options
export flagLineColor=auto
export flagLineWrapping=1
fields=

#------------------------------------------------------------------------------
# read command line arguments

fHelp=
while (($#)); do
  arg="$1"; shift
  case "$arg" in
  (--color|--color=always|--color=color)
    flagLineColor=256 ;;
  (--color=none|--color=never)
    flagLineColor= ;;
  (--color=*)
    flagLineColor=${arg#*=} ;;
  (--?*) echo "psforest: unrecognized option $arg" >&2 ;;
  (-?*)
    arg=${arg:1}
    while [[ $arg ]]; do
      o=${arg::1}
      case "$o" in
      (*) echo "psforest: unrecognized option -$o" >&2 ;;
      esac
      arg=${arg:1}
    done ;;
  (*) fields="${fields}$arg" ;;
  esac
  break
done

if [[ $flagLineColor == auto ]]; then
  if [[ -t 1 ]]; then
    flagLineColor=256
  else
    flagLineColor=
  fi
fi

#------------------------------------------------------------------------------

{
  if [[ $OSTYPE == cygwin* || $OSTYPE == mingw* || $OSTYPE == msys* ]]; then
    cd /tmp
    if [[ $fields == *w* ]]; then
      echo "psforest: mode=wmic"
      : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
      echo "psforest: mode=cygps"
      ps -We
    elif [[ $fields == *e* ]]; then
      echo "psforest: mode=wmic"
      : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
      echo "psforest: mode=cygps"
      ps -e
    else
      echo "psforest: mode=cygps"
      ps -e
    fi

    # echo "psforest: mode=ls"
    # ls -1d /proc/*/root/
  elif [[ $OSTYPE == darwin* || $OSTYPE == freebsd* || $OSTYPE == bsd* ]]; then
    echo "psforest: mode=macps"
    ps -A -o ppid,user,pid,pcpu,pmem,vsize,tty,stat,start,time,args
  elif [[ $OSTYPE == aix* ]]; then
    echo "psforest: mode=aixps"
    ps -A -o ppid,user,pid,pcpu,pmem,vsize,tty,stat,start,time,args
  else
    ps uaxf
  fi
} | gawk -f %share%/psforest.awk
