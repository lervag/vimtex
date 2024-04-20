" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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
  let l:groups = reverse(call('vimtex#syntax#stack', a:000))
  let l:group = matchstr(l:groups, s:__mathzone_regex)
  return l:group =~# '^texMathZone'
endfunction

" This specifies matchers that are combined for finding the group used to
" determine if we are in a mathzone. The first entry is `texMathZone`, which
" indicates that we are in a mathzone. The other entries are groups that
" indicate specifically that we are NOT in a mathzone. The entries here are
" part of the core spec. Extensions can register more groups that should be
" ignored with vimtex#syntax#register_mathzone_ignore.
let s:__mathzone_matchers = [
      \ 'texMathZone',
      \ 'texMathText',
      \ 'texMathTag',
      \ 'texRefArg',
      \]
let s:__mathzone_regex = '^\%(' . join(s:__mathzone_matchers, '\|') . '\)'

" }}}1
function! vimtex#syntax#add_to_mathzone_ignore(regex) abort " {{{1
  let s:__mathzone_matchers += [a:regex]
  let s:__mathzone_regex = '^\%(' . join(s:__mathzone_matchers, '\|') . '\)'
endfunction

" }}}1
