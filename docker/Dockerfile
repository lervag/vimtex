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

FROM ubuntu

ARG DEBIAN_FRONTEND=noninteractive

RUN apt -qq update && apt -qq -y install \
  vim neovim moreutils \
  gcc git make wget tree \
  texlive texlive-latex-extra texlive-extra-utils latexmk \
  texlive-bibtex-extra libtext-bibtex-perl \
  libmodule-build-perl \
  libconfig-autoconf-perl \
  libextutils-libbuilder-perl

WORKDIR /vimtex

CMD bash
