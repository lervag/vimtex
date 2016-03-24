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

  " Add indent on begin environment
  if l:prev =~# '\\begin{.*}' && l:prev !~ s:envs_noindent
    let l:ind = l:ind + &sw

    " Add extra indent for list environments
    if l:prev =~ s:envs_lists
      let l:ind = l:ind + &sw
    endif
  endif

  " Subtract indent on end environment
  if l:cur =~# '\\end{.*}' && l:cur !~ s:envs_noindent
    let l:ind = l:ind - &sw

    " Subtract extra indent for list environments
    if l:cur =~ s:envs_lists
      let l:ind = l:ind - &sw
    endif
  endif

  " Indent opening and closing delimiters
  let [l:re_open, l:re_close] = vimtex#delim#get_valid_regexps(v:lnum, col('.'))
  let l:ind += &sw*(
        \   max([s:count(l:prev, l:re_open)  - s:count(l:prev, l:re_close), 0])
        \ - max([s:count(l:cur, l:re_close) - s:count(l:cur, l:re_open), 0]))

  " Indent list items
  if l:prev =~# '^\s*\\\(bib\)\?item'
    let l:ind += &sw
  endif
  if l:cur =~# '^\s*\\\(bib\)\?item'
    let l:ind -= &sw
  endif

  " Indent tikz elements
  if l:prev =~# s:tikz_commands && l:prev !~# ';'
    let l:ind += &sw
  elseif l:prev !~# s:tikz_commands && l:prev =~# ';'
    let l:ind -= &sw
  endif

  return l:ind
endfunction
"}}}
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

" {{{1 Script variables

" Define some common patterns
let s:envs_lists = 'itemize\|description\|enumerate\|thebibliography'
let s:envs_noindent = 'document\|verbatim\|lstlisting'
let s:tikz_commands = '\v\\%(' . join([
        \ 'draw',
        \ 'fill',
        \ 'path',
        \ 'node',
        \ 'coordinate',
        \ 'add%(legendentry|plot)',
      \ ], '|') . ')'

" }}}1

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker sw=2
