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

  function register_process(line, _pid,_ppid,_stat,_cmd){
    #----------------------------------------------------------------------
    #  sample
    #----------------------------------------------------------------------
    #   PPID     USER     PID  %CPU  %MEM   VSZ     TT S  STARTED        TIME COMMAND
    #2818312  kmurase 3145874   0.0   0.0   420  pts/4 A 04:08:31    00:00:00 /bin/bash /sr
    #      1  kmurase 3408008   0.0   0.0  2900      - A 23:50:31    00:00:00 SCREEN
    #2818312  kmurase 3735594   0.0   0.0   768  pts/4 A 04:39:15    00:00:00 ps -u kmurase
    #4063924  kmurase 5243088   0.0   0.0   568      - A 03:37:53    00:00:00 /usr/sbin/sft
    #3408008  kmurase 5439566   0.0   0.0   756  pts/3 A 23:50:31    00:00:00 /bin/bash
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
    print substr($0,10);
    next
  }
  /^[[:space:]]*$/{next}
  {register_process($0);}
  END{
    construct_tree();
    for(i=0;i<iData;i++){
      p=data_proc[i,"p"];
      if(data_proc[i,"HAS_PPID"])continue;
      output_process(i,"","");
    }
  }
'
