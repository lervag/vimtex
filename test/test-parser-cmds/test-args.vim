set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-args.tex

if empty($INMAKE) | finish | endif

let s:cmd = vimtex#cmd#get_at(4, 1)
call assert_equal('LucidaBrightOT', s:cmd.args[0].text)
call assert_match('BoldItalicFont', s:cmd.opts[0].text)

let s:cmd = vimtex#cmd#get_at(9, 1)
call assert_equal('helloworld', s:cmd.args[0].text)
call assert_match('BoldItalicFont', s:cmd.opts[0].text)

let s:cmd = vimtex#cmd#get_at(14, 1)
call assert_equal('\begin{textblock*}{3in}[0,0](3in,1in)', s:cmd.text)

call vimtex#test#finished()
