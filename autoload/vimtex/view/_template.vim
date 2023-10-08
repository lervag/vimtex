" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#_template#new(viewer) abort " {{{1
  return extend(deepcopy(s:viewer), a:viewer)
endfunction

" }}}1


let s:viewer = {}

function! s:viewer.init() abort dict " {{{1
  let l:viewer = deepcopy(self)
  unlet l:viewer.init
  return l:viewer
endfunction

" }}}1
function! s:viewer.check() abort " {{{1
  if !has_key(self, '_check_value')
    let self._check_value = self._check()
  endif

  return self._check_value
endfunction

" }}}1
function! s:viewer.out() dict abort " {{{1
  if !exists('b:vimtex') | return '' | endif

  let l:out = b:vimtex.compiler.get_file('pdf')

  " Copy pdf and synctex files if we use temporary files
  if g:vimtex_view_use_temp_files
    let l:temp = b:vimtex.root . '/' . b:vimtex.name . '_vimtex.pdf'
    if getftime(l:out) > getftime(l:temp)
      call writefile(readfile(l:out, 'b'), l:temp, 'b')
    endif
    let l:out = l:temp

    let l:old = b:vimtex.compiler.get_file('synctex.gz')
    let l:new = fnamemodify(l:out, ':r') . '.synctex.gz'
    if getftime(l:old) > getftime(l:new)
      call rename(l:old, l:new)
    endif
  endif

  return filereadable(l:out) ? l:out : ''
endfunction

" }}}1
function! s:viewer.view(file) dict abort " {{{1
  if !self.check() | return | endif

  if !empty(a:file)
    let l:outfile = a:file
  else
    let l:outfile = self.out()
  endif

  if !filereadable(l:outfile)
    call vimtex#log#warning('Viewer cannot read PDF file!', l:outfile)
    return
  endif

  if self._exists()
    call self._forward_search(l:outfile)
  else
    call self._start(l:outfile)
  endif

  if exists('#User#VimtexEventView')
    doautocmd <nomodeline> User VimtexEventView
  endif
endfunction

" }}}1
function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  if !g:vimtex_view_automatic
      \ || has_key(self, 'started_through_callback') | return | endif

  call self._start(a:outfile)
  let self.started_through_callback = 1

  if exists('#User#VimtexEventView')
    doautocmd <nomodeline> User VimtexEventView
  endif
endfunction

" }}}1
function! s:viewer.compiler_stopped() dict abort " {{{1
  if has_key(self, 'started_through_callback')
    unlet self.started_through_callback
  endif
endfunction

" }}}1

function! s:viewer._exists() dict abort " {{{1
  return v:false
endfunction

" }}}1

function! s:viewer.__pprint() abort dict " {{{1
  let l:list = []

  if has_key(self, 'xwin_id')
    call add(l:list, ['xwin id', self.xwin_id])
  endif

  if has_key(self, 'job')
    call add(l:list, ['job', self.job])
  endif

  for l:key in filter(keys(self), 'v:val =~# ''^cmd''')
    call add(l:list, [l:key, self[l:key]])
  endfor

  return l:list
endfunction

" }}}1


" Methods that rely on xdotool. These are made available to all viewers, but
" they are only relevant for those that has the "xwin_id" attribute.

function! s:viewer.xdo_check() dict abort " {{{1
  return executable('xdotool') && has_key(self, 'xwin_id')
endfunction

" }}}1
function! s:viewer.xdo_get_id() dict abort " {{{1
  if !self.xdo_check() | return 0 | endif

  if self.xwin_id > 0 | return self.xwin_id | endif

  " Try to find viewer's window ID by different methods:
  " * by PID (probably most reliable when it works)
  " * by window name
  " * by window class (fallback)
  for l:method in ['pid', 'name', 'class']
    execute "let self.xwin_id = self.xdo_find_win_id_by_" . l:method . "()"
    if self.xwin_id > 0 | return self.xwin_id | endif
  endfor

  call vimtex#log#warning('Viewer cannot find ' . self.name . ' window ID!')
  return self.xwin_id
endfunction

" }}}1
function! s:viewer.xdo_exists() dict abort " {{{1
  if !self.xdo_check() | return v:false | endif

  " If xwin_id is already set, check if a matching viewer window still exists
  if self.xwin_id > 0
    let l:xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
    if index(l:xwin_ids, self.xwin_id) < 0
      let self.xwin_id = 0
    endif
    if self.xwin_id > 0 | return v:true | endif
  endif

  " If xwin_id is unset, then search for viewer by PID
  let self.xwin_id = self.xdo_find_win_id_by_pid()
  if self.xwin_id > 0 | return v:true | endif

  " If xwin_id is still unset, then search for viewer by window name
  let self.xwin_id = self.xdo_find_win_id_by_name()

  return self.xwin_id > 0
endfunction

" }}}1
function! s:viewer.xdo_find_win_id_by_class() dict abort " {{{1
  " Attempt to find viewer's X window ID by window class name.
  " Returns the viewer's window ID if one is found or 0. If multiple IDs are
  " found, return the last one. This seems to work well in most cases.
  let l:xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
  return get(l:xwin_ids, -1)
endfunction

" }}}1
function! s:viewer.xdo_find_win_id_by_name() dict abort " {{{1
  " Attempt to find viewer's X window ID by window name (i.e. the string in the
  " window titlebar).
  " Returns the viewer's window ID if one is found or 0.
  let l:xwin_ids = vimtex#jobs#capture(
        \ 'xdotool search --name ' . fnamemodify(self.out(), ':t'))

  " Note: We filter by existing VimTeX states because a user may have multiple
  "       VimTeX sessions going with the same basename.
  let l:xwin_ids_in_use = filter(map(
        \   deepcopy(vimtex#state#list_all()),
        \   {_, x -> get(get(x, 'viewer', {}), 'xwin_id')}),
        \ 'v:val > 0')
  call filter(l:xwin_ids, {_, x -> index(l:xwin_ids_in_use, x) < 0})

  return get(l:xwin_ids, 0)
endfunction

" }}}1
function! s:viewer.xdo_find_win_id_by_pid() dict abort " {{{1
  " Attempt to find the viewer's X window ID by the viewer's process ID.
  " Returns the viewer's window ID if one is found or 0. If more than one ID is
  " found, return the first.
  let l:pid = has_key(self, 'get_pid') ? self.get_pid() : 0
  if l:pid <= 0 | return 0 | endif

  let l:xwin_ids = vimtex#jobs#capture(
        \   'xdotool search --all --pid ' . l:pid
        \ . ' --name ' . fnamemodify(self.out(), ':t'))
  return get(l:xwin_ids, 0)
endfunction

" }}}1
function! s:viewer.xdo_send_keys(keys) dict abort " {{{1
  if !self.xdo_check() || empty(a:keys) || self.xwin_id <= 0 | return | endif

  call vimtex#jobs#run('xdotool key --window ' . self.xwin_id . ' ' . a:keys)
endfunction

" }}}1
function! s:viewer.xdo_focus_viewer() dict abort " {{{1
  if !self.xdo_check() || self.xwin_id <= 0 | return | endif

  call vimtex#jobs#run('xdotool windowactivate ' . self.xwin_id . ' --sync')
  call vimtex#jobs#run('xdotool windowraise ' . self.xwin_id)
endfunction

" }}}1
function! s:viewer.xdo_focus_vim() dict abort " {{{1
  if !executable('xdotool') | return | endif
  if !executable('pstree') | return | endif

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
      call vimtex#jobs#run('xdotool mousemove --window '. l:xwinids[0] . ' --polar 0 0')
      call vimtex#jobs#run('xdotool windowactivate ' . l:xwinids[0] . ' &')
      return l:xwinids[0]
      break
    endif
  endfor
endfunction

" }}}1
