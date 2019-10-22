# vimtex - LaTeX plugin for Vim
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

RUN apt -qq update
RUN apt -qq -y install vim neovim moreutils
RUN apt -qq -y install texlive texlive-latex-extra
RUN apt -qq -y install latexmk libtext-bibtex-perl
RUN apt -qq -y install git make wget

WORKDIR /vimtex

CMD bash
