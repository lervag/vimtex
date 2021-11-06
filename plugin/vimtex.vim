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
  let l:line = matchstr(a:args, '^\s*\zs\d\+')
  if empty(l:line) | return [-1, ''] | endif

  let l:file = matchstr(a:args, '^\s*\d\+\s*\zs.*')
  let l:file = substitute(l:file, '\v^([''"])(.*)\1\s*', '\2', '')
  if empty(l:file) | return [-1, ''] | endif

  return [str2nr(l:line), l:file]
endfunction
