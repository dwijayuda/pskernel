// Test-only native Windows child-tree fixture; never included in npm payloads.
#define UNICODE
#define _UNICODE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>
int wmain(int argc, wchar_t **argv) {
  if (argc == 3 && wcscmp(argv[1], L"--probe") == 0) {
    DWORD pid=(DWORD)wcstoul(argv[2], NULL, 10);
    HANDLE p=OpenProcess(SYNCHRONIZE, FALSE, pid);
    if (!p) return GetLastError()==ERROR_INVALID_PARAMETER ? 0 : 2;
    DWORD state=WaitForSingleObject(p,0);CloseHandle(p);return state==WAIT_OBJECT_0 ? 0 : 1;
  }
  if (argc == 3 && wcscmp(argv[1], L"--child") == 0) {
    FILE *f=_wfopen(argv[2],L"wb");if(!f)return 3;
    fprintf(f,"%lu",(unsigned long)GetCurrentProcessId());fclose(f);Sleep(60000);return 0;
  }
  if (argc != 3) return 3;
  FILE *f=_wfopen(argv[1],L"rb");if(!f)return 3;
  char buffer[65536];size_t n=fread(buffer,1,sizeof(buffer)-1,f);fclose(f);buffer[n]=0;
  if (strncmp(buffer,"spawn",5)==0) {
    char *newline=strchr(buffer,'\n');if(!newline)return 3;
    wchar_t marker[30000],self[30000],command[62000];
    if(!MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,newline+1,-1,marker,30000))return 3;
    if(!GetModuleFileNameW(NULL,self,30000))return 3;
    _snwprintf(command,62000,L"\"%ls\" --child \"%ls\"",self,marker);
    STARTUPINFOW startup;PROCESS_INFORMATION process;
    ZeroMemory(&startup,sizeof(startup));startup.cb=sizeof(startup);ZeroMemory(&process,sizeof(process));
    if(!CreateProcessW(self,command,NULL,NULL,FALSE,CREATE_NO_WINDOW,NULL,NULL,&startup,&process))return 3;
    CloseHandle(process.hThread);CloseHandle(process.hProcess);
    for(int i=0;i<100&&GetFileAttributesW(marker)==INVALID_FILE_ATTRIBUTES;i++)Sleep(20);
    if(strncmp(buffer,"spawn-success",13)!=0)Sleep(60000);
  } else if(strncmp(buffer,"hang",4)==0)Sleep(60000);
  else if(strncmp(buffer,"overflow",8)==0){
    char b[4096];memset(b,'x',sizeof(b));for(int i=0;i<10240;i++)fwrite(b,1,sizeof(b),stdout);fflush(stdout);Sleep(60000);
  }
  f=_wfopen(argv[2],L"wb");if(!f)return 3;fputs("{}",f);fclose(f);return 0;
}
