" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latex#tol#gather_labels() " {{{1
  let file = g:latex#data[b:latex.id].tex
  let labels = s:gather_labels(file)
  PP labels
endfunction

" }}}1

" {{{1 TOL variables

let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'
let s:re_label = '\v\\label\{'
let s:re_label_title = s:re_label . '\zs.{-}\ze\}?\s*$'

" }}}1

function! s:gather_labels(file) " {{{1
  let tac = []
  let lnum = 0
  for line in readfile(a:file)
    let lnum += 1

    " 1. Parse inputs or includes
    if line =~# s:re_input
      call extend(tac, s:gather_labels(s:parse_line_input(line, a:file)))
      continue
    endif

    if line =~# s:re_label
      call add(tac, [matchstr(line, s:re_label_title), a:file, lnum])
      continue
    endif
  endfor

  return tac
endfunction

" }}}1
function! s:parse_line_input(line, file) " {{{1
  let l:file = matchstr(a:line, s:re_input_file)

  " Trim whitespaces from beginning and end of string
  let l:file = substitute(l:file, '^\s*', '', '')
  let l:file = substitute(l:file, '\s*$', '', '')

  " Ensure file has extension
  if l:file !~# '.tex$'
    let l:file .= '.tex'
  endif

  " Only return full path names
  if l:file !~# '\v^(\/|[A-Z]:)'
    let l:file = fnamemodify(a:file, ':p:h') . '/' . l:file
  endif

  " Only return filename if it is readable
  if filereadable(l:file)
    return l:file
  else
    return ''
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
