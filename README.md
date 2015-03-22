# vimtex

vimtex is a [vim](http://www.vim.org/) plugin that provides support for writing
LaTeX documents.

## Features

Below is a list of features offered by vimtex.  The features are accessible as
both commands and mappings.  The mappings generally start with
`<localleader>l`, but if desired one can disable default mappings to define
custom mappings.  All features are enabled by default, but each feature may be
disabled if desired.

- Document compilation through
  [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/)
- Support for several PDF viewers with forward search
  - [MuPDF](http://www.mupdf.com/)
  - [Zathura](https://pwmt.org/projects/zathura/)
  - [Okular](https://okular.kde.org/)
  - [qpdfview](https://launchpad.net/qpdfview)
  - [SumatraPDF](http://www.sumatrapdfreader.org/free-pdf-reader.html)
  - Other viewers are supported through a general interface
- Completion of citations and labels
- Document navigation through tables of
  - content
  - labels
- Motions
  - Move between sections `[[ [] ][ ]]`
  - Move between delimiters `%` (with highlighting)
- Text objects
  - LaTeX environments `ie ae`
  - Inline math structures `i$ a$`
  - Delimiters `id ad`
- Utility mappings
  - Delete/Change surrounding command or environment `cse`, `dse`, `csc`, `dsc`
  - Toggle starred environment `tse`
  - Toggle delimiters, e.g. between `()` and `\left(\right)`, `tsd`
  - Close current environment in insert mode `]]`
- Improved folding (`:h 'foldexpr'`)
- Improved indentation (`:h 'indentexpr'`)

See the [doc/vimtex.txt](https://raw.githubusercontent.com/lervag/vimtex/master/doc/vimtex.txt) for a more thorough introduction of the plugin.

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

