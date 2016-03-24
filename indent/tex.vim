" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:did_indent')
  finish
endif
let b:did_indent = 1
let b:did_vimtex_indent = 1

call vimtex#util#set_default('g:vimtex_indent_enabled', 1)
if !g:vimtex_indent_enabled | finish | endif

let s:cpo_save = &cpo
set cpo&vim

setlocal autoindent
setlocal indentexpr=VimtexIndent()
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=item

function! VimtexIndent() " {{{1
  " Find a non-blank non-comment line above the current line
  let l:nprev = prevnonblank(v:lnum - 1)
  while l:nprev != 0 && getline(l:nprev) =~# '^\s*%'
    let l:nprev = prevnonblank(l:nprev - 1)
  endwhile
  if l:nprev == 0
    return 0
  endif

  " Get current and previous line and remove comments
  let l:cur = substitute(getline(v:lnum), '\\\@<!%.*', '', '')
  let l:prev = substitute(getline(l:nprev),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if synIDattr(synID(v:lnum, indent(v:lnum), 1), 'name') ==# 'texZone'
    return empty(l:cur) ? indent(l:nprev) : indent(v:lnum)
  endif

  " Align on ampersands
  if l:cur =~# '^\s*&' && l:prev =~# '\\\@<!&.*'
    return indent(v:lnum) + match(l:prev, '\\\@<!&') - stridx(l:cur, '&')
  endif

  " Use previous indentation for comments
  if l:cur =~# '^\s*%'
    return indent(v:lnum)
  endif

  " Find previous non-empty non-comment non-ampersand line
  while l:nprev != 0 && (match(l:prev, '\\\@<!&') != -1 || l:prev =~# '^\s*%')
    let l:nprev = prevnonblank(l:nprev - 1)
    let l:prev = getline(l:nprev)
  endwhile
  if l:nprev == 0
    return 0
  endif

  let l:ind = indent(l:nprev)
  let l:ind += s:indent_envs(l:cur, l:prev)
  let l:ind += s:indent_delims(l:cur, l:prev)
  let l:ind += s:indent_tikz(l:prev)
  return l:ind
endfunction
"}}}

function! s:indent_envs(cur, prev) " {{{1
  let l:ind = 0

  " First for general environments
  let l:ind += &sw*((a:prev =~# '\\begin{.*}') && (a:prev !~# s:envs_ignore))
  let l:ind -= &sw*((a:cur  =~# '\\end{.*}')   && (a:cur  !~# s:envs_ignore))

  " Indentation for prolonged items in lists
  let l:ind += &sw*((a:prev =~# s:envs_item)    && (a:cur  !~# s:envs_enditem))
  let l:ind -= &sw*((a:cur  =~# s:envs_item)    && (a:prev !~# s:envs_begitem))
  let l:ind -= &sw*((a:cur  =~# s:envs_endlist) && (a:prev !~# s:envs_begitem))

  return l:ind
endfunction

let s:envs_ignore = 'document\|verbatim\|lstlisting'
let s:envs_lists = 'itemize\|description\|enumerate\|thebibliography'
let s:envs_item = '^\s*\\item'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
function! s:indent_delims(cur, prev) " {{{1
  let [l:open, l:close] = vimtex#delim#get_valid_regexps(v:lnum, col('.'))
  return &sw*(  max([s:count(a:prev, l:open) - s:count(a:prev, l:close), 0])
        \     - max([s:count(a:cur, l:close) - s:count(a:cur, l:open),   0]))
endfunction

" }}}1
function! s:indent_tikz(cur, prev) " {{{1
  if a:prev =~# s:tikz_commands && a:prev !~# ';'
    let l:ind += &sw
  elseif a:prev !~# s:tikz_commands && a:prev =~# ';'
    let l:ind -= &sw
  endif

  return l:ind
endfunction

let s:tikz_commands = '\v\\%(' . join([
        \ 'draw',
        \ 'fill',
        \ 'path',
        \ 'node',
        \ 'coordinate',
        \ 'add%(legendentry|plot)',
      \ ], '|') . ')'

" }}}1

function! s:count(line, pattern) " {{{1
  let sum = 0
  let indx = match(a:line, a:pattern)
  while indx >= 0
    let sum += 1
    let match = matchstr(a:line, a:pattern, indx)
    let indx += len(match)
    let indx = match(a:line, a:pattern, indx)
  endwhile
  return sum
endfunction

" }}}1

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker sw=2
