" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#common#apply_common_template(viewer) abort " {{{1
  return extend(a:viewer, deepcopy(s:common_template))
endfunction

" }}}1
function! vimtex#view#common#apply_xwin_template(class, viewer) abort " {{{1
  let a:viewer.class = a:class
  let a:viewer.xwin_id = 0
  call extend(a:viewer, deepcopy(s:xwin_template))
  return a:viewer
endfunction

" }}}1
function! vimtex#view#common#not_readable(output) abort " {{{1
  if !filereadable(a:output)
    call vimtex#log#warning('Viewer cannot read PDF file!', a:output)
    return 1
  else
    return 0
  endif
endfunction

" }}}1

let s:common_template = {}

function! s:common_template.out() dict abort " {{{1
  return g:vimtex_view_use_temp_files
        \ ? b:vimtex.root . '/' . b:vimtex.name . '_vimtex.pdf'
        \ : b:vimtex.out(1)
endfunction

" }}}1
function! s:common_template.synctex() dict abort " {{{1
  return fnamemodify(self.out(), ':r') . '.synctex.gz'
endfunction

" }}}1
function! s:common_template.copy_files() dict abort " {{{1
  if !g:vimtex_view_use_temp_files | return | endif

  "
  " Copy pdf file
  "
  let l:out = self.out()
  if getftime(b:vimtex.out()) > getftime(l:out)
    call writefile(readfile(b:vimtex.out(), 'b'), l:out, 'b')
  endif

  "
  " Copy synctex file
  "
  let l:old = b:vimtex.ext('synctex.gz')
  let l:new = self.synctex()
  if getftime(l:old) > getftime(l:new)
    call rename(l:old, l:new)
  endif
endfunction

" }}}1
function! s:common_template.pprint_items() abort dict " {{{1
  let l:list = []

  if has_key(self, 'xwin_id')
    call add(l:list, ['xwin id', self.xwin_id])
  endif

  if has_key(self, 'process')
    call add(l:list, ['process', self.process])
  endif

  for l:key in filter(keys(self), 'v:val =~# ''^cmd_''')
    call add(l:list, [l:key, self[l:key]])
  endfor

  return l:list
endfunction

" }}}1

let s:xwin_template = {}

function! s:xwin_template.view(file) dict abort " {{{1
  if empty(a:file)
    let outfile = self.out()
  else
    let outfile = a:file
  endif
  if vimtex#view#common#not_readable(outfile)
    return
  endif

  if self.xwin_exists()
    call self.forward_search(outfile)
  else
    if g:vimtex_view_use_temp_files
      call self.copy_files()
    endif
    call self.start(outfile)
  endif

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:xwin_template.xwin_get_id() dict abort " {{{1
  if !executable('xdotool') | return 0 | endif
  if self.xwin_id > 0 | return self.xwin_id | endif

  " Allow some time for the viewer to start properly
  sleep 500m

  "
  " Get the window ID
  "
  let cmd = 'xdotool search --class ' . self.class
  let xwin_ids = split(system(cmd), '\n')
  if len(xwin_ids) == 0
    call vimtex#log#warning('Viewer cannot find ' . self.class . ' window ID!')
    let self.xwin_id = 0
  else
    let self.xwin_id = xwin_ids[-1]
  endif

  return self.xwin_id
endfunction

" }}}1
function! s:xwin_template.xwin_exists() dict abort " {{{1
  if !executable('xdotool') | return 0 | endif

  "
  " If xwin_id is already set, check if it still exists
  "
  if self.xwin_id > 0
    let cmd = 'xdotool search --class ' . self.class
    if index(split(system(cmd), '\n'), self.xwin_id) < 0
      let self.xwin_id = 0
    endif
  endif

  "
  " If xwin_id is unset, check if matching viewer windows exist
  "
  if self.xwin_id == 0
    if has_key(self, 'get_pid')
      let cmd = 'xdotool search'
            \ . ' --all --pid ' . self.get_pid()
            \ . ' --name ' . fnamemodify(self.out(), ':t')
      let self.xwin_id = get(split(system(cmd), '\n'), 0)
    else
      let cmd = 'xdotool search --name ' . fnamemodify(self.out(), ':t')
      let ids = split(system(cmd), '\n')
      let ids_already_used = filter(map(deepcopy(vimtex#state#list_all()),
            \ "get(get(v:val, 'viewer', {}), 'xwin_id')"), 'v:val > 0')
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
function! s:xwin_template.xwin_send_keys(keys) dict abort " {{{1
  if a:keys ==# '' || !executable('xdotool') || self.xwin_id <= 0
    return
  endif

  let cmd  = 'xdotool key --window ' . self.xwin_id
  let cmd .= ' ' . a:keys
  silent call system(cmd)
endfunction

" }}}1
