set nocompatible
let &rtp = '../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

call vimtex#test#assert(vimtex#paths#is_abs('/some/path'), v:true)
call vimtex#test#assert(vimtex#paths#is_abs('other/path'), v:false)

call vimtex#test#assert('a', vimtex#paths#relative('a', 'b'))
call vimtex#test#assert('test1',
      \ vimtex#paths#relative('/test2/test1', '/test2'))
call vimtex#test#assert('Tex/test2',
      \ vimtex#paths#relative('\Files\2016-2017\Tex\test2', '\Files\2016-2017'))
call vimtex#test#assert('tilde~/test3',
      \ vimtex#paths#relative('/path/with/tilde~/test3', '/path/with'))

call vimtex#test#assert('some/path',
      \ vimtex#paths#shorten_relative(expand('%:p:h') . '/some/path'))

quit!
