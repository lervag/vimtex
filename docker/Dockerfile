# VimTeX - LaTeX plugin for Vim
#
# Maintainer: Karl Yngve Lervåg
# Email:      karl.yngve@gmail.com
#
# This is a dockerfile for creating an environment that is similar to the
# environment on Github Actions where the tests are run.
#
# To use, do something like this:
#
#   cd VIMTEX/docker
#   docker buildx build -t vimtex-test .
#   docker run -v /path/to/vimtex:/vimtex -ti vimtex-test

FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive

# Editor versions, kept in sync with .github/workflows/main.yml
ARG NEOVIM_VERSION=0.12.4
ARG VIM_VERSION=9.2

# Install test dependencies. moreutils/texlive/latexmk/perl packages mirror the
# ones installed in CI; the rest are needed to fetch and build the editors via
# mise (vim is compiled from source, hence gcc/make/libncurses-dev).
RUN apt-get update && apt-get install -y \
      moreutils gcc make wget tree \
      ca-certificates curl git xz-utils unzip libncurses-dev \
      texlive texlive-latex-extra texlive-extra-utils \
      texlive-bibtex-extra libtext-bibtex-perl \
      texlive-publishers \
      latexmk \
      libmodule-build-perl \
      libconfig-autoconf-perl \
      libextutils-libbuilder-perl \
  && rm -rf /var/lib/apt/lists/*

# Install neovim and vim through mise, matching the versions used in CI.
RUN curl -fsSL https://mise.run | sh
ENV PATH="/root/.local/bin:/root/.local/share/mise/shims:${PATH}"
RUN mise use -g neovim@${NEOVIM_VERSION} vim@${VIM_VERSION}

ENV SHELL=bash

WORKDIR /vimtex

CMD ["bash"]
