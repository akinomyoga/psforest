#!/bin/bash

cd /tmp
{
  if [ "$1" != "${1/w/-}" ]; then
    : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
    ps -We
  elif [ "$1" != "${1/e/-}" ]; then
    : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
    ps -e
  else
    ps -e
  fi
  ls -1d /proc/*/root/
} | gawk -f $HOME/.mwg/mcygex/bin/cygps.awk
