" vimtex - LaTeX plugin for Vim
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
  let l:ids = reverse(call('vimtex#syntax#stack', a:000))
  let l:index = match(l:ids, '^texMath\%(' . s:mathzones . '\|Text\)')
  return l:index >= 0
        \ && match(l:ids[l:index], '^texMathText') == -1
endfunction

let s:mathzones = g:vimtex_syntax_enabled ? 'Region' : 'Zone'

" }}}1
