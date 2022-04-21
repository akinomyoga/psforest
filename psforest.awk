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

#------------------------------------------------------------------------------
# wcwidth

BEGIN {
  ORD_UNICODE_MAX = 0x110000;
}

function ord_initialize(_, i) {
  for (i = 0; i < 128; i++)
    ord_cache[sprintf("%c", i)] = i;
}

function ord(c, _, l, u, m) {
  if ((l = ord_cache[c]) != "") return l;
  l = 128;
  u = ORD_UNICODE_MAX;
  if (!(sprintf("%c", l) <= c && c <=  sprintf("%c", u - 1))) return 0xFFFD;
  while (l + 1 < u) {
    if (c < sprintf("%c", m = int((l + u) / 2))) {
      u = m;
    } else {
      l = m;
    }
  }
  ord_cache[c] = l;
  return l;
}

function c2w_initialize(_, list) {
  if (USE_C2W) return;
  USE_C2W = 1;

  ord_initialize();

  # 半角スペース
  c2w_non_zenkaku[0x303F] = 1;

  # 絵文字
  c2w_non_zenkaku[0x3030] = -2;
  c2w_non_zenkaku[0x303d] = -2;
  c2w_non_zenkaku[0x3297] = -2;
  c2w_non_zenkaku[0x3299] = -2;

  # Table c2w_east_wranges
  list = " 161 162 164 165 167 169 170 171 174 175 176 181 182 187 188 192 198 199 208 209";
  list = list " 215 217 222 226 230 231 232 235 236 238 240 241 242 244 247 251 252 253 254 255";
  list = list " 257 258 273 274 275 276 283 284 294 296 299 300 305 308 312 313 319 323 324 325";
  list = list " 328 332 333 334 338 340 358 360 363 364 462 463 464 465 466 467 468 469 470 471";
  list = list " 472 473 474 475 476 477 593 594 609 610 708 709 711 712 713 716 717 718 720 721";
  list = list " 728 732 733 734 735 736 913 930 931 938 945 962 963 970 1025 1026 1040 1104 1105 1106";
  list = list " 8208 8209 8211 8215 8216 8218 8220 8222 8224 8227 8228 8232 8240 8241 8242 8244 8245 8246 8251 8252";
  list = list " 8254 8255 8308 8309 8319 8320 8321 8325 8364 8365 8451 8452 8453 8454 8457 8458 8467 8468 8470 8471";
  list = list " 8481 8483 8486 8487 8491 8492 8531 8533 8539 8543 8544 8556 8560 8570 8592 8602 8632 8634 8658 8659";
  list = list " 8660 8661 8679 8680 8704 8705 8706 8708 8711 8713 8715 8716 8719 8720 8721 8722 8725 8726 8730 8731";
  list = list " 8733 8737 8739 8740 8741 8742 8743 8749 8750 8751 8756 8760 8764 8766 8776 8777 8780 8781 8786 8787";
  list = list " 8800 8802 8804 8808 8810 8812 8814 8816 8834 8836 8838 8840 8853 8854 8857 8858 8869 8870 8895 8896";
  list = list " 8978 8979 9312 9450 9451 9548 9552 9588 9600 9616 9618 9622 9632 9634 9635 9642 9650 9652 9654 9656";
  list = list " 9660 9662 9664 9666 9670 9673 9675 9676 9678 9682 9698 9702 9711 9712 9733 9735 9737 9738 9742 9744";
  list = list " 9748 9750 9756 9757 9758 9759 9792 9793 9794 9795 9824 9826 9827 9830 9831 9835 9836 9838 9839 9840";
  list = list " 10045 10046 10102 10112 57344 63744 65533 65534 983040 1048574 1048576 1114110";
  c2w_east_wranges_count = split(list, c2w_east_wranges);
}

function c2w_unambiguous(code) {
  if (code < 0xA0) return 1;
  if (code < 0xFB00) {
    if (0x2E80 <= code && code < 0xA4D0 && !c2w_non_zenkaku[code]) return 2;
    if (0xAC00<=code&&code<0xD7A4) return 2;
    if (0xF900<=code) return 2;
    if (0x1100<=code&&code<0x1160) return 2;
    if (code==0x2329||code==0x232A) return 2;
  } else if (code<0x10000) {
    if (0xFF00<=code&&code<0xFF61) return 2;
    if (0xFE30<=code&&code<0xFE70) return 2;
    if (0xFFE0<=code&&code<0xFFE7) return 2;
  } else {
    if (0x20000<=code&&code<0x2FFFE) return 2;
    if (0x30000<=code&&code<0x3FFFE) return 2;
  }
  return -1;
}

function c2w_east(code, _, w, l, u, m) {
  w = c2w_unambiguous(code);
  if (w >= 0) return w;

  # if (c2w_emoji_enabled && c2w_is_emoji(code))
  #   return c2w_emoji_width;

  l = 1;
  u = c2w_east_wranges_count + 1;
  if (code < c2w_east_wranges[l]) return 1;
  if (code >= c2w_east_wranges[u - 1]) return 1;
  while (l + 1 < u) {
    if (c2w_east_wranges[m = (l + u) / 2] <= code)
      l = m;
    else
      u = m;
  }
  return l % 2 == 0 ? 2 : 1;
}

function c2w_west(code, _, w) {
  w = c2w_unambiguous(code);
  if (w >= 0) return w;

  # if (c2w_emoji_enabled && c2w_is_emoji(code))
  #   return c2w_emoji_width;

  return 1;
}

function s2w(s) {
  return c2w_east(ord(s));
}

function str2w(str) {
  ret = 0;
  while (match(str, /^[ -~]+|^./)) {
    ret += RLENGTH > 1 ? RLENGTH : s2w(substr(str, 1, 1));
    str = substr(str, 1 + RLENGTH);
  }
  return ret;
}

function c2w_slice(str, beg, end, _, ret, x, ml, ms, w) {
  if (!USE_C2W) return substr(str, beg + 1, end - beg);
  ret = ""; x = 0;
  while (match(str, /^[ -~]+|^./)) {
    ml = RLENGTH;
    ms = substr(str, 1, RLENGTH);
    if (RLENGTH > 1) {
      if (beg < x + ml && x < end) {
        if (x < beg) {
          ml -= beg - x;
          ms = substr(ms, beg - x + 1);
          x = beg;
        }
        ret = ret substr(ms, 1, end - x);
      }
      x += ml;
    } else {
      w = s2w(ms);
      if (beg <= x && x + w <= end)
        ret = ret ms;
      x += w;
    }
    if (x >= end) break;
    str = substr(str, 1 + RLENGTH);
  }
  return ret;
}

#------------------------------------------------------------------------------

BEGIN {
  mode = "pass";
  flagLineColor = ENVIRON["flagLineColor"];
  flagLineWrapping = ENVIRON["flagLineWrapping"];
  optionColorTheme = ENVIRON["optionColorTheme"];

  SCREEN_WIDTH = 80;
  if (ENVIRON["COLUMNS"] != "")
    SCREEN_WIDTH = max(80, or(0, ENVIRON["COLUMNS"])) - 1;

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
  } else if (mode == "minix") {
    initialize_minix();
  } else if (mode == "aixps") {
    initialize_aixps();
  } else if (mode == "procps") {
    initialize_procps();
  }
  next;
}

#-------------------------------------------------------------------------------
# read wmic outputs

# data_wmic[WINPID, "p"] ... Parent Windows PID
# data_wmic[WINPID, "a"] ... arguments
# data_wmic[WINPID, "i"] ... Cygwin PID (set by register_process_cygps)

# Note: somehow there are multiple CRs at the end of line in recent Windows versions
mode == "wmic" { sub(/\r+$/, ""); }

mode == "wmic" && /^CommandLine=/ {
  sub(/^CommandLine=("[^"]+"|[^"[:space:]]+|$)/, "", $0);
  args = $0;
  next;
}

mode == "wmic" && /^ParentProcessId=/ {
  sub(/^ParentProcessId=/, "", $0);
  ppid = $0;
  next;
}

mode == "wmic" && /^ProcessId=/ {
  sub(/^ProcessId=/, "", $0);
  winpid = $0;
  data_wmic[winpid, "p"] = ppid;
  data_wmic[winpid, "a"] = args;
  #print winpid, ppid, "[" substr(args, 1, 40) "]";
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
    columns[_i,"hidden"] = columns_config[_label, "hidden"];
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

    # 末尾で align 調整が起こる事を意味する。
    # 今までに起こった overflow による ずれを rmargin で解消する。
    columns[_i,"unshift"] = columns_config[_label, "unshift"];

    columns_label2index[_label] = _i;
    columns_data["HEAD", _i] = _label;
  }
}

function columns_register(line, _l, _i, _width, _value, _vlen, _len, _lpad, _shift) {
  _l = columns_nline++;
  _shift = 0;
  for (_i = 0; _i < columns_count - 1; _i++) {
    _width = columns[_i, "width"];
    if (USE_C2W) {
      _value = c2w_slice(line, 0, _width);
      line = substr(line, length(_value) + 1);
    } else {
      _value = substr(line, 1, _width);
      line = substr(line, _width + 1);
    }

    # read overflowing data
    if (match(line, /^[^[:space:]]+/) > 0) {
      _value = _value substr(line, 1, RLENGTH);
      line = substr(line, RLENGTH + 1);

      if (columns[_i, "align"] != "right") {
        _lpad = USE_C2W ? str2w(_value) - _width : RLENGTH;
        _shift += max(0, _lpad - columns[_i, "rmargin"]);
        _lpad = min(_lpad, columns[_i, "rmargin"]);
        line = sprintf("%*s", _lpad, "") line;
      } else {
        _shift += RLENGTH;
      }
    }

    _value = trim(_value);
    _len = USE_C2W ? str2w(_value) : length(_value);
    if (_len > _width)
      columns[_i, "novf"]++;
    if (_len > columns[_i, "wmax"])
      columns[_i, "wmax"] = _len;

    columns_data[_l, _i] = _value;

    # skip space
    line = substr(line, 2);

    # Note: procps はセルに収まらないフィールドでずれても、特定の列で
    # ずれが元に戻る。恐らくフィールドのグループ毎に再び横位置合わせを
    # している。
    if (_shift && columns[_i, "unshift"]) {
      line = sprintf("%*s", min(_shift, columns[_i, "rmargin"]), "") line;
      _shift = 0;
    }

  }

  # the last column has an unlimited length
  columns_data[_l, _i] = line;
  return _l;
}

function columns_getColumnByLabel(iline, label, _index) {
  _index = columns_label2index[label];
  if (_index == "") return "";
  return columns_data[iline, _index];
}

function columns_construct(iline, _ret, _label, _fmt, _wmax, _data) {
  if (iline == "") iline = "HEAD";

  _ret = "";
  for (_i = 0; _i < columns_count - 1; _i++) {
    if (columns[_i, "hidden"]) continue;
    _fmt = columns[_i, "align"] == "left" ? "%-*s " : "%*s ";
    _wmax = columns[_i, "wmax"];
    _data = columns_data[iline, _i];
    if (USE_C2W) _wmax -= str2w(_data) - length(_data);
    _ret = _ret sprintf(_fmt, _wmax, _data);
  }
  if (!columns[columns_count - 1, "hidden"])
    _ret = _ret columns_data[iline, columns_count - 1];

  return _ret;
}

#-------------------------------------------------------------------------------
# read ps outputs for cygwin

function initialize_cygps() {
  USE_TREE = 1;
  ORD_UNICODE_MAX = 0x10000;
  c2w_initialize();

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

mode == "cygps" && /^[[:space:]]{2,}PID/ {
  columns_initialize("S" substr($0, 2));
  next;
}

function register_process_cygps(line, _pid, _ppid, _stat, _cmd, _iline) {
  _iline = columns_register(line);
  data_proc[_iline, "i"] = columns_getColumnByLabel(_iline, "PID");
  data_proc[_iline, "p"] = columns_getColumnByLabel(_iline, "PPID");
  data_proc[_iline, "w"] = columns_getColumnByLabel(_iline, "WINPID");
  data_proc[_iline, "c"] = columns_getColumnByLabel(_iline, "COMMAND");
  data_proc[_iline, "N"] = 0;
  dict_proc[data_proc[_iline, "i"]] = _iline;

  # WINPID to Cygwin PID
  data_wmic[data_proc[_iline, "w"], "i"] = data_proc[_iline, "i"];
}

mode == "cygps" { register_process_cygps($0); next; }

#-------------------------------------------------------------------------------
# read ps outputs for mac

function initialize_macps() {
  USE_TREE = 1;
  c2w_initialize();

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

  data_proc[_iline, "i"] = _pid;
  data_proc[_iline, "p"] = _ppid;
  data_proc[_iline, "c"] = _command;
  data_proc[_iline, "N"] = 0;
  dict_proc[data_proc[_iline, "i"]] = _iline;
}

mode == "macps" { register_process_mac($0); next; }

#-------------------------------------------------------------------------------
# read ps outputs for minix

function initialize_minix() {
  USE_TREE = 1;

  #----------------------------------------------------------------------
  # sample: minix
  #----------------------------------------------------------------------
  # ST UID   PID  PPID  PGRP     SZ         RECV TTY  TIME CMD
  #  S 1000   354     1   354  15312    (wait) pm  co  0:03 -bash
  #  S 1000   458   354   354   2304 (select) vfs  co  0:02 ssh -R 52222:127.0.0.1:22 hp2019
  #  S 1000   459   458   354    780 (select) vfs  co  0:06 nc 162.105.13.50 22
  #----------------------------------------------------------------------
  DEFAULT_HEAD_MINIX = "PST UID   PID  PPID  PGRP     SZ         RECV TTY  TIME CMD";

  # detailed settings
  columns_config["PPID", "hidden"] = 1;
  columns_config["CMD", "hidden"] = 1;
  columns_initialize(DFAULT_HEAD_MINIX);
}

mode == "minix" && /^[[:space:]]*ST/ {
  columns_initialize($0);
  next;
}

mode == "minix" && /^[[:space:]]*$/ { next; }

function register_process_minix(line, _iline, _ppid, _pid, _command) {
  _iline = columns_register(line);
  _ppid = columns_data[_iline, 3];
  _pid = columns_data[_iline, 2];
  _command = columns_getColumnByLabel(_iline, "CMD");

  data_proc[_iline, "i"] = _pid;
  data_proc[_iline, "p"] = _ppid;
  data_proc[_iline, "c"] = _command;
  data_proc[_iline, "N"] = 0;
  dict_proc[data_proc[_iline, "i"]] = _iline;
}

mode == "minix" { register_process_minix($0); next; }

#-------------------------------------------------------------------------------
# read ps outputs for aix

function initialize_aixps() {
  iColumnOfUser = 8;
}

mode == "aixps" && /^[[:space:]]*PPID/ {
  iColumnOfUser = index($0, "PPID") + 4;
  tree_print_header(substr($0, iColumnOfUser + 1));
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
  data_proc[_iline, "i"] = trim(slice(line, 17, 24)); # PID
  data_proc[_iline, "p"] = trim(slice(line, 0, 7));   # PPID
  data_proc[_iline, "s"] = slice(line, 9, 73);        # USER-STIME
  data_proc[_iline, "c"] = slice(line, 73);           # COMMAND
  data_proc[_iline, "N"] = 0;
  dict_proc[data_proc[_iline,"i"]] = _iline;
}

mode == "aixps" { register_process_aix($0); next; }

#-------------------------------------------------------------------------------

function initialize_procps() {
  c2w_initialize();

  DEFAULT_HEAD_PROCPS = "USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND";
  columns_config["USER", "align"] = "left";
  columns_config["TTY", "align"] = "left";
  columns_config["STAT", "align"] = "left";
  columns_config["TTY", "unshift"] = 1;
  columns_initialize(DEFAULT_HEAD_PROCPS);
}

mode == "procps" && /^[[:space:]]*USER\y/ {
  columns_initialize($0);
  next;
}

mode == "procps" {
  columns_register($0);
  next;
}

mode == "pass" { print; }

#-------------------------------------------------------------------------------

function tree_resolve( _i, _ppid, _pid, _iP) {
  for (_i = 0; _i < columns_nline; _i++) {
    _pid = data_proc[_i, "i"];
    _winpid = data_proc[_i, "w"];
    _ppid = data_proc[_i, "p"];

    # check if it is <defunct>
    if (fCHKDEFUNCT && _ppid != "0" && !proc_info[_pid, "D"])
      data_proc[_i, "<defunct>"] = 1;

    # resolve ppid
    if ((_ppid == "0" || _ppid == "1") && data_wmic[_winpid, "p"]) {
      _ppid = data_wmic[_winpid, "p"];

      # convert Windows PPID to Cygwin PPID
      if (data_wmic[_ppid, "i"]) _ppid = data_wmic[_ppid, "i"];
    }
    if (_ppid == _pid) continue;

    _iP = dict_proc[_ppid];
    if (_iP == "") continue;

    data_proc[_iP, "L", data_proc[_iP, "N"]++] = _i;
    data_proc[_i, "HAS_PPID"] = 1;
  }
}

function tree_print_header(line) {
  if (flagLineColor)
    print ti_smhead substr(line txt_fill, 1, SCREEN_WIDTH) ti_rmhead;
  else
    print line;
}

function tree_getProcessArgs(iProc, _ret, _winpid, _pid) {
  _winpid = data_proc[iProc, "w"];
  _ret = data_wmic[_winpid, "a"];
  if (_ret) return _ret;

  _pid = data_proc[iProc, "i"];
  return proc_info[_pid, "a"];
}

function tree_printProcess(iProc, head, head2, _stat, _cmd, _args, _i, _iN, _line, _txtbr, _ti1, _ti2, slice1) {
  _cmd = data_proc[iProc, "c"];
  if (_cmd ~ /[^\\]$/) gsub(/^.+\\/, "", _cmd);
  _args = tree_getProcessArgs(iProc);
  _stat = columns_count ? columns_construct(iProc) : data_proc[iProc, "s"];
  _line = _stat head _cmd _args;
  _iN = data_proc[iProc, "N"];

  _ti1 = "";_ti2 = "";
  if (flagLineColor) {
    if (tree_outputProcessCount % 2 == 1) {
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
    slice1 = c2w_slice(_line txt_fill, 0, SCREEN_WIDTH);
    print _ti1 slice1 _ti2;
    if (flagLineWrapping != "truncate" && length(slice1) < length(_line)) {
      _txtbr = _iN == 0 ? "  " : " |  ";
      _txtbr = substr(txt_indent head2 _txtbr, 1, SCREEN_WIDTH - 40);
      do {
        _line = _txtbr substr(_line, length(slice1) + 1);
        slice1 = c2w_slice(_line txt_fill, 0, SCREEN_WIDTH);
        print _ti1 slice1 _ti2;
      } while (length(slice1) < length(_line));
    }
  } else {
    print _ti1 _line _ti2;
  }

  tree_outputProcessCount++;

  for (_i = 0; _i < _iN; _i++)
    tree_printProcess(data_proc[iProc, "L", _i], head2 " \\_ ", head2 " " (_i + 1 == _iN ? "   " : "|  "));
}

function tree_print(_, _i, _head) {
  tree_resolve();

  if (columns_count) {
    _head = columns_construct("HEAD");
    txt_indent = sprintf("%*s", length(_head), "");
    tree_print_header(_head "COMMAND");
  }

  tree_outputProcessCount = 0;
  for (_i = 0; _i < columns_nline; _i++) {
    if (data_proc[_i, "HAS_PPID"]) continue;
    tree_printProcess(_i, "", "");
  }
}

function flat_print(_i) {
  print columns_construct("HEAD");
  for (_i = 0; _i < columns_nline; _i++) {
    print columns_construct(_i);
  }
}

END {
  if (USE_TREE) {
    tree_print();
  } else {
    flat_print();
  }
}
