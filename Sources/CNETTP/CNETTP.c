//
// See LICENSE.txt for license information
//

#if __APPLE__
#include "CNETTP.h"
#include <SystemConfiguration/SystemConfiguration.h>
#include <tun2proxy.h>

int CNETTP_tunnel_provider_start_tunnel_with_options(int tun_fd, const char *protocol, const char *listen_addr, unsigned short port, unsigned short mtu, enum cnettp_dns_strategy dns_strategy, enum cnettp_log_level log_level) {
  size_t buffer_size = strlen(protocol) + strlen(listen_addr) + 24;
//  char* proxy_url = (char*)malloc(buffer_size);
  char proxy_url[buffer_size];
  sprintf(proxy_url, "%s://%s:%u", protocol, listen_addr, port);
//  snprintf(proxy_url, sizeof(proxy_url), "%s://%s:%u", protocol, listen_addr, port);

  enum Tun2proxyDns _dns_strategy = Tun2proxyDns_Virtual;
  switch (dns_strategy) {
      case 0:
        break;
      case 1:
      _dns_strategy = Tun2proxyDns_OverTcp;
        break;
      case 2:
      _dns_strategy = Tun2proxyDns_Direct;
      break;
    }

  enum Tun2proxyVerbosity verbosity = Tun2proxyVerbosity_Off;
  switch (log_level) {
    case 0:
      break;
    case 1:
      verbosity = Tun2proxyVerbosity_Error;
      break;
    case 2:
      verbosity = Tun2proxyVerbosity_Warn;
      break;
    case 3:
      verbosity = Tun2proxyVerbosity_Info;
      break;
    case 4:
      verbosity = Tun2proxyVerbosity_Debug;
      break;
    case 5:
      verbosity = Tun2proxyVerbosity_Trace;
      break;
  }

  return tun2proxy_with_fd_run(proxy_url, tun_fd, false, true, mtu, _dns_strategy, verbosity);
}

int CNETTP_tunnel_provider_stop_tunnel(void) {
  return tun2proxy_with_fd_stop();
}
#endif
