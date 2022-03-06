#!/bin/bash
################################################################################
# Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
# See https://llvm.org/LICENSE.txt for license information.
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
################################################################################
#
# This script will install the llvm toolchain on the different
# Debian and Ubuntu versions

set -eux

CURRENT_LLVM_STABLE=13

# Check for required tools
needed_binaries=(lsb_release wget gpg add-apt-repository)
missing_binaries=()
for binary in "${needed_binaries[@]}"; do
    if ! which $binary &>/dev/null ; then
        missing_binaries+=($binary)
    fi
done
if [[ ${#missing_binaries[@]} -gt 0 ]] ; then
    echo "You are missing some tools this script requires: ${missing_binaries[@]}"
    echo "(hint: apt install lsb-release wget gpg software-properties-common)"
    apt-get update -y && \
    apt-get install -y lsb-release wget gpg software-properties-common
fi

# read optional command line argument
# We default to the current stable branch of LLVM
LLVM_VERSION=$CURRENT_LLVM_STABLE
ALL=0
if [ "$#" -ge 1 ]; then
    LLVM_VERSION=$1
    if [ "$1" == "all" ]; then
        # special case for ./llvm.sh all
        LLVM_VERSION=$CURRENT_LLVM_STABLE
        ALL=1
    fi
    if [ "$#" -ge 2 ]; then
      if [ "$2" == "all" ]; then
          # Install all packages
          ALL=1
      fi
    fi
fi

DISTRO=$(lsb_release -is)
VERSION=$(lsb_release -sr)
DIST_VERSION="${DISTRO}_${VERSION}"

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

declare -A LLVM_VERSION_PATTERNS
LLVM_VERSION_PATTERNS[9]="-9"
LLVM_VERSION_PATTERNS[10]="-10"
LLVM_VERSION_PATTERNS[11]="-11"
LLVM_VERSION_PATTERNS[12]="-12"
LLVM_VERSION_PATTERNS[13]="-13"
LLVM_VERSION_PATTERNS[14]="-14"
LLVM_VERSION_PATTERNS[15]=""

if [ ! ${LLVM_VERSION_PATTERNS[$LLVM_VERSION]+_} ]; then
    echo "This script does not support LLVM version $LLVM_VERSION"
    exit 3
fi

LLVM_VERSION_STRING=${LLVM_VERSION_PATTERNS[$LLVM_VERSION]}

llvm_gpg_keyring=/usr/share/keyrings/llvm-archive-keyring.gpg
llvm_gpg_signature="[arch=$(dpkg --print-architecture) signed-by=$llvm_gpg_keyring]"

# find the right repository name for the distro and version
case "$DIST_VERSION" in
    Debian_9* )       REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/stretch/  llvm-toolchain-stretch$LLVM_VERSION_STRING main" ;;
    Debian_10* )      REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/buster/   llvm-toolchain-buster$LLVM_VERSION_STRING  main" ;;
    Debian_11* )      REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/bullseye/ llvm-toolchain-bullseye$LLVM_VERSION_STRING  main" ;;
    Debian_unstable ) REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;
    Debian_testing )  REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/unstable/ llvm-toolchain$LLVM_VERSION_STRING         main" ;;

    Ubuntu_16.04 )    REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/xenial/   llvm-toolchain-xenial$LLVM_VERSION_STRING  main" ;;
    Ubuntu_18.04 )    REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/bionic/   llvm-toolchain-bionic$LLVM_VERSION_STRING  main" ;;
    Ubuntu_18.10 )    REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/cosmic/   llvm-toolchain-cosmic$LLVM_VERSION_STRING  main" ;;
    Ubuntu_19.04 )    REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/disco/    llvm-toolchain-disco$LLVM_VERSION_STRING   main" ;;
    Ubuntu_19.10 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/eoan/      llvm-toolchain-eoan$LLVM_VERSION_STRING    main" ;;
    Ubuntu_20.04 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/focal/     llvm-toolchain-focal$LLVM_VERSION_STRING   main" ;;
    Ubuntu_20.10 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/groovy/    llvm-toolchain-groovy$LLVM_VERSION_STRING  main" ;;
    Ubuntu_21.04 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/hirsute/   llvm-toolchain-hirsute$LLVM_VERSION_STRING main" ;;
    Ubuntu_21.10 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/impish/    llvm-toolchain-impish$LLVM_VERSION_STRING main" ;;
    Ubuntu_22.04 )   REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/jammy/     llvm-toolchain-jammy$LLVM_VERSION_STRING main" ;;

    Linuxmint_19* )  REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/bionic/   llvm-toolchain-bionic$LLVM_VERSION_STRING  main" ;;
    Linuxmint_20* )  REPO_NAME="deb $llvm_gpg_signature https://apt.llvm.org/focal/    llvm-toolchain-focal$LLVM_VERSION_STRING   main" ;;

    * )
    echo "Distribution '$DISTRO' in version '$VERSION' is not supported by this script (${DIST_VERSION})."
        exit 2
esac


# install everything
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | gpg --yes --dearmor -o $llvm_gpg_keyring
echo "${REPO_NAME}" | tee /etc/apt/sources.list.d/llvm.list > /dev/null
apt-get update -y
PKG="clang-$LLVM_VERSION lld-$LLVM_VERSION"
if [[ $ALL -eq 1 ]]; then
    # same as in test-install.sh
    # No worries if we have dups
    PKG="$PKG clang-tidy-$LLVM_VERSION clang-format-$LLVM_VERSION clang-tools-$LLVM_VERSION llvm-$LLVM_VERSION-dev lld-$LLVM_VERSION lldb-$LLVM_VERSION llvm-$LLVM_VERSION-tools libomp-$LLVM_VERSION-dev libc++-$LLVM_VERSION-dev libc++abi-$LLVM_VERSION-dev libclang-common-$LLVM_VERSION-dev libclang-$LLVM_VERSION-dev libclang-cpp$LLVM_VERSION-dev libunwind-$LLVM_VERSION-dev"
fi
apt-get install -y $PKG
# remove unnecessary packages
apt-get remove -y build-essential g++ gcc && \
apt-get autoremove -y

update-alternatives --install /usr/bin/clang clang $(which clang-$LLVM_VERSION) 20
update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang 20
update-alternatives --install /usr/bin/lld lld $(which lld-$LLVM_VERSION) 20

update-alternatives --set clang $(which clang-$LLVM_VERSION)
update-alternatives --set lld $(which lld-$LLVM_VERSION)

echo "Clang detection:"
clang --version

echo "Linker detection:"
clang -fuse-ld=lld -Wl,--version
