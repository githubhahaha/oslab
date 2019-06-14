#define __LIBRARY__
#include <unistd.h>
#include <asm/segment.h>
#include <asm/system.h>
#include <linux/kernel.h>

/*sem list */

sem_t sem_list[_SEM_MAX] = {
    {'\0', 0, NULL}, {'\0', 0, NULL}, {'\0', 0, NULL}, {'\0', 0, NULL}, {'\0', 0, NULL}};

sem_t *sys_sem_open(const char *name, unsigned int value)
{
    char nbuff[_SEM_NAME_MAX];
    int i = 0;
    char tmp;
    for (i = 0; i < _SEM_NAME_MAX; i++)
    {
        tmp = get_fs_byte(name + i);
        if (!tmp)
            break;
        nbuff[i] = get_fs_byte(name + i);
    }
    if (tmp)
    {
        printk("name is too long!\n");
        return 0;
    }

    /*search for the exsit sem */
    sem_t *result = 0;
    for (i = 0; i < _SEM_MAX; i++)
    {
        if (!strcmp(sem_list[i].name, nbuff))
        {
            result = &sem_list[i];
            printk("sem %s has exist,so we'll use it\n", result->name);
            return result;
        }
    }

    /*sem not found */
    for (i = 0; i < _SEM_MAX; i++)
    {
        if (sem_list[i].name[0] == '\0')
        {
            strcpy(sem_list[i].name, nbuff);
            sem_list[i].value = value;
            sem_list[i].queue = NULL;
            result = &sem_list[i];
            printk("sem %s is created, value is %d\n", result->name, result->value);
            return result;
        }
    }
    return result;
}

int sys_sem_wait(sem_t *sem)
{
    cli();
    if (sem < sem_list || sem > sem_list + _SEM_MAX)
    {
        sti();
        printk("sem wait error!\n");
        return -1;
    }
    sem->value--;
    /*search for sem's value is no zero */
    while (sem->value < 0)
    {
        sleep_on(&(sem->queue));
        schedule();
    }

    sti();
    return 0;
}

int sys_sem_post(sem_t *sem)
{
    cli();
    if (sem < sem_list || sem > sem_list + _SEM_MAX)
    {
        sti();
        printk("sem post error!\n");
        return -1;
    }

    sem->value++;
    wake_up(&(sem->queue));
    sti();
    return 0;
}

int sys_sem_unlink(const char *name)
{
    char nbuff[20];
    int i = 0;
    char tmp;
    for (i = 0; i < 20; i++)
    {
        tmp = get_fs_byte(name + i);
        if (!tmp)
            break;
        nbuff[i] = get_fs_byte(name + i);
    }
    if (tmp)
    {
        printk("name is too long!\n");
        return -1;
    }
    for (i = 0; i < _SEM_MAX; i++)
    {
        if (!strcmp(sem_list[i].name, nbuff))
            ;
        {
            sem_list[i].name[0] = '\0';
            sem_list[i].value = 0;
            sem_list[i].queue = NULL;
            printk("sem %s is unlinked!\n", nbuff);
            return 0;
        }
    }
    printk("sem %s is not found!\n", nbuff);
    return -1;
}
