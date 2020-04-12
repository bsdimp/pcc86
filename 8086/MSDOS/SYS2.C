#include <sgtty.h>

/* system call writearounds for MSDOS 2.0
 */

#define	SHORT(XX) (*((short *) XX))
#define	LONG(XX)  (*((long  *) XX))

dos_ini()
 {
 }

/* Close all open files.  Called by _exit.
 */

_dos_cleanup()
 {
 }

int isatty(fid)
 {
	return(-1);
 }

char *sbrk(incr)
  {	char a[1];
	extern char *_memtop;	/* current top of user data */
	register char *p,*q;

	q = _memtop;		/* answer if we succeed */
	if (((int) q) & 1) q++;	/* SAW: malloc seems to want int align	*/

	p = &q[(incr+1)&~1];	/* new top of user data */

	/* allocation succeeds if we didn't wrap around, and if we
	 * are still below stack.
	 */
	if (p >= _memtop && p < &a[-64])
	 { _memtop = p;
	   return(q);
	 }

	return ((char *) -1);
 }

ioctl(fid,request,argp)
 {	register struct _fcb *f;

	prints("***ioctl call ignored\r\n");
	return(-1);
 }
