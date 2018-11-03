" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#mupdf#new() abort " {{{1
  " Check if the viewer is executable
  if !executable('mupdf')
    call vimtex#log#error(
          \ 'MuPDF is not executable!',
          \ '- vimtex viewer will not work!')
    return {}
  endif

  " Use the xwin template
  return vimtex#view#common#apply_xwin_template('MuPDF',
        \ vimtex#view#common#apply_common_template(deepcopy(s:mupdf)))
endfunction

" }}}1

let s:mupdf = {
      \ 'name': 'MuPDF',
      \}

function! s:mupdf.start(outfile) dict abort " {{{1
  let l:cmd = 'mupdf ' .  g:vimtex_view_mupdf_options
        \ . ' ' . vimtex#util#shellescape(a:outfile)
  let self.process = vimtex#process#start(l:cmd)

  call self.xwin_get_id()
  call self.xwin_send_keys(g:vimtex_view_mupdf_send_keys)

  if g:vimtex_view_forward_search_on_start
    call self.forward_search(a:outfile)
  endif
endfunction

" }}}1
function! s:mupdf.forward_search(outfile) dict abort " {{{1
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let self.cmd_synctex_view = 'synctex view -i '
        \ . (line('.') + 1) . ':'
        \ . (col('.') + 1) . ':'
        \ . vimtex#util#shellescape(expand('%:p'))
        \ . ' -o ' . vimtex#util#shellescape(a:outfile)
        \ . " | grep -m1 'Page:' | sed 's/Page://' | tr -d '\n'"
  let self.page = system(self.cmd_synctex_view)

  if self.page > 0
    let l:cmd = 'xdotool'
          \ . ' type --window ' . self.xwin_id
          \ . ' "' . self.page . 'g"'
    call vimtex#process#run(l:cmd)
    let self.cmd_forward_search = l:cmd
  endif

  call self.focus_viewer()
endfunction

" }}}1
function! s:mupdf.reverse_search() dict abort " {{{1
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let outfile = self.out()
  if vimtex#view#common#not_readable(outfile) | return | endif

  if !self.xwin_exists()
    call vimtex#log#warning('Reverse search failed (is MuPDF open?)')
    return
  endif

  " Get page number
  let self.cmd_getpage  = 'xdotool getwindowname ' . self.xwin_id
  let self.cmd_getpage .= " | sed 's:.* - \\([0-9]*\\)/.*:\\1:'"
  let self.cmd_getpage .= " | tr -d '\n'"
  let self.page = system(self.cmd_getpage)
  if self.page <= 0 | return | endif

  " Get file
  let self.cmd_getfile  = 'synctex edit '
  let self.cmd_getfile .= "-o \"" . self.page . ':288:108:' . outfile . "\""
  let self.cmd_getfile .= "| grep 'Input:' | sed 's/Input://' "
  let self.cmd_getfile .= "| head -n1 | tr -d '\n' 2>/dev/null"
  let self.file = system(self.cmd_getfile)

  " Get line
  let self.cmd_getline  = 'synctex edit '
  let self.cmd_getline .= "-o \"" . self.page . ':288:108:' . outfile . "\""
  let self.cmd_getline .= "| grep -m1 'Line:' | sed 's/Line://' "
  let self.cmd_getline .= "| head -n1 | tr -d '\n'"
  let self.line = system(self.cmd_getline)

  " Go to file and line
  silent exec 'edit ' . fnameescape(self.file)
  if self.line > 0
    silent exec ':' . self.line
    " Unfold, move to top line to correspond to top pdf line, and go to end of
    " line in case the corresponding pdf line begins on previous pdf page.
    normal! zvztg_
  endif
endfunction

" }}}1
function! s:mupdf.compiler_callback(status) dict abort " {{{1
  if !a:status && g:vimtex_view_use_temp_files < 2
    return
  endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

  if !filereadable(self.out()) | return | endif

  if g:vimtex_view_automatic
    "
    " Search for existing window created by latexmk
    "   It may be necessary to wait some time before it is opened and
    "   recognized. Sometimes it is very quick, other times it may take
    "   a second. This way, we don't block longer than necessary.
    "
    if !has_key(self, 'started_through_callback')
      for l:dummy in range(30)
        sleep 50m
        if self.xwin_exists() | break | endif
      endfor
    endif

    if !self.xwin_exists() && !has_key(self, 'started_through_callback')
      call self.start(self.out())
      let self.started_through_callback = 1
    endif
  endif

  if g:vimtex_view_use_temp_files || get(b:vimtex.compiler, 'callback')
    call self.xwin_send_keys('r')
  endif

  if has_key(self, 'hook_callback')
    call self.hook_callback()
  endif
endfunction

" }}}1
function! s:mupdf.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files
    let cmd = ' -view=none'
  else
    let cmd  = vimtex#compiler#latexmk#wrap_option('new_viewer_always', '0')
    let cmd .= vimtex#compiler#latexmk#wrap_option('pdf_update_method', '2')
    let cmd .= vimtex#compiler#latexmk#wrap_option('pdf_update_signal', 'SIGHUP')
    let cmd .= vimtex#compiler#latexmk#wrap_option('pdf_previewer',
          \ 'mupdf ' .  g:vimtex_view_mupdf_options)
  endif

  return cmd
endfunction

" }}}1
function! s:mupdf.focus_viewer() dict abort " {{{1
  if !executable('xdotool') | return | endif

  if self.xwin_id > 0
    silent call system('xdotool windowactivate ' . self.xwin_id . ' --sync')
    silent call system('xdotool windowraise ' . self.xwin_id)
  endif
endfunction

" }}}1
function! s:mupdf.focus_vim() dict abort " {{{1
  if !executable('xdotool') | return | endif

  silent call system('xdotool windowactivate ' . v:windowid . ' --sync')
  silent call system('xdotool windowraise ' . v:windowid)
endfunction

" }}}1
