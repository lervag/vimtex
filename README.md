# vimtex

A [vim](http://www.vim.org/) plugin that provides support for writing
LaTeX documents.

## Features

Below is a list of features offered by vimtex.  The features are accessible as
both commands and mappings.  The mappings generally start with
`<localleader>l`, but if desired one can disable default mappings to define
custom mappings.  All features are enabled by default, but each feature may be
disabled if desired.

- Document compilation with
  [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/)
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
  - `ip ap` Paragraphs
- Other mappings
  - Delete the surrounding command or environment with `dsc`/`dse`/`ds$`
  - Change the surrounding command or environment with `csc`/`cse`/`cs$`
  - Toggle starred environment with `tse`
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
  - Support for `minted` package
  - Support for `dot2tex` with nested syntax highlighting
- Support for multi-file project packages
  - [import](http://ctan.uib.no/macros/latex/contrib/import/import.pdf)
  - [subfiles](http://ctan.uib.no/macros/latex/contrib/import/import.pdf)

See the documentation for a more thorough introduction of the plugin (e.g. `:h
vimtex`).

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

## Alternatives

- [LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box)
- [LaTeX-Suite](http://vim-latex.sourceforge.net)
- [AutomaticTexPlugin](http://atp-vim.sourceforge.net)
- [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview)

## License

The MIT license (MIT)

Copyright (c) 2016 Karl Yngve Lervåg

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

