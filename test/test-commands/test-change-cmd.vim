set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

setfiletype tex


" csc  /  Change surrounding command
call vimtex#test#keys("csctest\<cr>", '\cmd{foo}', '\test{foo}')


call vimtex#test#finished()
