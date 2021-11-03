set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

if vimtex#util#is_win() | quitall | endif


let s:job = vimtex#jobs#start('sleep 100')
call assert_true(s:job.is_running())
call s:job.stop()
call assert_false(s:job.is_running())
call s:job.stop()


call vimtex#test#finished()
