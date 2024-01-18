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
- [Configuration](#configuration)
- [Quick Start](#quick-start)
  - [Tutorial](#tutorial)
  - [Documentation](#documentation)
- [Screenshots](#screenshots)
  - [GIFs](#gifs)
- [Features](#features)
- [Other relevant plugins](#other-relevant-plugins)
  - [Linting and syntax checking](#linting-and-syntax-checking)
  - [Snippets and templates](#snippets-and-templates)
  - [Tag navigation](#tag-navigation)
- [Alternatives](#alternatives)
- [VimTeX on the Web](#vimtex-on-the-web)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Requirements

VimTeX requires Vim version 8.0.1453 or Neovim version 0.4.3. The requirements
were updated in July 2020 after the release of VimTeX 1.0. If you are stuck
on older versions of Vim or Neovim, then you should not use the most recent
version of VimTeX, but instead remain at the v1.0 tag.

Some features require external tools. For example, the default compiler backend
relies on [latexmk](https://www.cantab.net/users/johncollins/latexmk/index.html).
Users are encouraged to read the requirements section in the
[documentation](doc/vimtex.txt) (`:h vimtex-requirements`).

## Installation

If you use [vim-plug](https://github.com/junegunn/vim-plug) or [packer.nvim](https://github.com/wbthomason/packer.nvim), then add one of the
following lines to your `vimrc` file, correspondingly:

```vim
" vim-plug
Plug 'lervag/vimtex'

" packer.nvim
use 'lervag/vimtex'
```

Or use some other plugin manager:
* [vundle](https://github.com/gmarik/vundle)
* [neobundle](https://github.com/Shougo/neobundle.vim)
* [pathogen](https://github.com/tpope/vim-pathogen)

**Note**: Many plugin managers provide mechanisms to lazy load plugins. Please
    don't use this for VimTeX! VimTeX is already lazy loaded by virtue of being
    a filetype plugin and by using the autoload mechanisms. There is therefore
    nothing to gain by forcing VimTeX to lazily load through the plugin
    manager. In fact, doing it will _break_ the inverse-search mechanism, which
    relies on a _global_ command (`:VimtexInverseSearch`).

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

## Configuration

After installing VimTeX, you should edit your `.vimrc` file or `init.vim` file
to configure VimTeX to your liking. Users should read the documentation to
learn the various configuration possibilities, but the below is a simple
overview of some of the main aspects.

```vim
" This is necessary for VimTeX to load properly. The "indent" is optional.
" Note that most plugin managers will do this automatically.
filetype plugin indent on

" This enables Vim's and neovim's syntax-related features. Without this, some
" VimTeX features will not work (see ":help vimtex-requirements" for more
" info).
syntax enable

" Viewer options: One may configure the viewer either by specifying a built-in
" viewer method:
let g:vimtex_view_method = 'zathura'

" Or with a generic interface:
let g:vimtex_view_general_viewer = 'okular'
let g:vimtex_view_general_options = '--unique file:@pdf\#src:@line@tex'

" VimTeX uses latexmk as the default compiler backend. If you use it, which is
" strongly recommended, you probably don't need to configure anything. If you
" want another compiler backend, you can change it as follows. The list of
" supported backends and further explanation is provided in the documentation,
" see ":help vimtex-compiler".
let g:vimtex_compiler_method = 'latexrun'

" Most VimTeX mappings rely on localleader and this can be changed with the
" following line. The default is usually fine and is the symbol "\".
let maplocalleader = ","
```

**Note**: If the compiler or the viewer doesn't start properly, one may
  type `<localleader>li` to view the system commands that were executed to
  start them. To inspect the compiler output, use `<localleader>lo`.

## Quick Start

The following video shows how to use VimTeX's main features (credits:
[@DustyTopology](https://github.com/DustyTopology) from
[#1946](https://github.com/lervag/vimtex/issues/1946#issuecomment-846345095)).
The example LaTeX file used in the video is available under
[`test/example-quick-start/main.tex`](test/example-quick-start/main.tex) and it
may be instructive to copy the file and play with it to learn some of these
basic functions.

https://user-images.githubusercontent.com/66584581/119213849-1b7d4080-ba77-11eb-8a31-7ff7b9a4a020.mp4

### Tutorial

Both new and experienced users are also encouraged to read the third-party
article [Getting started with the VimTeX
plugin](https://www.ejmastnak.com/tutorials/vim-latex/vimtex.html). The
article covers VimTeX's core features and contains plenty of examples and
high-resolution animations intended to help new users ease into working with
the plugin.

### Documentation

Users are of course _strongly_ encouraged to read the documentation, at least
the introduction, to learn about the different features and possibilities
provided by VimTeX (see [`:h vimtex`](doc/vimtex.txt)). Advanced users and
potential developers may also be interested in reading the supplementary
documents:

* [CONTRIBUTING.md](CONTRIBUTING.md)
* [DOCUMENTATION.md](DOCUMENTATION.md)

## Screenshots

Here is an example of the syntax highlighting provided by VimTeX. The conceal
feature is active on the right-hand side split. The example is made by
@DustyTopology with the
[vim-colors-xcode](https://github.com/arzg/vim-colors-xcode) colorscheme with
some minor adjustments [described
here](https://github.com/lervag/vimtex/issues/1946#issuecomment-843674951).

![Syntax example](https://github.com/lervag/vimtex-media/blob/main/img/syntax.png)

### GIFs

See the file [VISUALS.md](VISUALS.md) for screencast-style GIFs demonstrating
VimTeX's core motions, text-editing commands, and text objects.

## Features

Below is a list of features offered by VimTeX. The features are accessible as
both commands and mappings. The mappings generally start with `<localleader>l`,
but if desired one can disable default mappings to define custom mappings. 
Nearly all features are enabled by default, but each feature may be disabled if
desired. The two exceptions are code folding and formating, which are disabled
by default and must be manually enabled.

- Document compilation with
  [latexmk](https://www.cantab.net/users/johncollins/latexmk/index.html),
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
  - [TeXShop](https://pages.uoregon.edu/koch/texshop/)
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
  - table of contents
  - table of labels
  - proper settings for `'include'`, `'includexpr'`, `'suffixesadd'` and
    `'define'`, which among other things
    - allow `:h include-search` and `:h definition-search`
    - give enhanced `gf` command
- Easy access to (online) documentation of packages
- Word count (through `texcount`)
- Motions ([link to GIF demonstrations](VISUALS.md#motion-commands))
  - Move between section boundaries with `[[`, `[]`, `][`, and `]]`
  - Move between environment boundaries with `[m`, `[M`, `]m`, and `]M`
  - Move between math environment boundaries with `[n`, `[N`, `]n`, and `]N`
  - Move between frame environment boundaries with `[r`, `[R`, `]r`, and `]R`
  - Move between comment boundaries with `[*` and `]*`
  - Move between matching delimiters with `%`
- Text objects ([link to GIF demonstrations](VISUALS.md#text-objects))
  - `ic ac` Commands
  - `id ad` Delimiters
  - `ie ae` LaTeX environments
  - `i$ a$` Math environments
  - `iP aP` Sections
  - `im am` Items
- Other mappings ([link to GIF demonstrations](VISUALS.md#deleting-surrounding-latex-content))
  - Delete the surrounding command, environment or delimiter with
    `dsc`/`dse`/`ds$`/`dsd`
  - Change the surrounding command, environment or delimiter with
    `csc`/`cse`/`cs$`/`csd`
  - Toggle starred command or environment with `tsc`/`tse`
  - Toggle inline and displaymath with `ts$`
  - Toggle between e.g. `()` and `\left(\right)` with `tsd`
  - Toggle (inline) fractions with `tsf`
  - Close the current environment/delimiter in insert mode with `]]`
  - Add `\left ... \right)` modifiers to surrounding delimiters with `<F8>`
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
vimtex-and-friends`](doc/vimtex.txt#L540).

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

## VimTeX on the Web

VimTeX users may be interested in reading
[@ejmastnak](https://github.com/ejmastnak)'s series on [Efficient LaTeX Using
(Neo)Vim](https://www.ejmastnak.com/tutorials/vim-latex/intro.html), which
covers all the fundamentals of setting up a VimTeX-based LaTeX workflow,
including usage of the VimTeX plugin, compilation, setting up forward and
inverse search with a PDF reader, and Vimscript tools for user-specific
customization.

If you know of (or create) other up-to-date, high-quality guides to VimTeX's
features on third-party websites, feel free to submit a pull request updating
this section.
