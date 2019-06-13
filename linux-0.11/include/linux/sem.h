#ifndef _SEM_H
#define _SEM_H
#include <linux/sched.h>

#define _SEM_MAX 5
#define _SEM_NAME_MAX 20
//sem struct
typedef struct
{
    char name[_SEM_NAME_MAX];
    int value;
    struct task_struct *queue;
} sem_t;

/* Value returned if `sem_open` failed. */
#define SEM_FAILED ((sem_t *)0)

#endif /* _SEM_H */