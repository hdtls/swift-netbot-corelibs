/*
 * Copyright (C) 2023 Joan Lledó <jlledom@member.fsf.org>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
 * SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
 * IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 */

#ifndef HURD_LWIP_POSIX_SOCKET_H
#define HURD_LWIP_POSIX_SOCKET_H

#include <sys/socket.h>
#include <poll.h>
#include <errno.h>
#include LWIP_SOCKET_EXTERNAL_HEADER_INET_H

#ifdef __cplusplus
extern "C" {
#endif

/* sockaddr and pals include length fields */
#if defined(__APPLE__) || defined(__FreeBSD__)
  #define LWIP_SOCKET_HAVE_SA_LEN  1
#endif

#ifndef __SOCKADDR_COMMON_SIZE
  #if LWIP_SOCKET_HAVE_SA_LEN
    #define __SOCKADDR_COMMON_SIZE (sizeof(sa_family_t) + sizeof(uint8_t))
  #else
    #define __SOCKADDR_COMMON_SIZE sizeof(sa_family_t)
  #endif
#endif

#ifdef __APPLE__
  #define s6_addr   __u6_addr.__u6_addr8
  #define s6_addr16 __u6_addr.__u6_addr16
  #define s6_addr32 __u6_addr.__u6_addr32
#endif

#define SIN_ZERO_LEN  sizeof (struct sockaddr) - \
                           __SOCKADDR_COMMON_SIZE - \
                           sizeof (in_port_t) - \
                           sizeof (struct in_addr)

#if !defined IOV_MAX
  #define IOV_MAX 0xFFFF
#elif IOV_MAX > 0xFFFF
  #error "IOV_MAX larger than supported by LwIP"
#endif /* IOV_MAX */

typedef int msg_iovlen_t;

/* cmsg header/data alignment. NOTE: we align to native word size (double word
size on 16-bit arch) so structures are not placed at an unaligned address.
16-bit arch needs double word to ensure 32-bit alignment because socklen_t
could be 32 bits. If we ever have cmsg data with a 64-bit variable, alignment
will need to increase long long */
#define ALIGN_H(size) (((size) + sizeof(long) - 1U) & ~(sizeof(long)-1U))
#define ALIGN_D(size) ALIGN_H(size)

/*
 * Additional options, not kept in so_options.
 */
#define SO_DONTLINGER   ((int)(~SO_LINGER))
#define SO_CONTIMEO     0x1009 /* Unimplemented: connect timeout */
#ifdef __APPLE__
  #define SO_NO_CHECK     0x100a /* don't create UDP checksum */
#endif


/* Flags we can use with send and recv. */
//#define MSG_PEEK       0x01    /* Peeks at an incoming message */
//#define MSG_WAITALL    0x02    /* Unimplemented: Requests that the function block until the full amount of data requested can be returned */
//#define MSG_OOB        0x04    /* Unimplemented: Requests out-of-band data. The significance and semantics of out-of-band data are protocol-specific */
//#define MSG_DONTWAIT   0x08    /* Nonblocking i/o for this operation only */
#ifdef __APPLE__
  #define MSG_MORE       0x10    /* Sender will send more */
#endif
//#define MSG_NOSIGNAL   0x20    /* Uninmplemented: Requests not to send the SIGPIPE signal if an attempt to send is made on a stream-oriented socket that is no longer connected. */

#if LWIP_TCP
/*
 * Options for level IPPROTO_TCP
 */
#if __APPLE__
  #define TCP_KEEPIDLE   0x03    /* set pcb->keep_idle  - Same as TCP_KEEPALIVE, but use seconds for get/setsockopt */
#else
  #define TCP_KEEPALIVE 0x10
#endif
#endif /* LWIP_TCP */

#if LWIP_UDP && LWIP_UDPLITE
/*
 * Options for level IPPROTO_UDPLITE
 */
  #define UDPLITE_SEND_CSCOV 0x01 /* sender checksum coverage */
  #define UDPLITE_RECV_CSCOV 0x02 /* minimal receiver checksum coverage */
#endif /* LWIP_UDP && LWIP_UDPLITE*/


/*
 * Commands for ioctlsocket(),  taken from the BSD file fcntl.h.
 * lwip_ioctl only supports FIONREAD and FIONBIO, for now
 *
 * Ioctl's have the command encoded in the lower word,
 * and the size of any in or out parameters in the upper
 * word.  The high 2 bits of the upper word are used
 * to encode the in/out status of the parameter; for now
 * we restrict parameters to at most 128 bytes.
 */
#if !defined(FIONREAD) || !defined(FIONBIO)
  #define IOCPARM_MASK    0x7fUL          /* parameters must be < 128 bytes */
  #define IOC_VOID        0x20000000UL    /* no parameters */
  #define IOC_OUT         0x40000000UL    /* copy out parameters */
  #define IOC_IN          0x80000000UL    /* copy in parameters */
  #define IOC_INOUT       (IOC_IN|IOC_OUT)
                                          /* 0x20000000 distinguishes new &
                                             old ioctl's */
  #define _IO(x,y)        ((long)(IOC_VOID|((x)<<8)|(y)))

  #define _IOR(x,y,t)     ((long)(IOC_OUT|((sizeof(t)&IOCPARM_MASK)<<16)|((x)<<8)|(y)))

  #define _IOW(x,y,t)     ((long)(IOC_IN|((sizeof(t)&IOCPARM_MASK)<<16)|((x)<<8)|(y)))
#endif /* !defined(FIONREAD) || !defined(FIONBIO) */

#ifndef FIONREAD
  #define FIONREAD    _IOR('f', 127, unsigned long) /* get # bytes to read */
#endif
  #ifndef FIONBIO
  #define FIONBIO     _IOW('f', 126, unsigned long) /* set/clear non-blocking i/o */
#endif

/* commands for fnctl */
#ifndef F_GETFL
  #define F_GETFL 3
#endif
#ifndef F_SETFL
  #define F_SETFL 4
#endif

/* File status flags and file access modes for fnctl,
   these are bits in an int. */
#ifndef O_NONBLOCK
  #define O_NONBLOCK  1 /* nonblocking I/O */
#endif
#ifndef O_NDELAY
  #define O_NDELAY    O_NONBLOCK /* same as O_NONBLOCK, for compatibility */
#endif
#ifndef O_RDONLY
  #define O_RDONLY    2
#endif
#ifndef O_WRONLY
  #define O_WRONLY    4
#endif
#ifndef O_RDWR
  #define O_RDWR      (O_RDONLY|O_WRONLY)
#endif

#ifndef SHUT_RD
  #define SHUT_RD   0
  #define SHUT_WR   1
  #define SHUT_RDWR 2
#endif

/* FD_SET used for lwip_select */
#ifndef FD_SET
  #undef  FD_SETSIZE
  /* Make FD_SETSIZE match NUM_SOCKETS in socket.c */
  #define FD_SETSIZE    MEMP_NUM_NETCONN
  #define LWIP_SELECT_MAXNFDS (FD_SETSIZE + LWIP_SOCKET_OFFSET)
  #define FDSETSAFESET(n, code) do { \
    if (((n) - LWIP_SOCKET_OFFSET < MEMP_NUM_NETCONN) && (((int)(n) - LWIP_SOCKET_OFFSET) >= 0)) { \
    code; }} while(0)
  #define FDSETSAFEGET(n, code) (((n) - LWIP_SOCKET_OFFSET < MEMP_NUM_NETCONN) && (((int)(n) - LWIP_SOCKET_OFFSET) >= 0) ?\
    (code) : 0)
  #define FD_SET(n, p)  FDSETSAFESET(n, (p)->fd_bits[((n)-LWIP_SOCKET_OFFSET)/8] = (u8_t)((p)->fd_bits[((n)-LWIP_SOCKET_OFFSET)/8] |  (1 << (((n)-LWIP_SOCKET_OFFSET) & 7))))
  #define FD_CLR(n, p)  FDSETSAFESET(n, (p)->fd_bits[((n)-LWIP_SOCKET_OFFSET)/8] = (u8_t)((p)->fd_bits[((n)-LWIP_SOCKET_OFFSET)/8] & ~(1 << (((n)-LWIP_SOCKET_OFFSET) & 7))))
  #define FD_ISSET(n,p) FDSETSAFEGET(n, (p)->fd_bits[((n)-LWIP_SOCKET_OFFSET)/8] &   (1 << (((n)-LWIP_SOCKET_OFFSET) & 7)))
  #define FD_ZERO(p)    memset((void*)(p), 0, sizeof(*(p)))

  typedef struct fd_set
  {
    unsigned char fd_bits [(FD_SETSIZE+7)/8];
  } fd_set;

#elif FD_SETSIZE < (LWIP_SOCKET_OFFSET + MEMP_NUM_NETCONN)
  #error "external FD_SETSIZE too small for number of sockets"
#else
  #define LWIP_SELECT_MAXNFDS FD_SETSIZE
#endif /* FD_SET */

/* poll-related defines and types */
/* @todo: find a better way to guard the definition of these defines and types if already defined */
#if !defined(POLLIN) && !defined(POLLOUT)
  #define POLLIN     0x1
  #define POLLOUT    0x2
  #define POLLERR    0x4
  #define POLLNVAL   0x8
  /* Below values are unimplemented */
  #define POLLRDNORM 0x10
  #define POLLRDBAND 0x20
  #define POLLPRI    0x40
  #define POLLWRNORM 0x80
  #define POLLWRBAND 0x100
  #define POLLHUP    0x200
  typedef unsigned int nfds_t;
  struct pollfd
  {
    int fd;
    short events;
    short revents;
  };
#endif

#ifdef __cplusplus
}
#endif

#endif /* HURD_LWIP_POSIX_SOCKET_H */
