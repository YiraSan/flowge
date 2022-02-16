# MacOs

```
brew install cmake llvm node
npm install -g flowge
```

# Linux (ubuntu)

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
```

NodeJS + npm (wsl2+ubuntu): 
```
apt-get update
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
```

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