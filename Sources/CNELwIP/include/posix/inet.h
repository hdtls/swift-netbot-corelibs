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

#ifndef HURD_LWIP_POSIX_INET_H
#define HURD_LWIP_POSIX_INET_H

#include <arpa/inet.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#if __has_include(<linux/udp.h>)
#include <linux/udp.h>
#else
#include <netinet/udp.h>
#endif
#include <sys/ioctl.h>
#include <fcntl.h>
#include <net/if.h>

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __APPLE__
  #define IPPROTO_UDPLITE 136
#endif

/*
 * The Type of Service provides an indication of the abstract
 * parameters of the quality of service desired.  These parameters are
 * to be used to guide the selection of the actual service parameters
 * when transmitting a datagram through a particular network.  Several
 * networks offer service precedence, which somehow treats high
 * precedence traffic as more important than other traffic (generally
 * by accepting only traffic above a certain precedence at time of high
 * load).  The major choice is a three way tradeoff between low-delay,
 * high-reliability, and high-throughput.
 * The use of the Delay, Throughput, and Reliability indications may
 * increase the cost (in some sense) of the service.  In many networks
 * better performance for one of these parameters is coupled with worse
 * performance on another.  Except for very unusual cases at most two
 * of these three indications should be set.
 */
#define IPTOS_TOS_MASK          0x1E
#define IPTOS_TOS(tos)          ((tos) & IPTOS_TOS_MASK)
#define IPTOS_LOWCOST           0x02

/*
 * The Network Control precedence designation is intended to be used
 * within a network only.  The actual use and control of that
 * designation is up to each network. The Internetwork Control
 * designation is intended for use by gateway control originators only.
 * If the actual use of these precedence designations is of concern to
 * a particular network, it is the responsibility of that network to
 * control the access to, and use of, those precedence designations.
 */
#define IPTOS_PREC_MASK                 0xe0
#define IPTOS_PREC(tos)                ((tos) & IPTOS_PREC_MASK)

#if LWIP_IGMP
  /*
   * Options and types related to multicast membership
   */
  #define IP_ADD_MEMBERSHIP  3
  #define IP_DROP_MEMBERSHIP 4

  typedef struct ip_mreq {
      struct in_addr imr_multiaddr; /* IP multicast address of group */
      struct in_addr imr_interface; /* local IP address of interface */
  } ip_mreq;
#endif /* LWIP_IGMP */

#if LWIP_IPV4

#define inet_addr_from_ip4addr(target_inaddr, source_ipaddr) ((target_inaddr)->s_addr = ip4_addr_get_u32(source_ipaddr))
#define inet_addr_to_ip4addr(target_ipaddr, source_inaddr)   (ip4_addr_set_u32(target_ipaddr, (source_inaddr)->s_addr))

#ifdef LWIP_UNIX_HURD
#define IP_PKTINFO  8

struct in_pktinfo {
  unsigned int   ipi_ifindex;  /* Interface index */
  struct in_addr ipi_addr;     /* Destination (from header) address */
};
#endif /* LWIP_UNIX_HURD */

#endif /* LWIP_IPV4 */

#if LWIP_IPV6
#define inet6_addr_from_ip6addr(target_in6addr, source_ip6addr) {(target_in6addr)->s6_addr32[0] = (source_ip6addr)->addr[0]; \
                                                                 (target_in6addr)->s6_addr32[1] = (source_ip6addr)->addr[1]; \
                                                                 (target_in6addr)->s6_addr32[2] = (source_ip6addr)->addr[2]; \
                                                                 (target_in6addr)->s6_addr32[3] = (source_ip6addr)->addr[3];}
#define inet6_addr_to_ip6addr(target_ip6addr, source_in6addr)   {(target_ip6addr)->addr[0] = (source_in6addr)->s6_addr32[0]; \
                                                                 (target_ip6addr)->addr[1] = (source_in6addr)->s6_addr32[1]; \
                                                                 (target_ip6addr)->addr[2] = (source_in6addr)->s6_addr32[2]; \
                                                                 (target_ip6addr)->addr[3] = (source_in6addr)->s6_addr32[3]; \
                                                                 ip6_addr_clear_zone(target_ip6addr);}
/* ATTENTION: the next define only works because both in6_addr and ip6_addr_t are an u32_t[4] effectively! */
#define inet6_addr_to_ip6addr_p(target_ip6addr_p, source_in6addr)   ((target_ip6addr_p) = (ip6_addr_t*)(source_in6addr))
#endif /* LWIP_IPV6 */

#ifdef __cplusplus
}
#endif

#endif /* HURD_LWIP_POSIX_INET_H */
