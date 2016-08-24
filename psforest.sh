#!/bin/bash

cd /tmp
{
  if [ "$1" != "${1/w/-}" ]; then
    echo "psforest: mode=wmic"
    : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
    echo "psforest: mode=cyg.ps"
    ps -We
  elif [ "$1" != "${1/e/-}" ]; then
    echo "psforest: mode=wmic"
    : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
    echo "psforest: mode=cyg.ps"
    ps -e
  else
    echo "psforest: mode=cyg.ps"
    ps -e
  fi

  # echo "psforest: mode=ls"
  # ls -1d /proc/*/root/
} | gawk -f %share%/psforest.awk
