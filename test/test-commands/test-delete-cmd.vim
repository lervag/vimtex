set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

setfiletype tex


" dsc  /  Delete surrounding command
call vimtex#test#keys('dsc', '\cmd{foo}', 'foo')


call vimtex#test#finished()
