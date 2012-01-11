#!/bin/bash

ps -A -o ppid,user,pid,pcpu,pmem,vsize,tty,stat,start,time,args|gawk '
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

  #----------------------------------------------------------------------------
  # tree structure

  function register_process_mac(line, _pid,_ppid,_stat,_cmd,_arr,_iC0){
    #----------------------------------------------------------------------
    # sample: Mac OS X
    #----------------------------------------------------------------------
    # PPID USER       PID  %CPU %MEM      VSZ TTY      STAT STARTED      TIME ARGS
    #    0 root         1   0.0  0.0  2475324 ??       Ss    4:30AM   1:13.29 /sbin/launchd
    #    1 root        28   0.0  0.0  2466708 ??       Ss    4:30AM   0:02.28 /usr/libexec/kextd
    #    1 root        29   4.3  0.1  2474748 ??       Ss    4:30AM   6:31.52 /usr/sbin/DirectoryService
    #    1 root        30   0.0  0.0  2462972 ??       Ss    4:30AM   0:15.59 /usr/sbin/notifyd
    #    1 root        31   0.0  0.0  2466264 ??       Ss    4:30AM   0:00.38 /usr/sbin/diskarbitrationd
    #    1 root        32   0.0  0.0  2475528 ??       Ss    4:30AM   0:15.91 /usr/sbin/syslogd
    #    1 root        33   0.0  0.0  2483636 ??       Ss    4:30AM   0:54.63 /usr/libexec/configd
    #    1 daemon      34   0.0  0.0  2467140 ??       Ss    4:30AM   0:01.39 /usr/sbin/distnoted
    #    1 _mdnsresponder    35   0.0  0.0  2477544 ??       Ss    4:30AM   0:03.95 /usr/sbin/mDNSResponder -launchd
    #    1 root        43   0.0  0.0  2464112 ??       Ss    4:30AM   0:00.38 /usr/sbin/securityd -i
    #    1 root        51   0.0  0.0  2435208 ??       Ss    4:30AM   0:03.77 /usr/sbin/ntpd -c /private/etc/ntp-restrict.conf -n -g -p /var/r
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
  function construct_tree( _i,_ppid,_pid,_iP){
    for(_i=0;_i<iData;_i++){
      _pid=data_proc[_i,"i"];
  
      # get ppid
      _ppid=data_proc[_i,"p"];
      ###if(_ppid=="0")_ppid=data_wmic[_pid,"p"];
      if(_ppid==_pid)continue;
  
      _iP=dict_proc[_ppid];
      if(_iP=="")continue;
  
      data_proc[_iP,"L",data_proc[_iP,"N"]++]=_i;
      data_proc[_i,"HAS_PPID"]=1;
    }
  }
  function output_process(iProc,head,head2, _cmd,_args,_i,_iN){
    _cmd=data_proc[iProc,"c"];
    print substr(data_proc[iProc,"s"] head _cmd,1,200)
  
    _iN=data_proc[iProc,"N"];
    for(_i=0;_i<_iN;_i++)
      output_process(data_proc[iProc,"L",_i],head2 " \\_ ",head2 (_i+1==_iN?"    ":" |  "));
  }

  #----------------------------------------------------------------------------

  BEGIN{
    iData=0;
  }
  /^[[:space:]]*PPID/{
    iColumnOfUser=index($0,"USER")-1;
    print substr($0,iColumnOfUser+1);
    next
  }
  /^[[:space:]]*$/{next}
  {register_process_mac($0);}
  END{
    construct_tree();
    for(i=0;i<iData;i++){
      p=data_proc[i,"p"];
      if(data_proc[i,"HAS_PPID"])continue;
      output_process(i,"","");
    }
  }
'
