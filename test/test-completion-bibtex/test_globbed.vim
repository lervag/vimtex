set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let s:build_dir = expand('<sfile>:r') . '.dir'
let g:vimtex_cache_root = '.'
let g:vimtex_cache_persistent = 0
let g:vimtex_log_verbose = 0
let g:vimtex_compiler_method = 'latexmk'
let g:vimtex_compiler_latexmk = {
      \ 'callback' : 0,
      \ 'continuous' : 0,
      \ 'build_dir' : s:build_dir,
      \}


function! Clean()
  if isdirectory(s:build_dir)
    call delete(s:build_dir, 'rf')
  endif
endfunction

function! TestCompletion(expected)
  let l:candidates = vimtex#test#completion('\cite{', '')
  call vimtex#test#assert_equal(a:expected, len(l:candidates))

  call Clean()
endfunction

au! User
au  User VimtexEventCompileFailed  cquit
au  User VimtexEventCompileSuccess call TestCompletion(1) | quit!

silent edit test_globbed.tex

if empty($INMAKE) | finish | endif

call Clean()
call TestCompletion(1)
silent call vimtex#compiler#compile()
