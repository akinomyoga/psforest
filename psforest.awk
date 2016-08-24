#!/bin/gawk -f

function max(a,b){
  return a>b?a:b;
}
function slice(str,start,end){
  if(end=="")
    return substr(str,start+1);
  else
    return substr(str,start+1,end-start);
}
function trim(str){
  gsub(/^[[:space:]]+|^[[:space:]]*$/,"",str);
  return str;
}

BEGIN{
  mode="pass";
  flagLineColor = ENVIRON["flagLineColor"];
  flagLineWrapping = ENVIRON["flagLineWrapping"];

  SCREEN_WIDTH=80;
  if(ENVIRON["COLUMNS"]!="")
    SCREEN_WIDTH=max(80,or(0,ENVIRON["COLUMNS"]))-1;

  iData=0;

  initialize_cygps();

  fCHKDEFUNCT=0;
  ti_dim="\33[2m";if(ENVIRON["TERM"]=="rosaterm")ti_dim="\33[9m";
  ti_gray="\33[37m";
  ti_sgr0="\33[m";

  if(flagLineWrapping){
    txt_indent="                                                        ";
  }

  if(flagLineColor){
    ti_smhead="\33[1;48;5;239;38;5;231m";
    ti_rmhead="\33[m";
    # ti_smodd="\33[48;5;189m";
    ti_smodd="\33[48;5;254m";
    ti_rmodd="\33[49m";

    txt_fill_length=4;
    txt_fill="    ";
    while(txt_fill_length<SCREEN_WIDTH){
      txt_fill=txt_fill txt_fill;
      txt_fill_length*=2;
    }
    txt_fill=slice(txt_fill,0,SCREEN_WIDTH);
  }else{
    ti_smhead="";
    ti_rmhead="";
    ti_smodd="";
    ti_rmodd="";
    txt_fill="";
  }
}

/^psforest: mode=/{
  sub(/^psforest: mode=/,"");
  mode=$0;
  if(mode=="cygps"){
    initialize_cygps();
  }else if(mode=="macps"){
    initialize_macps();
  }
  next
}

#-------------------------------------------------------------------------------
# read wmic outputs

mode=="wmic" && /^CommandLine\=/{
  gsub(/^CommandLine\=("[^"]+"|[^"[:space:]]+|\r$)|\r$/,"",$0);
  args=$0;
  next;
}

mode=="wmic" && /^ParentProcessId\=/{
  gsub(/^ParentProcessId\=|\r$/,"",$0);
  ppid=$0;
  next;
}

mode=="wmic" && /^ProcessId\=/{
  gsub(/^ProcessId\=|\r$/,"",$0);
  pid=$0;
  data_wmic[pid,"p"]=ppid;
  data_wmic[pid,"a"]=args;
  #print pid,ppid,substr(args,1,40)
  next;
}

mode=="wmic" && /^[[:space:]]*$/{
  next;
}

#-------------------------------------------------------------------------------
# read ls outputs

mode=="ls" && /^\/proc\/[0-9]+\/root\/$/{
  fCHKDEFUNCT=1;
  gsub(/^\/proc\/|\/root\/$/,"");
  data_wmic[$0,"D"]=1;
  next;
}

mode=="ls" && /^\/proc\/.+\/root\/$/{
  next;
}

#-------------------------------------------------------------------------------
# read ps outputs for cygwin

function initialize_cygps(){
  ofs_ppid0=9;
  ofs_ppidN=17;
  ofs_winpid0=25;
  ofs_winpidN=36;
  ofs_command=56;
}

function indexof_or(text,needle,def ,_i){
  _i=index(text,needle)-1;
  if(_i<0)return def;
  return _i;
}

mode=="cygps" && /^[[:space:]]*PID/ {
  output_header($0);

  if(flagLineWrapping && $0 ~ /COMMAND/){
    txt_indent=$0;
    sub(/COMMAND.*$/,"",txt_indent);
    gsub(/./," ",txt_indent);
  }

  ofs_ppid0=indexof_or($0,"PID",6)+3;
  ofs_ppidN=indexof_or($0,"PPID",13)+4;
  ofs_winpid0=indexof_or($0,"PGID",21)+4;
  ofs_winpidN=indexof_or($0,"WINPID",30)+6;
  ofs_command=indexof_or($0,"COMMAND",56);
  next;
}

function register_process(line, _pid,_ppid,_stat,_cmd){
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
  #0         1         2         3         4         5         6
  #0123456789012345678901234567890123456789012345678901234567890123456789
  #----------------------------------------------------------------------
  data_proc[iData,"i"]=trim(slice(line,1,ofs_ppid0));             # PID
  data_proc[iData,"p"]=trim(slice(line,ofs_ppid0  ,ofs_ppidN  )); # PPID
  data_proc[iData,"w"]=trim(slice(line,ofs_winpid0,ofs_winpidN)); # WINPID
  data_proc[iData,"s"]=slice(line,0,ofs_command);                 # PID-STIME
  data_proc[iData,"c"]=slice(line,ofs_command);                   # COMMAND
  data_proc[iData,"N"]=0;
  dict_proc[data_proc[iData,"i"]]=iData;
  iData++;
}

mode=="cygps" {register_process($0);next;}

#-------------------------------------------------------------------------------
# read ps outputs for mac

function initialize_macps(){
  iColumnOfUser=6;
}

mode=="macps" && /^[[:space:]]*PPID/{
  iColumnOfUser=index($0,"USER")-1;
  output_header(substr($0,iColumnOfUser+1));
  next;
}

mode=="macps" && /^[[:space:]]*$/{next}

function register_process_mac(line, _pid,_ppid,_stat,_cmd,_arr,_iC0){
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
  #0         1         2         3         4         5         6         7
  #01234567890123456789012345678901234567890123456789012345678901234567890123456789
  #----------------------------------------------------------------------
  split(line,_arr);
  _iC0=index(line,_arr[10])+length(_arr[10]);if(_iC0<0)iC0=73;
  data_proc[iData,"i"]=_arr[3];  # PID
  data_proc[iData,"p"]=_arr[1];  # PPID
  data_proc[iData,"s"]=slice(line,iColumnOfUser,_iC0);         # PID-STIME
  data_proc[iData,"c"]=slice(line,_iC0);           # COMMAND
  data_proc[iData,"N"]=0;
  dict_proc[data_proc[iData,"i"]]=iData;
  iData++;
}

mode=="macps" {register_process_mac($0);next;}

#-------------------------------------------------------------------------------
# read ps outputs for aix

function initialize_aixps(){
  iColumnOfUser=9;
}

mode=="aixps" && /^[[:space:]]*PPID/{
  iColumnOfUser=index($0,"PPID")+4;
  output_header(substr($0,iColumnOfUser+1));
  next;
}

mode=="aixps" && /^[[:space:]]*$/{next}

function register_process_aix(line, _pid,_ppid,_stat,_cmd){
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
  data_proc[iData,"i"]=trim(slice(line,17,24));  # PID
  data_proc[iData,"p"]=trim(slice(line,0,7));    # PPID
  data_proc[iData,"s"]=slice(line,9,73);         # PID-STIME
  data_proc[iData,"c"]=slice(line,73);           # COMMAND
  data_proc[iData,"N"]=0;
  dict_proc[data_proc[iData,"i"]]=iData;
  iData++;
}

mode=="aixps" {register_process_aix($0);next;}

#-------------------------------------------------------------------------------

function construct_tree( _i,_ppid,_pid,_iP){
  for(_i=0;_i<iData;_i++){
    _pid=data_proc[_i,"i"];
    _ppid=data_proc[_i,"p"];

    # check if it is <defunct>
    if(fCHKDEFUNCT&&_ppid!="0"&&!data_wmic[_pid,"D"])
      data_proc[_i,"<defunct>"]=1;

    # resolve ppid
    if((_ppid=="0"||_ppid=="1")&&data_wmic[_pid,"p"])
      _ppid=data_wmic[_pid,"p"];
    if(_ppid==_pid)continue;

    _iP=dict_proc[_ppid];
    if(_iP=="")continue;

    data_proc[_iP,"L",data_proc[_iP,"N"]++]=_i;
    data_proc[_i,"HAS_PPID"]=1;
  }
}

function output_header(line){
  if(flagLineColor)
    print ti_smhead substr(line txt_fill,1,SCREEN_WIDTH) ti_rmhead;
  else
    print line;
}

function output_process(iProc,head,head2, _cmd,_args,_i,_iN,_line,_txtbr){
  _cmd=data_proc[iProc,"c"];
  if(_cmd ~ /[^\\]$/)gsub(/^.+\\/,"",_cmd);
  _args=data_wmic[data_proc[iProc,"w"],"a"];
  _line=data_proc[iProc,"s"] head _cmd _args;
  _iN=data_proc[iProc,"N"];

  if(flagLineColor && outputProcessCount%2==1)
    printf("%s",ti_smodd);
  if(data_proc[iProc,"<defunct>"])
    printf(ti_dim ti_gray);

  print substr(_line txt_fill,1,SCREEN_WIDTH);
  if(flagLineWrapping && length(_line)>SCREEN_WIDTH){
    _txtbr=_iN==0?"  ":" |  ";
    _txtbr=substr(txt_indent head2 _txtbr,1,SCREEN_WIDTH-40)
    do{
      _line=_txtbr substr(_line,SCREEN_WIDTH+1);
      print substr(_line txt_fill,1,SCREEN_WIDTH);
    }while(length(_line)>SCREEN_WIDTH);
  }

  if(data_proc[iProc,"<defunct>"])
    printf(ti_sgr0);

  if(flagLineColor && outputProcessCount%2==1)
    printf("%s",ti_rmodd);
  outputProcessCount++;

  for(_i=0;_i<_iN;_i++)
    output_process(data_proc[iProc,"L",_i],head2 " \\_ ",head2 " " (_i+1==_iN?"   ":"|  "));
}

mode=="pass"{print;}

END{
  construct_tree();

  outputProcessCount=0;
  for(i=0;i<iData;i++){
    p=data_proc[i,"p"];
    if(data_proc[i,"HAS_PPID"])continue;
    output_process(i,"","");
  }
}
