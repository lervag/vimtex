" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#parser#toc#preamble#new() abort " {{{1
  return s:matcher
endfunction

" }}}1

let s:matcher = {
      \ 'disable' : !g:vimtex_toc_show_preamble,
      \ 'in_preamble' : 1,
      \ 'in_content' : 0,
      \ 'prefilter_cmds' : ['documentclass'],
      \ 'priority' : 0,
      \ 're' : '\v^\s*\\documentclass',
      \}
function! s:matcher.get_entry(context) abort " {{{1
  return {
        \ 'title'  : 'Preamble',
        \ 'number' : '',
        \ 'file'   : a:context.file,
        \ 'line'   : a:context.lnum,
        \ 'level'  : 0,
        \ 'rank'   : a:context.lnum_total,
        \ 'type'   : 'content',
        \}
endfunction

" }}}1
