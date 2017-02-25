" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#include#expr() " {{{1
  let l:candidates = [
        \ s:get_include_argument(),
        \ v:fname
        \]

  for l:candidate in filter(l:candidates, '!empty(v:val)')
    let l:candidate = s:try_suffixes(s:clean(l:candidate))
    if !empty(l:candidate) | return l:candidate | endif
  endfor

  return v:fname
endfunction

" }}}1

function! s:get_include_argument() " {{{1
  let [l:lnum, l:cnum] = searchpairpos(&l:include, '', '}', 'bnW')
  if l:lnum != line('.') | return '' | endif

  let l:cmd = vimtex#cmd#get_at(l:lnum, l:cnum)
  let l:args = get(l:cmd, 'args', [{'text' : ''}])
  let l:file = l:args[0].text
  return l:file
endfunction

" }}}1
function! s:clean(file) " {{{1
  let l:file = substitute(a:file, '^\s*"\|"\s*$', '', 'g')
  let l:file = substitute(l:file, '\\space', '', 'g')

  return l:file
endfunction

" }}}1
function! s:try_suffixes(file) " {{{1
  for l:suffix in split(&l:suffixesadd, ',')
    let l:candidate = a:file . l:suffix
    if filereadable(l:candidate)
      return l:candidate
    endif
  endfor

  return ''
endfunction

" }}}1

" vim: fdm=marker sw=2
