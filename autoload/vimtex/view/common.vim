" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#common#apply_common_template(viewer) " {{{1
  call extend(a:viewer, deepcopy(s:common_template))
  call a:viewer.refresh_paths()
  return a:viewer
endfunction

" }}}1
function! vimtex#view#common#apply_xwin_template(class, viewer) " {{{1
  let a:viewer.class = a:class
  let a:viewer.xwin_id = 0
  call extend(a:viewer, deepcopy(s:xwin_template))
  call a:viewer.xwin_exists()
  return a:viewer
endfunction

" }}}1
function! vimtex#view#common#not_readable(output) " {{{1
  if !filereadable(a:output)
    call vimtex#echo#warning('viewer can not read PDF file!')
    return 1
  else
    return 0
  endif
endfunction

" }}}1

let s:common_template = {}

function! s:common_template.refresh_paths() dict " {{{1
  if g:vimtex_view_use_temp_files
    let self.out = b:vimtex.root . '/' . b:vimtex.name . '_vimtex.pdf'
  else
    let self.out = b:vimtex.out(1)
  endif

  let self.synctex = fnamemodify(self.out, ':r') . '.synctex.gz'
endfunction

" }}}1
function! s:common_template.copy_files() dict " {{{1
  if !g:vimtex_view_use_temp_files | return | endif

  "
  " Copy pdf file
  "
  if getftime(b:vimtex.out()) > getftime(self.out)
    call writefile(readfile(b:vimtex.out(), 'b'), self.out, 'b')
  endif

  "
  " Copy synctex file
  "
  let l:old = b:vimtex.ext('synctex.gz')
  if getftime(l:old) > getftime(self.synctex)
    call rename(l:old, self.synctex)
  endif
endfunction

" }}}1

let s:xwin_template = {}

function! s:xwin_template.view(file) dict " {{{1
  if empty(a:file)
    let outfile = self.out
  else
    let outfile = a:file
  endif
  if !filereadable(outfile)
    call vimtex#echo#warning('viewer can not read PDF file!')
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
function! s:xwin_template.xwin_get_id() dict " {{{1
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
    call vimtex#echo#warning(
          \ 'viewer can not find ' . self.class . ' window ID!')
    let self.xwin_id = 0
  else
    let self.xwin_id = xwin_ids[-1]
  endif

  return self.xwin_id
endfunction

" }}}1
function! s:xwin_template.xwin_exists() dict " {{{1
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
    let cmd = 'xdotool search --name ' . fnamemodify(self.out, ':t')
    let result = split(system(cmd), '\n')
    if len(result) > 0
      let self.xwin_id = result[-1]
    endif
  endif

  return (self.xwin_id > 0)
endfunction

" }}}1
function! s:xwin_template.xwin_send_keys(keys) dict " {{{1
  if !executable('xdotool') | return | endif

  if a:keys !=# ''
    let cmd  = 'xdotool key --window ' . self.xwin_id
    let cmd .= ' ' . a:keys
    silent call system(cmd)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
