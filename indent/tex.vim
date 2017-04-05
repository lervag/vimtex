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

if !get(g:, 'vimtex_indent_enabled', 1) | finish | endif

let s:cpo_save = &cpoptions
set cpoptions&vim

setlocal autoindent
setlocal indentexpr=VimtexIndent()
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=item

function! VimtexIndent() " {{{1
  let l:lnum = v:lnum
  let l:prev_lnum = s:get_prev_line(prevnonblank(l:lnum - 1), 0)
  if l:prev_lnum == 0 | return indent(l:lnum) | endif

  " Get current and previous line and remove comments
  let l:line = substitute(getline(l:lnum), '\\\@<!%.*', '', '')
  let l:prev_line = substitute(getline(l:prev_lnum),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if s:is_verbatim(l:line, l:lnum)
    return empty(l:line) ? indent(l:prev_lnum) : indent(l:lnum)
  endif

  " Align on ampersands
  if get(g:, 'vimtex_indent_on_ampersands', 1)
        \ && l:line =~# '^\s*&'
        \ && l:prev_line =~# '\\\@<!&.*'
    return indent(l:lnum) + match(l:prev_line, '\\\@<!&') - stridx(l:line, '&')
  endif

  " Use previous indentation for comments
  if l:line =~# '^\s*%'
    return indent(l:lnum)
  endif

  " Ensure previous line does not start with ampersand
  let l:prev_lnum = s:get_prev_line(l:prev_lnum,
        \ get(g:, 'vimtex_indent_on_ampersands', 1))
  if l:prev_lnum == 0 | return 0 | endif
  let l:prev_line = substitute(getline(l:prev_lnum), '\\\@<!%.*', '', '')

  " Indent environments, delimiters, and tikz
  let l:ind = indent(l:prev_lnum)
  let l:ind += s:indent_envs(l:line, l:prev_line)
  let l:ind += s:indent_delims(l:line, l:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)
  return l:ind
endfunction
"}}}

function! s:get_prev_line(lnum, ignore_amps) " {{{1
  let l:lnum = a:lnum
  let l:prev = getline(l:lnum)

  while l:lnum != 0
        \ && (l:prev =~# '^\s*%'
        \     || s:is_verbatim(l:prev, l:lnum)
        \     || a:ignore_amps && match(l:prev, '^\s*&') >= 0)
    let l:lnum = prevnonblank(l:lnum - 1)
    let l:prev = getline(l:lnum)
  endwhile

  return l:lnum
endfunction

" }}}1
function! s:is_verbatim(line, lnum) " {{{1
  return a:line !~# '\v\\%(begin|end)\{%(verbatim|lstlisting|minted)'
        \ && vimtex#env#is_inside('\%(lstlisting\|verbatim\|minted\)')
endfunction

" }}}1

function! s:indent_envs(cur, prev) " {{{1
  let l:ind = 0

  " First for general environments
  let l:ind += &sw*((a:prev =~# '\\begin{.*}') && (a:prev !~# s:envs_ignored))
  let l:ind -= &sw*((a:cur  =~# '\\end{.*}')   && (a:cur  !~# s:envs_ignored))

  " Indentation for prolonged items in lists
  let l:ind += &sw*((a:prev =~# s:envs_item)    && (a:cur  !~# s:envs_enditem))
  let l:ind -= &sw*((a:cur  =~# s:envs_item)    && (a:prev !~# s:envs_begitem))
  let l:ind -= &sw*((a:cur  =~# s:envs_endlist) && (a:prev !~# s:envs_begitem))

  return l:ind
endfunction

let s:envs_ignored = '\v'
      \ . join(get(g:, 'vimtex_indent_ignored_envs', ['document']), '|')
let s:envs_lists = 'itemize\|description\|enumerate\|thebibliography'
let s:envs_item = '^\s*\\item'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
function! s:indent_delims(line, lnum, prev_line, prev_lnum) " {{{1
  return &sw*(  max([  s:count(a:prev_line, s:re_open)
        \            - s:count(a:prev_line, s:re_close), 0])
        \     - max([  s:count(a:line, s:re_close)
        \            - s:count(a:line, s:re_open), 0]))
endfunction

let s:re_open = join([
      \ g:vimtex#delim#re.delim_mod_math.open,
      \ '{',
      \ '\\\@<!\\\[',
      \], '\|')
let s:re_close = join([
      \ g:vimtex#delim#re.delim_mod_math.close,
      \ '}',
      \ '\\\]',
      \], '\|')

" }}}1
function! s:indent_tikz(lnum, prev) " {{{1
  if !has_key(b:vimtex.packages, 'tikz') | return 0 | endif

  let l:env_lnum = vimtex#env#is_inside('tikzpicture')
  if l:env_lnum > 0 && l:env_lnum < a:lnum
    let l:prev_starts = a:prev =~# s:tikz_commands
    let l:prev_stops  = a:prev =~# ';\s*$'

    " Increase indent on tikz command start
    if l:prev_starts && ! l:prev_stops
      return &sw
    endif

    " Decrease indent on tikz command end, i.e. on semicolon
    if ! l:prev_starts && l:prev_stops
      let l:context = join(getline(l:env_lnum, a:lnum-1), '')
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
  let l:sum = 0
  let l:indx = match(a:line, a:pattern)
  while l:indx >= 0
    let l:sum += 1
    let l:match = matchstr(a:line, a:pattern, l:indx)
    let l:indx += len(l:match)
    let l:indx = match(a:line, a:pattern, l:indx)
  endwhile
  return l:sum
endfunction

" }}}1

let &cpoptions = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker sw=2
