" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#init_buffer() abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  " Set compiler (this defines the errorformat)
  compiler latexmk

  " Define commands
  command! -buffer        VimtexCompile                        call vimtex#compiler#compile()
  command! -buffer -bang  VimtexCompileSS                      call vimtex#compiler#compile_ss()
  command! -buffer -range VimtexCompileSelected <line1>,<line2>call vimtex#compiler#compile_selected('cmd')
  command! -buffer        VimtexCompileToggle                  call vimtex#compiler#toggle()
  command! -buffer        VimtexCompileOutput                  call vimtex#compiler#output()
  command! -buffer        VimtexStop                           call vimtex#compiler#stop()
  command! -buffer        VimtexStopAll                        call vimtex#compiler#stop_all()
  command! -buffer        VimtexErrors                         call vimtex#compiler#errors_toggle()
  command! -buffer -bang  VimtexClean                          call vimtex#compiler#clean(<q-bang> == "!")
  command! -buffer -bang  VimtexStatus                         call vimtex#compiler#status(<q-bang> == "!")
  command! -buffer        VimtexLacheck                        call vimtex#compiler#lacheck()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-compile)          :call vimtex#compiler#compile()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-ss)       :call vimtex#compiler#compile_ss()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-selected) :set opfunc=vimtex#compiler#compile_selected<cr>g@
  xnoremap <buffer> <plug>(vimtex-compile-selected) :<c-u>call vimtex#compiler#compile_selected('visual')<cr>
  nnoremap <buffer> <plug>(vimtex-compile-toggle)   :call vimtex#compiler#toggle()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-output)   :call vimtex#compiler#output()<cr>
  nnoremap <buffer> <plug>(vimtex-stop)             :call vimtex#compiler#stop()<cr>
  nnoremap <buffer> <plug>(vimtex-stop-all)         :call vimtex#compiler#stop_all()<cr>
  nnoremap <buffer> <plug>(vimtex-errors)           :call vimtex#compiler#errors_toggle()<cr>
  nnoremap <buffer> <plug>(vimtex-clean)            :call vimtex#compiler#clean(0)<cr>
  nnoremap <buffer> <plug>(vimtex-clean-full)       :call vimtex#compiler#clean(1)<cr>
  nnoremap <buffer> <plug>(vimtex-status)           :call vimtex#compiler#status(0)<cr>
  nnoremap <buffer> <plug>(vimtex-status-all)       :call vimtex#compiler#status(1)<cr>
  nnoremap <buffer> <plug>(vimtex-lacheck)          :call vimtex#compiler#lacheck()<cr>
endfunction

" }}}1
function! vimtex#compiler#init_state(state) abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  try
    let a:state.compiler = vimtex#compiler#{g:vimtex_compiler_method}#init()
  catch /vimtex: Requirements not met/
    call vimtex#echo#echo('- vimtex#compiler was not initialized!')
    call vimtex#echo#wait()
  catch /E117/
    call vimtex#echo#warning('compiler '
          \ . g:vimtex_compiler_method . ' does not exist!')
    call vimtex#echo#echo('- Please see :h g:vimtex_compiler_method')
    call vimtex#echo#wait()
  endtry
endfunction

" }}}1

function! vimtex#compiler#callback(status) abort " {{{1
  if get(b:vimtex.compiler, 'silence_next_callback')
    let b:vimtex.compiler.silence_next_callback = 0
    return
  endif

  call vimtex#compiler#errors_open(0)
  redraw

  if exists('s:output')
    call s:output.update()
  endif

  call vimtex#echo#status(['compiler: ',
        \ a:status ? ['VimtexSuccess', 'success'] : ['VimtexWarning', 'fail']])

  for l:hook in g:vimtex_compiler_callback_hooks
    execute 'call' l:hook . '(' . a:status . ')'
  endfor

  return ''
endfunction

" }}}1

function! vimtex#compiler#compile() abort " {{{1
  call b:vimtex.compiler.start()
endfunction

" }}}1
function! vimtex#compiler#compile_ss() abort " {{{1
  call b:vimtex.compiler.start_single()
endfunction

" }}}1
function! vimtex#compiler#compile_selected(type) abort range " {{{1
  let l:file = vimtex#parser#selection_to_texfile(a:type)
  if empty(l:file) | return | endif

  " Create and initialize temporary compiler
  let l:options = {
        \ 'target' : l:file.base,
        \ 'target_full_path' : l:file.tex,
        \ 'background' : 0,
        \ 'continuous' : 0,
        \ 'callback' : 0,
        \}
  let l:compiler = vimtex#compiler#{g:vimtex_compiler_method}#init(l:options)

  call vimtex#echo#status([
        \ ['VimtexInfo', 'vimtex: '],
        \ ['VimtexMsg', 'compiling selected lines ...']])
  call l:compiler.start()

  " Check if successful
  if vimtex#compiler#errors_inquire(l:file.base)
    call vimtex#echo#formatted([
          \ ['VimtexInfo', 'vimtex: '],
          \ ['VimtexMsg', 'compiling selected lines ...'],
          \ ['VimtexWarning', ' failed!']])
    botright cwindow
    return
  else
    call l:compiler.clean(0)
    call b:vimtex.viewer.view(l:file.pdf)
    call vimtex#echo#status([
          \ ['VimtexInfo', 'vimtex: '],
          \ ['VimtexMsg', 'compiling selected lines ... done!']])
  endif
endfunction

" }}}1
function! vimtex#compiler#toggle() " {{{1
  if b:vimtex.compiler.is_running()
    call b:vimtex.compiler.stop()
  else
    call b:vimtex.compiler.start()
  endif
endfunction

" }}}1
function! vimtex#compiler#output() " {{{1
  let l:file = get(b:vimtex.compiler, 'output', '')
  if empty(l:file)
    call vimtex#echo#status(['vimtex: ', ['VimtexWarning', 'No output exists']])
    return
  endif

  " If window already open, then go there
  if exists('s:output')
    if bufwinnr(l:file) == s:output.winnr
      execute s:output.winnr . 'wincmd w'
      return
    else
      call s:output.destroy()
    endif
  endif

  " Create new output window
  silent execute 'split' l:file

  " Create the output object
  let s:output = {}
  let s:output.name = l:file
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
function! vimtex#compiler#stop() " {{{1
  call b:vimtex.compiler.stop()
endfunction

" }}}1
function! vimtex#compiler#stop_all() " {{{1
  for l:state in vimtex#state#list_all()
    if exists('l:state.compiler.is_running')
          \ && l:state.compiler.is_running()
      call l:state.compiler.stop()
    endif
  endfor
endfunction

" }}}1
function! vimtex#compiler#errors_toggle() " {{{1
  if s:qf.is_open
    let s:qf.is_open = 0
    cclose
  else
    call vimtex#compiler#errors_open(1)
  endif
endfunction

" }}}1
function! vimtex#compiler#errors_open(force) " {{{1
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

  " Store winnr of current window in order to jump back later
  call s:window_save()

  " Save path for fixing quickfix entries
  let s:qf.is_active = 1
  let s:qf.main = b:vimtex.tex

  if g:vimtex_quickfix_autojump
    execute 'cfile' fnameescape(log)
  else
    execute 'cgetfile' fnameescape(log)
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
  let s:qf.is_open = a:force
        \ || (g:vimtex_quickfix_mode > 0
        \     && (g:vimtex_quickfix_open_on_warning
        \         || s:log_contains_error(log)))

  if s:qf.is_open
    botright cwindow
    if g:vimtex_quickfix_mode == 2
      call s:window_restore()
    endif
    redraw
  endif
endfunction

" }}}1
function! vimtex#compiler#errors_inquire(...) " {{{1
  if !exists('b:vimtex') | return | endif

  let l:log = a:0 > 0 ? a:1.log : b:vimtex.log()
  if empty(l:log) | return 0 | endif

  let s:qf.is_active = 1
  let s:qf.main = a:0 > 0 ? a:1.tex : b:vimtex.tex
  execute 'cgetfile ' . fnameescape(l:log)

  return !empty(getqflist())
endfunction

" }}}1
function! vimtex#compiler#clean(full) " {{{1
  call b:vimtex.compiler.clean(a:full)
endfunction

" }}}1
function! vimtex#compiler#status(detailed) " {{{1
  if a:detailed
    let l:running = 0
    for l:data in values(g:vimtex_data)
      if l:data.compiler.is_running()
        if !l:running
          call vimtex#echo#status(['latexmk status: ',
                \ ['VimtexSuccess', "running\n"]])
          call vimtex#echo#status([['None', '  pid    '],
                \ ['None', "file\n"]])
          let l:running = 1
        endif

        let l:name = l:data.tex
        if len(l:name) >= winwidth('.') - 20
          let l:name = '...' . l:name[-winwidth('.')+23:]
        endif

        call vimtex#echo#status([
              \ ['None', printf('  %-6s ', l:data.compiler.process.pid)],
              \ ['None', l:name . "\n"]])
      endif
    endfor

    if !l:running
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexWarning', 'not running']])
    endif
  else
    if b:vimtex.compiler.is_running()
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexSuccess', 'running']])
    else
      call vimtex#echo#status(['latexmk status: ',
            \ ['VimtexWarning', 'not running']])
    endif
  endif
endfunction

" }}}1
function! vimtex#compiler#lacheck() " {{{1
  compiler lacheck

  silent lmake %
  lwindow
  silent redraw
  wincmd p

  compiler latexmk
endfunction

" }}}1

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~# ''^.*:\d\+: ''')
  let lines = vimtex#util#uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

" }}}1
function! s:window_save() " {{{1
  if exists('*win_gotoid')
    let s:previous_window = win_getid()
  else
    let w:vimtex_remember_window = 1
  endif
endfunction

" }}}1
function! s:window_restore() " {{{1
  if exists('*win_gotoid')
    call win_gotoid(s:previous_window)
  else
    for l:winnr in range(1, winnr('$'))
      if getwinvar(l:winnr, 'vimtex_remember_window')
        execute l:winnr . 'wincmd p'
      endif
    endfor
  endif
endfunction

" }}}1


" {{{1 Initialize module

if !g:vimtex_compiler_enabled | finish | endif

augroup vimtex_compiler
  autocmd!
  autocmd VimLeave * call vimtex#compiler#stop_all()
augroup END

"
" Define a state object for the quickfix window in order to fix paths if
" necessary (the autocmd will fire on all filetypes, but the state object
" ensures that the function is only run for LaTeX files)
"

let s:qf = {
      \ 'is_open' : 0,
      \ 'is_active' : 0,
      \ 'title' : 'Vimtex errors',
      \ 'main' : b:vimtex.tex,
      \ 'root' : b:vimtex.root,
      \}

function! s:qf.fix_paths() abort dict " {{{2
  if !self.is_active | return | endif

  " Set quickfix title
  let w:quickfix_title = self.title

  let l:qflist = getqflist()
  for l:qf in l:qflist
    " For errors and warnings that don't supply a file, the basename of the
    " main file is used. However, if the working directory is not the root of
    " the LaTeX project, than this results in bufnr = 0.
    if l:qf.bufnr == 0
      let l:qf.bufnr = bufnr(s:qf.main)
      continue
    endif

    " The buffer names of all file:line type errors are relative to the root of
    " the main LaTeX file.
    let l:file = fnamemodify(
          \ simplify(self.root . '/' . bufname(l:qf.bufnr)), ':.')
    if !filereadable(l:file) | continue | endif
    if !bufexists(l:file)
      execute 'badd' l:file
    endif
    let l:qf.bufnr = bufnr(l:file)
  endfor
  call setqflist(l:qflist, 'r', {'title': self.title})

  let self.is_active = 0
endfunction

" }}}2

augroup vimtex_quickfix_fix_dirs
  au!
  au QuickFixCmdPost c*file call s:qf.fix_paths()
augroup END

" }}}1

" vim: fdm=marker sw=2
