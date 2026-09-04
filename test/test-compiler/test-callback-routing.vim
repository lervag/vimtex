set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

call vimtex#log#set_silent()

let g:events = []
augroup test_callback_routing
  autocmd!
  autocmd User VimtexEventCompiling      call add(g:events, 'compiling')
  autocmd User VimtexEventCompileSuccess call add(g:events, 'success')
  autocmd User VimtexEventCompileFailed  call add(g:events, 'failed')
augroup END

silent edit test-callback-routing.tex

if empty($INMAKE) | finish | endif

" Each compiler must have its own output file, else concurrent projects will
" write into the same file and :VimtexCompileOutput will show the wrong one.
let s:other_project = vimtex#compiler#latexmk#init({
      \ 'file_info': {
      \   'root': '/tmp/other',
      \   'target': '/tmp/other/main.tex',
      \   'target_name': 'main',
      \   'target_basename': 'main.tex',
      \   'jobname': 'main',
      \ }
      \})
call assert_notequal(b:vimtex.compiler.output, s:other_project.output)
call assert_false(empty(s:other_project.output))

" A callback from another project only updates that project's status. It must
" not touch the current project, and it must not report anything to the user
" through the current buffer. See #3296.
let s:windows = winnr('$')
call vimtex#compiler#callback(3, s:other_project)
call assert_equal(3, s:other_project.status)
call assert_equal(-1, b:vimtex.compiler.status)
call assert_equal([], g:events)
call assert_equal(s:windows, winnr('$'))

" A callback for the current project is handled as usual
call vimtex#compiler#callback(1, b:vimtex.compiler)
call assert_equal(1, b:vimtex.compiler.status)
call assert_equal(['compiling'], g:events)

" Without an explicit compiler, the callback applies to the current project.
" This is the documented public interface, see :help vimtex#compiler#callback.
call vimtex#compiler#callback(1)
call assert_equal(1, b:vimtex.compiler.status)
call assert_equal(['compiling', 'compiling'], g:events)

call vimtex#test#finished()
