#ifndef LWIP_LWIPOPTS_H
#define LWIP_LWIPOPTS_H
/*
 * Include user defined options first. Anything not defined in these files
 * will be set to standard values. Override anything you dont like!
 */

#include "debug.h"

// Core locking
#define LWIP_TCPIP_CORE_LOCKING_INPUT 1

// IP options
#define LWIP_IPV6 1
#define LWIP_IP4 1

// TCP options
#define TCP_MSS 512
#define TCP_LISTEN_BACKLOG 1

// Memory options
#define MEM_ALIGNMENT 8
#if defined __APPLE__
#define MEM_LIBC_MALLOC 1
#define MEMP_MEM_MALLOC 1
#elif defined __ANDROID__
#define MEM_LIBC_MALLOC 1
#define MEMP_MEM_MALLOC 0
#else
#define MEM_LIBC_MALLOC 0
#define MEMP_MEM_MALLOC 0
#endif

// Network interfaces options
#define LWIP_SINGLE_NETIF 1

// Sequential layer options
#define LWIP_NETCONN 0
#define LWIP_TCPIP_TIMEOUT 1

// Socket options
#define LWIP_TCP_KEEPALIVE 1

// Checksum options
#define LWIP_CHECKSUM_ON_COPY 1

#define LWIP_HAVE_SLIPIF 1
#define SLIP_MAX_SIZE 1500

#define LWIP_ERRNO_STDINCLUDE 1

#define LWIP_SOCKET_EXTERNAL_HEADERS 1
#define LWIP_SOCKET_EXTERNAL_HEADER_SOCKETS_H "posix/sockets.h"
#define LWIP_SOCKET_EXTERNAL_HEADER_INET_H "posix/inet.h"
#define ip6_hdr CNELwIP_ip6_hdr
#define icmp6_hdr CNELwIP_icmp6_hdr
#define LWIP_ERR_T err_enum_t

void sys_check_core_locking(void);
#define LWIP_ASSERT_CORE_LOCKED() sys_check_core_locking()

#endif /* LWIP_LWIPOPTS_H */
