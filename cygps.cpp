// サンプル from http://blog.goo.ne.jp/masaki_goo_2006/e/649b4637b28d8fff98b08aee26ab20e8

#include <cstdio>
#include <string>
#include <vector>
#include <memory>
#include <windows.h>
#include <tlhelp32.h>

struct ProcessInformation {
  PROCESSENTRY32 m_processEntry;
};

struct IProcessField;

static std::vector<IProcessField*>& getFields() {
  static std::vector<IProcessField*> instance;
  return instance;
}

struct IProcessField {
  virtual const char* specifier() const = 0;
  virtual const char* header() const = 0;
  virtual int width() const = 0;
  virtual void write(FILE* file, int width, ProcessInformation& info) const = 0;

  IProcessField() {
    getFields().push_back(this);
  }
  virtual ~IProcessField() {}
};

static struct FieldWINPID: IProcessField {
  const char* specifier() const {return "winpid";}
  const char* header() const {return "WINPID";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.th32ProcessID);
  }
} instance5;

static struct FieldWINPPID: IProcessField {
  const char* specifier() const {return "winppid";}
  const char* header() const {return "WINPPID";}
  int width() const {return 7;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.th32ParentProcessID);
  }
} instance4;

static struct FieldPriorityClassBase: IProcessField {
  const char* specifier() const {return "pri";}
  const char* header() const {return "PRI";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.pcPriClassBase);
  }
} instance8;

static struct FieldThreadCount: IProcessField {
  const char* specifier() const {return "thcount";}
  const char* header() const {return "THCNT";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.cntThreads);
  }
} instance3;

static struct FieldExeName: IProcessField {
  const char* specifier() const {return "command";}
  const char* header() const {return "COMMAND";}
  int width() const {return 30;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%-*s", width, info.m_processEntry.szExeFile);
  }
} instance1;

//-----------------------------------------------------------------------------
// These are no longer used, and are always set to zero.

static struct FieldUsageCount: IProcessField {
  const char* specifier() const {return "usage";}
  const char* header() const {return "USAGE";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.cntUsage);
  }
} instance2;

static struct FieldDefaultHeapID: IProcessField {
  const char* specifier() const {return "heapid";}
  const char* header() const {return "HEAPID";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.th32DefaultHeapID);
  }
} instance6;

static struct FieldModuleID: IProcessField {
  const char* specifier() const {return "modid";}
  const char* header() const {return "MODID";}
  int width() const {return 6;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%*d", width, info.m_processEntry.th32ModuleID);
  }
} instance7;

static struct FieldFlags: IProcessField {
  const char* specifier() const {return "flags";}
  const char* header() const {return "FLAGS";}
  int width() const {return 8;}
  void write(FILE* file, int width, ProcessInformation& info) const {
    std::fprintf(file, "%0*X", width, info.m_processEntry.dwFlags);
  }
} instance9;

//-----------------------------------------------------------------------------

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

  auto const& fields = getFields();

  {
    bool first = true;
    for (IProcessField* f: fields) {
      if (first)
        first = false;
      else
        std::fputc(' ', stdout);

      int const width = f->width();
      std::fprintf(stdout, "%*s", width, f->header());
    }
    std::fputc('\n', stdout);
  }

  for (ProcessInformation& info: processes) {
    {
      bool first = true;
      for (IProcessField* f: fields) {
        if (first)
          first = false;
        else
          std::fputc(' ', stdout);

        int const width = f->width();
        f->write(stdout, width, info);
      }
    }
    std::fputc('\n', stdout);

    // PROCESSENTRY32 const& pe32 = info.m_processEntry;
    // printf( "[%-30s] ", pe32.szExeFile);
    // printf( "%6d ",     pe32.cntUsage);
    // printf( "%6d ",     pe32.cntThreads);
    // printf( "%6d ",     pe32.th32ParentProcessID);
    // printf( "%6d ",     pe32.th32ProcessID);
    // printf( "%6d ",     pe32.th32DefaultHeapID);
    // printf( "%6d ",     pe32.th32ModuleID);
    // printf( "%6d ",     pe32.pcPriClassBase);
    // printf( "%08X\n",   pe32.dwFlags);
  }

  return 0;
}
