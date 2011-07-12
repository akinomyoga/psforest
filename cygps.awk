#!/bin/gawk -f

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
  iData=0;
}

#-------------------------------------------------------------------------------
# read wmic outputs

/^CommandLine\=/{
  gsub(/^CommandLine\=("[^"]+"|[^"[:space:]]+|\r$)|\r$/,"",$0);
  args=$0;
  next;
}

/^ParentProcessId\=/{
  gsub(/^ParentProcessId\=|\r$/,"",$0);
  ppid=$0;
  next;
}

/^ProcessId\=/{
  gsub(/^ProcessId\=|\r$/,"",$0);
  pid=$0;
  data_wmic[pid,"p"]=ppid;
  data_wmic[pid,"a"]=args;
  #print pid,ppid,substr(args,1,40)
  next;
}

/^[[:space:]]*$/{
  next;
}

#-------------------------------------------------------------------------------
# read ps outputs

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
  data_proc[iData,"i"]=trim(slice(line,1,9));   # PID
  data_proc[iData,"p"]=trim(slice(line,9,17));  # PPID
  data_proc[iData,"w"]=trim(slice(line,25,36)); # WINPID
  data_proc[iData,"s"]=slice(line,0,56);        # PID-STIME
  data_proc[iData,"c"]=slice(line,56);          # COMMAND
  data_proc[iData,"N"]=0;
  dict_proc[data_proc[iData,"i"]]=iData;
  iData++;
}

function construct_tree( _i,_ppid,_pid,_iP){
  for(_i=0;_i<iData;_i++){
    _pid=data_proc[_i,"i"];

    # get ppid
    _ppid=data_proc[_i,"p"];
    if(_ppid=="0")
      _ppid=data_wmic[_pid,"p"];
    if(_ppid==_pid)continue;

    _iP=dict_proc[_ppid];
    if(_iP=="")continue;

    data_proc[_iP,"L",data_proc[_iP,"N"]++]=_i;
    data_proc[_i,"HAS_PPID"]=1;
  }
}

function output_process(iProc,head,head2, _cmd,_args,_i,_iN){
  _cmd=data_proc[iProc,"c"];
  if(_cmd ~ /[^\\]$/)gsub(/^.+\\/,"",_cmd);
  _args=data_wmic[data_proc[iProc,"w"],"a"];
  print substr(data_proc[iProc,"s"] head _cmd _args,1,200)

  _iN=data_proc[iProc,"N"];
  for(_i=0;_i<_iN;_i++)
    output_process(data_proc[iProc,"L",_i],head2 " \\_ ",head2 (_i+1==_iN?"    ":" |  "));
}


/^[[:space:]]*PID/{
  print;
  next;
}

{register_process($0);}

END{
  construct_tree();

  for(i=0;i<iData;i++){
    p=data_proc[i,"p"];
    if(data_proc[i,"HAS_PPID"])continue;
    output_process(i,"","");
  }
}
