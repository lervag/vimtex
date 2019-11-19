" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#init() abort " {{{1
  if !get(g:, 'vimtex_syntax_enabled', 1) | return | endif

  " The following ensures that syntax addons are not loaded until after the
  " filetype plugin has been sourced. See e.g. #1428 for more info.
  if exists('b:vimtex')
    call vimtex#syntax#load()
  else
    augroup vimtex_syntax
      autocmd!
      autocmd User VimtexEventInitPost call vimtex#syntax#load()
    augroup END
  endif
endfunction

" }}}1
function! vimtex#syntax#load() abort " {{{1
  if s:is_loaded() | return | endif

  " Initialize project cache (used e.g. for the minted package)
  if !has_key(b:vimtex, 'syntax')
    let b:vimtex.syntax = {}
  endif

  " Initialize b:vimtex_syntax
  let b:vimtex_syntax = {}

  " Reset included syntaxes (necessary e.g. when doing :e)
  call vimtex#syntax#misc#include_reset()

  " Set some better defaults
  syntax spell toplevel
  syntax sync maxlines=500

  " Load some general syntax improvements
  call vimtex#syntax#load#general()

  "
  " Load syntax for documentclass
  "
  try
    call vimtex#syntax#p#{b:vimtex.documentclass}#load()
  catch /E117:/
  endtry

  "
  " Load syntax for packages
  "
  for l:package in keys(b:vimtex.packages)
    try
      call vimtex#syntax#p#{l:package}#load()
    catch /E117:/
    endtry
  endfor

  " Hack to make it possible to determine if vimtex syntax was loaded
  syntax match texVimtexLoaded 'dummyVimtexLoadedText' contained
endfunction

" }}}1

function! s:is_loaded() abort " {{{1
  if exists('*execute')
    let l:result = split(execute('syntax'), "\n")
    return !empty(filter(l:result, 'v:val =~# "texVimtexLoaded"'))
  else
    return 0
  endif
endfunction

" }}}1
