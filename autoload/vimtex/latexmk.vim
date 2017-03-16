" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#latexmk#init_buffer() " {{{1
  if !g:vimtex_latexmk_enabled | return | endif

  " Check option validity
  if g:vimtex_latexmk_callback
        \ && !(has('clientserver') || has('nvim'))
    let g:vimtex_latexmk_callback = 0
    call vimtex#echo#warning('Can''t use callbacks without +clientserver')
    call vimtex#echo#wait()
  endif

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
  command! -buffer -range VimtexCompileSelected
        \ <line1>,<line2>call vimtex#latexmk#compile_selected('cmd')

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
  nnoremap <buffer> <plug>(vimtex-compile-selected)
        \ :set opfunc=vimtex#latexmk#compile_selected<cr>g@
  xnoremap <buffer> <plug>(vimtex-compile-selected)
        \ :<c-u>call vimtex#latexmk#compile_selected('visual')<cr>
endfunction

" }}}1

function! vimtex#latexmk#callback(status) " {{{1
  if get(s:, 'silence_next_callback', 0)
    let s:silence_next_callback = 0
    return
  endif

  call vimtex#latexmk#errors_open(0)
  redraw

  if exists('s:output')
    call s:output.update()
  endif

  call vimtex#echo#status(['latexmk compile: ',
        \ a:status ? ['VimtexSuccess', 'success'] : ['VimtexWarning', 'fail']])

  for l:hook in g:vimtex_latexmk_callback_hooks
    execute 'call' l:hook . '(' . a:status . ')'
  endfor

  return ''
endfunction

" }}}1
function! vimtex#latexmk#clean(full, ...) " {{{1
  if b:vimtex.pid && a:0 == 0
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
  let cmd .= vimtex#util#shellescape(a:0 > 0 ? a:1 : b:vimtex.base)
  call vimtex#util#execute({'cmd' : cmd})
  let b:vimtex.cmd_latexmk_clean = cmd

  if get(l:, 'restart', 0)
    silent call vimtex#latexmk#compile()
  endif

  if a:0 == 0
    call vimtex#echo#status(['latexmk clean: ',
          \ ['VimtexSuccess', 'finished' . (a:full ? ' (full)' : '')]])
  endif
endfunction

" }}}1
function! vimtex#latexmk#lacheck() " {{{1
  compiler lacheck

  silent lmake %
  lwindow
  silent redraw
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

  " Initialize build dir
  call s:latexmk_init_build_dir()

  " Build command line and start latexmk
  let l:exe = s:latexmk_build_cmd()
  if !g:vimtex_latexmk_continuous && !g:vimtex_latexmk_background
    let l:exe.bg = 0
    let l:exe.silent = 0
  endif
  call vimtex#util#execute(l:exe)

  if g:vimtex_latexmk_continuous
    call s:latexmk_set_pid()
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'started continuous mode']])
    if exists('#User#VimtexEventCompileStarted')
      doautocmd User VimtexEventCompileStarted
    endif
  else
    if get(l:exe, 'bg', 1)
      call vimtex#echo#status(['latexmk compile: ',
            \ ['VimtexSuccess', 'started in background!']])
    else
      call vimtex#echo#status(['latexmk compile: ',
            \ vimtex#latexmk#errors_inquire()
            \   ? ['VimtexWarning', 'fail']
            \   : ['VimtexSuccess', 'success']])
    endif
  endif
endfunction

" }}}1
function! vimtex#latexmk#compile_ss(verbose) " {{{1
  let l:vimtex_latexmk_continuous = g:vimtex_latexmk_continuous
  let l:vimtex_latexmk_background = g:vimtex_latexmk_background

  let g:vimtex_latexmk_continuous = 0
  let g:vimtex_latexmk_background = g:vimtex_latexmk_background && !a:verbose
  call vimtex#latexmk#compile()

  let g:vimtex_latexmk_continuous = l:vimtex_latexmk_continuous
  let g:vimtex_latexmk_background = l:vimtex_latexmk_background
endfunction

" }}}1
function! vimtex#latexmk#compile_selected(type) range " {{{1
  let l:file = vimtex#parser#selection_to_texfile(a:type)
  if empty(l:file) | return | endif

  "
  " Compile the temporary file
  "
  let l:exe = s:latexmk_build_cmd_selected(l:file.base)
  let l:exe.bg = 0
  let l:exe.silent = 1
  call vimtex#echo#status([
        \ ['VimtexInfo', 'vimtex: '],
        \ ['VimtexMsg', 'compiling selected lines ...']])
  call vimtex#util#execute(l:exe)

  "
  " Check if successful
  "
  if vimtex#latexmk#errors_inquire(l:file)
    call vimtex#echo#formatted([
          \ ['VimtexInfo', 'vimtex: '],
          \ ['VimtexMsg', 'compiling selected lines ...'],
          \ ['VimtexWarning', ' failed!']])
    botright cwindow
  else
    call vimtex#latexmk#clean(0, l:file.base)
    call vimtex#echo#status([
          \ ['VimtexInfo', 'vimtex: '],
          \ ['VimtexMsg', 'compiling selected lines ... done!']])
    call b:vimtex.viewer.view(l:file.pdf)
  endif
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

  " Save paths for fixing quickfix entries
  let s:qf_main = b:vimtex.tex
  let s:qf_root = b:vimtex.root

  " Store winnr of current window in order to jump back later
  let winnr = winnr()

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
      execute winnr . 'wincmd p'
    endif
    redraw
  endif
endfunction

let s:open_quickfix_window = 0

" }}}1
function! vimtex#latexmk#errors_inquire(...) " {{{1
  if !exists('b:vimtex') | return | endif

  let log = a:0 > 0 ? a:1.log : b:vimtex.log()
  if empty(log) | return 0 | endif

  " Save paths for fixing quickfix entries
  let s:qf_main = a:0 > 0 ? a:1.tex : b:vimtex.tex
  let s:qf_root = b:vimtex.root

  execute 'cgetfile ' . fnameescape(log)
  return !empty(getqflist())
endfunction

" }}}1
function! vimtex#latexmk#output() " {{{1
  if has_key(b:vimtex, 'tmp')
    let tmp = b:vimtex.tmp
  else
    call vimtex#echo#status(['vimtex: ', ['VimtexWarning', 'No output exists']])
    return
  endif

  " If window already open, then go there
  if exists('s:output')
    if bufwinnr(tmp) == s:output.winnr
      execute s:output.winnr . 'wincmd w'
      return
    else
      call s:output.destroy()
    endif
  endif

  " Create latexmk output window
  silent execute 'split' tmp

  " Create the output object
  let s:output = {}
  let s:output.name = tmp
  let s:output.bufnr = bufnr('%')
  let s:output.winnr = bufwinnr('%')
  function! s:output.update() dict
    if bufwinnr(self.name) != self.winnr
      return
    endif

    " Try to enforce a file read
    execute 'checktime' self.name
    redraw

    " Go to last line of file if it is not the current window
    if bufwinnr('%') != self.winnr
      let l:return = bufwinnr('%')
      execute 'keepalt' self.winnr . 'wincmd w'
      normal! Gzb
      execute 'keepalt' l:return . 'wincmd w'
    endif
  endfunction
  function! s:output.destroy() dict
    autocmd! vimtex_output_window
    augroup! vimtex_output_window
    unlet s:output
  endfunction

  " Better automatic update
  augroup vimtex_output_window
    autocmd!
    autocmd BufDelete <buffer> call s:output.destroy()
    autocmd BufEnter     *     call s:output.update()
    autocmd FocusGained  *     call s:output.update()
    autocmd CursorHold   *     call s:output.update()
    autocmd CursorHoldI  *     call s:output.update()
    autocmd CursorMoved  *     call s:output.update()
    autocmd CursorMovedI *     call s:output.update()
  augroup END

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
    if exists('#User#VimtexEventCompileStopped')
      doautocmd User VimtexEventCompileStopped
    endif
  else
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexWarning', 'no process to stop (' . b:vimtex.base . ')']])
  endif
endfunction

" }}}1
function! vimtex#latexmk#stop_all() " {{{1
  for data in values(g:vimtex_data)
    if get(data, 'pid', 0)
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

  if has('win32')
    let cmd  = 'cd /D "' . b:vimtex.root . '"'
    let cmd .= ' && set max_print_line=2000 & latexmk'
    let l:shellslash = &shellslash
    set noshellslash
  else
    let cmd  = 'cd ' . vimtex#util#shellescape(b:vimtex.root)
    if fnamemodify(&shell, ':t') ==# 'fish'
      let cmd .= '; and set max_print_line 2000; and latexmk'
    elseif fnamemodify(&shell, ':t') ==# 'tcsh'
      let cmd .= ' && set max_print_line=2000 && latexmk'
    else
      let cmd .= ' && max_print_line=2000 latexmk'
    endif
  endif

  let cmd .= ' ' . g:vimtex_latexmk_options

  let cmd .= ' ' . b:vimtex.engine

  if g:vimtex_latexmk_build_dir !=# ''
    let cmd .= ' -outdir=' . g:vimtex_latexmk_build_dir
  endif

  if g:vimtex_latexmk_continuous
    let cmd .= ' -pvc'

    "
    " Set viewer options
    "
    if !get(g:, 'vimtex_view_automatic', 1)
          \ || get(get(b:vimtex, 'viewer', {}), 'xwin_id', 0) > 0
          \ || get(s:, 'silence_next_callback', 0)
      let cmd .= ' -view=none'
    elseif g:vimtex_view_enabled
          \ && has_key(b:vimtex.viewer, 'latexmk_append_argument')
      let cmd .= b:vimtex.viewer.latexmk_append_argument()
    endif
  endif

  if g:vimtex_latexmk_callback && exists('v:servername')
    let l:cb = shellescape('""') . g:vimtex_latexmk_progname . shellescape('""')
          \ . ' --servername ' . v:servername
    let cmd .= vimtex#latexmk#add_option('success_cmd',
          \ l:cb . ' --remote-expr \"vimtex\#latexmk\#callback(1)\"')
    let cmd .= vimtex#latexmk#add_option('failure_cmd',
          \ l:cb . ' --remote-expr \"vimtex\#latexmk\#callback(0)\"')
    let s:first_callback = 1
  endif

  let cmd .= ' ' . vimtex#util#shellescape(b:vimtex.base)

  if g:vimtex_latexmk_continuous || g:vimtex_latexmk_background
    let tmp = tempname()
    let b:vimtex.tmp = tmp

    if has('win32')
      let cmd .= ' >'  . tmp
      let cmd = 'cmd /s /c "' . cmd . '"'
    elseif fnamemodify(&shell, ':t') ==# 'tcsh'
      let cmd .= ' >' . tmp . ' |& cat'
    else
      let cmd .= ' >' . tmp . ' 2>&1'
    endif
  elseif has('win32')
    let cmd = 'cmd /c "' . cmd . '"'
  endif

  let exe.cmd  = cmd
  let b:vimtex.cmd_latexmk_compile = cmd

  if has('win32')
    let &shellslash = l:shellslash
  endif

  return exe
endfunction

" }}}1
function! s:latexmk_build_cmd_selected(fname) " {{{1
  let exe = {}
  let exe.null = 0

  if has('win32')
    let cmd  = 'cd /D "' . b:vimtex.root . '"'
    let cmd .= ' && set max_print_line=2000 & latexmk'
    let l:shellslash = &shellslash
    set noshellslash
  else
    let cmd  = 'cd ' . vimtex#util#shellescape(b:vimtex.root)
    if fnamemodify(&shell, ':t') ==# 'fish'
      let cmd .= '; and set max_print_line 2000; and latexmk'
    elseif fnamemodify(&shell, ':t') ==# 'tcsh'
      let cmd .= ' && set max_print_line=2000 && latexmk'
    else
      let cmd .= ' && max_print_line=2000 latexmk'
    endif
  endif

  let cmd .= ' ' . g:vimtex_latexmk_options

  let cmd .= ' ' . b:vimtex.engine

  if g:vimtex_latexmk_build_dir !=# ''
    let cmd .= ' -outdir=' . g:vimtex_latexmk_build_dir
  endif

  let cmd .= ' ' . vimtex#util#shellescape(a:fname)

  let exe.cmd  = cmd
  let b:vimtex.cmd_latexmk_compile_selected = cmd

  if has('win32')
    let &shellslash = l:shellslash
  endif

  return exe
endfunction

" }}}1
function! s:latexmk_init_pid() " {{{1
  "
  " First see if the PID is already defined
  "
  let b:vimtex.pid = get(b:vimtex, 'pid', 0)

  "
  " Only search for PIDs if continuous mode is active
  "
  if !g:vimtex_latexmk_continuous | return | endif

  "
  " If the PID is 0, then search for existing processes
  "
  if b:vimtex.pid == 0
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
            \ 'pgrep -f "^[^ ]*perl.*latexmk.*' . b:vimtex.base . '"'), "\n")
        let path = resolve('/proc/' . l:pid . '/cwd') . '/' . b:vimtex.base
        if path ==# b:vimtex.tex
          let b:vimtex.pid = str2nr(l:pid)
          return
        endif
      endfor
    endif
  endif
endfunction

function! s:latexmk_init_build_dir() " {{{1
  if g:vimtex_latexmk_build_dir ==# '' | return | endif

  " First create list of necessary directories
  let l:dirs = split(glob(b:vimtex.root . '/**/*.tex'), '\n')
  call map(l:dirs, 'fnamemodify(v:val, '':h'')')
  call map(l:dirs, 'strpart(v:val, strlen(b:vimtex.root) + 1)')
  call s:uniq(sort(filter(l:dirs, "v:val !=# ''")))
  call map(l:dirs,
        \ "b:vimtex.root . '/' . g:vimtex_latexmk_build_dir . '/' . v:val")
  call filter(l:dirs, '!isdirectory(v:val)')

  " Create the non-existing directories
  for l:dir in l:dirs
    call mkdir(l:dir, 'p')
  endfor
endfunction

function! s:latexmk_set_pid() " {{{1
  if has('win32')
    let pidcmd = 'tasklist /fi "imagename eq latexmk.exe"'
    let pidinfo = split(system(pidcmd), '\n')[-1]
    let b:vimtex.pid = str2nr(split(pidinfo,'\s\+')[1])
  else
    let b:vimtex.pid = str2nr(system('pgrep -nf "^[^ ]*perl.*latexmk"')[:-2])
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
function! s:latexmk_set_build_dir() " {{{1
  let l:pattern = '^\s*\$out_dir\s*=\s*[''"]\(.\+\)[''"]\s*;\?\s*$'
  let l:files = [
        \ b:vimtex.root . '/latexmkrc',
        \ b:vimtex.root . '/.latexmkrc',
        \ fnamemodify('~/.latexmkrc', ':p'),
        \]

  let l:build_dir = ''
  for l:file in l:files
    if filereadable(l:file)
      let l:out_dir = matchlist(readfile(l:file), l:pattern)
      if len(l:out_dir) > 1
        let l:build_dir = l:out_dir[1]
        break
      endif
    endif
  endfor

  if !empty(l:build_dir)
    if !empty(g:vimtex_latexmk_build_dir)
      call vimtex#echo#warning(
            \ 'g:vimtex_latexmk_build_dir changed to: ' . l:build_dir)
      call vimtex#echo#wait()
    endif
    let g:vimtex_latexmk_build_dir = l:build_dir
  endif
endfunction

" }}}1

function! s:fix_quickfix_paths() " {{{1
  " Ensure this is only applied when necessary
  if !exists('s:qf_main') | return | endif

  " Set quickfix title
  let w:quickfix_title = 'Vimtex errors'

  let l:qflist = getqflist()
  for l:qf in l:qflist
    " For errors and warnings that don't supply a file, the basename of the
    " main file is used. However, if the working directory is not the root of
    " the LaTeX project, than this results in bufnr = 0.
    if l:qf.bufnr == 0
      let l:qf.bufnr = bufnr(s:qf_main)
      continue
    endif

    " The buffer names of all file:line type errors are relative to the root of
    " the main LaTeX file.
    let l:file = fnamemodify(simplify(s:qf_root . '/' . bufname(l:qf.bufnr)), ':.')
    if !filereadable(l:file) | continue | endif
    if !bufexists(l:file)
      execute 'badd' l:file
    endif
    let l:qf.bufnr = bufnr(l:file)
  endfor
  call setqflist(l:qflist)

  unlet s:qf_main
endfunction

" }}}1
function! s:clean_on_quit() " {{{1
  " Kill latexmk process if it exists
  if get(b:vimtex, 'pid', 0)
    call s:latexmk_kill(b:vimtex)
    call vimtex#echo#status(['latexmk compile: ',
          \ ['VimtexSuccess', 'stopped (' . b:vimtex.base . ')']])
  endif

  " Close quickfix window
  cclose
endfunction

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~# ''^.*:\d\+: ''')
  let lines = s:uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

function! s:check_system_compatibility() " {{{1
  if !g:vimtex_latexmk_enabled | return | endif

  "
  " Check for required executables
  "
  let required = ['latexmk']
  if g:vimtex_latexmk_continuous && !has('win32')
    let required += ['pgrep']
  endif
  let missing = filter(required, '!executable(v:val)')

  "
  " Disable latexmk if required programs are missing
  "
  if len(missing) > 0
    for cmd in missing
      call vimtex#echo#warning(cmd . ' is not executable')
    endfor
    call vimtex#echo#echo('- vimtex#latexmk was not initialized!')
    call vimtex#echo#wait()
    let g:vimtex_latexmk_enabled = 0
  endif
endfunction

" }}}1
function! s:uniq(list) " {{{1
  if exists('*uniq')
    return uniq(a:list)
  elseif len(a:list) == 0
    return a:list
  endif

  let l:last = get(a:list, 0)
  let l:ulist = [l:last]

  for l:i in range(1, len(a:list) - 1)
    let l:next = get(a:list, l:i)
    if l:next != l:last
      let l:last = l:next
      call add(l:ulist, l:next)
    endif
  endfor

  return l:ulist
endfunction

" }}}1


" {{{1 Initialize options

call vimtex#util#set_default('g:vimtex_latexmk_enabled', 1)
call vimtex#util#set_default('g:vimtex_latexmk_build_dir', '')
call vimtex#util#set_default('g:vimtex_latexmk_progname',
      \ get(v:, 'progpath', get(v:, 'progname')))
call vimtex#util#set_default('g:vimtex_latexmk_callback_hooks', [])
call vimtex#util#set_default('g:vimtex_latexmk_background', 0)
call vimtex#util#set_default('g:vimtex_latexmk_callback', 1)
call vimtex#util#set_default('g:vimtex_latexmk_continuous', 1)
call vimtex#util#set_default('g:vimtex_latexmk_options',
      \ '-verbose -pdf -file-line-error -synctex=1 -interaction=nonstopmode')

call vimtex#util#set_default('g:vimtex_quickfix_autojump', '0')
call vimtex#util#set_default('g:vimtex_quickfix_mode', '2')
call vimtex#util#set_default('g:vimtex_quickfix_open_on_warning', '1')

" Check if .latexmkrc sets the build_dir - if so this should be respected
call s:latexmk_set_build_dir()

call s:check_system_compatibility()

if g:vimtex_latexmk_enabled
  if exists('g:vimtex_quickfix_ignore_all_warnings')
    echoerr 'Deprecated option: g:vimtex_quickfix_ignore_all_warnings'
    echoerr 'Please see ":h g:vimtex_quickfix_ignore_all_warnings"'
  endif

  if exists('g:vimtex_quickfix_ignored_warnings')
    echoerr 'Deprecated option: g:vimtex_quickfix_ignored_warnings'
    echoerr 'Please see ":h g:vimtex_quickfix_ignored_warnings"'
  endif
endif

" }}}1
" {{{1 Initialize module

if !g:vimtex_latexmk_enabled | finish | endif

" Ensure that all latexmk processes are stopped when a latex project is
" closed and when vim exits
if g:vimtex_latexmk_continuous
  augroup vimtex_latexmk
    autocmd!
    autocmd VimLeave * call vimtex#latexmk#stop_all()
    autocmd User VimtexEventQuit call s:clean_on_quit()
  augroup END
endif

" Add autocommand to fix paths in quickfix
augroup vimtex_latexmk_fix_dirs
  au!
  au QuickFixCmdPost c*file call s:fix_quickfix_paths()
augroup END

" }}}1

" vim: fdm=marker sw=2
