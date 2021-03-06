#!/usr/bin/env bash

# default options
export flagLineColor=auto
export flagLineWrapping=truncate
export optionColorTheme=light
fields=

#------------------------------------------------------------------------------
# read command line arguments

fHelp=
fError=
while (($#)); do
  arg="$1"; shift
  case "$arg" in
  (--color|--color=always|--color=color)
    flagLineColor=256 ;;
  (--color=none|--color=never)
    flagLineColor= ;;
  (--color=*)
    flagLineColor=${arg#*=} ;;
  (--theme=*)
    optionColorTheme=${arg#*=} ;;
  (--wrap|--wrap=always)
    flagLineWrapping=1 ;;
  (--wrap=none|--wrap=never)
    flagLineWrapping= ;;
  (--wrap=*)
    flagLineWrapping=${arg#*=} ;;
  (--help)
    fHelp=1 ;;
  (--?*) fError=1; echo "psforest: unrecognized option $arg" >&2 ;;
  (-?*)
    arg=${arg:1}
    while [[ $arg ]]; do
      o=${arg::1}
      case "$o" in
      (w) flagLineWrapping=1 ;;
      (W) fields="${fields}w" ;;
      (*) fError=1; echo "psforest: unrecognized option -$o" >&2 ;;
      esac
      arg=${arg:1}
    done ;;
  (*) fields="${fields}$arg" ;;
  esac
done

if [[ $flagLineColor == auto ]]; then
  if [[ -t 1 ]]; then
    flagLineColor=256
  else
    flagLineColor=
  fi
fi

if [[ $flagLineWrapping == auto ]]; then
  if [[ -t 1 ]]; then
    flagLineWrapping=1
  else
    flagLineWrapping=
  fi
fi

if [[ $fError ]]; then
  exit 1
fi

if [[ $fHelp ]]; then
  cat <<EOF
psforest [OPTIONS]

OPTIONS

  --color
  --color=WHEN

    Control if the line coloring is enabled or not.

    WHEN is one of the following values.
      auto    automatically determine if the feature is enabled.
              if stdout is connected to a pseudo terminal, the feature is
              turned on.
      always  always enable the feature
      never   never enable the feature
      none    sinonym of 'never'

    If the value is omitted, 'always' is used.
    The default value is 'auto'.

  --theme=THEME

    Specify color theme. THEME is one of the following values.
      light   theme for terminals with a light background
      dark    theme for terminals with a dark background

    The default value is 'light'.

  -w, --wrap
  --wrap=WHEN
  --wrap=truncate

    Control the wrapping of lines which do not fit into terminal width.

    WHEN is one of the values described in the option '--color'.
    If the value 'truncate' is specified long command lines are truncated.

    If the value is omitted, 'always' is used.
    The default value is 'truncate'.

  --help

    Show this help

  -W
  w
    In cygwin, show non-Cygwin processes as well as cygwin processes

EOF
  exit
fi

#------------------------------------------------------------------------------

{
  if [[ $OSTYPE == cygwin* || $OSTYPE == mingw* || $OSTYPE == msys* ]]; then
    cd /tmp

    echo "psforest: mode=cmdline"
    awk '
        FILENAME ~ /^\/proc\/[0-9]+\/cmdline$/{
          gsub(/^\/proc\/|\/cmdline$/,"",FILENAME);
          sub(/^[^\x0]*(\x0|$)/,"");
          gsub(/[[:cntrl:]]/," ");
          if($0!="") print FILENAME,$0;
        }
      '  /proc/*/cmdline

    if [[ $fields == *w* ]]; then
      echo "psforest: mode=wmic"
      : | wmic process get CommandLine,ParentProcessId,ProcessId /format:list | iconv -f cp932 -t utf-8
      echo "psforest: mode=cygps"
      ps -We
    else
      echo "psforest: mode=cygps"
      ps -e
    fi

    # echo "psforest: mode=ls"
    # ls -1d /proc/[0-9]*/root/
  elif [[ $OSTYPE == darwin* || $OSTYPE == freebsd* || $OSTYPE == bsd* ]]; then
    echo "psforest: mode=macps"
    ps -A -o ppid,user,pid,pcpu,pmem,vsize,tty,stat,start,time,args
  elif [[ $OSTYPE == aix* ]]; then
    echo "psforest: mode=aixps"
    ps -A -o ppid,user,pid,pcpu,pmem,vsize,tty,stat,start,time,args
  elif [[ $OSTYPE == minix* ]]; then
    echo "psforest: mode=minix"
    ps el
  else
    echo "psforest: mode=procps"
    ps uaxf
  fi
} | gawk -f ./psforest.awk
