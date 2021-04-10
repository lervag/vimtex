" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#u#caddfile(qf, file) abort " {{{1
  " This is a utility function for loading errors from a file into the quickfix
  " window with ":caddfile" without calling possibly defined QuickFixCmdPost
  " autotocmds e.g. from plugins like vim-qf.

  let l:errorformat_saved = &l:errorformat
  call a:qf.set_errorformat()
  noautocmd execute 'caddfile' a:file
  let &l:errorformat = l:errorformat_saved
endfunction

" }}}1
