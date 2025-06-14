//
// See LICENSE.txt for license information
//

#ifndef C_NE_LWIP_DEBUG_H
#define C_NE_LWIP_DEBUG_H

  #if defined __APPLE__
    #include <os/log.h>

    static os_log_t OS_LOG_CNELwIP;

    __attribute__((constructor))
    static void CNELwIP_log_init() {
      OS_LOG_CNELwIP = os_log_create("com.tenbits.netbot.packet-tunnel.extension", "lwip-tcpip");
    }

    static void CNELwIP_log_with_type(os_log_type_t type, const char *format, ...) {
      va_list args;
      va_start(args, format);

      char message[256];  // Adjust size as needed
      vsnprintf(message, sizeof(message), format, args);
      os_log_with_type(OS_LOG_CNELwIP, type, "%{public}s", message);

      va_end(args);
    }

    static void CNELwIP_log(const char *fmt, ...) {
      va_list args;
      va_start(args, fmt);
      int capacity = vsnprintf(NULL, 0, fmt, args);
      va_end(args);

      va_start(args, fmt);
      char message[capacity + 1];  // Adjust size as needed
      vsnprintf(message, sizeof(message), fmt, args);
      va_end(args);

      os_log_with_type(OS_LOG_CNELwIP, OS_LOG_TYPE_DEBUG, "%{public}s", message);
    }

    #ifndef LWIP_PLATFORM_DIAG
      #define LWIP_PLATFORM_DIAG(x) do {CNELwIP_log x;} while(0)
    #endif

    #ifndef LWIP_PLATFORM_ASSERT
      #define LWIP_PLATFORM_ASSERT(x) do {CNELwIP_log_with_type(OS_LOG_TYPE_FAULT, x); fflush(NULL); abort();} while(0)
      #include <stdio.h>
    #endif

    #ifndef LWIP_ERROR
      #ifdef LWIP_DEBUG
        #define LWIP_PLATFORM_ERROR(message) do {CNELwIP_log_with_type(OS_LOG_TYPE_ERROR, message);} while(0)
      #else
        #define LWIP_PLATFORM_ERROR(message)
      #endif

      /* if "expression" isn't true, then print "message" and execute "handler" expression */
      #define LWIP_ERROR(message, expression, handler) do { if (!(expression)) { \
        LWIP_PLATFORM_ERROR(message); handler;}} while(0)
    #endif /* LWIP_ERROR */
  #endif

  // Debugging options
  #define LWIP_DEBUG 0

  #if LWIP_DEBUG
//    #define IP_DEBUG LWIP_DBG_ON

//    #define IP_REASS_DEBUG LWIP_DBG_ON

//    #define IP6_DEBUG LWIP_DBG_ON

//    #define TCP_DEBUG LWIP_DBG_ON
//
//    #define TCP_INPUT_DEBUG LWIP_DBG_ON

//    #define TCP_FR_DEBUG LWIP_DBG_ON

//    #define TCP_RTO_DEBUG LWIP_DBG_ON

//    #define TCP_CWND_DEBUG LWIP_DBG_ON

//    #define TCP_WND_DEBUG LWIP_DBG_ON

//    #define TCP_OUTPUT_DEBUG LWIP_DBG_ON

//    #define TCP_RST_DEBUG LWIP_DBG_ON

//    #define TCP_QLEN_DEBUG LWIP_DBG_ON

    #define MEM_DEBUG 1
    #define MEMP_DEBUG 1
    #define MEM_STATS 1
    #define MEMP_STATS 1
    #define PBUF_STATS 1
    #define SYS_STATS 1
    #define LWIP_STATS 1

    #define LWIP_STATS_DISPLAY 1
    #define UDP_DEBUG LWIP_DBG_ON
    #define MEM_SANITY_CHECK 1
    #define MEM_OVERFLOW_CHECK 2
    #define MEMP_SANITY_CHECK 1
    #define MEMP_OVERFLOW_CHECK 2
  #endif

#endif /* C_NE_LWIP_DEBUG_H */
