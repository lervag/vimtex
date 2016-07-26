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
  "
  " It seems that there is a bug when indenting after formatting text, where
  " for some reason, "getline(v:lnum)" does NOT get the current line, at least
  " not as seen in the buffer. I did not find a good way of solving this, and
  " so for now, I instead insist that the formatting operators, gw and gq, do
  " not reindent lines.
  "
  if v:operator =~# 'g[wq]' | return -1 | endif

  let l:nprev = s:get_prev_line(prevnonblank(v:lnum - 1))
  if l:nprev == 0 | return 0 | endif

  " Get current and previous line and remove comments
  let l:cur = substitute(getline(v:lnum), '\\\@<!%.*', '', '')
  let l:prev = substitute(getline(l:nprev),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if s:is_verbatim(l:cur, v:lnum)
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

  let l:nprev = s:get_prev_line(l:nprev, 'ignore-ampersands')
  if l:nprev == 0 | return 0 | endif
  let l:prev = getline(l:nprev)

  let l:ind = indent(l:nprev)
  let l:ind += s:indent_envs(l:cur, l:prev)
  let l:ind += s:indent_delims(l:cur, l:prev)
  let l:ind += s:indent_tikz(l:nprev, l:prev)
  return l:ind
endfunction
"}}}

function! s:get_prev_line(lnum, ...) " {{{1
  let l:ignore_amps = a:0 > 0

  let l:lnum = a:lnum
  let l:prev = getline(l:lnum)

  while l:lnum != 0
        \ && (l:prev =~# '^\s*%'
          \ || s:is_verbatim(l:prev, l:lnum)
          \ || match(l:prev, '\\\@<!&') >= 0)
    let l:lnum = prevnonblank(l:lnum - 1)
    let l:prev = getline(l:lnum)
  endwhile

  return l:lnum
endfunction

" }}}1
function! s:is_verbatim(line, lnum) " {{{1
  let l:env = a:line !~# '\v\\%(begin|end)\{%(verbatim|lstlisting|minted)'
  let l:syn = synIDattr(synID(a:lnum, 1, 1), 'name') ==# 'texZone'
  return l:env && l:syn
endfunction

" }}}1

function! s:indent_envs(cur, prev) " {{{1
  let l:ind = 0

  " First for general environments
  let l:ind += &sw*((a:prev =~# '\\begin{.*}') && (a:prev !~# 'document'))
  let l:ind -= &sw*((a:cur  =~# '\\end{.*}')   && (a:cur  !~# 'document'))

  " Indentation for prolonged items in lists
  let l:ind += &sw*((a:prev =~# s:envs_item)    && (a:cur  !~# s:envs_enditem))
  let l:ind -= &sw*((a:cur  =~# s:envs_item)    && (a:prev !~# s:envs_begitem))
  let l:ind -= &sw*((a:cur  =~# s:envs_endlist) && (a:prev !~# s:envs_begitem))

  return l:ind
endfunction

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
function! s:indent_tikz(lnum, prev) " {{{1
  if vimtex#env#is_inside('tikzpicture')
    let l:prev_starts = a:prev =~# s:tikz_commands
    let l:prev_stops  = a:prev =~# ';\s*$'

    " Increase indent on tikz command start
    if l:prev_starts && ! l:prev_stops
      return &sw
    endif

    " Decrease indent on tikz command end, i.e. on semicolon
    if ! l:prev_starts && l:prev_stops
      let l:context = join(getline(max([1,a:lnum-4]), a:lnum-1), '')
      return -&sw*(l:context =~# s:tikz_commands)
    endif
  endif

  return 0
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
