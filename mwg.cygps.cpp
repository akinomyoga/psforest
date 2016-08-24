// �T���v�� from http://blog.goo.ne.jp/masaki_goo_2006/e/649b4637b28d8fff98b08aee26ab20e8

#include <cstdio>
#include <string>
#include <windows.h>
#include <tlhelp32.h>

/*
c      cmd          ���s�t�@�C���̒Z�����O
C      pcpu         cpu �g�p��
f      flags        �t���O (�����`���� F �t�B�[���h�̏���)
g      pgrp         �v���Z�X�̃O���[�v ID
G      tpgid        ����[���v���Z�X�O���[�v ID
j      cutime       �ݐς������[�U�[����
J      cstime       �ݐς����V�X�e������
k      utime        ���[�U�[����
m      min_flt      �}�C�i�[�y�[�W�t�H���g�̉�
M      maj_flt      ���W���[�y�[�W�t�H���g�̉�
n      cmin_flt     �}�C�i�[�y�[�W�t�H���g�̗ݐϐ�
N      cmaj_flt     �}�C�i�[�y�[�W�t�H���g�̗ݐϐ�
o      session      �Z�b�V���� ID
p      pid          �v���Z�X ID
P      ppid         �e�v���Z�X�̃v���Z�X ID
r      rss          �풓�Z�b�g�̑傫��
R      resident     �풓�y�[�W��
s      size         �������T�C�Y (�L���o�C�g�P��)
S      share        ��߂Ă���y�[�W�̗�
t      tty          ����[���̃f�o�C�X�ԍ�
T      start_time   �v���Z�X���N����������
U      uid          ���[�U�[ ID �ԍ�
u      user         ���[�U�[��
v      vsize        ���z�������̑S�T�C�Y (kB �P��)
y      priority     �J�[�l���X�P�W���[�����O�̗D��x

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
void wExeFile(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%-30s",proc.szExeFile);
}
void wCntUsage(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%6d",proc.cntUsage);
}
void wCntUsage(FILE* f,PROCESSENTRY32& proc){
  std::fprintf(f,"%6d",proc.cntThreads);
}

struct{
  const char* name;
  const char* header;
  void (*write)(FILE*,PROCESSENTRY32&);
} fields[]={
  {"comm","COMMAND",wExeFiles}
};

// ���C���֐�
int main( void ){
  static LPCTSTR Msg[] = {
    TEXT(" No. [szExeFile                     ] ")
    TEXT(" Usage Thread PareID ProcID HeapID ModuID Priori  dwFlags\n"),
    
    TEXT("---- -------------------------------- ")
    TEXT("------ ------ ------ ------ ------ ------ ------ --------\n"),
  };
  HANDLE hSnapshot;
  INT nCount = 0;
  
  if ( (hSnapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0)) != INVALID_HANDLE_VALUE ){
    PROCESSENTRY32 pe32;
    pe32.dwSize = sizeof( PROCESSENTRY32 );
    printf( Msg[0] );
    printf( Msg[1] );
    
    if ( Process32First(hSnapshot,&pe32) ){
      do {
        printf( "%3d: ",        ++nCount );
        printf( "[%-30s] ",     pe32.szExeFile );
        printf( "%6d ",         pe32.cntUsage );
        printf( "%6d ",         pe32.cntThreads );
        printf( "%6d ",         pe32.th32ParentProcessID );
        printf( "%6d ",         pe32.th32ProcessID );
        printf( "%6d ",         pe32.th32DefaultHeapID );
        printf( "%6d ",         pe32.th32ModuleID );
        printf( "%6d ",         pe32.pcPriClassBase );
        printf( "%08X\n",       pe32.dwFlags );
      } while ( Process32Next(hSnapshot,&pe32) );
    }
    CloseHandle( hSnapshot );
    printf( Msg[1] );
  }
  printf( "�v���Z�X���F%d��\n", nCount );
  return 0;
}