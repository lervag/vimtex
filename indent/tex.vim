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
setlocal indentexpr=VimtexIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=item

function! VimtexIndent(lnum) " {{{1
  let l:prev_lnum = s:get_prev_line(prevnonblank(a:lnum - 1))
  if l:prev_lnum == 0 | return indent(a:lnum) | endif

  " Get current and previous line and remove comments
  let l:line = substitute(getline(a:lnum), '\\\@<!%.*', '', '')
  let l:prev_line = substitute(getline(l:prev_lnum),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if s:is_verbatim(l:line, a:lnum)
    return empty(l:line) ? indent(l:prev_lnum) : indent(a:lnum)
  endif

  " Align on ampersands
  if l:line =~# '^\s*&' && l:prev_line =~# '\\\@<!&.*'
    return indent(a:lnum) + match(l:prev_line, '\\\@<!&') - stridx(l:line, '&')
  endif

  " Use previous indentation for comments
  if l:line =~# '^\s*%'
    return indent(a:lnum)
  endif

  " Ensure previous line does not start with ampersand
  let l:prev_lnum = s:get_prev_line(l:prev_lnum, 'ignore-ampersands')
  if l:prev_lnum == 0 | return 0 | endif
  let l:prev_line = substitute(getline(l:prev_lnum), '\\\@<!%.*', '', '')

  " Indent environments, delimiters, and tikz
  let l:ind = indent(l:prev_lnum)
  let l:ind += s:indent_envs(l:line, l:prev_line)
  let l:ind += s:indent_delims(l:line, a:lnum, l:prev_line, l:prev_lnum)
  let l:ind += s:indent_tikz(l:prev_lnum, l:prev_line)
  return l:ind
endfunction
"}}}

function! s:get_prev_line(lnum, ...) " {{{1
  let l:ignore_amps = a:0 > 0
  let l:lnum = a:lnum
  let l:prev = getline(l:lnum)

  while l:lnum != 0
        \ && (l:prev =~# '^\s*%'
        \     || s:is_verbatim(l:prev, l:lnum)
        \     || !l:ignore_amps && match(l:prev, '^\s*&') >= 0)
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
function! s:indent_delims(line, lnum, prev_line, prev_lnum) " {{{1
  let [l:text, l:math] = s:split(a:line, a:lnum)
  let [l:prev_tex, l:prev_math] = s:split(a:prev_line, a:prev_lnum, 'prev')

  return &sw*(  max([  s:count(l:prev_math, s:re_delims[0])
        \            - s:count(l:prev_math, s:re_delims[1])
        \            + s:count(l:prev_tex, s:re_delims[2])
        \            - s:count(l:prev_tex, s:re_delims[3]), 0])
        \     - max([  s:count(l:math, s:re_delims[1])
        \            - s:count(l:math, s:re_delims[0])
        \            + s:count(l:text, s:re_delims[3])
        \            - s:count(l:text, s:re_delims[2]), 0]))
endfunction

"
" This fetches the regexes for delimiters in text and math mode:
"   s:re_delims[0]  == math open
"   s:re_delims[1]  == math close
"   s:re_delims[2]  == text open
"   s:re_delims[3]  == text close
"
let s:re_delims = vimtex#delim#get_delim_regexes()

function! s:count(line, pattern) " {{{2
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

" }}}2
function! s:split(line, lnum, ...) " {{{2
  let l:map = map(range(1,col([a:lnum, strlen(a:line)])),
        \ '[v:val, vimtex#util#in_mathzone(a:lnum, v:val)]')

  " Adjust math mode limits (currently handle only $'s)
  let l:prev = 1
  for l:i in range(len(l:map))
    if l:map[l:i][1] == 1 && l:prev == 0
      let l:prev = l:map[l:i][1]
      let l:map[l:i][1] = 0
    else
      let l:prev = l:map[l:i][1]
    endif
  endfor
  if l:map[0][1] == 1 && a:line[0] ==# '$'
    let l:map[0][1] = 0
  endif

  " Extract normal text
  let l:normal = ''
  for [l:i, l:val] in l:map
    if l:val == 0
      let l:normal .= a:line[l:i - 1]
    endif
  endfor
  let l:normal = substitute(l:normal, '\\verb\(.\).\{}\1', '', 'g')

  "
  " Extract math text (either at beginning or end of line, depending on if we
  " are looking at the current line or a previous line)
  "
  if a:0 == 0
    " Extract math text from beginning of line
    let l:math = ''
    let l:indx = 0
    while l:map[l:indx][1] == 1
      let l:math .= a:line[l:map[l:indx][0] - 1]
      let l:indx += 1
    endwhile
  else
    " Extract math text from end of line
    let l:math = ''
    let l:indx = -1
    while l:map[l:indx][1] == 1
      let l:math = a:line[l:map[l:indx][0] - 1] . l:math
      let l:indx -= 1
    endwhile
  endif

  return [l:normal, l:math]
endfunction

" }}}2

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

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: fdm=marker sw=2
