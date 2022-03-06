# LLVM.sh

an automatic installation script installs LLVM.

original version: https://apt.llvm.org/llvm.sh

replace deprecated apt-key with GPG keyring.

install `clang`, `lld` by default.

## How to install

```bash
# install clang 12, lld 12
sudo ./llvm.sh 12
```

## How to use

```bash
export CC=clang
export CXX=$CC++
export LDFLAGS=-fuse-ld=lld
```