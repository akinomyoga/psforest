#!/bin/bash

#ps uaxf

# for cygwin
ps -e|awk '
  function slice(str,start,end){
    if(end=="")
      return substr(str,start+1);
    else
      return substr(str,start+1,end-start);
  }
  function trim(str){
    gsub(/^\s+|^\s*$/,"",str);
    return str;
  }

  BEGIN{
    iData=0;
  }

  function register_process(line, _pid,_ppid,_stat,_cmd){
    data_proc[iData,"i"]=trim(slice(line,1,9));
    data_proc[iData,"p"]=trim(slice(line,9,17));
    data_proc[iData,"s"]=slice(line,0,56);
    data_proc[iData,"c"]=slice(line,56);
    data_proc[iData,"N"]=0;
    dict_proc[data_proc[iData,"i"]]=iData;
    iData++;
  }

  function construct_tree( _i,_iP){
    for(_i=0;_i<iData;_i++){
      _iP=dict_proc[data_proc[_i,"p"]];
      if(_iP=="")continue;
      data_proc[_iP,"L",data_proc[_iP,"N"]++]=_i;
    }
  }

  function output_process(iProc,head,head2, _i,_iN){
    print data_proc[iProc,"s"] head data_proc[iProc,"c"];

    _iN=data_proc[iProc,"N"];
    for(_i=0;_i<_iN;_i++)
      output_process(data_proc[iProc,"L",_i],head2 " \\_ ",head2 (_i+1==_iN?"    ":" |  "));
  }

  /^\s*PID/{
    print
    next
  }

  {register_process($0);}

  END{
    construct_tree();

    for(i=0;i<iData;i++){
      p=data_proc[i,"p"];
      if(dict_proc[p]!="")continue;
      output_process(i,"","");
    }
  }
'

#0         1         2         3         4         5         6
#0123456789012345678901234567890123456789012345678901234567890123456789
#      PID    PPID    PGID     WINPID  TTY  UID    STIME COMMAND
#     5288       1    4924       4496    ? 1005   Jul 10 /usr/sbin/cygserver
#     4080       1    4080       4080    ? 1005   Jul 10 /usr/sbin/httpd2
#      880    4080    4080        880    ? 1005   Jul 10 /usr/sbin/httpd2
#     4824    4080    4080       4824    ? 1005   Jul 10 /usr/sbin/httpd2
#     5096    4080    4080       5096    ? 1005   Jul 10 /usr/sbin/httpd2
#     4564    4080    4080       4564    ? 1005   Jul 10 /usr/sbin/httpd2
#      572    4080    4080        572    ? 1005   Jul 10 /usr/sbin/httpd2
#     5728    4080    4080       5728    ? 1005   Jul 10 /usr/sbin/httpd2

