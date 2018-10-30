# This file is part of libertine. It is subject to the license terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT. No part of libertine, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2018 The developers of libertine. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/libertine-linux/libertine/master/COPYRIGHT.


FROM alpine:3.8
MAINTAINER Raphael Cohn <raphael.cohn@stormmq.com>


# 1 Baseline environment


# 1.1 Arguments
ARG officialRustupBaseUrl=https://static.rust-lang.org/rustup/dist
ARG glibcTag=glibc-2.28


# 1.2 User settings

USER 0:0
ENV HOME=/root
WORKDIR "$HOME"


# 1.3 Ensure PATH is consistent and contains /usr/local/sbin

RUN /bin/mkdir -m 0755 -p /usr/local/sbin
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


# 1.4 Bring apk package manager up-to-date with known repositories

RUN apk update
RUN apk upgrade


# 2 Development environment for Libertine Linux


# 2.1 Essential C compiler

RUN apk add binutils fortify-headers g++ gcc gmp-dev libc-dev mpc1-dev mpfr-dev


# 2.2 Boostrap rustc and cargo; Rust is needed to bootstrap Rust


# 2.2.1 Create a glibc dynamic library (this will be heavily polluted by the host environment)

RUN apk add alpine-sdk bison gawk linux-headers
ENV glibcInstallPath=/usr/glibc-compat
RUN git clone --depth 1 --single-branch --branch "$glibcTag" git://sourceware.org/git/glibc.git
WORKDIR /root/glibc
RUN mkdir build
WORKDIR /root/glibc/build
# Yes, it really is called `configparms`.
RUN echo "slibdir=${glibcInstallPath}/lib" >> configparms
RUN echo "rtlibdir=${glibcInstallPath}/lib" >> configparms
RUN echo "sbindir=${glibcInstallPath}/bin" >> configparms
RUN echo "rootsbindir=${glibcInstallPath}/bin" >> configparms
RUN echo 'build-programs=yes' >> configparms
RUN ../configure --prefix "$glibcInstallPath"
RUN make
RUN make install
RUN printf '%s/lib\n/usr/local/lib\n/usr/lib\n/lib\n' "${glibcInstallPath}" >/etc/ld.so.conf
RUN printf 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4\n' "${glibcInstallPath}" >/etc/nsswitch.configure
# To use this particular library with gcc, say, if necesary: gcc -L "${glibcInstallPath}/lib" -I "${glibcInstallPath}/include" -Wl,--rpath="${glibcInstallPath}/lib" -Wl,--dynamic-linker="${glibcInstallPath}/lib/ld-linux-x86-64.so.2"
RUN apk del alpine-sdk bison gawk linux-headers


# 2.2.2 Configure glibc binaries

RUN "${glibcInstallPath}"/bin/localedef -i en_US -f UTF-8 en_US.UTF-8
RUN "${glibcInstallPath}"/sbin/ldconfig
ENV PATH="${glibcInstallPath}"/sbin:"${glibcInstallPath}"/bin:/usr/sbin:/usr/bin:/sbin:/bin


# 2.2.3 Install, patch and run rustup

RUN apk add curl patchelf
WORKDIR /root
RUN curl --location --output rustup-init "$officialRustupBaseUrl"/x86_64-unknown-linux-gnu/rustup-init
RUN chmod +x rustup-init
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/lib:/lib rustup-init
RUN ./rustup-init --verbose -y --no-modify-path --default-toolchain nightly
RUN rm rustup-init
RUN apk del curl patchelf


# 2.2.4 Patch Rust binaries to use a RPATH which locates glibc

RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/rustup
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/cargo
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/rust-gdb
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/rust-lldb
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/rustc
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.cargo/bin/rustdoc
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/cargo
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rust-gdb
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rustc
RUN patchelf --set-rpath "${glibcInstallPath}"/lib:/usr/local/lib:/usr/lib:/lib /root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin/rustdoc


# 2.2.5 Integrate Rust binaries.

ENV PATH=/root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu/bin:"$PATH"
RUN /root/.cargo/bin/rustup target add x86_64-unknown-linux-musl
RUN /root/.cargo/bin/rustup update
RUN rustc -Vv




# 2.3 Git for Libertine Linux ./libertine progam

RUN apk add git


# 3 Clean up apk

RUN rm -rf /var/cache/apk/*


# 4 Leave as needed.

VOLUME "$HOME"/libertine
WORKDIR "$HOME"/libertine
ENTRYPOINT ["./libertine"]
