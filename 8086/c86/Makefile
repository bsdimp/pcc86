# make clang like this old old code
PROG=	c86
CFLAGS=-O -g \
	-Wno-array-bounds \
	-Wno-comment \
	-Wno-format \
	-Wno-implicit-function-declaration \
	-Wno-implicit-int \
	-Wno-incompatible-pointer-types \
	-Wno-int-conversion \
	-Wno-parentheses \
	-Wno-return-type

SRCS= trees.c optim.c pftn.c code.c local.c scan.c xdefs.c cgram.y \
	reader.c order.c match.c allo.c comm1.c local2.c table.c
MAN1=

.include <bsd.prog.mk>
