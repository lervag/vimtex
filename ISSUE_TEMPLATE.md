# Explain the issue

A good issue ticket typically consists of the following parts. For feature requests, step 3 may often suffice (although steps 1 and 2 are always very much appreciated!). Also, please read [this guide](https://guides.github.com/features/mastering-markdown/) on how to format Github issues.

1. A minimal `vimrc` file, for instance:

    ```vim
    set nocompatible
    let &rtp  = '~/.vim/bundle/vimtex,' . &rtp
    let &rtp .= ',~/.vim/bundle/vimtex/after'

    " Load other plugins, if necessary
    " let &rtp = '~/path/to/other/plugin,' . &rtp

    filetype plugin indent on
    syntax enable

    " Vimtex options go here
    ```

2. A minimal `.tex` file, such as:

    ```tex
    \documentclass{minimal}
    \begin{document}

    Hello World!

    \end{document}
    ```

3. A concise description of the issue and **the steps to reproduce** it. This should include something like `vim --servername VIM -u vimrc mwe.tex` to show that one understands the use of minimal vimrc files.

   Often it is useful to describe the *expected behaviour* and the *observed behaviour*.

   Note: On Windows most people use the GUI `gvim`, and it may seem difficult with a custom `_vimrc` file. In this case, I suggest that one makes a copy of ones `_vimrc` file, then deletes the content and uses the above template instead.

4. A `.latexmkrc` file [*if relevant*].

