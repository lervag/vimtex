set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax on

setfiletype tex


" csc  /  Change surrounding command
call vimtex#test#keys("csctest\<cr>", '\cmd{foo}', '\test{foo}')


call vimtex#test#finished()
