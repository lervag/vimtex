" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#latexmk#init_options() " {{{1
  call vimtex#util#set_default('g:vimtex_latexmk_enabled', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_build_dir', '')
  if !g:vimtex_latexmk_enabled | return | endif

  call vimtex#util#set_default('g:vimtex_latexmk_background', 0)
  call vimtex#util#set_default('g:vimtex_latexmk_callback', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_continuous', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_file_line_error', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_options', '')
  call vimtex#util#set_default('g:vimtex_latexmk_progname',
        \ get(v:, 'progpath', get(v:, 'progname')))
  call vimtex#util#set_default('g:vimtex_quickfix_autojump', '0')
  call vimtex#util#set_default('g:vimtex_quickfix_ignore_all_warnings', 0)
  call vimtex#util#set_default('g:vimtex_quickfix_ignored_warnings', [])
  call vimtex#util#set_default('g:vimtex_quickfix_mode', '2')
  call vimtex#util#set_default('g:vimtex_quickfix_open_on_warning', '1')
  call vimtex#util#set_default('g:vimtex_quickfix_fix_paths', '0')
endfunction

" }}}1
function! vimtex#latexmk#init_script() " {{{1
  if !g:vimtex_latexmk_enabled | return | endif

  call s:check_system_compatibility()

  " Ensure that all latexmk processes are stopped when a latex project is
  " closed and when vim exits
  if g:vimtex_latexmk_continuous
    augroup vimtex_latexmk
      autocmd!
      autocmd VimLeave * call vimtex#latexmk#stop_all()
      autocmd User VimtexQuit call s:stop_before_leaving()
    augroup END
  endif

  " Add autocommand to fix paths in quickfix
  if g:vimtex_quickfix_fix_paths
    augroup vimtex_latexmk_fix_dirs
      au!
      au QuickFixCmdPost c*file call s:fix_quickfix_paths()
    augroup END
  endif
endfunction

" }}}1
function! vimtex#latexmk#init_buffer() " {{{1
  if !g:vimtex_latexmk_enabled | return | endif

  " Set compiler (this defines the errorformat)
  compiler latexmk

  " Initialize system PID
  call s:latexmk_init_pid()

  " Define commands
  command! -buffer       VimtexCompile       call vimtex#latexmk#compile()
  command! -buffer -bang VimtexCompileSS     call vimtex#latexmk#compile_ss(<q-bang> == "!")
  command! -buffer       VimtexCompileToggle call vimtex#latexmk#toggle()
  command! -buffer       VimtexCompileOutput call vimtex#latexmk#output()
  command! -buffer       VimtexStop          call vimtex#latexmk#stop()
  command! -buffer       VimtexStopAll       call vimtex#latexmk#stop_all()
  command! -buffer       VimtexErrors        call vimtex#latexmk#errors()
  command! -buffer -bang VimtexClean         call vimtex#latexmk#clean(<q-bang> == "!")
  command! -buffer -bang VimtexStatus        call vimtex#latexmk#status(<q-bang> == "!")
  command! -buffer       VimtexLacheck       call vimtex#latexmk#lacheck()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-compile)        :call vimtex#latexmk#compile()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-ss)     :call vimtex#latexmk#compile_ss(0)<cr>
  nnoremap <buffer> <plug>(vimtex-compile-toggle) :call vimtex#latexmk#toggle()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-output) :call vimtex#latexmk#output()<cr>
  nnoremap <buffer> <plug>(vimtex-stop)           :call vimtex#latexmk#stop()<cr>
  nnoremap <buffer> <plug>(vimtex-stop-all)       :call vimtex#latexmk#stop_all()<cr>
  nnoremap <buffer> <plug>(vimtex-errors)         :call vimtex#latexmk#errors()<cr>
  nnoremap <buffer> <plug>(vimtex-clean)          :call vimtex#latexmk#clean(0)<cr>
  nnoremap <buffer> <plug>(vimtex-clean-full)     :call vimtex#latexmk#clean(1)<cr>
  nnoremap <buffer> <plug>(vimtex-status)         :call vimtex#latexmk#status(0)<cr>
  nnoremap <buffer> <plug>(vimtex-status-all)     :call vimtex#latexmk#status(1)<cr>
  nnoremap <buffer> <plug>(vimtex-lacheck)        :call vimtex#latexmk#lacheck()<cr>
endfunction

" }}}1

function! vimtex#latexmk#callback(status) " {{{1
  if get(s:, 'silence_next_callback', 0)
    let s:silence_next_callback = 0
    return
  endif

  call vimtex#latexmk#errors_open(0)
  redraw!

  if g:vimtex_view_enabled
        \ && has_key(b:vimtex.viewer, 'latexmk_callback')
    call b:vimtex.viewer.latexmk_callback()
  endif

  call vimtex#echo#status(['latexmk compile: ',
        \ a:status ? ['VimtexSuccess', 'success'] : ['VimtexWarning', 'fail']])

  return ''
endfunction

" }}}1
function! vimtex#latexmk#clean(full) " {{{1
  if b:vimtex.pid
    silent call vimtex#latexmk#stop()
    let l:restart = 1
    let s:silence_next_callback = 1
  endif

  "
  " Run latexmk clean process
  "
  if has('win32')
    let cmd = 'cd /D "' . b:vimtex.root . '" & '
  else
    let cmd = 'cd ' . vimtex#util#shellescape(b:vimtex.root) . '; '
  endif
  let cmd .= 'latexmk'
  if g:vimtex_latexmk_build_dir !=# ''
    let cmd .= ' -outdir=' . g:vimtex_latexmk_build_dir
  endif
  let cmd .= a:full ? ' -C ' : ' -c '
  let cmd .= vimtex#util#shellescape(b:vimtex.base)
  call vimtex#util#execute({'cmd' : cmd})
  let b:vimtex.cmd_latexmk_clean = cmd

  if get(l:, 'restart', 0)
    silent call vimtex#latexmk#compile()
  endif

  call vimtex#echo#status(['latexmk clean: ',
        \ ['VimtexSuccess', 'finished' . (a:full ? ' (full)' : '')]])
endfunction

" }}}1
function! vimtex#latexmk#lacheck() " {{{1
  compiler lacheck

  silent lmake %
  lwindow
  silent redraw!
  wincmd p

  compiler latexmk
endfunction

" }}}1
function! vimtex#latexmk#toggle() " {{{1
  if b:vimtex.pid
    call vimtex#latexmk#stop()
  else
    call vimtex#latexmk#compile()
  endif
endfunction

" }}}1
function! vimtex#latexmk#compile() " {{{1
  if b:vimtex.pid
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'already running for `' . b:vimtex.base . "'"]])
    return
  endif

  " Build command line and start latexmk
  let exe = s:latexmk_build_cmd()
  if !g:vimtex_latexmk_continuous && !g:vimtex_latexmk_background
    let exe.bg = 0
    let exe.silent = 0
  endif
  call vimtex#util#execute(exe)

  if g:vimtex_latexmk_continuous
    call s:latexmk_set_pid()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'started continuous mode']])
  else
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'compiling ...']])
  endif
endfunction

" }}}1
function! vimtex#latexmk#compile_ss(verbose) " {{{1
  if b:vimtex.pid
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'already running for `' . b:vimtex.base . "'"]])
    return
  endif

  let l:vimtex_latexmk_continuous = g:vimtex_latexmk_continuous
  let g:vimtex_latexmk_continuous = 0
  let exe = s:latexmk_build_cmd()
  if a:verbose
    let exe.bg = 0
    let exe.silent = 0
  endif
  call vimtex#util#execute(exe)
  let g:vimtex_latexmk_continuous = l:vimtex_latexmk_continuous
endfunction

" }}}1
function! vimtex#latexmk#errors() " {{{1
  if s:open_quickfix_window
    let s:open_quickfix_window = 0
    cclose
  else
    call vimtex#latexmk#errors_open(1)
  endif
endfunction

" }}}1
function! vimtex#latexmk#errors_open(force) " {{{1
  if !exists('b:vimtex') | return | endif
  cclose

  let log = b:vimtex.log()
  if empty(log)
    if a:force
      call vimtex#echo#status(['latexmk errors: ',
            \ ['VimtexWarning', 'No log file found']])
    endif
    return
  endif

  " Save root name for fixing quickfix paths
  let s:vimtex_tmp_path = b:vimtex.root

  if g:vimtex_quickfix_autojump
    execute 'cfile ' . fnameescape(log)
  else
    execute 'cgetfile ' . fnameescape(log)
  endif
  if empty(getqflist())
    if a:force
      call vimtex#echo#status(['latexmk errors: ',
            \ ['VimtexSuccess', 'No errors!']])
    endif
    return
  endif

  "
  " There are two options that determine when to open the quickfix window.  If
  " forced, the quickfix window is always opened when there are errors or
  " warnings (forced typically imply that the functions is called from the
  " normal mode mapping).  Else the behaviour is based on the settings.
  "
  let s:open_quickfix_window = a:force
        \ || (g:vimtex_quickfix_mode > 0
        \     && (g:vimtex_quickfix_open_on_warning
        \         || s:log_contains_error(log)))

  if s:open_quickfix_window
    botright cwindow
    if g:vimtex_quickfix_mode == 2
      wincmd p
    endif
    redraw!
  endif
endfunction

let s:open_quickfix_window = 0

" }}}1
function! vimtex#latexmk#output() " {{{1
  if has_key(b:vimtex, 'tmp')
    let tmp = b:vimtex.tmp
  else
    call vimtex#echo#status(['vimtex: ', ['VimtexWarning', 'No output exists']])
    return
  endif

  " Create latexmk output window
  if bufnr(tmp) >= 0
    silent exe 'bwipeout' . bufnr(tmp)
  endif
  silent exe 'split ' . tmp

  " Better automatic update
  augroup vimtex_tmp_update
    autocmd!
    autocmd BufEnter        * silent! checktime
    autocmd CursorHold      * silent! checktime
    autocmd CursorHoldI     * silent! checktime
    autocmd CursorMoved     * silent! checktime
    autocmd CursorMovedI    * silent! checktime
  augroup END
  silent exe 'autocmd! BufDelete ' . tmp . ' augroup! vimtex_tmp_update'

  " Set some mappings
  nnoremap <buffer> <silent> q :bwipeout<cr>

  " Set some buffer options
  setlocal autoread
  setlocal nomodifiable
endfunction

" }}}1
function! vimtex#latexmk#status(detailed) " {{{1
  if a:detailed
    let running = 0
    for data in values(g:vimtex_data)
      if data.pid
        if !running
          call vimtex#echo#status(['latexmk status: ',
                \ ['VimtexSuccess', "running\n"]])
          call vimtex#echo#status([['None', '  pid    '],
                \ ['None', "file\n"]])
          let running = 1
        endif

        let name = data.tex
        if len(name) >= winwidth('.') - 20
          let name = '...' . name[-winwidth('.')+23:]
        endif

        call vimtex#echo#status([
              \ ['None', printf('  %-6s ', data.pid)],
              \ ['None', name . "\n"]])
      endif
    endfor

    if !running
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexWarning', 'not running']])
    endif
  else
    if b:vimtex.pid
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexSuccess', 'running']])
    else
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexWarning', 'not running']])
    endif
  endif
endfunction

" }}}1
function! vimtex#latexmk#stop() " {{{1
  if b:vimtex.pid
    call s:latexmk_kill(b:vimtex)
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'stopped (' . b:vimtex.base . ')']])
  else
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'no process to stop (' . b:vimtex.base . ')']])
  endif
endfunction

" }}}1
function! vimtex#latexmk#stop_all() " {{{1
  for data in values(g:vimtex_data)
    if data.pid
      call s:latexmk_kill(data)
    endif
  endfor
endfunction

" }}}1

" Helper function(s) for building the latexmk command
function! vimtex#latexmk#add_option(name, value) " {{{1
  if has('win32')
    return ' -e "$' . a:name . ' = ''' . a:value . '''"'
  else
    return ' -e ''$' . a:name . ' = "' . a:value . '"'''
  endif
endfunction

"}}}1

" Helper functions for latexmk command
function! s:latexmk_build_cmd() " {{{1
  let exe = {}
  let exe.null = 0

  " Note: We don't send output to /dev/null, but rather to a temporary file,
  "       which allows inspection of latexmk output
  let tmp = tempname()

  if has('win32')
    let cmd  = 'cd /D "' . b:vimtex.root . '"'
    let cmd .= ' && set max_print_line=2000 & latexmk'
  else
    let cmd  = 'cd ' . vimtex#util#shellescape(b:vimtex.root)
    if fnamemodify(&shell, ':t') ==# 'fish'
      let cmd .= '; and set max_print_line 2000; and latexmk'
    else
      let cmd .= ' && max_print_line=2000 latexmk'
    endif
  endif

  let cmd .= ' -verbose -pdf ' . g:vimtex_latexmk_options

  if g:vimtex_latexmk_file_line_error
    let cmd .= ' -e ' . vimtex#util#shellescape(
          \ '$pdflatex =~ s/ / -file-line-error /')
  endif

  if g:vimtex_latexmk_build_dir !=# ''
    let cmd .= ' -outdir=' . g:vimtex_latexmk_build_dir
  endif

  if g:vimtex_latexmk_continuous
    let cmd .= ' -pvc'
    if get(s:, 'silence_next_callback', 0)
      let cmd .= ' -view=none'
    endif
  endif

  if g:vimtex_latexmk_callback && has('clientserver')
    let success  = '\"' . g:vimtex_latexmk_progname . '\"'
    let success .= ' --servername ' . v:servername
    let success .= ' --remote-expr \"vimtex\#latexmk\#callback(1)\"'
    let failed   = '\"' . g:vimtex_latexmk_progname . '\"'
    let failed  .= ' --servername ' . v:servername
    let failed  .= ' --remote-expr \"vimtex\#latexmk\#callback(0)\"'
    let cmd .= vimtex#latexmk#add_option('success_cmd', success)
    let cmd .= vimtex#latexmk#add_option('failure_cmd', failed)
    let s:first_callback = 1
  endif

  if g:vimtex_view_enabled
        \ && has_key(b:vimtex.viewer, 'latexmk_append_argument')
    let cmd .= b:vimtex.viewer.latexmk_append_argument()
  endif

  let cmd .= ' ' . vimtex#util#shellescape(b:vimtex.base)

  if g:vimtex_latexmk_continuous || g:vimtex_latexmk_background
    if has('win32')
      let cmd .= ' >'  . tmp
      let cmd = 'cmd /s /c "' . cmd . '"'
    else
      let cmd .= ' >' . tmp . ' 2>&1'
    endif
  elseif has('win32')
    let cmd = 'cmd /c "' . cmd . '"'
  endif

  let exe.cmd  = cmd
  let b:vimtex.cmd_latexmk_compile = cmd
  let b:vimtex.tmp = tmp

  return exe
endfunction

" }}}1
function! s:latexmk_init_pid() " {{{1
  "
  " First see if the PID is already defined
  "
  let b:vimtex.pid = get(b:vimtex, 'pid', 0)

  "
  " If the PID is 0, then search for existing processes
  "
  if b:vimtex.pid ==# 0
    if has('win32')
      "
      " PASS - don't know how to do this on Windows yet.
      "
      return
    else
      "
      " Use pgrep combined with /proc/PID/cwd to search for existing process
      "
      for l:pid in split(system(
            \ 'pgrep -f "^perl.*latexmk.*' . b:vimtex.base . '"'), "\n")
        let path = resolve('/proc/' . l:pid . '/cwd') . '/' . b:vimtex.base
        if path ==# b:vimtex.tex
          let b:vimtex.pid = str2nr(l:pid)
          return
        endif
      endfor
    endif
  endif
endfunction

function! s:latexmk_set_pid() " {{{1
  if has('win32')
    let pidcmd = 'tasklist /fi "imagename eq latexmk.exe"'
    let pidinfo = split(system(pidcmd), '\n')[-1]
    let b:vimtex.pid = str2nr(split(pidinfo,'\s\+')[1])
  else
    let b:vimtex.pid = str2nr(system('pgrep -nf "^perl.*latexmk"')[:-2])
  endif
endfunction

function! s:latexmk_kill(data) " {{{1
  let exe = {}
  let exe.null = 0

  if has('win32')
    let exe.cmd = 'taskkill /PID ' . a:data.pid . ' /T /F'
  else
    let exe.cmd = 'kill ' . a:data.pid
  endif

  call vimtex#util#execute(exe)
  let a:data.pid = 0
endfunction

" }}}1

function! s:fix_quickfix_paths() " {{{1
  let qflist = getqflist()
  for i in qflist
    let file = s:vimtex_tmp_path . '/'
          \ . substitute(bufname(i.bufnr), '^\.\/', '', '')
    if !bufexists(file) && filereadable(fnameescape(file))
      execute 'badd' fnamemodify(file, ':~:.')
    endif
    let i.bufnr = bufnr(file)
  endfor
  call setqflist(qflist)
endfunction

" }}}1
function! s:stop_before_leaving() " {{{1
  if b:vimtex.pid > 0
    call s:latexmk_kill(b:vimtex)
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'stopped (' . b:vimtex.base . ')']])
  endif
endfunction

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~# ''^.*:\d\+: ''')
  let lines = uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

function! s:check_system_compatibility() " {{{1
  "
  " Check for required executables
  "
  if has('win32')
    let required = ['latexmk']
  else
    let required = ['latexmk', 'pgrep']
  endif
  let missing = filter(required, '!executable(v:val)')

  "
  " Disable latexmk if required programs are missing
  "
  if len(missing) > 0
    call vimtex#echo#warning('vimtex warning: ')
    call vimtex#echo#warning('  vimtex#latexmk was not initialized', 'None')
    for cmd in missing
      call vimtex#echo#warning('  ' . cmd . ' is not executable', 'None')
    endfor
    let g:vimtex_latexmk_enabled = 0
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
