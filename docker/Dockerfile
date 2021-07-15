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
#   docker build -t vimtex-test .
#   docker run -v /path/to/vimtex:/vimtex -ti vimtex-test

FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install -y software-properties-common
RUN add-apt-repository -y ppa:neovim-ppa/stable && apt update
RUN apt -y install \
  vim neovim moreutils gcc make wget tree \
  texlive texlive-latex-extra texlive-extra-utils \
  texlive-bibtex-extra libtext-bibtex-perl \
  texlive-publishers \
  latexmk \
  libmodule-build-perl \
  libconfig-autoconf-perl \
  libextutils-libbuilder-perl

ENV SHELL=bash

WORKDIR /vimtex

CMD bash
