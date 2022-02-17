# Install Flowge

## Supported OS

|  | x86_64 | ARM64 |
| :---: | :---: | :---: |
| macOS 10.15 Catalina | ✅ | / |
| macOS 11 Big Sur | ✅ | ✅ |
| macOS 12 Monterey | ✅ | ✅ |
| Ubuntu 18.04 | ✅ | ✅ |
| Ubuntu 20.04 | ✅ | ✅ |
| Ubuntu 21.10 | ✅ | ✅ |
| Windows 10 | ❌ | ❌ |
| Windows 11 | ❌ | ❌ |

> Use [WSL](https://docs.microsoft.com/fr-fr/windows/wsl/install) with [ubuntu](https://www.microsoft.com/en-us/p/ubuntu/9nblggh4msv6) on Windows to use Flowge.

## MacOs

```
brew install cmake llvm node
npm install -g flowge
```

> Need [homebrew](https://brew.sh/)

## Ubuntu

Essential:
```sh
apt-get update
apt-get install build-essential zlib1g-dev curl apt-transport-https ca-certificates gnupg software-properties-common wget
```

NodeJS + npm (ubuntu):
```
cd ~
curl -sL https://deb.nodesource.com/setup_16.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt install nodejs
npm install -g npm@latest
```

> On wsl, use nvm to install nodejs & npm

CMake:
```
apt-get update
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | sudo apt-key add -
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
apt-get update
apt-get install cmake
```

LLVM:
```
add-apt-repository 'deb http://apt.llvm.org/bionic/   llvm-toolchain-bionic-14  main'
apt-get update
apt-get install llvm-13 clang-13 lld-13 lldb-13
```

To finish:
```
npm install -g flowge
```
