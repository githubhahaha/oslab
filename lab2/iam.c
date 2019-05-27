
#define __LIBRARY__
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <stdio.h>
_syscall1(int,iam,const char*,name)
 
int main(int argc,char* argv[])
{
    int n;
    n=iam(argv[1]);
    return n;
}
