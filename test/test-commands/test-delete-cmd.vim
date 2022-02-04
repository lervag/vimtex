set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax on

setfiletype tex


" dsc  /  Delete surrounding command
call vimtex#test#keys('dsc', '\cmd{foo}', 'foo')


call vimtex#test#finished()
