// Linux optional-tool launcher. Fixed package-local programs, no shell.
// Resource/lifetime limits apply before loading the emitter or target consumer.
#define _GNU_SOURCE
#include <sys/resource.h>
#include <sys/prctl.h>
#include <signal.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <limits.h>
static void die(void){perror("PSC1_OPTIONAL_TOOL");exit(125);}
int main(int argc,char **argv){
  if(argc<2)return 125;
  pid_t parent=getppid();
  if(prctl(PR_SET_PDEATHSIG,SIGKILL)||getppid()!=parent)return 125;
  struct rlimit memory={4294967296ULL,4294967296ULL},stack={8388608,8388608};
  if(setrlimit(RLIMIT_AS,&memory)||setrlimit(RLIMIT_STACK,&stack))die();
  char root[PATH_MAX],binary[PATH_MAX+64],libs[PATH_MAX*3],script[PATH_MAX+64],extension[PATH_MAX+64];
  ssize_t size=readlink("/proc/self/exe",root,sizeof(root)-1);if(size<1)die();root[size]=0;
  char *slash=strrchr(root,'/');if(!slash)return 125;*slash=0;
  if(snprintf(libs,sizeof(libs),"%s/lib:%s/runtime/lib",root,root)>=sizeof(libs))return 125;
  unsetenv("LD_PRELOAD");unsetenv("PYTHONPATH");unsetenv("PYTHONHOME");unsetenv("PHPRC");unsetenv("PHP_INI_SCAN_DIR");
  if(setenv("LD_LIBRARY_PATH",libs,1))die();
  char **args=calloc((size_t)argc+12,sizeof(char*));if(!args)die();
  int n=0;
  if(!strcmp(argv[1],"emit-portable")||!strcmp(argv[1],"--identity")){
    if((!strcmp(argv[1],"emit-portable")&&argc!=3)||(!strcmp(argv[1],"--identity")&&argc!=2))return 125;
    snprintf(binary,sizeof(binary),"%s/worker",root);args[n++]=binary;
    for(int i=1;i<argc;i++)args[n++]=argv[i];
  }else if((!strcmp(argv[1],"python-check")&&argc==4)||(!strcmp(argv[1],"python-run")&&argc>=3)){
    snprintf(binary,sizeof(binary),"%s/runtime/bin/python3",root);
    snprintf(script,sizeof(script),"%s/validate.py",root);
    args[n++]=binary;args[n++]="-I";args[n++]="-S";args[n++]="-B";
    if(!strcmp(argv[1],"python-check")){args[n++]=script;args[n++]=argv[2];args[n++]=argv[3];}
    else for(int i=2;i<argc;i++)args[n++]=argv[i];
  }else if((!strcmp(argv[1],"php-check")&&argc==4)||(!strcmp(argv[1],"php-run")&&argc>=3)){
    snprintf(binary,sizeof(binary),"%s/runtime/bin/php",root);
    snprintf(script,sizeof(script),"%s/validate.php",root);
    snprintf(extension,sizeof(extension),"extension=%s/runtime/gmp.so",root);
    args[n++]=binary;args[n++]="-n";args[n++]="-d";args[n++]=extension;
    args[n++]="-d";args[n++]="ffi.enable=0";
    if(!strcmp(argv[1],"php-check")){args[n++]=script;args[n++]=argv[2];args[n++]=argv[3];}
    else for(int i=2;i<argc;i++)args[n++]=argv[i];
  }else if(!strcmp(argv[1],"validate")||(!strcmp(argv[1],"component")&&argc==4&&!strcmp(argv[2],"wit"))){
    snprintf(binary,sizeof(binary),"%s/wasm-tools",root);args[n++]=binary;
    for(int i=1;i<argc;i++)args[n++]=argv[i];
  }else return 125;
  args[n]=NULL;execv(binary,args);die();return 125;
}
