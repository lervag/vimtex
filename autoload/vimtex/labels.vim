" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#labels#init(initialized) " {{{1
  call vimtex#util#set_default('g:vimtex_labels_enabled', 1)
  if !g:vimtex_labels_enabled | return | endif

  let g:vimtex#data[b:vimtex.id].labels = function('s:gather_labels')
endfunction

" }}}1

" {{{1 TOL variables

let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'
let s:re_label = '\v\\label\{'
let s:re_label_title = s:re_label . '\zs.{-}\ze\}?\s*$'

" }}}1

function! s:gather_labels() dict " {{{1
  return s:gather_labels_file(self.tex)
endfunction

" }}}1
function! s:gather_labels_file(file) " {{{1
  let tac = []
  let lnum = 0
  for line in readfile(a:file)
    let lnum += 1

    " 1. Parse inputs or includes
    if line =~# s:re_input
      call extend(tac,
            \ s:gather_labels_file(s:gather_labels_input(line, a:file)))
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
function! s:gather_labels_input(line, file) " {{{1
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
