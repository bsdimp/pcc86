.SUFFIXES: .b
.c.b: ; ncc86 -c $<

OBJECTS =	abs.b atoi.b blt.b atof.b atol.b  calloc.b crypt.b\
		ctime.b ctype_.b cuexit.b ecvt.b errlst.b execvp.b clear.b\
		getenv.b getlogin.b index.b l3.b\
		malloc.b mfill.b frexp.b\
		mktemp.b mon.b perror.b qsort.b rand.b\
		rindex.b sleep.b strcat.b strcatn.b strcmp.b strcmpn.b\
		strcpy.b strcpyn.b strlen.b strncat.b strncmp.b strncpy.b\
		stty.b swab.b tell.b timezone.b ttyname.b ttyslot.b\
		setjmp.b

all:		$(OBJECTS)

blt.b:		blt.a86
		a86 blt

clear.b:	clear.a86
		a86 clear

mfill.b:	mfill.a86
		a86 mfill

setjmp.b:	setjmp.a86
		a86 setjmp
