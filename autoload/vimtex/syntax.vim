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

  if exists('b:current_syntax')
    return
  elseif !get(g:, 'vimtex_syntax_alpha')
    source $VIMRUNTIME/syntax/tex.vim
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
    call vimtex#syntax#after#load()
  else
    augroup vimtex_syntax
      autocmd!
      autocmd User VimtexEventInitPost call vimtex#syntax#after#load()
    augroup END
  endif
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
