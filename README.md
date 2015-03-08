# vimtex

## Introduction

`vimtex` is a [vim](http://www.vim.org/) plugin that provides support for writing LaTeX documents.  The
main features are:

1. Control over document compilation (through [latexmk](http://users.phys.psu.edu/~collins/software/latexmk-jcc/))
2. Completion of citations and labels
3. A Convenient table of contents
4. Control over `pdf` viewers with forward search for several different viewers
5. Some vim motions and mappings

See the [documentation](https://raw.githubusercontent.com/lervag/vimtex/master/doc/vimtex.txt) for a more thorough introduction of the plugin.

## Installation

### With gmarik vundle
_https://github.com/gmarik/vundle_

Add `Plugin 'lervag/vimtex'` to your ~/.vimrc and run
`:PluginInstall` in a vim buffer. Add `!` to the command to update.

### With neobundle
_https://github.com/Shougo/neobundle.vim_

Add `NeoBundle 'lervag/vimtex'` to your ~/.vimrc and run
`:NeoBundleInstall` in a vim buffer. Add `!` to the command to update.

### With pathogen
_https://github.com/tpope/vim-pathogen_

Add the vimtex bundle to your bundle directory, for instance with `git
clone`.  This will typically be enough:

    cd ~/.vim/bundle
    git clone git://github.com/lervag/vimtex

### Without a plugin manager

Copy the directories to your `.vim/` folder.

## Alternatives

There exists several vim plugins for writing LaTeX documents.  Some of the most
popular and/or interesting ones are:
- [LaTeX-Suite](http://vim-latex.sourceforge.net):
  [vimscript#475](http://www.vim.org/scripts/script.php?script_id=475)
- [AutomaticTexPlugin](http://atp-vim.sourceforge.net):
  [vimscript#2945](http://www.vim.org/scripts/script.php?script_id=2945)
- [LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box):
  [vimscript#3109](http://www.vim.org/scripts/script.php?script_id=3109)
- [vim-latex-live-preview](https://github.com/xuhdev/vim-latex-live-preview):
  [vimscript#4524](http://www.vim.org/scripts/script.php?script_id=4524)

