set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

if vimtex#util#is_win() | quitall | endif


let s:t0 = vimtex#profile#time()
call vimtex#jobs#run('sleep 0.2')
let s:t1 = vimtex#profile#time()
call assert_inrange(0.2, 0.25, s:t1 - s:t0)


call vimtex#jobs#run('echo foobar')
call assert_equal(0, v:shell_error)

call vimtex#jobs#run('echo (foobar')
call assert_notequal(0, v:shell_error)

call vimtex#jobs#run('echofoobar')
call assert_equal(127, v:shell_error)



call vimtex#test#finished()
