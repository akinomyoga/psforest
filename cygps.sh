#!/bin/bash

cd /tmp
{
  if [ "$1" != "${1/w/-}" ]; then
    echo | wmic process get CommandLine,ParentProcessId,ProcessId /format:list
    ps -We
  else
    ps -e
  fi
} | iconv -f cp932 -t utf-8 | gawk -f ~/.mwg/mwg.cygps.awk
