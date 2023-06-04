set nocompatible
set runtimepath^=../..
filetype plugin on

nnoremap q :qall!<cr>

function! SetCompilerMethod(mainfile)
  if filereadable(a:mainfile)
    for line in readfile(a:mainfile, '', 5)
      if line =~# '^%\s*arara'
        return 'arara'
      endif
    endfor
  endif

  return 'latexmk'
endfunction

let g:vimtex_compiler_method = 'SetCompilerMethod'

silent edit test-arara.tex
if empty($INMAKE) | finish | endif


call assert_equal('arara', b:vimtex.compiler.name)

silent edit test-fallback.tex
call assert_equal('latexmk', b:vimtex.compiler.name)

call vimtex#test#finished()
