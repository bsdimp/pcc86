| Some global data locations:

	.data
	.globl	__dosax,__dosbx,__doscx,__dosdx
__dosax:	.byte	0,0
__dosbx:	.byte	0,0
__doscx:	.byte	0,0
__dosdx:	.byte	0,0

cmdbuf:		.byte	0	| Used by "system" call.
. = .+0x80
cmdbu1:		.ascii	"COMMAND -C"	| Prototype.
		.byte	0
shell:		.ascii	"/BIN/COMMAND.COM"
		.byte	0
		.even
pblk:		.word	0		| env string seg ptr
pbcmd:		.word	0,0		| cmdbuf ptr
pbfcb1:		.word	0,0		| 1st FCB ptr
pbfcb2:		.word	0,0

	.text
| _exec("path", *paramblk, fnval)

	.globl	__exec
__exec:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	bx,6(bp)
	mov	al,8(bp)
	mov	ah,#0x4b
cdos:	int	0x21

| Fall thru to...

| Common error handling code: returns >= 0 in AX iff no err, else returns
|   -(error code):

cyerr:	jb	cyerr1		| An error happened.
	or	ax,ax		| Make sure AX is non-negative
	jge	cyerr2
cyerr1:	neg	ax		| if neg, negate it.
cyerr2:	mov	__dosax,ax
	mov	__dosbx,bx
	mov	__doscx,cx
	mov	__dosdx,dx

	pop	si
	pop	di
	pop	bp
	ret			| return to caller.

| system(cmd) -- Execute COMMAND.COM -ccmd
	.globl	_system
_system:
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	push	es
	seg	cs
	mov	sssave,ss
	seg	cs
	mov	spsave,sp

	mov	ax,ds			| Fill in pblk.
	mov	pbcmd+2,ax
	mov	pbcmd,#cmdbuf
	mov	al,*0
	mov	cmdbuf,al		| char count.
	mov	bx,#cmdbu1		| command prefix.
	call	sys1			| fill it in.
	mov	bx,4(bp)
	call	sys1

	mov	dx,#shell
	mov	bx,#pblk
	mov	al,#0
	mov	ah,#0x4B
	int	0x21

	cli
	seg	cs
	mov	sp,spsave
	seg	cs
	mov	ss,sssave
	pop	es
	pop	ds
	sti
	pop	si
	pop	di
	pop	bp
	ret

| internal saved stack pointer:
sssave:	.word	0
spsave:	.word	0

| internal: copy .asciz string from *bx++ into combuf:

sys1:	mov	di,#cmdbuf+1
	mov	ax,#0
	mov	al,cmdbuf
	add	di,ax
sys11:	mov	al,(bx)
	inc	bx
	or	al,al
	jz	sys12
	mov	(di),al
	inc	di
	mov	al,cmdbuf
	inc	al
	mov	cmdbuf,al
	jmp	sys11
sys12:	ret

| Copy the nth environment variable into *cc++:
| _genv(n, cc)

	.globl	__genv
__genv:	push	bp
	mov	bp,sp
	push	bx
	push	es
	push	di

	mov	bx,0x2c			| pp ptr to environment.
	mov	es,bx
	mov	di,6(bp)		| target location.
	mov	cx,4(bp)		| count.
	mov	bx,0
	mov	(di),bl			| default: null string.

genv1:	or	cx,cx			| n = 0?
	jeq	genv8			| yup, found it.
	dec	cx
	seg	es
	mov	al,(bx)
	or	al,al			| end of env?
	jeq	genv8			| yup, copy in null string.
genv3:	inc	bx			| look for end of string.
	mov	al,(bx)
	or	al,al
	jne	genv3
	jmp	genv1


| _fdate(fid, &dtime, code); short dtime[2]; 
| sets if code = 1, gets if code0.

	.globl	__fdate

__fdate:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	bx,4(bp)
	mov	al,8(bp)
	mov	bp,6(bp)
	mov	ah,#0x57
	mov	dx,(bp)
	mov	cx,2(bp)
	int	0x21
	mov	(bp),dx
	mov	2(bp),cx
	jmp	cyerr

| rename(from, to)
	.globl	_rename
_rename:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	di,6(bp)
	mov	ah,0x56
	int	0x21
	jmp	cyerr

| code = _wait()
	.globl	__wait
__wait:	mov	ah,0x4D
	int	0x21
	ret

| __exit(code)
	.globl	___exit
___exit:
	mov	bp,sp
	mov	al,2(bp)
	mov	ah,0x4C
	int	0x21

| _dir1st("path", attr)
	.globl	__dir1st
__dir1st:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	cx,6(bp)
	mov	ah,#0x4E
	int	0x21
	jmp	cyerr

| _dirnxt()
	.globl	__dirnxt
__dirnxt:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	ah,#0x4F
	int	0x21
	jmp	cyerr

| err = _adjblk(seg, newsize); _dosbx = max size on error.
	.globl	__adjblk
__adjblk:
	push	bp
	mov	bp,sp
	push	di
	push	si

	push	es
	mov	ax,4(bp)
	mov	es,ax
	mov	bx,6(bp)
	mov	ah,#0x4A
	int	0x21
	pop	es
	jmp	cyerr

| err = _freblk(seg);
	.globl	__freblk
__freblk:
	push	bp
	mov	bp,sp
	push	di
	push	si

	push	es
	mov	ax,4(bp)
	mov	es,ax
	mov	ah,#0x49
	int	0x21
	pop	es
	jmp	cyerr

| seg = _allblk(size); returns 0 on error (whence see _dosbx for largest
|   available block).

	.globl	__allblk
__allblk:
	push	bp
	mov	bp,sp

	push	es
	mov	bx,4(bp)
	mov	ah,#0x48
	int	0x21
	jnb	allbl1		| no error.
	mov	ax,#0
	mov	es,ax
allbl1:	mov	ax,es
	pop	es
	ret

| _getcd(drive, buf); char buf[64];
	.globl	__getcd
__getcd:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dl,4(bp)
	mov	si,6(bp)
	mov	ah,#0x47
	jmp	cdos

| _fdup(fid, newfid)
	.globl	__fdup
__fdup:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	ah,#0x46
	mov	bx,4(bp)
	mov	cx,6(bp)
	jmp	cdos

| newfid = dup(fid)
	.globl	_dup
_dup:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	ah,#0x45
	mov	bx,4(bp)
	jmp	cdos

| _ioctl(al, bx, cx, dx)
	.globl	__ioctl
__ioctl:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	al,4(bp)
	mov	ah,#0x44
	mov	bx,6(bp)
	mov	cx,8(bp)
	mov	dx,10(bp)
	jmp	cdos

| _fattr(code, "path", mode) - get (code=0) or set (code=1) file attribute
|  If code=0, attr returned in _doscx.
	.globl	__fattr
__fattr:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	al,4(bp)
	mov	dx,6(bp)
	mov	cx,8(bp)
	mov	ah,#0x43
	jmp	cdos

| (long) err = lseek(fid, offset, whence); long offset;
	.globl	_lseek
_lseek:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	bx,4(bp)
	mov	dx,6(bp)
	mov	cx,8(bp)		| most sig part
	mov	al,10(bp)
	mov	ah,#0x42
	int	0x21
	jnb	lseek1
	mov	dx,#-1			| Make a long negative return.
lseek1:	jmp	cyerr

| unlink("path")
	.globl	_unlink
_unlink:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	ah,#0x41
	jmp	cdos

| write(fid, buf, nbytes)
	.globl	_write
_write:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	bx,4(bp)
	mov	dx,6(bp)
	mov	cx,8(bp)
	mov	ah,#0x40
	jmp	cdos

| read(fid, buf, nbytes)
	.globl	_read
_read:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	bx,4(bp)
	mov	dx,6(bp)
	mov	cx,8(bp)
	mov	ah,#0x3F
	jmp	cdos

| close(fid)
	.globl	_close
_close:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	bx,4(bp)
	mov	ah,0x3E
	jmp	cdos

| open("path", how)
	.globl	_open
_open:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	al,6(bp)
	mov	ah,#0x3D
	jmp	cdos

| creat("path", attr)
	.globl	_creat
_creat:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
|	mov	cx,6(bp)
	mov	cx,#0		| Make things work, for now...
	mov	ah,#0x3C
	jmp	cdos

| chdir("path")
	.globl	_chdir
_chdir:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	ah,#0x3B
	jmp	cdos

| rmdir("path")
	.globl	_rmdir
_rmdir:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	ah,#0x3A
	jmp	cdos

| mkdir("path")
	.globl	_mkdir
_mkdir:	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	dx,4(bp)
	mov	ah,#0x39
	jmp	cdos

| _resid(code) -- terminate, stay resident.

	.globl	__resid
__resid:
	push	bp
	mov	bp,sp
	push	di
	push	si

	mov	ax,__memtop		| Compute current size, in parags.
	add	ax,#0xF			| Round up.
	mov	cl,*4
	shr	ax,cl
	jne	resid1
	mov	ax,#0x1000		| Full data segment.
resid1:	mov	bx,ax			| size of data seg, in pp.
	mov	dx,ds
	mov	cx,cs			| Add size of code seg.
	sub	ax,cx
	add	dx,ax			| Total memory size.

	mov	al,4(bp)		| exit code
	mov	ah,#0x31
	jmp	cdos

