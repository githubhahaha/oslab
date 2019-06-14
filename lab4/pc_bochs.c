#define __LIBRARY__
#include <stdio.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

#define EMPTY "/empty"
#define MUTEX "/mutex"
#define FULL "/full"
#define BUFF_SIZE 10

_syscall2(sem_t *, sem_open, const char *, name, unsigned int, value);
_syscall1(int, sem_wait, sem_t *, sem);
_syscall1(int, sem_post, sem_t *, sem);
_syscall1(int, sem_unlink, const char *, name);

sem_t *mutex, *empty, *full;

int buff_in = 0;
int buff_out = 0;
int data;
int i;
pid_t p;
int fd;

int main()
{
    printf("father pid is:%d\n", getpid());
    fflush(stdout);
    mutex = sem_open(MUTEX, 1);
    empty = sem_open(EMPTY, 10);
    full = sem_open(FULL, 0);
    if (empty == SEM_FAILED || full == SEM_FAILED || mutex == SEM_FAILED)
    {
        perror("create sem failed!\n");
        return -1;
    }

    if ((fd = open("buffer.dat", O_CREAT | O_RDWR | O_TRUNC, 0666)) == -1)
    {
        perror("open file failed!\n");
        return -1;
    }

    lseek(fd, BUFF_SIZE * sizeof(int), SEEK_SET);

    write(fd, (char *)&buff_out, sizeof(int));

    if (!(p = fork()))
    {
        printf("producer pid is:%d\n", getpid());
        fflush(stdout);

        for (i = 0; i < 500; i++)
        {
            sem_wait(empty);
            sem_wait(mutex);

            lseek(fd, buff_in * sizeof(int), SEEK_SET);
            write(fd, (char *)&i, sizeof(int));
            buff_in = (buff_in + 1) % BUFF_SIZE;

            sem_post(mutex);
            sem_post(full);
        }
        return 0;
    }
    else if (p < 0)
    {
        perror("producer create failed\n");
        return -1;
    }

    for (i = 0; i < 5; i++)
    {
        if (!(p = fork()))
        {
            for (i = 0; i < 100; i++)
            {
                sem_wait(full);
                sem_wait(mutex);

                lseek(fd, BUFF_SIZE * sizeof(int), SEEK_SET);
                read(fd, (char *)&buff_out, sizeof(int));

                lseek(fd, buff_out * sizeof(int), SEEK_SET);
                read(fd, (char *)&data, sizeof(int));
                buff_out = (buff_out + 1) % BUFF_SIZE;

                lseek(fd, BUFF_SIZE * sizeof(int), SEEK_SET);
                write(fd, (char *)&buff_out, sizeof(int));

                printf("%d\t%d\n", getpid(), data);
                fflush(stdout);
                sem_post(mutex);
                sem_post(empty);
            }
            return 0;
        }
        else if (p < 0)
        {
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
    close(fd);
    return 0;
}
