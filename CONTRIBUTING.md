# Guide for code contributions

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Branch model](#branch-model)
- [Documentation style](#documentation-style)
- [Code style](#code-style)
- [Running tests](#running-tests)
- [Documentation](#documentation)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Branch model

VimTeX is developed mainly through the master branch, and pull requests should
be [fork based](https://help.github.com/articles/using-pull-requests/).

## Documentation style

Vim help files have their own specific syntax. There is a Vim help section on
how to write them, see [`:h help-writing`](http://vimdoc.sourceforge.net/htmldoc/helphelp.html#help-writing).

The VimTeX documentation style should be relatively clear, and it should be
easy to see from the existing documentation how to write it. Still, here are
some pointers:

- Max 80 columns per line
- Use the help tag system for pointers to other parts of the Vim documentation
- Use line of `=`s to separate sections
- Use line of `-`s to separate subsections
- The section tags should be right aligned at the 79th column
- Sections should be included and linked to from the table of contents

## Code style

When submitting code for VimTeX, please adhere to the following standards:

- Use `shiftwidth=2` - no tabs!
- Write readable code
  - Break lines for readability
    - Line should not be longer than 80 columns
  - Use comments:
    - For complex code that is difficult to understand
    - Simple code does not need comments
  - Use (single) empty lines to separate logical blocks of code
  - Use good variable names
    - The name should indicate what the variable is/does
    - Variable names should be lower case
    - Local function variables should be preceded with `l:`
  - Prefer single quoted strings
  - See also the [Google vimscript style
    guide](https://google.github.io/styleguide/vimscriptguide.xml)
- Use markers for folding
  - I generally only fold functions, and I tend to group similar functions so
    that when folded, I get a nice structural overview of a file
  - See some of the files for examples of how I do this

## Running tests

New functionality should be accompanied by tests. Tests can be run from the
`test` folder with `make`. The tests currently only run on Linux, and the
following utilities are required to run all the tests:

- `wget`
- `chronic` (from [moreutils](https://joeyh.name/code/moreutils/))

These utilities may not come with all Linux distributions and may need to be
installed with your favorite package manager (e.g. `yum`, `apt-get`, or `brew`
on Mac).

By default, the tests are run with the Neovim executable `nvim`. You can change
the executable by setting the environment variable `MYVIM` before running. To
run with vanilla vim, use `MYVIM="vim -T dumb --not-a-term --noplugin -n"`.
Either export this in your shell, or prepend to `make`, that is, run
`MYVIM="vim -T dumb --not-a-term --noplugin -n" make`.

## Documentation
This section should help you to understand the structure of this plugin and how
it works.

So first of all, we're taking a look into the first layer of the plugin, after
that, we're going to through each necessary directory, if it needs some more
description. We won't go through *every* file, because it would take a little
bit too long the most should be probably self explained.
```
vimtex
├── after
│   └── ftplugin
│       └── tex.vim
├── autoload
│   ├── health
│   ├── unite
│   ├── vimtex
│   └── vimtex.vim
├── compiler
│   ├── bibertool.vim
│   ├── chktex.vim
│   ├── lacheck.vim
│   ├── style-check.vim
│   ├── textidote.vim
│   └── vlty.vim
├── CONTRIBUTING.md
├── doc
│   ├── targets-textobj-cheatsheet.md
│   └── vimtex.txt
├── docker
│   └── Dockerfile
├── ftdetect
│   └── tex.vim
├── ftplugin
│   ├── bib.vim
│   └── tex.vim
├── indent
│   ├── bib.vim
│   └── tex.vim
├── LICENSE.md
├── media
│   └── quick_start.gif
├── README.md
├── rplugin
│   └── python3
│       └── denite
│           └── source
│               └── vimtex.py
├── syntax
│   └── tex.vim
├── test
└── xclip
```
