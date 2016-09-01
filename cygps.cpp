// サンプル from http://blog.goo.ne.jp/masaki_goo_2006/e/649b4637b28d8fff98b08aee26ab20e8

#include <cstdio>
#include <string>
#include <windows.h>
#include <tlhelp32.h>
#include <vector>

struct ProcessInformation{
  PROCESSENTRY32 m_processEntry;
};

/*
c      cmd          実行ファイルの短い名前
C      pcpu         cpu 使用率
f      flags        フラグ (長い形式の F フィールドの書式)
g      pgrp         プロセスのグループ ID
G      tpgid        制御端末プロセスグループ ID
j      cutime       累積したユーザー時間
J      cstime       累積したシステム時間
k      utime        ユーザー時間
m      min_flt      マイナーページフォルトの回数
M      maj_flt      メジャーページフォルトの回数
n      cmin_flt     マイナーページフォルトの累積数
N      cmaj_flt     マイナーページフォルトの累積数
o      session      セッション ID
p      pid          プロセス ID
P      ppid         親プロセスのプロセス ID
r      rss          常駐セットの大きさ
R      resident     常駐ページ数
s      size         メモリサイズ (キロバイト単位)
S      share        占めているページの量
t      tty          制御端末のデバイス番号
T      start_time   プロセスが起動した時刻
U      uid          ユーザー ID 番号
u      user         ユーザー名
v      vsize        仮想メモリの全サイズ (kB 単位)
y      priority     カーネルスケジューリングの優先度

%C       pcpu       %CPU
%G       group      GROUP
%P       ppid       PPID
%U       user       USER
%a       args       COMMAND
%c       comm       COMMAND
%g       rgroup     RGROUP
%n       nice       NI
%p       pid        PID
%r       pgid       PGID
%t       etime      ELAPSED
%u       ruser      RUSER
%x       time       TIME
%y       tty        TTY
%z       vsz        VSZ

%cpu       %CPU
%mem       %MEM
args       COMMAND
blocked    BLOCKED
bsdstart   START
bsdtime    TIME
c          C
caught     CAUGHT
class      CLS
cls        CLS
cmd        CMD
comm       COMMAND
command    COMMAND
cp         CP
cputime    TIME
egid       EGID
egroup     EGROUP
eip        EIP
esp        ESP
etime      ELAPSED
euid       EUID
euser      EUSER
f          F
fgid       FGID
fgroup     FGROUP
flag       F
flags      F
fname      COMMAND
fuid       FUID
fuser      FUSER
gid        GID
group      GROUP
ignored    IGNORED
label      LABEL
lstart     STARTED
lwp        LWP
ni         NI
nice       NI
nlwp       NLWP
nwchan     WCHAN
pcpu       %CPU
pending    PENDING
pgid       PGID
pgrp       PGRP
pid        PID
pmem       %MEM
policy     POL
ppid       PPID
psr        PSR
rgid       RGID
rgroup     RGROUP
rss        RSS
rssize     RSS
rsz        RSZ
rtprio     RTPRIO
ruid       RUID
ruser      RUSER
s          S
sched      SCH
sess       SESS
sgi_p      P
sgid       SGID
sgroup     SGROUP
sid        SID
sig        PENDING
sigcatch   CAUGHT
sigignore  IGNORED
sigmask    BLOCKED
size       SZ
spid       SPID
stackp     STACKP
start      STARTED
start_time START
stat       STAT
state      S
suid       SUID
suser      SUSER
svgid      SVGID
svuid      SVUID
sz         SZ
thcount    THCNT
tid        TID
time       TIME
tname      TTY
tpgid      TPGID
tt         TT
tty        TT
ucmd       CMD
ucomm      COMMAND
uid        UID
uname      USER
user       USER
vsize      VSZ
vsz        VSZ
wchan      WCHAN

*/

void wExeFiles(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%-30s",proc.szExeFile);
}
void wCntUsage(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%6d",proc.cntUsage);
}
void wCntThreads(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%6d",proc.cntThreads);
}

static struct{
  const char* name;
  const char* header;
  void (*write)(FILE*,PROCESSENTRY32&);
} fields[]={
  {"comm","COMMAND",wExeFiles}
};

void get_list_of_processes(std::vector<ProcessInformation>& processes) {
  HANDLE hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  if (hSnapshot != INVALID_HANDLE_VALUE) {
    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof(PROCESSENTRY32);

    if (Process32First(hSnapshot, &pe32)) {
      do {
        ProcessInformation info;
        info.m_processEntry = pe32;
        processes.push_back(info);
      } while (Process32Next(hSnapshot,&pe32));
    }
    CloseHandle(hSnapshot);
  }
}

// メイン関数
int main() {
  std::vector<ProcessInformation> processes;
  get_list_of_processes(processes);

  for (ProcessInformation const& info: processes) {
    PROCESSENTRY32 const& pe32 = info.m_processEntry;
    printf( "[%-30s] ", pe32.szExeFile);
    printf( "%6d ",     pe32.cntUsage);
    printf( "%6d ",     pe32.cntThreads);
    printf( "%6d ",     pe32.th32ParentProcessID);
    printf( "%6d ",     pe32.th32ProcessID);
    printf( "%6d ",     pe32.th32DefaultHeapID);
    printf( "%6d ",     pe32.th32ModuleID);
    printf( "%6d ",     pe32.pcPriClassBase);
    printf( "%08X\n",   pe32.dwFlags);
  }

  return 0;
}
