# vim-latex
## Introduction

There exists several LaTeX plugins for vim, for instance:
- [LaTeX-Suite](http://vim-latex.sourceforge.net):
  [vimscript#475](http://www.vim.org/scripts/script.php?script_id=475)
- [AutomaticTexPlugin](http://atp-vim.sourceforge.net):
  [vimscript#2945](http://www.vim.org/scripts/script.php?script_id=2945)
- [LaTeX-Box](https://github.com/LaTeX-Box-Team/LaTeX-Box):
  [vimscript#3109](http://www.vim.org/scripts/script.php?script_id=3109)

I have been using both LaTeX-Suite and LaTeX-Box myself, but I found both of
these to be relatively bulky and difficult to manage and extend.  LaTeX-Box
was supposed to be simple and lightweight, and I think it was close to being
just that.  However, after having worked on it for some time, I felt that much
of the simplicity could be improved by a complete restructuring.

Enter vim-latex, which is a lightweight and simple plugin that provides LaTeX
support for vim.  It has most of the functionality of LaTeX-Box, but the idea
is to combine vim-latex with the strength of other plugins.  I personally
recommend [UltiSnips](https://github.com/SirVer/ultisnips) for snippets and
[neocomplete](https://github.com/Shougo/neocomplete.vim) for completion.

Note that vim-latex should not be confused with LaTeX-Suite, which is also to
some extent known as vim-latex.  The present plugin is not related to
LaTeX-Suite in any way.

Read the documentation for a more thorough introduction.

## Installation
### With gmarik vundle
_https://github.com/gmarik/vundle_

Add `Plugin 'lervag/vim-latex'` to your ~/.vimrc and run
`:PluginInstall` in a vim buffer. Add `!` to the command to update.

### With neobundle
_https://github.com/Shougo/neobundle.vim_

Add `NeoBundle 'lervag/vim-latex'` to your ~/.vimrc and run
`:NeoBundleInstall` in a vim buffer. Add `!` to the command to update.

### With pathogen
_https://github.com/tpope/vim-pathogen_

Add the vim-latex bundle to your bundle directory, for instance with `git
clone`.  This will typically be enough:

    cd ~/.vim/bundle
    git clone git://github.com/lervag/vim-latex

### Without a plugin manager

Copy the directories to your `.vim/` folder.
