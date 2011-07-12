#!/bin/bash

{
  echo | wmic process get CommandLine,ParentProcessId,ProcessId /format:list
  ps -We
} | iconv -f cp932 -t utf-8 | gawk -f ps1.awk
