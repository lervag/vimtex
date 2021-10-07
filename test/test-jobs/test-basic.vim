set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

if vimtex#util#get_os() ==# 'win' | quitall | endif
call vimtex#log#set_silent()


let s:output = vimtex#jobs#capture("echo 'a\nb'")
call assert_equal(['a', 'b'], s:output)

call vimtex#jobs#run('sleep 0.2', {'wait_timeout': 150})
let s:log = vimtex#log#get()
call assert_equal(1, len(s:log))
call assert_equal('Job timed out while waiting!', s:log[0].msg[0])

let s:job = vimtex#jobs#start('sleep 100')
call assert_true(s:job.is_running())
call s:job.stop()
call assert_false(s:job.is_running())
call s:job.stop()

let s:output = vimtex#jobs#capture("echobaad foobar")
call assert_match('command not found', s:output[0])


call vimtex#test#finished()
