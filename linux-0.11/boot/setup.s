!
!	setup.s		(C) 1991 Linus Torvalds
!
! setup.s is responsible for getting the system data from the BIOS,
! and putting them into the appropriate places in system memory.
! both setup.s and system has been loaded by the bootblock.
!
! This code asks the bios for memory/disk/other parameters, and
! puts them in a "safe" place: 0x90000-0x901FF, ie where the
! boot-block used to be. It is then up to the protected mode
! system to read them from there before the area is overwritten
! for buffer-blocks.
!

! NOTE! These had better be the same as in bootsect.s!

INITSEG  = 0x9000	! we move boot here - out of the way
SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).
SETUPSEG = 0x9020	! this is the current segment

.globl begtext, begdata, begbss, endtext, enddata, endbss
.text
begtext:
.data
begdata:
.bss
begbss:
.text

entry start
	start:

!设置cs=ds=es
	mov ax,cs
	mov ds,ax
	mov es,ax

! Print some inane message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#28			! 23 + 6
	mov	bx,#0x000c		! page 0, attribute 7 (normal)
	mov	bp,#msg1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, we've written the message

! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.

!显示 Cursor POS: 字符串
    mov ah,#0x03        ! read cursor pos
    xor bh,bh
    int 0x10
    mov cx,#11
    mov bx,#0x0007      ! page 0, attribute c 
    mov bp,#cur
    mov ax,#0x1301      ! write string, move cursor
    int 0x10

	mov ax,[0]			!find cursor info in 0x90000
	call print_hex
	call print_nl


! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Print memory message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#10
	mov	bx,#0x0007		! page 0, attribute 'c' (red)
	mov	bp,#mem
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, we've written the message

	mov ax,[2]			!find mem info in 0x90002
	call print_hex

! Get video-card data:

	mov	ah,#0x0f
	int	0x10
	mov	[4],bx		! bh = display page
	mov	[6],ax		! al = video mode, ah = window width

! check for EGA/VGA and some config parameters

	mov	ah,#0x12
	mov	bl,#0x10
	int	0x10
	mov	[8],ax
	mov	[10],bx
	mov	[12],cx


! Print VGA message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#19
	mov	bx,#0x0007		! page 0, attribute 'c' (red)
	mov	bp,#VGA
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, we've written the message

	mov ax,[10]			!find mem info in 0x9000A
	call print_hex

	mov ax,[12]			!find mem info in 0x9000C
	call print_hex
	call print_nl

! Get hd0 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x41]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0080
	mov	cx,#0x10
	rep
	movsb

! 前面修改了ds寄存器，这里将其设置为0x9000
    mov ax,#INITSEG
    mov ds,ax
    mov ax,#SETUPSEG
    mov es,ax 

! Print hdd message
	mov	ah,#0x03		! read cursor pos
	xor	bh,bh			! bh=page 显示page为0
	int	0x10
	
	mov	cx,#11
	mov	bx,#0x0007		! page 0, attribute 'c' (red)
	mov	bp,#hdd
	mov	ax,#0x1301		! write string, move cursor AH 入口参数 AL显示输出方式
	int	0x10
! ok, we've written the message

	mov ax,[0x80]			!find hdd info in 0x9080
	call print_hex
	call print_nl

! Get hd1 data

	mov	ax,#0x0000
	mov	ds,ax
	lds	si,[4*0x46]
	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	rep
	movsb

! Print disk1 message

! 前面修改了ds寄存器，这里将其设置为0x9000
    mov ax,#INITSEG
    mov ds,ax
    mov ax,#SETUPSEG
    mov es,ax 

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	mov	cx,#9
	mov	bx,#0x0007		! page 0, attribute 'c' (red)
	mov	bp,#disk1
	mov	ax,#0x1301		! write string, move cursor
	int	0x10
! ok, we've written the message

! Check that there IS a hd1 :-)

	mov	ax,#0x01500
	mov	dl,#0x81
	int	0x13
	jc	no_disk1
	cmp	ah,#3
	je	is_disk1

mov ax,#1111
	call print_hex

no_disk1:
	mov ax,#0000
	call print_hex
	call print_nl

	mov	ax,#INITSEG
	mov	es,ax
	mov	di,#0x0090
	mov	cx,#0x10
	mov	ax,#0x00
	rep
	stosb
is_disk1:


! now we want to move to protected mode ...

l: j l   			！死循环

!以16进制方式打印ax寄存器里的16位数
print_hex:
    mov cx,#4   	! 4个十六进制数字
    mov dx,ax   	! 将ax所指的值放入dx中，ax作为参数传递寄存器
print_digit:
    rol dx,#4  		! 循环以使低4比特用上 !! 取dx的高4比特移到低4比特处。
    mov ax,#0xe0f  	! ah = 请求的功能值,al = 半字节(4个比特)掩码。
    and al,dl 		! 取dl的低4比特值。
    add al,#0x30  	! 给al数字加上十六进制0x30
    cmp al,#0x3a
    jl outp  		!是一个不大于十的数字
    add al,#0x07  	!是a~f,要多加7
outp:
    int 0x10
    loop print_digit
    ret

!打印回车换行
print_nl:
    mov ax,#0xe0d
    int 0x10
    mov al,#0xa
    int 0x10
    ret


msg1:						! length 28
	.byte 13,10
	.ascii "Now we are in setup..."
	.byte 13,10,13,10

cur:
    .ascii "Cursor POS:"

mem:						! length:10
	.ascii "memory is:"

hdd:
	.ascii "the hdd is:"	! length 11

VGA:						! length 19
	.ascii "KB"
	.byte 13,10
	.ascii "the display is:"

disk1:						! length 9
	.ascii "is disk1:"


	
.text
endtext:
.data
enddata:
.bss
endbss:
