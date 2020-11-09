source common.vim

let &rtp = '.,' . &rtp
let g:vimtex_fold_enabled = 1

silent edit test-various-packages.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(15, len(keys(b:vimtex_syntax)))

" PythonTeX inside tikzpictures (#1563)
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 218, 11))
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 223, 11))

quit!
