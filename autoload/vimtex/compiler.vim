" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#init_buffer() abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  " Define commands
  command! -buffer        VimtexCompile                        call vimtex#compiler#compile()
  command! -buffer -bang  VimtexCompileSS                      call vimtex#compiler#compile_ss()
  command! -buffer -range VimtexCompileSelected <line1>,<line2>call vimtex#compiler#compile_selected('cmd')
  command! -buffer        VimtexCompileOutput                  call vimtex#compiler#output()
  command! -buffer        VimtexStop                           call vimtex#compiler#stop()
  command! -buffer        VimtexStopAll                        call vimtex#compiler#stop_all()
  command! -buffer -bang  VimtexClean                          call vimtex#compiler#clean(<q-bang> == "!")
  command! -buffer -bang  VimtexStatus                         call vimtex#compiler#status(<q-bang> == "!")

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-compile)          :call vimtex#compiler#compile()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-ss)       :call vimtex#compiler#compile_ss()<cr>
  nnoremap <buffer> <plug>(vimtex-compile-selected) :set opfunc=vimtex#compiler#compile_selected<cr>g@
  xnoremap <buffer> <plug>(vimtex-compile-selected) :<c-u>call vimtex#compiler#compile_selected('visual')<cr>
  nnoremap <buffer> <plug>(vimtex-compile-output)   :call vimtex#compiler#output()<cr>
  nnoremap <buffer> <plug>(vimtex-stop)             :call vimtex#compiler#stop()<cr>
  nnoremap <buffer> <plug>(vimtex-stop-all)         :call vimtex#compiler#stop_all()<cr>
  nnoremap <buffer> <plug>(vimtex-clean)            :call vimtex#compiler#clean(0)<cr>
  nnoremap <buffer> <plug>(vimtex-clean-full)       :call vimtex#compiler#clean(1)<cr>
  nnoremap <buffer> <plug>(vimtex-status)           :call vimtex#compiler#status(0)<cr>
  nnoremap <buffer> <plug>(vimtex-status-all)       :call vimtex#compiler#status(1)<cr>
endfunction

" }}}1
function! vimtex#compiler#init_state(state) abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  try
    let l:options = {
          \ 'root': a:state.root,
          \ 'target' : a:state.base,
          \ 'target_path' : a:state.tex,
          \ 'engine' : a:state.engine,
          \}
    let a:state.compiler
          \ = vimtex#compiler#{g:vimtex_compiler_method}#init(l:options)
  catch /vimtex: Requirements not met/
    call vimtex#log#error('Compiler was not initialized!')
  catch /E117/
    call vimtex#log#error(
          \ 'Invalid compiler: ' . g:vimtex_compiler_method,
          \ 'Please see :h g:vimtex_compiler_method')
  endtry
endfunction

" }}}1

function! vimtex#compiler#callback(status) abort " {{{1
  if get(b:vimtex.compiler, 'silence_next_callback')
    let b:vimtex.compiler.silence_next_callback = 0
    return
  endif

  call vimtex#qf#open(0)
  redraw

  if exists('s:output')
    call s:output.update()
  endif

  if a:status
    call vimtex#log#info('Compilation completed')
  else
    call vimtex#log#warning('Compilation failed!')
  endif

  if a:status
    call b:vimtex.parse_packages_from_fls()
  endif

  for l:hook in g:vimtex_compiler_callback_hooks
    execute 'call' l:hook . '(' . a:status . ')'
  endfor

  return ''
endfunction

" }}}1

function! vimtex#compiler#compile() abort " {{{1
  if get(b:vimtex.compiler, 'continuous')
    if b:vimtex.compiler.is_running()
      call b:vimtex.compiler.stop()
    else
      call b:vimtex.compiler.start()
    endif
  else
    call b:vimtex.compiler.start_single()
  endif
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
        \ 'root' : l:file.root,
        \ 'target' : l:file.base,
        \ 'target_path' : l:file.tex,
        \ 'backend' : 'process',
        \ 'engine' : b:vimtex.engine,
        \ 'background' : 1,
        \ 'continuous' : 0,
        \ 'callback' : 0,
        \}
  let l:compiler = vimtex#compiler#{g:vimtex_compiler_method}#init(l:options)

  call vimtex#log#toggle_verbose()
  call l:compiler.start()

  " Check if successful
  if vimtex#qf#inquire(l:file.base)
    call vimtex#log#toggle_verbose()
    call vimtex#log#warning('Compiling selected lines ... failed!')
    botright cwindow
    return
  else
    call l:compiler.clean(0)
    call b:vimtex.viewer.view(l:file.pdf)
    call vimtex#log#toggle_verbose()
    call vimtex#log#info('Compiling selected lines ... done')
  endif
endfunction

" }}}1
function! vimtex#compiler#output() " {{{1
  let l:file = get(b:vimtex.compiler, 'output', '')
  if empty(l:file)
    call vimtex#log#warning('No output exists!')
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
  nnoremap <silent><buffer> q :bwipeout<cr>
  if has('nvim') || has('gui_running')
    nnoremap <silent><buffer> <esc> :bwipeout<cr>
  endif

  " Set some buffer options
  setlocal autoread
  setlocal nomodifiable
  setlocal bufhidden=wipe
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
function! vimtex#compiler#clean(full) " {{{1
  call b:vimtex.compiler.clean(a:full)

  if empty(b:vimtex.compiler.build_dir) | return | endif
  sleep 100m

  " Remove auxilliary output directories if they are empty
  let l:build_dir = b:vimtex.root . '/' . b:vimtex.compiler.build_dir
  let l:tree = glob(l:build_dir . '/**/*', 0, 1)
  let l:files = filter(copy(l:tree), 'filereadable(v:val)')
  if !empty(l:files) | return | endif

  for l:dir in sort(l:tree) + [l:build_dir]
    call delete(l:dir, 'd')
  endfor
endfunction

" }}}1
function! vimtex#compiler#status(detailed) " {{{1
  if a:detailed
    let l:running = []
    for l:data in vimtex#state#list_all()
      if l:data.compiler.is_running()
        let l:name = l:data.tex
        if len(l:name) >= winwidth('.') - 20
          let l:name = '...' . l:name[-winwidth('.')+23:]
        endif
        call add(l:running, printf('%-6s %s',
              \ string(l:data.compiler.get_pid()) . ':', l:name))
      endif
    endfor

    if empty(l:running)
      call vimtex#log#warning('Compiler is not running!')
    else
      call vimtex#log#info('Compiler is running', l:running)
    endif
  else
    if b:vimtex.compiler.is_running()
      call vimtex#log#info('Compiler is running')
    else
      call vimtex#log#warning('Compiler is not running!')
    endif
  endif
endfunction

" }}}1


" {{{1 Initialize module

if !g:vimtex_compiler_enabled | finish | endif

augroup vimtex_compiler
  autocmd!
  autocmd VimLeave * call vimtex#compiler#stop_all()
augroup END

" }}}1

" vim: fdm=marker sw=2
