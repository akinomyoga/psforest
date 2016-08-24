// サンプル from http://blog.goo.ne.jp/masaki_goo_2006/e/649b4637b28d8fff98b08aee26ab20e8

#include <stdio.h>
#include <windows.h>
#include <tlhelp32.h>

// メイン関数
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
  printf( "プロセス数：%d個\n", nCount );
  return 0;
}