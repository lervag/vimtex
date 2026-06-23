set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

let g:vimtex_view_automatic = 0
let g:vimtex_compiler_method = 'texpresso'
call vimtex#log#set_silent()

silent edit test.tex

if empty($INMAKE) | finish | endif

let s:c = b:vimtex.compiler

" Compiler flags
call assert_true(s:c.continuous,
      \ 'texpresso must run in continuous mode')
call assert_true(get(s:c, 'stdin_pipe', 0),
      \ 'stdin_pipe must be set so Vim can write to texpresso stdin')

" Required protocol flags are always present, regardless of user options
let s:cmd = s:c.__build_cmd('')
call assert_match('^texpresso ', s:cmd)
call assert_match('\V-json', s:cmd)
call assert_match('\V-lines', s:cmd)

" User options are appended after the required flags
let g:vimtex_compiler_texpresso = {'options': ['-tectonic']}
bwipeout!
silent edit test.tex
let s:cmd = b:vimtex.compiler.__build_cmd('')
call assert_match('^texpresso -json -lines', s:cmd)
call assert_match('\V-tectonic', s:cmd)

" passed_options are separated from the last flag regardless of leading space
let s:cmd = b:vimtex.compiler.__build_cmd('-extra')
call assert_match('\V-lines -tectonic -extra ', s:cmd)

" The Neovim backend must keep stdin open for the TeXpresso JSON protocol
if has('nvim')
  let s:c = b:vimtex.compiler
  call s:c.exec(['cat'])
  try
    call assert_true(s:c.is_running(),
          \ 'test helper job should be running')
    call assert_true(chansend(s:c.job, "[]\n") > 0,
          \ 'stdin_pipe must open job stdin in Neovim')
  finally
    call s:c.kill()
  endtry
endif

" Actual buffer changes must be forwarded through the Neovim attach callback
if has('nvim')
  call nvim_buf_set_lines(0, 0, -1, v:false, ['alpha', 'gamma'])
  setlocal nomodified

  let s:c = b:vimtex.compiler
  let s:out = tempname()
  let s:job = jobstart(['sh', '-c', 'cat > "$1"', 'vimtex-cat', s:out],
        \ {'stdin': 'pipe'})
  let s:had_job = has_key(s:c, 'job')
  let s:old_job = get(s:c, 'job', 0)
  let s:c.job = s:job

  try
    let s:detach = luaeval("require('vimtex.compiler.texpresso').attach()")
    call append(1, 'beta')
    2delete _
    call nvim_buf_set_lines(0, 0, 2, v:false, ['one', 'two', 'three'])
  finally
    if exists('s:detach')
      call s:detach()
    endif
    call chanclose(s:job, 'stdin')
    call jobwait([s:job], 1000)
    if s:had_job
      let s:c.job = s:old_job
    else
      unlet s:c.job
    endif
  endtry

  let s:path = fnamemodify(bufname('%'), ':p')
  let s:messages = map(readfile(s:out), 'json_decode(v:val)')
  call assert_equal([
        \ ['change-lines', s:path, 1, 0, "beta\n"],
        \ ['change-lines', s:path, 1, 1, ''],
        \ ['change-lines', s:path, 0, 2, "one\ntwo\nthree\n"],
        \], s:messages)
endif

" TeXpresso quickfix messages may arrive one-by-one or batched by Neovim
let s:hook = b:vimtex.compiler.hooks[-1]
call setqflist([], 'r')
call s:hook(json_encode(['append-lines', 'out',
      \ 'error: test.tex:1: Broken']))
call assert_equal(1, len(getqflist()))

call s:hook(json_encode(['truncate-lines', 'out', 0]))
call assert_equal(0, len(getqflist()))

call s:hook(json_encode(['append-lines', 'out',
      \ 'error: test.tex:1: Broken'])
      \ . "\n"
      \ . json_encode(['append-lines', 'out',
      \ 'warning: test.tex:2: Careful']))
call assert_equal(2, len(getqflist()))

call vimtex#test#finished()
