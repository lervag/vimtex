set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

set nomore

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_method = 'texpresso'
call vimtex#log#set_silent()

if !executable('texpresso')
  echo "Warning! texpresso not found; skipping integration test.\n"
  quitall!
endif

call writefile([
      \ '\documentclass{minimal}',
      \ '\begin{document}',
      \ 'Hello World!',
      \ '\end{document}',
      \], 'minimal.tex')

silent edit minimal.tex

if empty($INMAKE) | finish | endif

call vimtex#compiler#start()
sleep 2000m

call assert_true(b:vimtex.compiler.get_pid() > 0,
      \ 'texpresso should be running after start')

" Test that we can send messages over stdin without crashing the process
call b:vimtex.compiler.texpresso_reload()
sleep 200m

call assert_true(b:vimtex.compiler.get_pid() > 0,
      \ 'texpresso should still be running after sending reload')

call vimtex#compiler#stop()
sleep 500m

call assert_equal(0, b:vimtex.compiler.get_pid(),
      \ 'texpresso should be stopped after stop()')

call delete('minimal.tex')
call vimtex#test#finished()
