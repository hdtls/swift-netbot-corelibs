#!/bin/bash
##
## See LICENSE.txt for license information
##

set -eou pipefail

SRCROOT=$(pwd)
TMPDIR=$(mktemp -d)
DERIVED_FILES_DIR="${TMPDIR}/src/savannah.gnu.org/lwip"
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
find "$SRCROOT/Sources/CNELwIP/include/" \
  ! -path "$SRCROOT/Sources/CNELwIP/include/debug.h" \
  ! -path "$SRCROOT/Sources/CNELwIP/include/lwipopts.h" \
  -delete

rm -rf "$SRCROOT/Sources/CNELwIP/contrib"
rm -rf "$SRCROOT/Sources/CNELwIP/src"

echo "CLONING LwIP"
mkdir -p "$DERIVED_FILES_DIR"
git clone https://git.savannah.gnu.org/git/lwip.git "$DERIVED_FILES_DIR"
cd "$DERIVED_FILES_DIR"
LWIP_REVISION=$(git rev-parse HEAD)
cd "$SRCROOT"
echo "CLONED lwip@${LWIP_REVISION}"

echo "COPYING lwip"
rsync -avmz \
  --exclude="apps/" \
  --exclude="include/" \
  --include="*/" \
  --include="*.c" \
  --exclude="*" \
  "$DERIVED_FILES_DIR/src/" "$SRCROOT/Sources/CNELwIP/src/"

rsync -avmz \
  --exclude="lwip/apps/" \
  --include="*/" \
  --include="*.h" \
  --exclude="*" \
  "$DERIVED_FILES_DIR/src/include/" "$SRCROOT/Sources/CNELwIP/include/"

rsync -avmz \
  --exclude="win32/" \
  --exclude="freertos/" \
  --exclude="unix/check/" \
  --exclude="unix/example_app/" \
  --exclude="unix/lib/" \
  --exclude="*/vdeif.c" \
  --exclude="*/pcapif.c" \
  --include="*/" \
  --include="*.c" \
  --exclude="*" \
  "$DERIVED_FILES_DIR/contrib/ports/" "$SRCROOT/Sources/CNELwIP/contrib/ports"

# There headerSearchPath looks like not work as expected when target is used as dependencies for other targets.
# We consider to copy all headers into one.
rsync -avmz \
  --exclude="*/vdeif.h" \
  --exclude="*/pcapif.h" \
  --include="*/" \
  --include="*.h" \
  --exclude="*" \
 "$DERIVED_FILES_DIR/contrib/ports/unix/port/include/" "$SRCROOT/Sources/CNELwIP/include/"

rsync -avmz \
  --include="*/" \
  --include="*.h" \
  --exclude="*" \
  "$DERIVED_FILES_DIR/contrib/ports/unix/posixlib/include/" "$SRCROOT/Sources/CNELwIP/include/"

echo "PATCHING LwIP"
git apply "$SRCROOT/scripts/CNELwIP.patch"

$sed -i 's/struct icmp6_hdr {/struct CNELwIP_icmp6_hdr {/' "$SRCROOT/Sources/CNELwIP/include/lwip/prot/icmp6.h"
$sed -i 's/struct ip6_hdr {/struct CNELwIP_ip6_hdr {/' "$SRCROOT/Sources/CNELwIP/include/lwip/prot/ip6.h"
$sed -i 's/struct udp_hdr {/struct CNELwIP_udp_hdr {/' "$SRCROOT/Sources/CNELwIP/include/lwip/prot/udp.h"

# Patching ambiguous expansion of macro 'BIG_ENDIAN'.
$sed -i '/#ifndef LITTLE_ENDIAN/i #ifndef __APPLE__' "$SRCROOT/Sources/CNELwIP/include/lwip/arch.h"
$sed -i '/#define BIG_ENDIAN 4321/a #endif' "$SRCROOT/Sources/CNELwIP/include/lwip/arch.h"

# Patching memp errors.
$sed -i '1i #ifdef LWIP_MEMPOOL' "$SRCROOT/Sources/CNELwIP/include/lwip/priv/memp_std.h"
echo '#endif /* LWIP_MEMPOOL */' >> "$SRCROOT/Sources/CNELwIP/include/lwip/priv/memp_std.h"
$sed -i -e "/#include \"lwip\/priv\/memp_std\.h\"/ { r $SRCROOT/Sources/CNELwIP/include/lwip/priv/memp_std.h"  -e 'd' -e '}' "$SRCROOT/Sources/CNELwIP/include/lwip/memp.h"

# Patching implicit conversion loses integer precision.
$sed -i -e 's/int len = strlen/size_t len = strlen/' "$SRCROOT/Sources/CNELwIP/contrib/ports/unix/port/netif/sio.c"
$sed -i -e 's/cnt = read( fd/cnt = (int)read( fd/' "$SRCROOT/Sources/CNELwIP/contrib/ports/unix/port/netif/fifo.c"
$sed -i 's/u32_t sio_write/ssize_t sio_write/' "$SRCROOT/Sources/CNELwIP/include/lwip/sio.h"
$sed -i 's/u32_t sio_read/ssize_t sio_read/' "$SRCROOT/Sources/CNELwIP/include/lwip/sio.h"
$sed -i 's/u32_t sio_tryread/ssize_t sio_tryread/' "$SRCROOT/Sources/CNELwIP/include/lwip/sio.h"
$sed -i 's/u32_t sio_write/ssize_t sio_write/' "$SRCROOT/Sources/CNELwIP/contrib/ports/unix/port/netif/sio.c"
$sed -i 's/u32_t sio_read/ssize_t sio_read/' "$SRCROOT/Sources/CNELwIP/contrib/ports/unix/port/netif/sio.c"
$sed -i '/void sio_read_abort(sio_status_t \* siostat)/i\
ssize_t sio_tryread(sio_status_t \* siostat, u8_t \*buf, u32_t size)\
{\
    ssize_t rsz = read( siostat->fd, buf, size );\
    return rsz < 0 ? 0 : rsz;\
}\

' "$SRCROOT/Sources/CNELwIP/contrib/ports/unix/port/netif/sio.c"

echo "RECORDING LwIP revision"
#$sed -i -e "s/LwIP Commit: [0-9a-f]\+/LwIP Commit: ${LWIP_REVISION}/" "$HERE/Package.swift"
echo "This directory is derived from LwIP cloned from https://git.savannah.gnu.org/git/lwip.git at revision ${LWIP_REVISION}" > "$SRCROOT/Sources/CNELwIP/hash.txt"

echo "CLEANING temporary directory"
rm -rf "${TMPDIR}"
