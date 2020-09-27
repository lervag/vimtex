source common.vim

let &rtp = '.,' . &rtp
let g:vimtex_fold_enabled = 1
let g:vimtex_syntax_alpha = 1

silent edit test-large.tex

syntax sync fromstart

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(len(keys(b:vimtex_syntax)), 20)

" PythonTeX inside tikzpictures (#1563)
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 243, 11))
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 248, 11))

quit!
