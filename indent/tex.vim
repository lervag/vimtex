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
call vimtex#util#set_default('g:vimtex_indent_ignored_envs', [
      \ 'document',
      \])

let s:cpo_save = &cpoptions
set cpoptions&vim

setlocal autoindent
setlocal indentexpr=VimtexIndent(v:lnum)
setlocal indentkeys&
setlocal indentkeys+=[,(,{,),},],\&,=item

function! VimtexIndent(lnum) " {{{1
  let l:prev_lnum = s:get_prev_line(prevnonblank(a:lnum - 1), 0)
  if l:prev_lnum == 0 | return indent(a:lnum) | endif

  " Get current and previous line and remove comments
  let l:line = substitute(getline(a:lnum), '\\\@<!%.*', '', '')
  let l:prev_line = substitute(getline(l:prev_lnum),   '\\\@<!%.*', '', '')

  " Check for verbatim modes
  if s:is_verbatim(l:line, a:lnum)
    return empty(l:line) ? indent(l:prev_lnum) : indent(a:lnum)
  endif

  " Align on ampersands
  if get(g:, 'vimtex_indent_on_ampersands', 1)
        \ && l:line =~# '^\s*&'
        \ && l:prev_line =~# '\\\@<!&.*'
    return indent(a:lnum) + match(l:prev_line, '\\\@<!&') - stridx(l:line, '&')
  endif

  " Use previous indentation for comments
  if l:line =~# '^\s*%'
    return indent(a:lnum)
  endif

  " Ensure previous line does not start with ampersand
  let l:prev_lnum = s:get_prev_line(l:prev_lnum,
        \ get(g:, 'vimtex_indent_on_ampersands', 1))
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

let s:envs_ignored = '\v' . join(g:vimtex_indent_ignored_envs, '|')
let s:envs_lists = 'itemize\|description\|enumerate\|thebibliography'
let s:envs_item = '^\s*\\item'
let s:envs_beglist = '\\begin{\%(' . s:envs_lists . '\)'
let s:envs_endlist =   '\\end{\%(' . s:envs_lists . '\)'
let s:envs_begitem = s:envs_item . '\|' . s:envs_beglist
let s:envs_enditem = s:envs_item . '\|' . s:envs_endlist

" }}}1
function! s:indent_delims(line, lnum, prev_line, prev_lnum) " {{{1
  if empty(s:re_delims) | return 0 | endif

  let l:pre = s:split(a:prev_line, a:prev_lnum)
  let l:cur = s:split(a:line, a:lnum)

  return &sw*(  max([  s:count(l:pre.math_post, s:re_delims[0])
        \            - s:count(l:pre.math_post, s:re_delims[1])
        \            + s:count(l:pre.text, s:re_delims[2])
        \            - s:count(l:pre.text, s:re_delims[3]), 0])
        \     - max([  s:count(l:cur.math_pre, s:re_delims[1])
        \            - s:count(l:cur.math_pre, s:re_delims[0])
        \            + s:count(l:cur.text, s:re_delims[3])
        \            - s:count(l:cur.text, s:re_delims[2]), 0]))
endfunction

"
" This fetches the regexes for delimiters in text and math mode:
"   s:re_delims[0]  == math open
"   s:re_delims[1]  == math close
"   s:re_delims[2]  == text open
"   s:re_delims[3]  == text close
"
let s:re_delims = vimtex#delim#get_delim_regexes()

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

"
" Utility functions for s:indent_delims
"
function! s:split(line, lnum) " {{{1
  "
  " This function splits a line into regions:
  "
  "   text       is all the normal text in the given line
  "   math_pre   is the math region at the beginning of the line (if any)
  "   math_post  is the math region at the end of the line (if any)
  "
  " Any math region that is not located at the beginning or end of the line
  " will be ignored.
  "
  let l:result = {}
  let l:result.text = ''
  let l:result.math_pre = ''
  let l:result.math_post = ''

  call setpos('.', [0, a:lnum, 1, 0])
  let l:strlen = strlen(a:line)
  let l:cnum = 0

  "
  " Handles the case where the start of the line is a math region
  "
  if vimtex#util#in_mathzone()
    let l:open = vimtex#delim#get_prev('env_math', 'open')
    if !empty(l:open) && l:open.lnum == a:lnum
      let l:cnum = strlen(l:open.match)
      let l:result.text .= strpart(a:line, 0, l:cnum)
    endif

    let l:close = vimtex#delim#get_next('env_math', 'close')
    if empty(l:close) || l:close.lnum > a:lnum
      let l:result.math_post = strpart(a:line, l:cnum)
      if l:cnum == 0
        let l:result.math_pre = l:result.math_post
      endif
      return s:strip(l:result)
    endif

    if l:cnum == 0
      let l:result.math_pre = strpart(a:line, l:cnum, l:close.cnum-1)
    endif
    let l:cnum = l:close.cnum-1
    call setpos('.', [0, a:lnum, l:close.cnum+strlen(l:close.match), 0])
  endif

  "
  " Iterate over all math regions in the line
  "
  while 1
    let l:open = vimtex#delim#get_next('env_math', 'open')
    if empty(l:open)
          \ || l:open.lnum > a:lnum
          \ || l:open.cnum + strlen(l:open.match) > l:strlen
      let l:result.text .= strpart(a:line, l:cnum)
      return s:strip(l:result)
    else
      let l:result.text .= strpart(a:line, l:cnum,
            \ l:open.cnum + strlen(l:open.match) - l:cnum - 1)
      let l:cnum = l:open.cnum+strlen(l:open.match)-1
      call setpos('.', [0, a:lnum, l:open.cnum+strlen(l:open.match), 0])
    endif

    let l:close = vimtex#delim#get_matching(l:open)
    if empty(l:close) || l:close.lnum == 0 || l:close.lnum > a:lnum
      let l:result.math_post = strpart(a:line, l:cnum)
      return s:strip(l:result)
    else
      let l:cnum = l:close.cnum-1
      call setpos('.', [0, a:lnum, l:close.cnum+strlen(l:close.match), 0])
    endif
  endwhile
endfunction

" }}}1
function! s:strip(result) " {{{1
  let a:result.text = substitute(a:result.text, '\\verb\(.\).\{}\1', '', 'g')
  return a:result
endfunction

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
