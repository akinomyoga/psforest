#!/bin/bash

{
  if [[ $OSTYPE == cygwin* || $OSTYPE == mingw* || $OSTYPE == msys* ]]; then
    cd /tmp
    if [ "$1" != "${1/w/-}" ]; then
      echo "psforest: mode=wmic"
      : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
      echo "psforest: mode=cygps"
      ps -We
    elif [ "$1" != "${1/e/-}" ]; then
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
  fi
} | gawk -f %share%/psforest.awk
