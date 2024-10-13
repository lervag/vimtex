" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if !get(g:, 'vimtex_enabled', 1) | finish | endif
if exists('g:loaded_vimtex') | finish | endif
let g:loaded_vimtex = 1


command! -nargs=* VimtexInverseSearch
      \ call call('vimtex#view#inverse_search_cmd', s:parse_args(<q-args>))


function! s:parse_args(args) abort
  " Examples:
  "   parse_args("foobar")    = [-1, '', 0]
  "   parse_args("5 a.tex")   = [5, 'a.tex', 0]
  "   parse_args("5 'a.tex'") = [5, 'a.tex', 0]
  "   parse_args("5:3 a.tex") = [5, 'a.tex', 3]
  let l:matchlist = matchlist(a:args, '^\s*\(\d\+\)\%(:\(-\?\d\+\)\)\?\s\+\(.*\)')
  if empty(l:matchlist) | return [-1, '', 0] | endif
  let l:lnum = str2nr(l:matchlist[1])
  let l:cnum = str2nr(l:matchlist[2])
  let l:file = l:matchlist[3]

  let l:file = substitute(l:file, '\v^([''"])(.*)\1\s*', '\2', '')
  if empty(l:file) | return [-1, '', 0] | endif

  return [l:lnum, l:file, l:cnum]
endfunction
