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
    - [delim.vim](#delimvim)
    - [cache.vim](#cachevim)
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
- If their might be any plugin-clashes.
- If the user has the needed dependencies for their PDF-Viewer

## unite/sources

This directory is used to combine VimTex with
[denite](https://github.com/Shougo/denite.nvim) or
[unite](https://github.com/Shougo/unite.vim). These extra-plugins are mainly
used to list the TOC of your current document. Take a look into `:h vimtex-unite`, to get more information.

## vimtex

This directory has the main files. Each file should be self-explaining but here
are some files which might be good to know!

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

### compiler
As the directory names says: This directory includes the vim files to interact
with the given LaTeX compiler. Each file have similar function names like
`s:compiler.start`. You can take a look into these function to get a better
understanding how they work.

### debug.vim
This file is used for interal debugging and is not related to LaTeX at all. It
parses the stacktrace from the `v:throwpoint` variable (see `:h v:throwpoint`
        for more information). If this does not exist, then we forcibly create
it and remove the top element.
You can try this code as an example:
```vim
function! Test() abort
  try
    throw "Error message is here :D"
  catch
    call vimtex#debug#stacktrace(1)
  endtry
endfunction
```
Now enter `:call Test()` and the quickfix window should pop up with the `"Error
message is here :D"` message.

### complete (dir)
This directory includes all keywords which can prompt up in the omnifunc popup.

#### tools
This directory includes all glyphs like α and β.

### context

### fold
This directory takes care of folding your `tex` document like this:
![folding example](./documentation_images/folding.png)

The filenames in this directory represent what it folds.

### parser
This directory includes some functions to get some information about your latex
document in order to create the table of contents for instance:
![toc example](./documentation_images/toc.png)

### qf
This directory creates the output in your quickfix window if you compile
your LaTeX file. Here's an example which is generated through the `latexlog.vim`
file:
![quickfix example](./documentation_images/quickfix.png)

Each filename represents which file formats the error message for which LaTeX
filetype.

### syntax
This directory includes the syntax highlighting rules for each keyword in a
LaTeX file.

The `core.vim` file also includes the concealling characters starting from line
745 if you want to take a look into it.

The `p` directory just includes more syntax highlighting rules which are *only*
loaded if they are needed.

### text_obj
This file includes some functions which can be used to get some information
about the current user position. `envtargets.vim` includes for instance some
functions like `vimtex#text_obj#envtargets#current` to get the current
environment where the user is.

### view
As you might see due to the filenames: This directory includes functions to
interact with the given PDF-Viewer which you've declared in the
`g:vimtex_view_method`.

# ftplugin
Well nothing really big to say here: If you open a `bib` or `tex` tiletype
it'll look, if you have VimTex has been loaded.

# indent
The main function is `VimtexIndent` which returns the indent of the next line
you're writing. If you want to know how it's doing that, take a look into this
function!

# rplugin/python3/denite/source/vimtex.py
This file is used to interact with the
[denite.vim](https://github.com/Shougo/denite.nvim) plugin. For example to jump
to a section/subsection or chapter.

# syntax
The main file which loads the syntax highlighting settings according to its
needs because all syntax rules might wouldn't be worth it.

# test
This directory includes *all* test cases which have to pass in order to have a
stable and functional awesome VimTex plugin :) Each directory and filename
should be self explaining for which cases they are used for.
