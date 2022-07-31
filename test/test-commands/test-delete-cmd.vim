set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

setfiletype tex


" dsc  /  Delete surrounding command
call vimtex#test#keys('dsc', '\cmd{foo}', 'foo')
call vimtex#test#keys("f{ldsc", '$ \ce{a > b} $', '$ a > b $')
call vimtex#test#keys("f}hdsc", '$ \ce{a > b} $', '$ a > b $')


call vimtex#test#finished()
