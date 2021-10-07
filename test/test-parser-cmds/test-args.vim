set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-args.tex

if empty($INMAKE) | finish | endif

let s:cmd = vimtex#cmd#get_at(6, 1)
call assert_equal('LucidaBrightOT', s:cmd.args[0].text)
call assert_match('BoldItalicFont', s:cmd.opts[0].text)

let s:cmd = vimtex#cmd#get_at(11, 1)
call assert_equal('helloworld', s:cmd.args[0].text)
call assert_match('BoldItalicFont', s:cmd.opts[0].text)

let s:cmd = vimtex#cmd#get_at(17, 1)
call assert_equal('\begin{textblock*}{3in}[0,0] (3in,1in)', s:cmd.text)
call assert_equal(1, len(s:cmd.args_parens))
call assert_equal('(3in,1in)', s:cmd.args_parens[0].text)

let s:cmd = vimtex#cmd#get_at(21, 1)
call assert_equal('\test', s:cmd.text)

call vimtex#test#finished()
