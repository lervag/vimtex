" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#syntax#init() abort " {{{1
  " This script is a fork of version 119 (dated 2020-06-29) of the syntax script
  " "tex.vim" created and maintained by Charles E. Campbell [0].
  "
  " [0]: http://www.drchip.org/astronaut/vim/index.html#SYNTAX_TEX

  if exists('b:current_syntax') || !get(g:, 'vimtex_syntax_alpha')
    return
  endif

  call vimtex#syntax#core#init()
endfunction

  " }}}1
function! vimtex#syntax#init_post() abort " {{{1
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

  " Load syntax for documentclass and packages
  call vimtex#syntax#load#packages()

  " Hack to make it possible to determine if vimtex syntax was loaded
  syntax match texVimtexLoaded 'dummyVimtexLoadedText' contained
endfunction

" }}}1

function! vimtex#syntax#stack(...) abort " {{{1
  let l:pos = a:0 > 0 ? [a:1, a:2] : [line('.'), col('.')]
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  call map(l:pos, 'max([v:val, 1])')

  return map(synstack(l:pos[0], l:pos[1]), "synIDattr(v:val, 'name')")
endfunction

" }}}1
function! vimtex#syntax#in(name, ...) abort " {{{1
  return match(call('vimtex#syntax#stack', a:000), '^' . a:name) >= 0
endfunction

" }}}1
function! vimtex#syntax#in_comment(...) abort " {{{1
  return call('vimtex#syntax#in', ['texComment'] + a:000)
endfunction

" }}}1
function! vimtex#syntax#in_mathzone(...) abort " {{{1
  return call('vimtex#syntax#in', ['texMathZone'] + a:000)
endfunction

" }}}1

function! s:is_loaded() abort " {{{1
  let l:result = vimtex#util#command('syntax')
  return !empty(filter(l:result, 'v:val =~# "texVimtexLoaded"'))
endfunction

" }}}1
