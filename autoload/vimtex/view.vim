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

  if has('nvim')
    call s:nvim_prune_servernames()
  endif
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

function! vimtex#view#inverse_search(line, filename) abort " {{{1
  " Only activate in VimTeX buffers
  if !exists('b:vimtex') | return -1 | endif

  " Only activate in relevant VimTeX projects
  let l:file = resolve(a:filename)
  let l:sources = copy(b:vimtex.sources)
  if vimtex#paths#is_abs(l:file)
    call map(l:sources, {_, x -> vimtex#paths#join(b:vimtex.root, x)})
  endif
  if index(l:sources, l:file) < 0 | return -2 | endif


  if mode() ==# 'i' | stopinsert | endif

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
        return -3
      endtry
    else
      call vimtex#log#warning([
            \ 'Reverse goto failed!',
            \ printf('File not readable: "%s"', l:file)])
      return -4
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
  call s:focus_vim()
  redraw

  if exists('#User#VimtexEventViewReverse')
    doautocmd <nomodeline> User VimtexEventViewReverse
  endif
endfunction

" }}}1
function! vimtex#view#inverse_search_cmd(line, filename) abort " {{{1
  " One may call this function manually, but the main usage is to through the
  " command "VimtexInverseSearch". See ":help vimtex-synctex-inverse-search"
  " for more info.

  if a:line > 0 && !empty(a:filename)
    try
      if has('nvim')
        call s:inverse_search_cmd_nvim(a:line, a:filename)
      else
        call s:inverse_search_cmd_vim(a:line, a:filename)
      endif
    catch
    endtry
  endif

  quitall!
endfunction

" }}}1

function! s:inverse_search_cmd_nvim(line, filename) abort " {{{1
  if !filereadable(s:nvim_servernames) | return | endif

  for l:server in readfile(s:nvim_servernames)
    try
      let l:socket = sockconnect('pipe', l:server, {'rpc': 1})
    catch
    endtry

    call rpcnotify(l:socket,
          \ 'nvim_call_function',
          \ 'vimtex#view#inverse_search',
          \ [a:line, a:filename])
    call chanclose(l:socket)
  endfor
endfunction

function! s:inverse_search_cmd_vim(line, filename) abort " {{{1
  for l:server in split(serverlist(), "\n")
    call remote_expr(l:server,
          \ printf("vimtex#view#inverse_search(%d, '%s')", a:line, a:filename))
  endfor
endfunction

" }}}1

function! s:nvim_prune_servernames() abort " {{{1
  " Load servernames from file
  let l:servers = filereadable(s:nvim_servernames)
        \ ? readfile(s:nvim_servernames)
        \ : []

  " Check which servers are available
  let l:available_servernames = []
  for l:server in vimtex#util#uniq_unsorted(l:servers + [v:servername])
    try
      let l:socket = sockconnect('pipe', l:server)
      call add(l:available_servernames, l:server)
      call chanclose(l:socket)
    catch
    endtry
  endfor

  " Write the pruned list to file
  call writefile(l:available_servernames, s:nvim_servernames)
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


let s:nvim_servernames = vimtex#cache#path('nvim_servernames.log')
