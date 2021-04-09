" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#_template_xwin#apply(viewer) abort " {{{1
  augroup vimtex_view_xwin
    autocmd!
    autocmd User VimtexEventCompileSuccess
            \ call vimtex#view#_template_xwin#compiler_callback()
  augroup END

  return extend(vimtex#view#_template#apply(a:viewer), deepcopy(s:template))
endfunction

" }}}1
function! vimtex#view#_template_xwin#compiler_callback() abort " {{{1
  if !exists('b:vimtex.viewer') | return | endif
  let self = b:vimtex.viewer
  if !filereadable(self.out()) | return | endif

  if (g:vimtex_view_automatic
        \ && g:vimtex_view_automatic_xwin)
        \ && !has_key(self, 'started_through_callback')
    "
    " Search for existing window created by latexmk
    " Note: It may be necessary to wait some time before it is opened and
    "       recognized. Sometimes it is very quick, other times it may take
    "       a second. This way, we don't block longer than necessary.
    "
    for l:dummy in range(30)
      let l:xwin_exists = self.xwin_exists()
      if l:xwin_exists | break | endif
      sleep 50m
    endfor

    if !l:xwin_exists
      call self.start(self.out())
      let self.started_through_callback = 1
    endif
  endif

  if has_key(self, 'compiler_callback')
    call self.compiler_callback()
  endif
endfunction

" }}}1


let s:template = {
      \ 'xwin_id': 0,
      \}

function! s:template.view(file) dict abort " {{{1
  if empty(a:file)
    let outfile = self.out()
  else
    let outfile = a:file
  endif
  if vimtex#view#not_readable(outfile) | return | endif

  if self.xwin_exists()
    call self.forward_search(outfile)
  else
    if g:vimtex_view_use_temp_files
      call self.copy_files()
    endif
    call self.start(outfile)
  endif

  if exists('#User#VimtexEventView')
    doautocmd <nomodeline> User VimtexEventView
  endif
endfunction

" }}}1
function! s:template.xwin_get_id() dict abort " {{{1
  if !executable('xdotool') | return 0 | endif
  if self.xwin_id > 0 | return self.xwin_id | endif

  " Allow some time for the viewer to start properly
  sleep 500m

  "
  " Get the window ID
  "
  let cmd = 'xdotool search --class ' . self.name
  let xwin_ids = split(system(cmd), '\n')
  if len(xwin_ids) == 0
    call vimtex#log#warning('Viewer cannot find ' . self.name . ' window ID!')
    let self.xwin_id = 0
  else
    let self.xwin_id = xwin_ids[-1]
  endif

  return self.xwin_id
endfunction

" }}}1
function! s:template.xwin_exists() dict abort " {{{1
  if !executable('xdotool') | return 0 | endif

  "
  " If xwin_id is already set, check if it still exists
  "
  if self.xwin_id > 0
    let cmd = 'xdotool search --class ' . self.name
    if index(split(system(cmd), '\n'), self.xwin_id) < 0
      let self.xwin_id = 0
    endif
  endif

  "
  " If xwin_id is unset, check if matching viewer windows exist
  "
  if self.xwin_id == 0
    let l:pid = has_key(self, 'get_pid') ? self.get_pid() : 0
    if l:pid > 0
      let cmd = 'xdotool search'
            \ . ' --all --pid ' . l:pid
            \ . ' --name ' . fnamemodify(self.out(), ':t')
      let self.xwin_id = get(split(system(cmd), '\n'), 0)
    else
      let cmd = 'xdotool search --name ' . fnamemodify(self.out(), ':t')
      let ids = split(system(cmd), '\n')
      let ids_already_used = filter(map(
            \   deepcopy(vimtex#state#list_all()),
            \   {_, x -> get(get(x, 'viewer', {}), 'xwin_id')}),
            \ 'v:val > 0')
      for id in ids
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
function! s:template.xwin_send_keys(keys) dict abort " {{{1
  if a:keys ==# '' || !executable('xdotool') || self.xwin_id <= 0
    return
  endif

  let cmd  = 'xdotool key --window ' . self.xwin_id
  let cmd .= ' ' . a:keys
  silent call system(cmd)
endfunction

" }}}1
function! s:template.move(arg) abort " {{{1
  if !executable('xdotool') || self.xwin_id <= 0
    return
  endif

  let l:cmd = 'xdotool windowmove ' . self.xwin_get_id() . ' ' . a:arg
  silent call system(l:cmd)
endfunction

" }}}1
function! s:template.resize(arg) abort " {{{1
  if !executable('xdotool') || self.xwin_id <= 0
    return
  endif

  let l:cmd = 'xdotool windowsize ' . self.xwin_get_id()  . ' ' . a:arg
  silent call system(l:cmd)
endfunction

" }}}1
function! s:template.focus_viewer() dict abort " {{{1
  if !executable('xdotool') | return | endif

  if self.xwin_id > 0
    silent call system('xdotool windowactivate ' . self.xwin_id . ' --sync')
    silent call system('xdotool windowraise ' . self.xwin_id)
  endif
endfunction

" }}}1
function! s:template.focus_vim() dict abort " {{{1
  if !executable('xdotool') | return | endif

  silent call system('xdotool windowactivate ' . v:windowid . ' --sync')
  silent call system('xdotool windowraise ' . v:windowid)
endfunction

" }}}1
