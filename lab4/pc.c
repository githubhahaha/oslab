#include <semaphore.h>
#include <stdio.h>
#include <fcntl.h>
#include<sys/types.h>
#include <unistd.h>
#include <stdlib.h>
#include<errno.h>

#define EMPTY "/empty"
#define MUTEX "/mutex"
#define FULL "/full"
#define BUFF_SIZE 10

extern int errno;

//int buff[500] = {0};

int main()
{
    printf("father pid is:%d\n", getpid());
    fflush(stdout);
    sem_t *mutex = sem_open(MUTEX, O_CREAT | O_EXCL, 0666, 1);
    sem_t *empty = sem_open(EMPTY, O_CREAT | O_EXCL, 0666, 10);
    sem_t *full = sem_open(FULL, O_CREAT | O_EXCL, 0666, 0);
    if (empty == SEM_FAILED || full == SEM_FAILED || mutex == SEM_FAILED)
    {
        perror("create sem failed!\n");
        return -1;
    }

    //打开文件，返回句柄给fd
    FILE* fd ;
    if((fd = fopen("buffer.dat", "w+"))==NULL){
        perror("open file failed!\n");
        return -1;
    }

    //landmark
    int buff_in=0;
    int buff_out=0;

    //根据后面两个参数重新定位被打开的fd文件的位移量
    fseek(fd,BUFF_SIZE*sizeof(int),SEEK_SET);

    fwrite(&buff_out, sizeof(int), 1, fd);
    fflush(fd);
    //producer
    pid_t p;
    if (!(p=fork()))
    {
        printf("producer pid is:%d\n", getpid());
        fflush(stdout);
        
        int i = 0;
        for (i = 0; i < 500; i++)
        {
            sem_wait(empty);
            sem_wait(mutex);
            //buff[i] = i;
            
            fseek(fd,buff_in*sizeof(int),SEEK_SET);

            fwrite(&i, sizeof(int), 1, fd);
            fflush(fd);
            buff_in=(buff_in+1)%BUFF_SIZE;

            sem_post(mutex);
            sem_post(full);
        }
        return 0;
    }
    else if(p<0){
        perror("producer create failed\n");
        return -1;
    }

    int data;
    //consumer
    int i;
    for (i = 0; i < 5; i++)
    {
        if (!(p=fork()))
        {
            int i;
            for (i = 0; i < 100; i++)
            {
                sem_wait(full);
                sem_wait(mutex);
                //seek read pos; 10 contains the next pos to read 
                fseek(fd,BUFF_SIZE*sizeof(int),SEEK_SET);
                fread(&buff_out,sizeof(int),1,fd);
                //read info
                fseek(fd,buff_out*sizeof(int),SEEK_SET);
                fread(&data, sizeof(int), 1, fd);
                buff_out=(buff_out+1)%BUFF_SIZE;
                //write pos in 10
                fseek(fd,BUFF_SIZE*sizeof(int),SEEK_SET);
                fwrite(&buff_out, sizeof(int), 1, fd);
                fflush(fd);
                printf("%d\t%d\n", getpid(), data);
                fflush(stdout);
                sem_post(mutex);
                sem_post(empty);
            }
            return 0;
        }
        else if(p<0){
            perror("consumer create failed!\n");
            return -1;
        }
    }

    for (i = 0; i < 5; i++)
    {
        wait(&i);
    }
    sem_unlink(EMPTY);
    sem_unlink(FULL);
    sem_unlink(MUTEX);
    fclose(fd);
    return 0;
}
