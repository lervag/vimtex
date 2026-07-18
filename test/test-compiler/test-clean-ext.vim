set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_compiler_method = 'latexmk'
let g:vimtex_compiler_latexmk = {'clean_ext': 'synctex.gz'}

call vimtex#log#set_silent()

silent edit test-clean.tex

" Intercept the clean command instead of executing it. This is defined after
" the buffer is initialized, both so the jobs autoload does not clobber it and
" to avoid E746 (an autoload function may only be newly defined from its own
" script).
let g:clean_cmd = ''
function! vimtex#jobs#run(cmd, ...) abort
  let g:clean_cmd = a:cmd
endfunction

" Case 1: clean_ext is set
silent VimtexClean!
call assert_match('-e .\{-}\$clean_ext = q/synctex\.gz/;', g:clean_cmd)
call assert_match(' -C\>', g:clean_cmd)

" Case 2: clean_ext is empty
let b:vimtex.compiler.clean_ext = ''
let g:clean_cmd = ''
silent VimtexClean!
call assert_notmatch(' -e ', g:clean_cmd)
call assert_match(' -C\>', g:clean_cmd)

call vimtex#test#finished()
