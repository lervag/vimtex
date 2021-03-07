# Documentation

Welcome to the high-level documentation of **VimTex**.

This file should help you to understand the structure of this plugin and how
it works.

So first of all, we're taking a look into the first layer of the plugin, after
that, we're going to through each necessary directory, if it needs some more
description. We won't go through _every_ file, because it would take a little
bit too long the most should be probably self explained.

This file works as follows:
The table of contents has the same structure as the file structure of
**VimTex**. If you want to know something about the
`vimtex/autoload/vimtex/compiler` directory, than you can lookup the path in the
table of contents and click on it. (Hopefully) It'll give you some nice
information.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [after/ftplugin](#afterftplugin)
- [autoload](#autoload)
  - [health](#health)
  - [unite/sources](#unitesources)
  - [vimtex](#vimtex)
    - [compiler](#compiler)
    - [complete](#complete)
      - [tools](#tools)
        - [unicode-math](#unicode-math)
    - [context](#context)
    - [fold](#fold)
    - [parser](#parser)
      - [toc](#toc)
    - [qf](#qf)
    - [syntax](#syntax)
      - [p](#p)
    - [text_obj](#text_obj)
    - [view](#view)
- [compiler](#compiler-1)
- [doc](#doc)
- [docker](#docker)
- [ftdetect](#ftdetect)
- [ftplugin](#ftplugin)
- [indent](#indent)
- [media](#media)
- [rplugin/python3/denite/source/](#rpluginpython3denitesource)
- [syntax](#syntax-1)
- [test](#test)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# after/ftplugin

Currently there's only one file in it which makes sure that VimTex loaded
successfully and that there're no conflicts with other plugins like LaTeX-Box.

# autoload

## health

This directory has the following health-checks functions:

- If the user has a valid vim version
- If the user selected a valid compiler
- If their might be any plugin-clashe.
- If the user has the needed dependencies for their PDF-Viewer

## unite/sources

This directory is used to combine VimTex with
[denite](https://github.com/Shougo/denite.nvim) or
[unite](https://github.com/Shougo/unite.vim). These extra-plugins are mainly
used to list the TOC of your current document. Take a look into `:h vimtex-unite`, to get more information.

## vimtex

This directory has the main files. Each filename should explain themself
for what they're used for. But here's a little table which explains
some files which are nice to know:

### delim.vim

This file includes some functions to detect the surrounding delimiters like
this:
```tex
\begin{Environment}
    Some awesome text |
\end{Environment}
```

The vertical line (`|`) should represent your cursor. Now you could use the
`vimtex#delim#get_surrounding('env_tex')` function in order to get the current
environment where the user is. Here's an example code:
```vim
" Return values are dictionaries
let [l:open, l:close] = vimtex#delim#get_surrounding('env_tex')

" Empty dicts mean we did not find a surrounding environment
if empty(l:open) | return | endif

" The dicts have several attributes, the most important are probably these:
echo l:open.name
echo l:open.lnum
echo l:open.cnum
```

For more information, take a look into [this
issue](https://github.com/lervag/vimtex/issues/1981#issuecomment-792263781).

### cache.vim
This file includes some functions to create and access your own caches.
Here's an example:
```vim
function VimTexCacheExample()
    " create a new cache (if the name doesn't exist yet)
    " with an attribute 'number'. So the cache would be like that:
    "
    "   let l:test = {
    "     'number' = 10,
    "   }
    let l:my_cache = vimtex#cache#open('cache_name', {'number' : 10})

    " change the value in you cache
    let l:my_cache['number'] = 9001

    " will print '9001'
    echo l:my_cache['number']

    " save your changes
    " In general it'll be saved in your `$XDG_CACHE_HOME/vimtex/` directory
    " (normally '~/.cache/vimtex') in the appropriate tex-file where you accessed
    " cache file.
    call vimtex#cache#close('cache_name')
endfunction
```

<!-- TODO: doc.vim, echo.vim -->

### compiler

### complete

#### tools

##### unicode-math

### context

### fold

### parser

#### toc

### qf

### syntax

#### p

### text_obj

### view

# compiler

# doc

# docker

# ftdetect

# ftplugin

# indent

# media

# rplugin/python3/denite/source/

# syntax

# test
