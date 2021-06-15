# VimTeX

VimTeX is a modern [Vim](http://www.vim.org/) and [Neovim](https://neovim.io/)
filetype and syntax plugin for LaTeX files.

[![Gitter](https://badges.gitter.im/vimtex-chat/community.svg)](https://gitter.im/vimtex-chat/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)
![CI tests](https://github.com/lervag/vimtex/workflows/CI%20tests/badge.svg)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5N4MFVXN7U8NW)

## Table of contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Screenshots](#screenshots)
- [Features](#features)
- [Other relevant plugins](#other-relevant-plugins)
  - [Linting and syntax checking](#linting-and-syntax-checking)
  - [Snippets and templates](#snippets-and-templates)
  - [Tag navigation](#tag-navigation)
- [Alternatives](#alternatives)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Requirements

VimTeX requires Vim version 8.0.1453 or Neovim version 0.4.3. The requirements
were updated in July 2020 after the release of VimTeX 1.0. If you are stuck
on older versions of Vim or Neovim, then you should not use the most recent
version of VimTeX, but instead remain at the v1.0 tag.

Some features require external tools. For example, the default compiler backend
relies on [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/).
Users are encouraged to read the requirements section in the
[documentation](doc/vimtex.txt) (`:h vimtex-requirements`).

## Installation

If you use [vim-plug](https://github.com/junegunn/vim-plug), then add the
following line to your `vimrc` file:

```vim
Plug 'lervag/vimtex'
```

Or use some other plugin manager:
* [vundle](https://github.com/gmarik/vundle)
* [neobundle](https://github.com/Shougo/neobundle.vim)
* [pathogen](https://github.com/tpope/vim-pathogen)

If you use the new package feature in Vim, please note the following:
* Make sure to read and understand the package feature: `:help package`!
* Use the `/pack/foo/start` subdirectory to make sure the filetype plugin is
  automatically loaded for the `tex` filetypes.
* Helptags are not generated automatically. Run `:helptags` to generate them.
* Please note that by default Vim puts custom `/start/` plugin directories at
  the end of the `&runtimepath`. This means the built in filetype plugin is
  loaded, which prevents VimTeX from loading. See
  [#1413](https://github.com/lervag/vimtex/issues/1413) for two suggested
  solutions to this. To see which scripts are loaded and in which order, use
  `:scriptnames`.
* For more information on how to use the Vim native package solution, see
  [here](https://vi.stackexchange.com/questions/9522/what-is-the-vim8-package-feature-and-how-should-i-use-it)
  and [here](https://shapeshed.com/vim-packages/).

## Quick Start

The following is a video guide for how to use VimTeX (credits:
[@DustyTopology](https://github.com/DustyTopology) from
[#1946](https://github.com/lervag/vimtex/issues/1946#issuecomment-846345095)).
It displays some of the main features. The example LaTeX file used in the video
is available under
[`test/example-quick-start/main.tex`](test/example-quick-start/main.tex) and it
may be instructive to copy the file and play with it to learn some of these
basic functions.

https://user-images.githubusercontent.com/66584581/119213849-1b7d4080-ba77-11eb-8a31-7ff7b9a4a020.mp4

Users are of course _strongly_
encouraged to read the documentation, at least the introduction, to learn about
the different features and possibilities provided by VimTeX (see [`:h
vimtex`](doc/vimtex.txt)).
Advanced users and potential developers may also be interested in reading the
supplementary documents:

* [CONTRIBUTING.md](CONTRIBUTING.md)
* [DOCUMENTATION.md](DOCUMENTATION.md)

## Screenshots

Here is an example of the syntax highlighting provided by VimTeX. The example
is made by @DustyTopology with the
[vim-colors-xcode](https://github.com/arzg/vim-colors-xcode) colorscheme with
some minor adjustments [described
here](https://github.com/lervag/vimtex/issues/1946#issuecomment-843674951).

![Syntax example](https://github.com/lervag/vimtex-media/blob/main/img/syntax.png)

## Features

Below is a list of features offered by VimTeX. The features are accessible as
both commands and mappings. The mappings generally start with `<localleader>l`,
but if desired one can disable default mappings to define custom mappings. All
features are enabled by default, but each feature may be disabled if desired.

- Document compilation with
  [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/),
  [latexrun](https://github.com/aclements/latexrun),
  [tectonic](https://tectonic-typesetting.github.io), or
  [arara](https://github.com/cereda/arara)
- LaTeX log parsing for quickfix entries using
  - internal method
  - [pplatex](https://github.com/stefanhepp/pplatex)
- Compilation of selected part of document
- Support for several PDF viewers with forward search
  - [MuPDF](http://www.mupdf.com/)
  - [Okular](https://okular.kde.org/)
  - [qpdfview](https://launchpad.net/qpdfview)
  - [Skim](http://skim-app.sourceforge.net/)
  - [SumatraPDF](http://www.sumatrapdfreader.org/free-pdf-reader.html)
  - [Zathura](https://pwmt.org/projects/zathura/)
  - Other viewers are supported through a general interface
- Completion of
  - citations
  - labels
  - commands
  - file names for figures, input/include, includepdf, includestandalone
  - glossary entries
  - package and documentclass names based on available `.sty` and `.cls` files
- Document navigation through
  - table of content
  - table of labels
  - proper settings for `'include'`, `'includexpr'`, `'suffixesadd'` and
    `'define'`, which among other things
    - allow `:h include-search` and `:h definition-search`
    - give enhanced `gf` command
- Easy access to (online) documentation of packages
- Word count (through `texcount`)
- Motions
  - Move between section boundaries with `[[`, `[]`, `][`, and `]]`
  - Move between environment boundaries with `[m`, `[M`, `]m`, and `]M`
  - Move between math environment boundaries with `[n`, `[N`, `]n`, and `]N`
  - Move between frame environment boundaries with `[r`, `[R`, `]r`, and `]R`
  - Move between comment boundaries with `[*` and `]*`
  - Move between matching delimiters with `%`
- Text objects
  - `ic ac` Commands
  - `id ad` Delimiters
  - `ie ae` LaTeX environments
  - `i$ a$` Inline math structures
  - `iP aP` Sections
  - `im am` Items
- Other mappings
  - Delete the surrounding command, environment or delimiter with
    `dsc`/`dse`/`ds$`/`dsd`
  - Change the surrounding command, environment or delimiter with
    `csc`/`cse`/`cs$`/`csd`
  - Toggle starred command or environment with `tsc`/`tse`
  - Toggle between e.g. `()` and `\left(\right)` with `tsd`
  - Toggle (inline) fractions with `tsf`
  - Close the current environment/delimiter in insert mode with `]]`
  - Insert new command with `<F7>`
  - Convenient insert mode mappings for faster typing of e.g. maths
  - Context menu on citations (e.g. `\cite{...}`) mapped to `<cr>`
- Improved folding (`:h 'foldexpr'`)
- Improved indentation (`:h 'indentexpr'`)
- Syntax highlighting
  - A consistent core syntax specification
  - General syntax highlighting for several popular LaTeX packages
  - Nested syntax highlighting for several popular LaTeX packages
  - Highlight matching delimiters
- Support for multi-file project packages
  - [import](http://ctan.uib.no/macros/latex/contrib/import/import.pdf)
  - [subfiles](http://ctan.uib.no/macros/latex/contrib/subfiles/subfiles.pdf)

See the documentation for a thorough introduction to VimTeX (e.g. `:h vimtex`).

## Other relevant plugins

Even though VimTeX provides a lot of nice features for working with LaTeX
documents, there are several features that are better served by other,
dedicated plugins. For a more detailed listing of these, please see [`:help
vimtex-non-features`](doc/vimtex.txt#L156).

### Linting and syntax checking

  * [ale](https://github.com/w0rp/ale)
  * [neomake](https://github.com/neomake/neomake)
  * [syntastic](https://github.com/vim-syntastic/syntastic)

### Snippets and templates

  * [UltiSnips](https://github.com/SirVer/ultisnips)
  * [neosnippet](https://github.com/Shougo/neosnippet.vim)

### Tag navigation

  * [vim-gutentags](https://github.com/ludovicchabant/vim-gutentags)

## Alternatives

The following are some alternative LaTeX plugins for Vim:

* [LaTeX-Suite](http://vim-latex.sourceforge.net)

    The main difference between VimTeX and LaTeX-Suite (aka vim-latex) is
    probably that VimTeX does not try to implement a full fledged IDE for LaTeX
    inside Vim. E.g.:

    * VimTeX does not provide a full snippet feature, because this is better
      handled by [UltiSnips](https://github.com/SirVer/ultisnips) or
      [neosnippet](https://github.com/Shougo/neosnippet.vim) or similar snippet
      engines.
    * VimTeX builds upon Vim principles: It provides text objects for
      environments, inline math, it provides motions for sections and
      paragraphs
    * VimTeX uses `latexmk`, `latexrun`, `tectonic` or `arara` for compilation
      with a callback feature to get instant feedback on compilation errors
    * VimTeX is very modular: if you don't like a feature, you can turn it off.

* [TexMagic.nvim](https://github.com/jakewvincent/texmagic.nvim)

    "A simple, lightweight Neovim plugin that facilitates LaTeX build engine
    selection via magic comments. It is designed with the TexLab LSP server's
    build functionality in mind, which at the time of this plugin's inception
    had to be specified in init.lua/init.vim and could not be set on
    a by-project basis."

    This plugin should be combined with the TexLab LSP server, and it only
    works on neovim.

* [LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box)

    VimTeX currently has most of the features of LaTeX-Box, as well as
    some additional ones. See [here](#features) for a relatively complete list
    of features.

    One particular feature that LaTeX-Box has but VimTeX misses, is the ability
    to do single-shot compilation _with callback_. This functionality was
    removed because it adds a lot of complexity for relatively little gain
    (IMHO).

* [AutomaticTexPlugin](http://atp-vim.sourceforge.net)
* [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview)

For more alternatives and more information and discussions regarding LaTeX
plugins for Vim, see:

* [What are the differences between LaTeX plugins](http://vi.stackexchange.com/questions/2047/what-are-the-differences-between-latex-plugins)
* [List of LaTeX editors (not only Vim)](https://tex.stackexchange.com/questions/339/latex-editors-ides)

