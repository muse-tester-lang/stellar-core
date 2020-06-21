FROM gitpod/workspace-full-vnc:latest

# Work around https://github.com/sudo-project/sudo/issues/42
USER root
RUN echo "Set disable_coredump false" >> /etc/sudo.conf

# Switch back to non-root user
USER gitpod
ENV HOME=/home/gitpod
WORKDIR $HOME

# Add test tool chain
# NOTE: newer version of the compilers are not
#    provided by stock distributions
#    and are provided by the /test toolchain
RUN sudo apt-get update \
    && sudo apt-get -y install apt-utils software-properties-common \
    && sudo apt-get update

# Install common compilation tools
RUN sudo apt-get -y install git build-essential pkg-config autoconf automake libtool bison flex libpq-dev parallel bear

# Update compiler tools
RUN sudo apt-get -y install clang clangd clang-tools libc++-dev libc++abi-dev

# Install postgresql to enable tests under make check
RUN sudo apt-get -y install postgresql

# Set up locale
RUN sudo sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && sudo locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install clangd for code navigation and clang-format for formatting, and link them into a directory in the $PATH
# (For now, our standard is an old version of clang-format, 5.0.2)
RUN sudo apt-get -y install curl
RUN sudo curl https://releases.llvm.org/5.0.2/clang+llvm-5.0.2-x86_64-linux-gnu-ubuntu-16.04.tar.xz | sudo tar -xJf - -C /usr/local
RUN sudo ln -sf /usr/local/clang+llvm-5.0.2-x86_64-linux-gnu-ubuntu-16.04/bin/clang-format /usr/bin

# Get code navigation going by running a build and generating
# compile_commands.json
RUN git submodule init
RUN git submodule update
RUN ./autogen.sh
RUN ./configure --enable-tracy --enable-tracy-capture
RUN time bear make