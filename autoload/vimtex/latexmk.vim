" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#latexmk#init(initialized) " {{{1
  call vimtex#util#set_default('g:vimtex_latexmk_enabled', 1)
  if !g:vimtex_latexmk_enabled | return | endif
  if s:system_incompatible() | return | endif

  " Set default options
  call vimtex#util#set_default('g:vimtex_latexmk_background', 0)
  call vimtex#util#set_default('g:vimtex_latexmk_build_dir', '.')
  call vimtex#util#set_default('g:vimtex_latexmk_callback', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_continuous', 1)
  call vimtex#util#set_default('g:vimtex_latexmk_options', '-pdf')
  call vimtex#util#set_default('g:vimtex_quickfix_autojump', '0')
  call vimtex#util#set_default('g:vimtex_quickfix_mode', '2')
  call vimtex#util#set_default('g:vimtex_quickfix_open_on_warning', '1')
  call vimtex#util#error_deprecated('g:vimtex_build_dir')
  call vimtex#util#error_deprecated('g:vimtex_latexmk_autojump')
  call vimtex#util#error_deprecated('g:vimtex_latexmk_output')
  call vimtex#util#error_deprecated('g:vimtex_latexmk_quickfix')

  " Set compiler (this defines the errorformat)
  compiler latexmk

  let g:vimtex#data[b:vimtex.id].pid = 0

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

  " The remaining part is only relevant for continuous mode
  if !g:vimtex_latexmk_continuous | return | endif

  " Ensure that all latexmk processes are stopped when vim exits
  " Note: Only need to define this once, globally.
  if !a:initialized
    augroup latex_latexmk
      autocmd!
      autocmd VimLeave * call vimtex#latexmk#stop_all()
    augroup END
  endif

  " If all buffers for a given latex project are closed, kill latexmk
  " Note: This must come after the above so that the autocmd group is properly
  "       refreshed if necessary
  augroup latex_latexmk
    autocmd BufUnload <buffer> call s:stop_buffer()
  augroup END
endfunction

" }}}1
function! vimtex#latexmk#callback(status) " {{{1
  call vimtex#latexmk#errors_open(0)
  redraw!

  echohl ModeMsg
  echon "latexmk compile: "
  if a:status
    echohl Statement
    echon "success"
  else
    echohl WarningMsg
    echon "fail"
  endif
  echohl None

  if has_key(g:vimtex#data[b:vimtex.id].viewer, 'latexmk_callback')
    call g:vimtex#data[b:vimtex.id].viewer.latexmk_callback()
  endif

  return ""
endfunction

" }}}1
function! vimtex#latexmk#clean(full) " {{{1
  let data = g:vimtex#data[b:vimtex.id]
  if data.pid
    echohl ModeMsg
    echon "latexmk clean: "
    echohl WarningMsg
    echon "not while latexmk is running!"
    echohl None
    return
  endif

  "
  " Run latexmk clean process
  "
  if has('win32')
    let cmd = 'cd /D "' . data.root . '" & '
  else
    let cmd = 'cd ' . shellescape(data.root) . '; '
  endif
  let cmd .= 'latexmk -outdir=' . g:vimtex_latexmk_build_dir
  let cmd .= a:full ? ' -C ' : ' -c'
  let cmd .= vimtex#util#fnameescape(data.base)
  let exe = {
        \ 'cmd' : cmd,
        \ 'bg'  : 0,
        \ }
  call vimtex#util#execute(exe)
  let g:vimtex#data[b:vimtex.id].cmd_latexmk_clean = cmd

  echohl ModeMsg
  echon "latexmk clean: "
  echohl Statement
  if a:full
    echon "finished (full)"
  else
    echon "finished"
  endif
  echohl None
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
  let data = g:vimtex#data[b:vimtex.id]

  if data.pid
    call vimtex#latexmk#stop()
  else
    call vimtex#latexmk#compile()
  endif
endfunction

" }}}1
function! vimtex#latexmk#compile() " {{{1
  let data = g:vimtex#data[b:vimtex.id]
  if data.pid
    echomsg "latexmk is already running for `" . data.base . "'"
    return
  endif

  " Build command line and start latexmk
  let exe = s:latexmk_build_cmd(data)
  if !g:vimtex_latexmk_continuous && !g:vimtex_latexmk_background
    let exe.bg = 0
    let exe.silent = 0
  endif
  call vimtex#util#execute(exe)

  if g:vimtex_latexmk_continuous
    call s:latexmk_set_pid(data)

    echomsg 'latexmk started in continuous mode ...'
  else
    echomsg 'latexmk compiling ...'
  endif
endfunction

" }}}1
function! vimtex#latexmk#compile_ss(verbose) " {{{1
  let data = g:vimtex#data[b:vimtex.id]
  if data.pid
    echomsg "latexmk is already running for `" . data.base . "'"
    return
  endif

  let l:vimtex_latexmk_continuous = g:vimtex_latexmk_continuous
  let g:vimtex_latexmk_continuous = 0
  let exe = s:latexmk_build_cmd(data)
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
  cclose

  let log = g:vimtex#data[b:vimtex.id].log()
  if empty(log)
    if a:force
      echohl ModeMsg
      echon "latexmk errors: "
      echohl WarningMsg
      echon "No log file found!"
      echohl None
    endif
    return
  endif

  if g:vimtex_quickfix_autojump
    execute 'cfile ' . fnameescape(log)
  else
    execute 'cgetfile ' . fnameescape(log)
  endif
  if empty(getqflist())
    if a:force
      echohl ModeMsg
      echon "latexmk errors: "
      echohl Statement
      echon "No errors!"
      echohl None
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
  if has_key(g:vimtex#data[b:vimtex.id], 'tmp')
    let tmp = g:vimtex#data[b:vimtex.id].tmp
  else
    echo "vimtex: No output exists"
    return
  endif

  " Create latexmk output window
  if bufnr(tmp) >= 0
    silent exe 'bwipeout' . bufnr(tmp)
  endif
  silent exe 'split ' . tmp

  " Better automatic update
  augroup tmp_update
    autocmd!
    autocmd BufEnter        * silent! checktime
    autocmd CursorHold      * silent! checktime
    autocmd CursorHoldI     * silent! checktime
    autocmd CursorMoved     * silent! checktime
    autocmd CursorMovedI    * silent! checktime
  augroup END
  silent exe 'autocmd! BufDelete ' . tmp . ' augroup! tmp_update'

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
    for data in g:vimtex#data
      if data.pid
        if !running
          echo "latexmk is running"
          let running = 1
        endif

        let name = data.tex
        if len(name) >= winwidth('.') - 20
          let name = "..." . name[-winwidth('.')+23:]
        endif

        echom printf('pid: %6s, file: %-s', data.pid, name)
      endif
    endfor

    if !running
      echo "latexmk is not running"
    endif
  else
    if g:vimtex#data[b:vimtex.id].pid
      echo "latexmk is running"
    else
      echo "latexmk is not running"
    endif
  endif
endfunction

" }}}1
function! vimtex#latexmk#stop() " {{{1
  let pid  = g:vimtex#data[b:vimtex.id].pid
  let base = g:vimtex#data[b:vimtex.id].base
  if pid
    call s:latexmk_kill_pid(pid)
    let g:vimtex#data[b:vimtex.id].pid = 0
    echohl ModeMsg
    echon "latexmk compile: "
    echohl Statement
    echon "stopped (" . base . ")"
    echohl None
  else
    echohl ModeMsg
    echon "latexmk compile: "
    echohl WarningMsg
    echon "no process to stop (" . base . ")"
    echohl None
  endif
endfunction

" }}}1
function! vimtex#latexmk#stop_all() " {{{1
  for data in g:vimtex#data
    if data.pid
      call s:latexmk_kill_pid(data.pid)
      let data.pid = 0
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
function! s:latexmk_build_cmd(data) " {{{1
  let exe = {}
  let exe.null = 0

  " Note: We don't send output to /dev/null, but rather to a temporary file,
  "       which allows inspection of latexmk output
  let tmp = tempname()

  if has('win32')
    let cmd  = 'cd /D "' . a:data.root . '"'
    let cmd .= ' && set max_print_line=2000 & latexmk'
  else
    let cmd  = 'cd ' . shellescape(a:data.root)
    let cmd .= ' && max_print_line=2000 latexmk'
  endif

  let cmd .= ' ' . g:vimtex_latexmk_options
  let cmd .= ' -e ' . shellescape('$pdflatex =~ s/ / -file-line-error /')
  let cmd .= ' -outdir=' . g:vimtex_latexmk_build_dir

  if g:vimtex_latexmk_continuous
    let cmd .= ' -pvc'
  endif

  if g:vimtex_latexmk_callback && has('clientserver')
    let success  = v:progname
    let success .= ' --servername ' . v:servername
    let success .= ' --remote-expr \"vimtex\#latexmk\#callback(1)\"'
    let failed   = v:progname
    let failed  .= ' --servername ' . v:servername
    let failed  .= ' --remote-expr \"vimtex\#latexmk\#callback(0)\"'
    let cmd .= vimtex#latexmk#add_option('success_cmd', success)
    let cmd .= vimtex#latexmk#add_option('failure_cmd', failed)
    let s:first_callback = 1
  endif

  if has_key(g:vimtex#data[b:vimtex.id].viewer, 'latexmk_append_argument')
    let cmd .= g:vimtex#data[b:vimtex.id].viewer.latexmk_append_argument()
  endif

  let cmd .= ' ' . vimtex#util#fnameescape(a:data.base)

  if g:vimtex_latexmk_continuous || g:vimtex_latexmk_background
    if has('win32')
      let cmd .= ' >'  . tmp
      let cmd = 'cmd /s /c "' . cmd . '"'
    else
      let cmd .= ' &>' . tmp
    endif
  endif

  let exe.cmd  = cmd
  let a:data.cmd_latexmk_compile = cmd
  let a:data.tmp = tmp

  return exe
endfunction

" }}}1
function! s:latexmk_set_pid(data) " {{{1
  if has('win32')
    let pidcmd = 'qprocess latexmk.exe'
    let pidinfo = systemlist(pidcmd)[-1]
    let a:data.pid = split(pidinfo,'\s\+')[-2]
  else
    let a:data.pid = system('pgrep -nf "^perl.*latexmk"')[:-2]
  endif
endfunction

function! s:latexmk_kill_pid(pid) " {{{1
  let exe = {}
  let exe.bg = 0
  let exe.null = 0

  if has('win32')
    let exe.cmd = 'taskkill /PID ' . a:pid . ' /T /F'
  else
    let exe.cmd = 'kill ' . a:pid
  endif

  call vimtex#util#execute(exe)
endfunction

" }}}1

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~ ''^.*:\d\+: ''')
  let lines = uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

function! s:stop_buffer() " {{{1
  "
  " Only run if latex variables are set
  "
  if !exists('b:vimtex') | return | endif
  let id = b:vimtex.id
  let pid = g:vimtex#data[id].pid

  "
  " Only stop if latexmk is running
  "
  if pid
    "
    " Count the number of buffers that point to current latex blob
    "
    let n = 0
    for b in filter(range(1, bufnr("$")), 'buflisted(v:val)')
      if id == getbufvar(b, 'vimtex', {'id' : -1}).id
        let n += 1
      endif
    endfor

    "
    " Only stop if current buffer is the last for current latex blob
    "
    if n == 1
      silent call vimtex#latexmk#stop()
    endif
  endif
endfunction

function! s:system_incompatible() " {{{1
  if has('win32')
    let required = ['latexmk']
  else
    let required = ['latexmk', 'pgrep']
  endif

  "
  " Check for required executables
  "
  for cmd in required
    if !executable(cmd)
      echom "Warning: Could not initialize vimtex#latexmk"
      echom "         Missing executable: " . cmd
      return 1
    endif
  endfor
endfunction

" }}}1

" vim: fdm=marker sw=2
