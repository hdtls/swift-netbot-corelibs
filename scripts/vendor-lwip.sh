#!/bin/bash
##
## See LICENSE.txt for license information
##

set -eou pipefail

HERE=$(pwd)
DSTROOT=Sources/CNELwIP
TMPDIR=$(mktemp -d)
SRCROOT="${TMPDIR}/src/savannah.gnu.org/lwip"

case "$(uname -s)" in
    Darwin)
        sed=gsed
        ;;
    *)
        # shellcheck disable=SC2209
        sed=sed
        ;;
esac

if ! hash ${sed} 2>/dev/null; then
    echo "You need sed \"${sed}\" to run this script ..."
    echo
    echo "On macOS: brew install gnu-sed"
    exit 43
fi

echo "REMOVING any previously-vendored LwIP code"
rm -rf $DSTROOT/include
rm -rf $DSTROOT/port
rm -rf $DSTROOT/src

echo "CLONING LwIP"
mkdir -p "$SRCROOT"
git clone https://git.savannah.gnu.org/git/lwip.git "$SRCROOT"
cd "$SRCROOT"
LWIP_REVISION=$(git rev-parse HEAD)
cd "$HERE"
echo "CLONED lwip@${LWIP_REVISION}"

PATTERNS=(
'src/core/init.c'
'src/core/def.c'
'src/core/dns.c'
'src/core/inet_chksum.c'
'src/core/ip.c'
'src/core/mem.c'
'src/core/memp.c'
'src/core/netif.c'
'src/core/pbuf.c'
'src/core/raw.c'
'src/core/stats.c'
'src/core/sys.c'
'src/core/altcp.c'
'src/core/altcp_alloc.c'
'src/core/altcp_tcp.c'
'src/core/tcp.c'
'src/core/tcp_in.c'
'src/core/tcp_out.c'
'src/core/timeouts.c'
'src/core/udp.c'

'src/core/ipv4/acd.c'
'src/core/ipv4/autoip.c'
'src/core/ipv4/dhcp.c'
'src/core/ipv4/etharp.c'
'src/core/ipv4/icmp.c'
'src/core/ipv4/igmp.c'
'src/core/ipv4/ip4_frag.c'
'src/core/ipv4/ip4.c'
'src/core/ipv4/ip4_addr.c'

'src/core/ipv6/dhcp6.c'
'src/core/ipv6/ethip6.c'
'src/core/ipv6/icmp6.c'
'src/core/ipv6/inet6.c'
'src/core/ipv6/ip6.c'
'src/core/ipv6/ip6_addr.c'
'src/core/ipv6/ip6_frag.c'
'src/core/ipv6/mld6.c'
'src/core/ipv6/nd6.c'

'src/api/api_lib.c'
'src/api/api_msg.c'
'src/api/err.c'
'src/api/if_api.c'
'src/api/netbuf.c'
'src/api/netdb.c'
'src/api/netifapi.c'
'src/api/sockets.c'
'src/api/tcpip.c'

'src/netif/ethernet.c'
'src/netif/bridgeif.c'
'src/netif/bridgeif_fdb.c'
#'src/netif/slipif.c'

'src/netif/lowpan6_common.c'
'src/netif/lowpan6.c'
'src/netif/lowpan6_ble.c'
'src/netif/zepif.c'

'src/netif/ppp/auth.c'
'src/netif/ppp/ccp.c'
'src/netif/ppp/chap-md5.c'
'src/netif/ppp/chap_ms.c'
'src/netif/ppp/chap-new.c'
'src/netif/ppp/demand.c'
'src/netif/ppp/eap.c'
'src/netif/ppp/ecp.c'
'src/netif/ppp/eui64.c'
'src/netif/ppp/fsm.c'
'src/netif/ppp/ipcp.c'
'src/netif/ppp/ipv6cp.c'
'src/netif/ppp/lcp.c'
'src/netif/ppp/magic.c'
'src/netif/ppp/mppe.c'
'src/netif/ppp/multilink.c'
'src/netif/ppp/ppp.c'
'src/netif/ppp/pppapi.c'
'src/netif/ppp/pppcrypt.c'
'src/netif/ppp/pppoe.c'
'src/netif/ppp/pppol2tp.c'
'src/netif/ppp/pppos.c'
'src/netif/ppp/upap.c'
'src/netif/ppp/utils.c'
'src/netif/ppp/vj.c'
'src/netif/ppp/polarssl/arc4.c'
'src/netif/ppp/polarssl/des.c'
'src/netif/ppp/polarssl/md4.c'
'src/netif/ppp/polarssl/md5.c'
'src/netif/ppp/polarssl/sha1.c'

'contrib/ports/unix/port/sys_arch.c'
'contrib/ports/unix/port/perf.c'

'contrib/ports/unix/port/netif/tapif.c'
'contrib/ports/unix/port/netif/list.c'
'contrib/ports/unix/port/netif/sio.c'
'contrib/ports/unix/port/netif/fifo.c'

'src/include/compat/posix/*.h'
'src/include/compat/posix/arpa/*.h'
'src/include/compat/posix/net/*.h'
'src/include/compat/posix/sys/*.h'
'src/include/compat/stdc/*.h'
'src/include/lwip/*.h'
'src/include/lwip/priv/*.h'
'src/include/lwip/prot/*.h'
'src/include/netif/*.h'
'src/include/netif/ppp/*.h'
'src/include/netif/ppp/polarssl/*.h'

'contrib/ports/unix/port/include/arch/*.h'
'contrib/ports/unix/port/include/netif/*.h'

'contrib/ports/unix/posixlib/include/posix/*.h'
)

EXCLUDES=(
'*_test.*'
'test_*.*'
'test'
'example_*.c'
)

echo "COPYING lwip"
for pattern in "${PATTERNS[@]}"
do
  for i in $SRCROOT/$pattern; do
    path=${i#"$SRCROOT"}
    dest="$DSTROOT$path"
    dest_dir=$(dirname "$dest")
    mkdir -p "$dest_dir"
    cp "$SRCROOT/$path" "$dest"
  done
done

for exclude in "${EXCLUDES[@]}"
do
  echo "EXCLUDING $exclude"
  find $DSTROOT -d -name "$exclude" -exec rm -rf {} \;
done

echo "RENAMING header files"
(
    # We need to rearrange a coouple of things here, the end state will be:
    # - Headers from 'src/include/' will be moved up a level to 'include/'
    # - Platform specific headers should also included into 'include/'

    # Let's move the headers up a level first.
    cd "$DSTROOT"
    mv src/include .

    # Add port headers.
    cp -R contrib/ports/unix/port/include/* include/
    rm -rf contrib/ports/unix/port/include

    # Add posix headers.
    cp -R contrib/ports/unix/posixlib/include/* include/

    # Add port src files.
    mkdir -p src/port/netif
    cp -R contrib/ports/unix/port/* src/port/
    rm -rf contrib

    cd "$HERE"
)

echo "PATCHING LwIP"
$sed -i -e 's/#define LWIP_HDR_ARCH_H/#define LWIP_HDR_ARCH_H\n#include "opt.h"/' "$HERE/$DSTROOT/include/lwip/arch.h"

$sed -i -e 's/#include "lwipopts\.h"/#include "..\/opt\/lwipopts.h"/g' "$HERE/$DSTROOT/include/lwip/opt.h"

$sed -i '1i #ifdef LWIP_MEMPOOL' "$HERE/$DSTROOT/include/lwip/priv/memp_std.h"
echo '#endif /* LWIP_MEMPOOL */' >> "$HERE/$DSTROOT/include/lwip/priv/memp_std.h"

$sed -i -e "/#include \"lwip\/priv\/memp_std\.h\"/ { r $HERE/$DSTROOT/include/lwip/priv/memp_std.h"  -e 'd' -e '}' "$HERE/$DSTROOT/include/lwip/memp.h"

$sed -i -e 's/int len = strlen/size_t len = strlen/' "$HERE/$DSTROOT/src/port/netif/sio.c"

$sed -i -e 's/cnt = read( fd/cnt = (int)read( fd/' "$HERE/$DSTROOT/src/port/netif/fifo.c"

echo "RECORDING LwIP revision"
#$sed -i -e "s/LwIP Commit: [0-9a-f]\+/LwIP Commit: ${LWIP_REVISION}/" "$HERE/Package.swift"
echo "This directory is derived from LwIP cloned from https://git.savannah.gnu.org/git/lwip.git at revision ${LWIP_REVISION}" > "$DSTROOT/hash.txt"

echo "CLEANING temporary directory"
rm -rf "${TMPDIR}"
