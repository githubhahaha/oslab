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
!SYSSEG   = 0x1000	! system loaded at 0x10000 (65536).
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
	mov	ax,cs
	mov	ds,ax
	mov	es,ax
! Print some inane message

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	
	
	mov	cx,#23
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#msg2
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

! ok, the read went well so we get current cursor position and save it for
! posterity.

	mov	ax,#INITSEG	! this is done in bootsect already, but...
	mov	ds,ax
	mov	ah,#0x03	! read cursor pos
	xor	bh,bh
	int	0x10		! save it in known place, con_init fetches
	mov	[0],dx		! it from 0x90000.

! Print cursor info

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#9
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#cur
	mov	ax,#0x1301		! write string, move cursor
	int	0x10


	mov ax,[0]
	call print_hex
	call print_nl

! Get memory size (extended mem, kB)

	mov	ah,#0x88
	int	0x15
	mov	[2],ax

! Print memory info

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#9
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#mem
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

	mov ax,[2]
	call print_hex

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#2
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#danwei
	mov	ax,#0x1301		! write string, move cursor
	int	0x10
	call print_nl


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

! Print vedio-card info

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#8
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#vedio
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

	mov ax,[10]
	call print_hex
	mov ax,[12]
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

	mov ax,#INITSEG
	mov ds,ax
	mov ax,#SETUPSEG
	mov es,ax

! Print HD info

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#10
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#cyl
	mov	ax,#0x1301		! write string, move cursor
	int	0x10

	!显示具体信息
	mov ax,[0x80]
	call print_hex
	call print_nl

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#8
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#head
	mov	ax,#0x1301		! write string, move cursor
	int	0x10
	
	mov ax,[0x80+0x02]
	call print_hex
	call print_nl

	mov	ah,#0x03		! read cursor pos
	xor	bh,bh
	int	0x10
	mov	cx,#8
	mov bx,#0x000c		! page 0, atrribute c (red)
	mov	bp,#sect
	mov	ax,#0x1301		! write string, move cursor
	int	0x10
	
	mov ax,[0x80+0x0e]
	call print_hex
	call print_nl


inf_j:
	jmp inf_j

! print devices' hex info
print_hex:
	mov cx,#4
	mov dx,ax

print_digit:
	rol dx,#4
	mov ax,#0xe0f
	and al,dl
	add al,#0x30
	cmp al,#0x3a
	jl  outp
	add al,#0x07

outp:
	int 0x10
	loop print_digit
	ret

print_nl:
	mov ax,#0xe0d	!CR
	int 0x10
	mov al,#0xa		!LF
	int 0x10
	ret



msg2:
	.byte 13,10
	.ascii "Now we are in SETUP"	!19
	.byte 13,10
mem:
	.byte 13,10
	.ascii "memory:"	!9
danwei:
	.ascii "KB"			!2

cur:
	.byte 13,10
	.ascii "cursor:"	!9

vedio:
	.ascii "VD Info:"	!8

hd_info:
	.ascii "HD Info:"	!8

cyl:
	.ascii "Cylinders:"	!10

head:
	.ascii "Headers:"	!8
sect:
	.ascii "Secotrs:"	!8


.text
endtext:
.data
enddata:
.bss
endbss:
