//
// See LICENSE.txt for license information
//

#ifndef CNETTP_h
#define CNETTP_h

#include <stdbool.h>
#include <stdint.h>

typedef enum cnettp_dns_strategy {
  cnettp_dns_strategy_over_virtual_dns_server = 0,
  cnettp_dns_strategy_over_tcp,
  cnettp_dns_strategy_relying_on_server_bypassing
} cnettp_dns_strategy;

typedef enum cnettp_log_level {
  cnettp_log_level_off = 0,
  cnettp_log_level_error,
  cnettp_log_level_warn,
  cnettp_log_level_info,
  cnettp_log_level_debug,
  cnettp_log_level_trace
} cnettp_log_level;

int CNETTP_tunnel_provider_start_tunnel_with_options(int tun_fd, const char *protocol, const char *listen_addr, unsigned short port, unsigned short mtu, enum cnettp_dns_strategy dns_strategy, enum cnettp_log_level log_level);

int CNETTP_tunnel_provider_stop_tunnel(void);

#endif /* CNETTP_h */
