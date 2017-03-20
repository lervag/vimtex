# vimtex

vimtex is a [Vim](http://www.vim.org/) plugin that provides support for writing
LaTeX documents. It is based on
[LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box) and it shares a
similar goal: to provide a simple and lightweight LaTeX plugin. It has been
rewritten from scratch to provide a more modern and modular code base. See
[here](#alternatives) for some more comments on the difference between vimtex
and other LaTeX plugins for Vim.

[![Build Status](https://travis-ci.org/lervag/vimtex.svg?branch=master)](https://travis-ci.org/lervag/vimtex)
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5N4MFVXN7U8NW)

## Installation

If you use [vim-plug](https://github.com/junegunn/vim-plug), then add the
following line to your `vimrc` file:

```vim
Plug 'lervag/vimtex'
```

Or use some other plugin manager:
- [vundle](https://github.com/gmarik/vundle)
- [neobundle](https://github.com/Shougo/neobundle.vim)
- [pathogen](https://github.com/tpope/vim-pathogen)

## Quick Start

The following is a simple guide for how to use vimtex. It only displays the
most basic features. Users are _strongly_ encouraged to read or at least skim
through the documentation to learn about the different features and
possibilities provided by vimtex (see
[here](https://github.com/lervag/vimtex/blob/master/doc/vimtex.txt) or `:h
vimtex`).

![Quick start gif](media/quick_start.gif?raw=true)

## Features

Below is a list of features offered by vimtex.  The features are accessible as
both commands and mappings.  The mappings generally start with
`<localleader>l`, but if desired one can disable default mappings to define
custom mappings.  All features are enabled by default, but each feature may be
disabled if desired.

- Document compilation with
  [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/)
- Compilation of selected part of document
- Support for several PDF viewers with forward search
  - [MuPDF](http://www.mupdf.com/)
  - [Zathura](https://pwmt.org/projects/zathura/)
  - [Okular](https://okular.kde.org/)
  - [qpdfview](https://launchpad.net/qpdfview)
  - [SumatraPDF](http://www.sumatrapdfreader.org/free-pdf-reader.html)
  - Other viewers are supported through a general interface
- Completion of citations, labels, and file names for figures
- Document navigation through
  - table of content
  - table of labels
- Word count (through `texcount`)
- Motions
  - Move between sections with `[[`, `[]`, `][`, `]]`
  - Move between matching delimiters with `%`
- Text objects
  - `ic ac` Commands
  - `id ad` Delimiters
  - `ie ae` LaTeX environments
  - `i$ a$` Inline math structures
- Other mappings
  - Delete the surrounding command or environment with `dsc`/`dse`/`ds$`
  - Change the surrounding command or environment with `csc`/`cse`/`cs$`
  - Toggle starred command or environment with `tsc`/`tse`
  - Toggle between e.g. `()` and `\left(\right)` with `tsd`
  - Close the current environment/delimiter in insert mode with `]]`
  - Insert new command with `<F7>`
  - Convenient insert mode mappings for faster typing of e.g. maths
- Improved folding (`:h 'foldexpr'`)
- Improved indentation (`:h 'indentexpr'`)
- Improved syntax highlighting
  - Highlight matching delimiters
  - Support for `biblatex`/`natbib` package
  - Support for `cleveref` package
  - Support for `listings` package
  - Nested syntax highlighting (`minted`, `dot2tex`, `lualatex`,
    `gnuplottex`, `asymptote`)
- Support for multi-file project packages
  - [import](http://ctan.uib.no/macros/latex/contrib/import/import.pdf)
  - [subfiles](http://ctan.uib.no/macros/latex/contrib/subfiles/subfiles.pdf)

See the documentation for a thorough introduction to vimtex (e.g. `:h vimtex`).

## Alternatives

The following are some alternative LaTeX plugins for Vim:

- [LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box)

    vimtex currently has most of the features of LaTeX-Box, as well as
    some additional ones. See [here](#features) for a relatively complete list
    of features.

    One particular feature that LaTeX-Box has but vimtex misses, is the ability
    to do single-shot compilation _with callback_. This functionality was
    removed because it adds a lot of complexity for relatively little gain
    (IMHO).

    Note: LaTeX-Box is included with
    [vim-polyglot](https://github.com/sheerun/vim-polyglot). Some users are not
    quite aware of this and end up trying vimtex with LaTeX-Box enabled. This
    will not work --- please disable LaTeX-Box first!

- [LaTeX-Suite](http://vim-latex.sourceforge.net)

    The main difference between vimtex and LaTeX-Suite (aka vim-latex) is
    probably that vimtex does not try to implement a full fledged IDE for LaTeX
    inside Vim. E.g.:

    - vimtex does not provide a full snippet feature, because this is better
      handled by [UltiSnips](https://github.com/SirVer/ultisnips) or
      [neosnippet](https://github.com/Shougo/neosnippet.vim) or similar snippet
      engines.
    - vimtex builds upon Vim principles: It provides text objects for
      environments, inline math, it provides motions for sections and
      paragraphs
    - vimtex uses `latexmk` for compilation with a callback feature to get
      instant feedback on compilation errors
    - vimtex is very modular: if you don't like a feature, you can turn it off.

- [AutomaticTexPlugin](http://atp-vim.sourceforge.net)
- [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview)

For more alternatives and more information and discussions regarding LaTeX
plugins for Vim, see:

- [What are the differences between LaTeX
  plugins](http://vi.stackexchange.com/questions/2047/what-are-the-differences-between-latex-plugins)
- [List of LaTeX editors (not only
  Vim)](https://tex.stackexchange.com/questions/339/latex-editors-ides)

