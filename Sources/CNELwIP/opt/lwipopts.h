/**
 * @file
 *
 * lwIP Options Configuration
 */

/*
 * Copyright (c) 2001-2004 Swedish Institute of Computer Science.
 * All rights reserved.
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
 *
 * This file is part of the lwIP TCP/IP stack.
 *
 * Author: Adam Dunkels <adam@sics.se>
 *
 */
#ifndef LWIP_LWIPOPTS_H
#define LWIP_LWIPOPTS_H

/*
 * Include user defined options first. Anything not defined in these files
 * will be set to standard values. Override anything you dont like!
 */

#ifdef __APPLE__
#include <machine/endian.h>
#else
#include <endian.h>
#endif

#define LWIP_SOCKET_EXTERNAL_HEADERS 1
#define LWIP_SOCKET_EXTERNAL_HEADER_SOCKETS_H "posix/sockets.h"
#define LWIP_SOCKET_EXTERNAL_HEADER_INET_H "posix/inet.h"

#define ip6_hdr LWIP_ip6_hdr
#define icmp6_hdr LWIP_icmp6_hdr

#define LWIP_ERR_T err_enum_t

#define LWIP_IPV6 1

#define TCP_LISTEN_BACKLOG 1

#define TCP_MSS 512

#define MEM_LIBC_MALLOC 1
#define MEMP_MEM_MALLOC 1
#define MEM_USE_POOLS 0

#if defined __LP64__
#define MEM_ALIGNMENT 8
#else
#define MEM_ALIGNMENT 4
#endif

#define LWIP_NOASSERT_ON_ERROR 1

#define LWIP_TCPIP_CORE_LOCKING_INPUT 1

#define LWIP_RAW 1

#define LWIP_UDP 1

#define LWIP_TCP 1

#define LWIP_NETCONN 0

#define LWIP_SOCKET 0

#if defined(LWIP_DEBUG)

#define NETIF_DEBUG LWIP_DBG_ON

#define PBUF_DEBUG LWIP_DBG_ON

#define ICMP_DEBUG LWIP_DBG_ON

#define INET_DEBUG LWIP_DBG_ON

#define IP_DEBUG LWIP_DBG_ON

#define IP_REASS_DEBUG LWIP_DBG_ON

#define RAW_DEBUG LWIP_DBG_ON

#define MEM_DEBUG LWIP_DBG_ON

#define MEMP_DEBUG LWIP_DBG_ON

#define SYS_DEBUG LWIP_DBG_ON

#define TIMERS_DEBUG LWIP_DBG_ON

#define TCP_DEBUG LWIP_DBG_ON

#define TCP_INPUT_DEBUG LWIP_DBG_ON

#define TCP_FR_DEBUG LWIP_DBG_ON

#define TCP_RTO_DEBUG LWIP_DBG_ON

#define TCP_CWND_DEBUG LWIP_DBG_ON

#define TCP_WND_DEBUG LWIP_DBG_ON

#define TCP_OUTPUT_DEBUG LWIP_DBG_ON

#define TCP_RST_DEBUG LWIP_DBG_ON

#define TCP_QLEN_DEBUG LWIP_DBG_ON

#define UDP_DEBUG LWIP_DBG_ON

#define TCPIP_DEBUG LWIP_DBG_ON

#define DNS_DEBUG LWIP_DBG_ON

#define IP6_DEBUG LWIP_DBG_ON

#endif

void sys_check_core_locking(void);
#define LWIP_ASSERT_CORE_LOCKED() sys_check_core_locking()

#endif /* LWIP_LWIPOPTS_H */
