ARG UBUNTU_VERSION="focal"
FROM ubuntu:${UBUNTU_VERSION}
LABEL maintainer="Vasiliy Polyakov <invasy.v+docker@gmail.com>"

ARG UBUNTU_VERSION="focal"
ARG CLANG_VERSION="13"
ARG CMAKE_VERSION="3.19.8"
ARG NINJA_VERSION="1.10.2"

RUN set -eu; \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update -qq; apt-get upgrade -qq; \
  apt-get install -qq --no-install-recommends ca-certificates curl gdb gdbserver gnupg make openssh-server rsync unzip; \
  echo "deb http://apt.llvm.org/${UBUNTU_VERSION}/ llvm-toolchain-${UBUNTU_VERSION} main" >/etc/apt/sources.list.d/llvm.list; \
  curl --silent --show-error --location 'https://apt.llvm.org/llvm-snapshot.gpg.key' | apt-key add -; \
  apt-get update -qq; apt-get install -qq --no-install-recommends \
    clang-${CLANG_VERSION} clang-format-${CLANG_VERSION} clang-tidy-${CLANG_VERSION} clang-tools-${CLANG_VERSION} \
    clangd-${CLANG_VERSION} lld-${CLANG_VERSION} lldb-${CLANG_VERSION}; \
  cd /tmp; \
  cmake_url="https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}" \
  cmake_sum="cmake-${CMAKE_VERSION}-SHA-256.txt" cmake_sig="${cmake_sum}.asc" \
  cmake_pkg="cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz" cmake_dir="/opt/cmake/${CMAKE_VERSION}"; \
  curl --silent --show-error --location --remote-name-all \
    "$cmake_url/$cmake_sig" "$cmake_url/$cmake_sum" "$cmake_url/$cmake_pkg"; \
  gpg --quiet --keyserver pool.sks-keyservers.net --recv-keys C6C265324BBEBDC350B513D02D2CEF1034921684; \
  gpg --quiet --verify "$cmake_sig" "$cmake_sum"; \
  sha256sum --quiet --check --ignore-missing "$cmake_sum"; \
  mkdir -p "/opt/cmake/${CMAKE_VERSION}" /run/sshd; \
  tar --extract --file="$cmake_pkg" --directory="$cmake_dir" \
    --strip-components=1 --wildcards '*/bin' '*/share/cmake-*/Templates' '*/share/cmake-*/Modules'; \
  for f in "$cmake_dir/bin/"*; do ln -s "$f" /usr/local/bin/; done; \
  curl --silent --show-error --location --remote-name \
    "https://github.com/ninja-build/ninja/releases/download/v${NINJA_VERSION}/ninja-linux.zip"; \
  echo "763464859c7ef2ea3a0a10f4df40d2025d3bb9438fcb1228404640410c0ec22d *ninja-linux.zip" | sha256sum --quiet --check; \
  unzip -qq ninja-linux.zip -d /usr/local/bin; \
  useradd --create-home --comment='C/C++ Remote Builder for CLion' --shell=/bin/bash builder; \
  yes builder | passwd --quiet builder; mkdir -p ~builder/.ssh; (\
    echo "CC=/usr/bin/clang-${CLANG_VERSION}"; \
    echo "CXX=/usr/bin/clang++-${CLANG_VERSION}"; \
  ) >~builder/.ssh/environment; \
  touch ~builder/.hushlogin; \
  chown -R builder: ~builder; chmod -R go= ~builder; \
  rm -rf /var/lib/apt/lists/* /var/cache/apt/* /var/log/* /tmp/* /root/.gnupg
COPY sshd_config /etc/ssh/sshd_config

ENV CC="/usr/bin/clang-${CLANG_VERSION}" CXX="/usr/bin/clang++-${CLANG_VERSION}"

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
