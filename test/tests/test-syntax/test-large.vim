source common.vim

let &rtp = '.,' . &rtp
let g:vimtex_fold_enabled = 1

silent edit test-large.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(len(keys(b:vimtex_syntax)), 16)

" PythonTeX inside tikzpictures (#1563)
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 219, 11))
call vimtex#test#assert(vimtex#syntax#in('pythonRawString', 224, 11))

quit!
