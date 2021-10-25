" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init_buffer() abort " {{{1
  if !g:vimtex_view_enabled | return | endif

  command! -buffer -nargs=? -complete=file VimtexView
        \ call vimtex#view#view(<q-args>)

  nnoremap <buffer> <plug>(vimtex-view) :VimtexView<cr>
endfunction

" }}}1
function! vimtex#view#init_state(state) abort " {{{1
  if !g:vimtex_view_enabled | return | endif
  if has_key(a:state, 'viewer') | return | endif

  if g:vimtex_view_use_temp_files
    augroup vimtex_view_buffer
      autocmd User VimtexEventCompileSuccess call b:vimtex.viewer.copy_files()
    augroup END
  endif

  try
    let a:state.viewer = vimtex#view#{g:vimtex_view_method}#new()
  catch /E117/
    call vimtex#log#warning(
          \ 'Invalid viewer: ' . g:vimtex_view_method,
          \ 'Please see :h g:vimtex_view_method')
    return
  endtry
endfunction

" }}}1

function! vimtex#view#view(...) abort " {{{1
  if exists('*b:vimtex.viewer.view')
    call b:vimtex.viewer.view(a:0 > 0 ? a:1 : '')
  endif
endfunction

" }}}1
function! vimtex#view#not_readable(output) abort " {{{1
  if filereadable(a:output) | return 0 | endif

  call vimtex#log#warning('Viewer cannot read PDF file!', a:output)
  return 1
endfunction

" }}}1

function! vimtex#view#reverse_goto(line, filename) abort " {{{1
  if mode() ==# 'i' | stopinsert | endif

  let l:file = resolve(a:filename)

  " Open file if necessary
  if !bufloaded(l:file)
    if filereadable(l:file)
      try
        execute g:vimtex_view_reverse_search_edit_cmd l:file
      catch
        call vimtex#log#warning([
              \ 'Reverse goto failed!',
              \ printf('Command error: %s %s',
              \        g:vimtex_view_reverse_search_edit_cmd, l:file)])
        return
      endtry
    else
      call vimtex#log#warning([
            \ 'Reverse goto failed!',
            \ printf('File not readable: "%s"', l:file)])
      return
    endif
  endif

  " Get buffer, window, and tab numbers
  " * If tab/window exists, switch to it/them
  let l:bufnr = bufnr(l:file)
  try
    let [l:winid] = win_findbuf(l:bufnr)
    let [l:tabnr, l:winnr] = win_id2tabwin(l:winid)
    execute l:tabnr . 'tabnext'
    execute l:winnr . 'wincmd w'
  catch
    execute g:vimtex_view_reverse_search_edit_cmd l:file
  endtry

  execute 'normal!' a:line . 'G'
  redraw
  call s:focus_vim()

  if exists('#User#VimtexEventViewReverse')
    doautocmd <nomodeline> User VimtexEventViewReverse
  endif
endfunction

" }}}1

function! vimtex#view#send(line, filename) abort " {{{1
  try
    if has('nvim')
      call vimtex#view#send_nvim(a:line, a:filename)
    else
      call vimtex#view#send_vim(a:line, a:filename)
    endif
  catch
  endtry
  quitall!
endfunction

" }}}1
function! vimtex#view#send_vim(line, filename) abort " {{{1
  for l:server in split(serverlist(), "\n")
    call remote_expr(l:server,
          \ printf("vimtex#view#receive(%d, '%s')", a:line, a:filename))
  endfor
endfunction

" }}}1
function! vimtex#view#send_nvim(line, filename) abort " {{{1
  py3 <<EOF
import psutil

sockets = []
for proc in (p for p in psutil.process_iter(attrs=['name'])
             if p.info['name'] == 'nvim'):
    sockets += [c.laddr for c in proc.connections('unix') if c.laddr]
EOF

  for l:socket_id in filter(py3eval('sockets'), 'v:val != v:servername')
    let l:socket = sockconnect('pipe', l:socket_id, {'rpc': 1})
    call rpcrequest(l:socket,
          \ 'nvim_call_function',
          \ 'vimtex#view#receive',
          \ [a:line, a:filename])
    call chanclose(l:socket)
  endfor
endfunction

" }}}1

function! vimtex#view#receive(line, filename) abort " {{{1
  if !exists('b:vimtex') | return | endif

  if mode() ==# 'i' | stopinsert | endif

  let l:file = resolve(a:filename)

  " Open file if necessary
  if !bufloaded(l:file)
    if filereadable(l:file)
      try
        execute g:vimtex_view_reverse_search_edit_cmd l:file
      catch
        call vimtex#log#warning([
              \ 'Reverse goto failed!',
              \ printf('Command error: %s %s',
              \        g:vimtex_view_reverse_search_edit_cmd, l:file)])
        return
      endtry
    else
      call vimtex#log#warning([
            \ 'Reverse goto failed!',
            \ printf('File not readable: "%s"', l:file)])
      return
    endif
  endif

  " Get buffer, window, and tab numbers
  " * If tab/window exists, switch to it/them
  let l:bufnr = bufnr(l:file)
  try
    let [l:winid] = win_findbuf(l:bufnr)
    let [l:tabnr, l:winnr] = win_id2tabwin(l:winid)
    execute l:tabnr . 'tabnext'
    execute l:winnr . 'wincmd w'
  catch
    execute g:vimtex_view_reverse_search_edit_cmd l:file
  endtry

  execute 'normal!' a:line . 'G'
  redraw
  call s:focus_vim()

  if exists('#User#VimtexEventViewReverse')
    doautocmd <nomodeline> User VimtexEventViewReverse
  endif
endfunction

" }}}1

function! s:focus_vim() abort " {{{1
  if !executable('pstree') || !executable('xdotool') | return | endif

  " The idea is to use xdotool to focus the window ID of the relevant windowed
  " process. To do this, we need to check the process tree. Inside TMUX we need
  " to check from the PID of the tmux client. We find this PID by listing the
  " PIDS of the corresponding pty.
  if empty($TMUX)
    let l:current_pid = getpid()
  else
    let l:output = vimtex#jobs#capture('tmux display-message -p "#{client_tty}"')
    let l:pts = split(trim(l:output[0]), '/')[-1]
    let l:current_pid = str2nr(vimtex#jobs#capture('ps o pid t ' . l:pts)[1])
  endif

  let l:output = join(vimtex#jobs#capture('pstree -s -p ' . l:current_pid))
  let l:pids = split(l:output, '\D\+')
  let l:pids = l:pids[: index(l:pids, string(l:current_pid))]

  for l:pid in reverse(l:pids)
    let l:output = vimtex#jobs#capture(
          \ 'xdotool search --onlyvisible --pid ' . l:pid)
    let l:xwinids = filter(reverse(l:output), '!empty(v:val)')

    if !empty(l:xwinids)
      call vimtex#jobs#run('xdotool windowactivate ' . l:xwinids[0] . ' &')
      call feedkeys("\<c-l>", 'tn')
      return l:xwinids[0]
      break
    endif
  endfor
endfunction

" }}}1
