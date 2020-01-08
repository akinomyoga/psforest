#!/bin/gawk -f

function max(a, b) {
  return a >= b ? a : b;
}
function min(a, b) {
  return a <= b ? a : b;
}
function slice(str, start, end) {
  if (end == "")
    return substr(str, start + 1);
  else
    return substr(str, start + 1, end - start);
}
function trim(str) {
  gsub(/^[[:space:]]+|[[:space:]]*$/, "", str);
  return str;
}

BEGIN {
  mode = "pass";
  flagLineColor = ENVIRON["flagLineColor"];
  flagLineWrapping = ENVIRON["flagLineWrapping"];
  optionColorTheme = ENVIRON["optionColorTheme"];

  SCREEN_WIDTH = 80;
  if (ENVIRON["COLUMNS"] != "")
    SCREEN_WIDTH = max(80, or(0, ENVIRON["COLUMNS"])) - 1;

  iData = 0;

  fCHKDEFUNCT = 0;

  if (flagLineWrapping) {
    txt_indent = "                                                        ";
  }

  ti_smhead = "";
  ti_rmhead = "";
  ti_smodd = "";
  ti_rmodd = "";
  ti_smeve = "";
  ti_rmeve = "";
  txt_fill = "";

  if (flagLineColor) {
    ti_dim = "\33[2m"; if (ENVIRON["TERM"] == "rosaterm") ti_dim = "\33[9m";
    ti_sgr0 = "\33[m";

    if (optionColorTheme == "dark") {
      ti_defunct = ti_dim "\33[38;5;248m";
      ti_smhead = "\33[1;48;5;252;38;5;16m";
      ti_smodd = "\33[48;5;237;38;5;231m";
      ti_smeve = "\33[48;5;16;38;5;231m";
    } else {
      ti_defunct = ti_dim "\33[38;5;240m";
      ti_smhead = "\33[1;48;5;239;38;5;231m";
      ti_smodd = "\33[48;5;254;38;5;16m";
      ti_smeve = "\33[48;5;231;38;5;16m";
    }

    ti_rmhead = "\33[m";
    ti_rmodd = "\33[49;39m";
    ti_rmeve = "\33[49;39m";

    txt_fill_length = 4;
    txt_fill = "    ";
    while (txt_fill_length < SCREEN_WIDTH) {
      txt_fill = txt_fill txt_fill;
      txt_fill_length *= 2;
    }
    txt_fill = slice(txt_fill, 0, SCREEN_WIDTH);
  }
}

/^psforest: mode=/ {
  sub(/^psforest: mode=/, "");
  mode = $0;
  if (mode == "cygps") {
    initialize_cygps();
  } else if (mode == "macps") {
    initialize_macps();
  }
  next;
}

#-------------------------------------------------------------------------------
# read wmic outputs

mode == "wmic" && /^CommandLine=/ {
  gsub(/^CommandLine=("[^"]+"|[^"[:space:]]+|\r$)|\r$/, "", $0);
  args = $0;
  next;
}

mode == "wmic" && /^ParentProcessId=/ {
  gsub(/^ParentProcessId=|\r$/, "", $0);
  ppid = $0;
  next;
}

mode == "wmic" && /^ProcessId=/ {
  gsub(/^ProcessId=|\r$/, "", $0);
  winpid = $0;
  data_wmic[winpid,"p"] = ppid;
  data_wmic[winpid,"a"] = args;
  #print winpid, ppid, substr(args, 1, 40)
  next;
}

mode == "wmic" && /^[[:space:]]*$/ {
  next;
}

#-------------------------------------------------------------------------------
# read ls outputs

mode == "ls" && /^\/proc\/[0-9]+\/root\/$/ {
  fCHKDEFUNCT = 1;
  gsub(/^\/proc\/|\/root\/$/, "");
  proc_info[$0, "D"] = 1;
  next;
}

mode == "ls" && /^\/proc\/.+\/root\/$/ {
  next;
}

mode == "cmdline" {
  pid = $1;
  sub(/^[0-9]+/, "");
  proc_info[pid, "a"] = $0;
  next;
}

#-------------------------------------------------------------------------------
# columns functions

## @fn columns_initialize(head_line)
## @var[out] columns[index]
## @var[out] columns_label2index[label]
function columns_initialize(head_line, _tail, _i, _offset, _width, _label) {
  columns_count = 0;
  _offset = 0;
  _tail = head_line;
  while (match(_tail, /[^[:space:]]+/) > 0) {
    _i = columns_count++;
    _label = substr(_tail, RSTART, RLENGTH);
    _width = RSTART - 1 + RLENGTH;
    columns[_i,"label"]  = _label;
    columns[_i,"offset"] = _offset;
    columns[_i,"width"]  = _width;
    columns[_i,"wmax"]   = length(_label); # maximal width of values
    columns[_i,"novf"]   = 0;              # number of overflowing values
    columns[_i,"hidden"]   = columns_config[_label, "hidden"];
    columns[_i,"align"]  = columns_config[_label, "align"];

    _tail = substr(_tail, _width + 2);
    _offset += _width + 1;

    #    PREV     LABEL            NEXT
    # offset-><-width->
    #                  <-rmargin->

    # rmagin: maximal padding on overflow
    _rmargin = 0;
    if (match(_tail, /^[[:space:]]+/) > 0)
      _rmargin = RLENGTH;
    columns[_i, "rmargin"] = _rmargin;

    columns_label2index[_label] = _i;
    columns_data["HEAD", _i] = _label;
  }
}

function columns_register(line, _l, _i, _value, _width, _len, _lpad) {
  _l = columns_nline++;
  for (_i = 0; _i < columns_count - 1; _i++) {
    _width = columns[_i, "width"];
    _value = substr(line, 1, _width);
    line = substr(line, _width + 1);

    # read overflowing data
    if (match(line, /^[^[:space:]]+/) > 0) {
      _value = _value substr(line, 1, RLENGTH);
      line = substr(line, RLENGTH + 1);

      if (columns[_i, "align"] != "right") {
        _lpad = min(RLENGTH, columns[_i, "rmargin"]);
        #_lpad = RLENGTH;
        line = sprintf("%*s", _lpad, "") line;
      }
    }

    _value = trim(_value);
    _len = length(_value);
    if (_len > _width)
      columns[_i, "novf"]++;
    if (_len > columns[_i, "wmax"])
      columns[_i, "wmax"] = _len;

    columns_data[_l, _i] = _value;

    # skip space
    line = substr(line, 2);
  }

  # the last column has an unlimited length
  columns_data[_l, _i] = line;
  return _l;
}

function columns_construct(iline, _ret, _label, _fmt) {
  if (iline == "") iline = "HEAD";

  _ret = "";
  for (_i = 0; _i < columns_count - 1; _i++) {
    if (columns[_i, "hidden"]) continue;
    _fmt = columns[_i, "align"] == "left" ? "%-*s " : "%*s ";
    _ret = _ret sprintf(_fmt, columns[_i, "wmax"], columns_data[iline, _i]);
  }
  if (!columns[columns_count - 1, "hidden"])
    _ret = _ret columns_data[iline, columns_count - 1];

  return _ret;
}

#-------------------------------------------------------------------------------
# read ps outputs for cygwin

function initialize_cygps() {
  #----------------------------------------------------------------------
  #  sample
  #----------------------------------------------------------------------
  #      PID    PPID    PGID     WINPID  TTY  UID    STIME COMMAND
  #     5288       1    4924       4496    ? 1005   Jul 10 /usr/sbin/cygserver
  #     4080       1    4080       4080    ? 1005   Jul 10 /usr/sbin/httpd2
  #      880    4080    4080        880    ? 1005   Jul 10 /usr/sbin/httpd2
  #     4824    4080    4080       4824    ? 1005   Jul 10 /usr/sbin/httpd2
  #     5096    4080    4080       5096    ? 1005   Jul 10 /usr/sbin/httpd2
  #     4564    4080    4080       4564    ? 1005   Jul 10 /usr/sbin/httpd2
  #      572    4080    4080        572    ? 1005   Jul 10 /usr/sbin/httpd2
  #     5728    4080    4080       5728    ? 1005   Jul 10 /usr/sbin/httpd2
  #----------------------------------------------------------------------
  columns_config["COMMAND", "hidden"] = 1;
  columns_config["PPID", "hidden"] = 1;
  columns_config["TTY", "align"] = "left";
  columns_initialize("S     PID    PPID    PGID     WINPID  TTY  UID    STIME COMMAND"); # default
}

mode == "cygps" && /^[[:space:]]*PID/ {
  columns_initialize("S" substr($0, 2));
  next;
}

function columns_getColumnByLabel(iline, label, _index) {
  _index = columns_label2index[label];
  if (_index == "") return "";
  return columns_data[iline, _index];
}

function register_process(line, _pid, _ppid, _stat, _cmd, _iline) {
  _iline=columns_register(line);
  data_proc[iData, "i"] = columns_getColumnByLabel(_iline, "PID");
  data_proc[iData, "p"] = columns_getColumnByLabel(_iline, "PPID");
  data_proc[iData, "w"] = columns_getColumnByLabel(_iline, "WINPID");
  data_proc[iData, "c"] = columns_getColumnByLabel(_iline, "COMMAND");
  data_proc[iData, "N"] = 0;
  dict_proc[data_proc[iData, "i"]] = iData;
  iData++;
}

mode == "cygps" { register_process($0); next; }

#-------------------------------------------------------------------------------
# read ps outputs for mac

function initialize_macps() {
  #----------------------------------------------------------------------
  # sample: Mac OS X
  #----------------------------------------------------------------------
  # PPID USER       PID  %CPU %MEM      VSZ TTY      STAT STARTED      TIME ARGS
  #    1 root        33   0.0  0.0  2483636 ??       Ss    4:30AM   0:54.63 /usr/libexec/configd
  #    1 daemon      34   0.0  0.0  2467140 ??       Ss    4:30AM   0:01.39 /usr/sbin/distnoted
  #    1 _mdnsresponder    35   0.0  0.0  2477544 ??       Ss    4:30AM   0:03.95 /usr/sbin/mDNSResponder -launchd
  #    1 root        43   0.0  0.0  2464112 ??       Ss    4:30AM   0:00.38 /usr/sbin/securityd -i
  #    1 _clamav     52   0.0  0.0  2435956 ??       Ss    4:30AM   0:00.55 freshclam -d -c 4
  #----------------------------------------------------------------------
  # sample: FreeBSD
  #----------------------------------------------------------------------
  # PPID USER     PID %CPU  %MEM     VSZ TTY   STAT STARTED      TIME COMMAND
  #    0 root       0  0.0   0.0       0 -     DLs  23:48     0:58.48 [kernel]
  #    0 root       1  0.0   0.1    3476 -     ILs  23:48     0:00.02 /sbin/init --
  #    0 root       2  0.0   0.0       0 -     DL   23:48     0:00.00 [crypto]
  #    0 root       3  0.0   0.0       0 -     DL   23:48     0:00.00 [crypto returns 0]
  #----------------------------------------------------------------------
  #0         1         2         3         4         5         6         7
  #01234567890123456789012345678901234567890123456789012345678901234567890123456789
  #----------------------------------------------------------------------
  DEFAULT_HEAD_FREEBSD = "PPID USER    PID %CPU  %MEM     VSZ TTY   STAT STARTED      TIME COMMAND";
  DEFAULT_HEAD_MACOS   = "PPID USER       PID  %CPU %MEM      VSZ TTY      STAT STARTED      TIME ARGS";

  # detailed settings
  columns_config["PPID", "hidden"] = 1;
  columns_config["USER", "align"] = "left";
  columns_config["TTY", "align"] = "left";
  columns_config["STAT", "align"] = "left";
  columns_config["ARGS", "hidden"] = 1;
  columns_config["COMMAND", "hidden"] = 1;
  columns_initialize(DFAULT_HEAD_MACOS);
}

mode == "macps" && /^[[:space:]]*PPID/ {
  columns_initialize($0);
  next;
}

mode == "macps" && /^[[:space:]]*$/{ next; }

function register_process_mac(line, _iline, _ppid, _pid, _command) {
  _iline = columns_register(line);
  _ppid = columns_data[_iline, 0];
  _pid = columns_data[_iline, 2];
  _command = columns_getColumnByLabel(_iline, "COMMAND");
  if (_command == "")
    _command = columns_getColumnByLabel(_iline, "ARGS");

  data_proc[iData, "i"] = _pid;
  data_proc[iData, "p"] = _ppid;
  data_proc[iData, "c"] = _command;
  data_proc[iData, "N"] = 0;
  dict_proc[data_proc[iData, "i"]] = iData;
  iData++;
}

mode == "macps" { register_process_mac($0); next; }

#-------------------------------------------------------------------------------
# read ps outputs for aix

function initialize_aixps() {
  iColumnOfUser = 8;
}

mode == "aixps" && /^[[:space:]]*PPID/ {
  iColumnOfUser = index($0, "PPID") + 4;
  output_header(substr($0, iColumnOfUser + 1));
  next;
}

mode == "aixps" && /^[[:space:]]*$/ { next; }

function register_process_aix(line, _pid, _ppid, _stat, _cmd) {
  #----------------------------------------------------------------------
  #  sample: AIX
  #----------------------------------------------------------------------
  #   PPID     USER     PID  %CPU  %MEM   VSZ     TT S  STARTED        TIME COMMAND
  #2818312  kmurase 3145874   0.0   0.0   420  pts/4 A 04:08:31    00:00:00 /bin/bash /sr
  #      1  kmurase 3408008   0.0   0.0  2900      - A 23:50:31    00:00:00 SCREEN
  #2818312  kmurase 3735594   0.0   0.0   768  pts/4 A 04:39:15    00:00:00 ps -u kmurase
  #4063924  kmurase 5243088   0.0   0.0   568      - A 03:37:53    00:00:00 /usr/sbin/sft
  #3408008  kmurase 5439566   0.0   0.0   756  pts/3 A 23:50:31    00:00:00 /bin/bash
  #----------------------------------------------------------------------
  #0         1         2         3         4         5         6         7
  #01234567890123456789012345678901234567890123456789012345678901234567890123456789
  #----------------------------------------------------------------------
  data_proc[iData, "i"] = trim(slice(line, 17, 24)); # PID
  data_proc[iData, "p"] = trim(slice(line, 0, 7));   # PPID
  data_proc[iData, "s"] = slice(line, 9, 73);        # USER-STIME
  data_proc[iData, "c"] = slice(line, 73);           # COMMAND
  data_proc[iData, "N"] = 0;
  dict_proc[data_proc[iData,"i"]] = iData;
  iData++;
}

mode == "aixps" { register_process_aix($0); next; }

#-------------------------------------------------------------------------------

function construct_tree( _i, _ppid, _pid, _iP) {
  for (_i = 0; _i < iData; _i++) {
    _pid = data_proc[_i, "i"];
    _winpid = data_proc[_i, "w"];
    _ppid = data_proc[_i, "p"];

    # check if it is <defunct>
    if (fCHKDEFUNCT && _ppid != "0" && !proc_info[_pid, "D"])
      data_proc[_i, "<defunct>"] = 1;

    # resolve ppid
    if ((_ppid == "0" || _ppid == "1") && data_wmic[_winpid, "p"])
      _ppid = data_wmic[_winpid, "p"];
    if (_ppid == _pid) continue;

    _iP = dict_proc[_ppid];
    if (_iP == "") continue;

    data_proc[_iP, "L", data_proc[_iP, "N"]++] = _i;
    data_proc[_i, "HAS_PPID"] = 1;
  }
}

function output_header(line) {
  if (flagLineColor)
    print ti_smhead substr(line txt_fill, 1, SCREEN_WIDTH) ti_rmhead;
  else
    print line;
}

function proc_get_args(iProc, _ret, _winpid, _pid) {
  _winpid = data_proc[iProc, "w"];
  _ret = data_wmic[_winpid, "a"];
  if (_ret) return _ret;

  _pid = data_proc[iProc, "i"];
  return proc_info[_pid, "a"];
}

function output_process(iProc, head, head2, _stat, _cmd, _args, _i, _iN, _line, _txtbr, _ti1, _ti2) {
  _cmd = data_proc[iProc, "c"];
  if (_cmd ~ /[^\\]$/) gsub(/^.+\\/, "", _cmd);
  _args = proc_get_args(iProc);
  _stat = columns_count ? columns_construct(iProc) : data_proc[iProc, "s"];
  _line = _stat head _cmd _args;
  _iN = data_proc[iProc, "N"];

  _ti1 = "";_ti2 = "";
  if (flagLineColor) {
    if (outputProcessCount % 2 == 1) {
      _ti1 = _ti1 ti_smodd;
      _ti2 = ti_rmodd _ti2;
    } else {
      _ti1 = _ti1 ti_smeve;
      _ti2 = ti_rmeve _ti2;
    }
    if (data_proc[iProc, "<defunct>"]) {
      _ti1 = _ti1 ti_defunct;
      _ti2 = ti_sgr0 _ti2;
    }
  }

  if (flagLineWrapping) {
    print _ti1 substr(_line txt_fill, 1, SCREEN_WIDTH) _ti2;
    if(flagLineWrapping != "truncate" && length(_line) > SCREEN_WIDTH) {
      _txtbr = _iN == 0 ? "  " : " |  ";
      _txtbr = substr(txt_indent head2 _txtbr, 1, SCREEN_WIDTH - 40)
      do {
        _line = _txtbr substr(_line, SCREEN_WIDTH + 1);
        print _ti1 substr(_line txt_fill, 1, SCREEN_WIDTH) _ti2;
      } while (length(_line) > SCREEN_WIDTH);
    }
  } else {
    print _ti1 _line _ti2;
  }

  outputProcessCount++;

  for (_i = 0; _i < _iN; _i++)
    output_process(data_proc[iProc, "L", _i], head2 " \\_ ", head2 " " (_i + 1 == _iN ? "   " : "|  "));
}

mode == "pass" { print; }

END {
  construct_tree();

  if (columns_count) {
    head = columns_construct("HEAD");
    txt_indent = sprintf("%*s", length(head), "");
    output_header(head "COMMAND");
  }

  outputProcessCount = 0;
  for (i = 0; i < iData; i++) {
    p = data_proc[i, "p"];
    if (data_proc[i, "HAS_PPID"]) continue;
    output_process(i, "", "");
  }
}
