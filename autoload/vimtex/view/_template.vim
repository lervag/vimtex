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
  " Copy pdf and synctex files if we use temporary files
  if g:vimtex_view_use_temp_files
    let l:out = b:vimtex.root . '/' . b:vimtex.name . '_vimtex.pdf'

    if getftime(b:vimtex.out()) > getftime(l:out)
      call writefile(readfile(b:vimtex.out(), 'b'), l:out, 'b')
    endif

    let l:old = b:vimtex.ext('synctex.gz')
    let l:new = fnamemodify(l:out, ':r') . '.synctex.gz'
    if getftime(l:old) > getftime(l:new)
      call rename(l:old, l:new)
    endif
  else
    let l:out = b:vimtex.out(1)
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

  if self.xwin_id <= 0
    " Allow some time for the viewer to start properly
    sleep 500m

    let l:xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
    if len(l:xwin_ids) == 0
      call vimtex#log#warning('Viewer cannot find ' . self.name . ' window ID!')
      let self.xwin_id = 0
    else
      let self.xwin_id = l:xwin_ids[-1]
    endif
  endif

  return self.xwin_id
endfunction

" }}}1
function! s:viewer.xdo_exists() dict abort " {{{1
  if !self.xdo_check() | return v:false | endif

  " If xwin_id is already set, check if it still exists
  if self.xwin_id > 0
    let xwin_ids = vimtex#jobs#capture('xdotool search --class ' . self.name)
    if index(xwin_ids, self.xwin_id) < 0
      let self.xwin_id = 0
    endif
  endif

  " If xwin_id is unset, check if matching viewer windows exist
  if self.xwin_id == 0
    let l:pid = has_key(self, 'get_pid') ? self.get_pid() : 0
    if l:pid > 0
      let xwin_ids = vimtex#jobs#capture(
            \   'xdotool search --all --pid ' . l:pid
            \ . ' --name ' . fnamemodify(self.out(), ':t'))
      let self.xwin_id = get(xwin_ids, 0)
    else
      let xwin_ids = vimtex#jobs#capture(
            \ 'xdotool search --name ' . fnamemodify(self.out(), ':t'))
      let ids_already_used = filter(map(
            \   deepcopy(vimtex#state#list_all()),
            \   {_, x -> get(get(x, 'viewer', {}), 'xwin_id')}),
            \ 'v:val > 0')
      for id in xwin_ids
        if index(ids_already_used, id) < 0
          let self.xwin_id = id
          break
        endif
      endfor
    endif
  endif

  return self.xwin_id > 0
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
      call vimtex#jobs#run('xdotool windowactivate ' . l:xwinids[0] . ' &')
      call feedkeys("\<c-l>", 'tn')
      return l:xwinids[0]
      break
    endif
  endfor
endfunction

" }}}1
