set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#paths#is_abs('/some/path'))
call assert_false(vimtex#paths#is_abs('other/path'))

call assert_equal('a', vimtex#paths#relative('a', 'b'))
call assert_equal('test1',
      \ vimtex#paths#relative('/test2/test1', '/test2'))
call assert_equal('Tex/test2',
      \ vimtex#paths#relative('\Files\2016-2017\Tex\test2', '\Files\2016-2017'))
call assert_equal('tilde~/test3',
      \ vimtex#paths#relative('/path/with/tilde~/test3', '/path/with'))

call assert_equal('some/path',
      \ vimtex#paths#shorten_relative(expand('%:p:h') . '/some/path'))

call vimtex#test#finished()
