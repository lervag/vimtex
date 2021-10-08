set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

if vimtex#util#get_os() ==# 'win' | quitall | endif


silent let s:t0 = str2float(system('date +"%s.%N"'))
call vimtex#jobs#run('sleep 0.2')
silent let s:t1 = str2float(system('date +"%s.%N"'))
call assert_inrange(0.2, 0.25, s:t1 - s:t0)


call vimtex#jobs#run('echo foobar')
call assert_equal(0, v:shell_error)

call vimtex#jobs#run('echo (foobar')
call assert_notequal(0, v:shell_error)

call vimtex#jobs#run('echofoobar')
call assert_equal(127, v:shell_error)



call vimtex#test#finished()
