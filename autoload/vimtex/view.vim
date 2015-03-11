" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#init(initialized) " {{{1
  call vimtex#util#set_default('g:vimtex_view_enabled', 1)
  if !g:vimtex_view_enabled | return | endif

  let data = g:vimtex#data[b:vimtex.id]

  " Initialize viewer options
  for viewer in s:viewers
    call vimtex#util#set_default('g:vimtex_view_' . viewer . '_options', '')
  endfor

  " Initialize other options
  call vimtex#util#set_default_os_specific('g:vimtex_view_general_viewer',
        \ {
        \   'linux' : 'xdg-open',
        \   'mac'   : 'open',
        \ })
  call vimtex#util#set_default('g:vimtex_view_method', 'general')
  call vimtex#util#set_default('g:vimtex_view_mupdf_send_keys', '')
  call vimtex#util#error_deprecated('g:vimtex_viewer')

  let viewer = 's:' . g:vimtex_view_method
  if !exists(viewer)
    echoerr 'vimtex viewer ' . g:vimtex_view_method . ' does not exist!'
    return
  endif

  execute 'let data.viewer = ' . viewer
  call data.viewer.init()

  " Define commands
  command! -buffer VimtexView call g:vimtex#data[b:vimtex.id].viewer.view()
  if has_key(data.viewer, 'reverse_search')
    command! -buffer -nargs=* VimtexRSearch
          \ call g:vimtex#data[b:vimtex.id].viewer.reverse_search()
  endif

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-view)
        \ :call g:vimtex#data[b:vimtex.id].viewer.view()<cr>
  if has_key(data.viewer, 'reverse_search')
    nnoremap <buffer> <plug>(vimtex-reverse-search)
          \ :call g:vimtex#data[b:vimtex.id].viewer.reverse_search()<cr>
  endif
endfunction

" }}}1

let s:viewers = [
      \ 'general',
      \ 'mupdf',
      \ 'okular',
      \ 'qpdfview',
      \ 'sumatrapdf',
      \ 'zathura',
      \ ]
for viewer in s:viewers
  execute 'let s:' . viewer . ' = {}'
endfor

" {{{1 General
function! s:general.init() dict " {{{2
  if !executable(g:vimtex_view_general_viewer)
    echoerr "vimtex viewer is not executable!"
    echoerr "g:vimtex_view_general_viewer = "
          \ . g:vimtex_view_general_viewer
  endif
endfunction

" }}}2
function! s:general.view() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd = g:vimtex_view_general_viewer
  let exe.cmd .= ' ' . g:vimtex_view_general_options
  let exe.cmd .= ' ' . vimtex#util#fnameescape(outfile)
  call vimtex#util#execute(exe)
  let self.cmd_view = exe.cmd
endfunction

" }}}2

" {{{1 MuPDF
function! s:mupdf.init() dict " {{{2
  if !executable('mupdf')
    echoerr "vimtex viewer MuPDF is not executable!"
  endif

  if !executable('xdotool')
    call vimtex#echo#warning('vimtex viewer MuPDF requires xdotool!')
  endif

  let self.class = 'MuPDF'
  let self.xwin_id = 0
  let self.xwin_exists = function("s:xwin_exists")
  let self.xwin_get_id = function("s:xwin_get_id")
  let self.xwin_send_keys = function("s:xwin_send_keys")
  let self.focus_vim = function("s:focus_vim")
  let self.focus_viewer = function("s:focus_viewer")
endfunction

" }}}2
function! s:mupdf.view() dict " {{{2
  if !self.xwin_exists()
    call self.start()
  else
    call self.forward_search()
  endif
endfunction

" }}}2
function! s:mupdf.start() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd  = 'mupdf ' .  g:vimtex_view_mupdf_options
  let exe.cmd .= ' ' . vimtex#util#fnameescape(outfile)
  call vimtex#util#execute(exe)
  let self.cmd_start = exe.cmd

  call self.xwin_get_id()
  call self.xwin_send_keys(g:vimtex_view_mupdf_send_keys)
  call self.forward_search()
endfunction

" }}}2
function! s:mupdf.forward_search() dict " {{{2
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let self.cmd_synctex_view = "synctex view -i "
        \ . (line(".") + 1) . ":"
        \ . (col(".") + 1) . ":"
        \ . vimtex#util#fnameescape(expand("%:p"))
        \ . " -o " . vimtex#util#fnameescape(outfile)
        \ . " | grep -m1 'Page:' | sed 's/Page://' | tr -d '\n'"
  let self.page = system(self.cmd_synctex_view)

  if self.page > 0
    let exe = {}
    let exe.cmd  = 'xdotool'
    let exe.cmd .= ' type --window ' . self.xwin_id
    let exe.cmd .= ' "' . self.page . 'g"'
    call vimtex#util#execute(exe)
    let self.cmd_forward_search = exe.cmd
  endif

  call self.focus_viewer()
endfunction

" }}}2
function! s:mupdf.reverse_search() dict " {{{2
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  if !self.xwin_exists()
    call vimtex#echo#warning(
          \ 'vimtex reverse search failed (is MuPDF open?)')
    return
  endif

  " Get page number
  let self.cmd_getpage  = "xdotool getwindowname " . self.xwin_id
  let self.cmd_getpage .= " | sed 's:.* - \\([0-9]*\\)/.*:\\1:'"
  let self.cmd_getpage .= " | tr -d '\n'"
  let self.page = system(self.cmd_getpage)
  if self.page <= 0 | return | endif

  " Get file
  let self.cmd_getfile  = "synctex edit "
  let self.cmd_getfile .= "-o \"" . self.page . ":288:108:" . outfile . "\""
  let self.cmd_getfile .= "| grep 'Input:' | sed 's/Input://' "
  let self.cmd_getfile .= "| head -n1 | tr -d '\n' 2>/dev/null"
  let self.file = system(self.cmd_getfile)

  " Get line
  let self.cmd_getline  = "synctex edit "
  let self.cmd_getline .= "-o \"" . self.page . ":288:108:" . outfile . "\""
  let self.cmd_getline .= "| grep -m1 'Line:' | sed 's/Line://' "
  let self.cmd_getline .= "| head -n1 | tr -d '\n'"
  let self.line = system(self.cmd_getline)

  " Go to file and line
  silent exec "edit " . self.file
  if self.line > 0
    silent exec ":" . self.line
    " Unfold, move to top line to correspond to top pdf line, and go to end of
    " line in case the corresponding pdf line begins on previous pdf page.
    normal! zvztg_
  endif
endfunction

" }}}2
function! s:mupdf.latexmk_callback() dict " {{{2
  " Try to get xwin ID
  if !self.xwin_exists()
    if self.xwin_get_id()
      call self.xwin_send_keys(g:vimtex_view_mupdf_send_keys)
      call self.forward_search()
      call self.focus_vim()
    endif
  endif
endfunction

" }}}2
function! s:mupdf.latexmk_append_argument() dict " {{{2
  let cmd  = vimtex#latexmk#add_option('new_viewer_always', '0')
  let cmd .= vimtex#latexmk#add_option('pdf_update_method', '2')
  let cmd .= vimtex#latexmk#add_option('pdf_update_signal', 'SIGHUP')
  let cmd .= vimtex#latexmk#add_option('pdf_previewer',
        \ 'start mupdf ' .  g:vimtex_view_mupdf_options)
  return cmd
endfunction

" }}}2

" {{{1 Okular
function! s:okular.init() dict " {{{2
  if !executable('okular')
    echoerr "vimtex viewer Okular is not executable!"
  endif
endfunction

" }}}2
function! s:okular.view() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd = 'okular ' . g:vimtex_view_okular_options
  let exe.cmd .= ' --unique ' . vimtex#util#fnameescape(outfile)
  let exe.cmd .= '\#src:' . line('.') . vimtex#util#fnameescape(expand('%:p'))
  call vimtex#util#execute(exe)
  let self.cmd_view = exe.cmd
endfunction

" }}}2

" {{{1 qpdfview
function! s:qpdfview.init() dict " {{{2
  if !executable('qpdfview')
    echoerr "vimtex viewer qpdfview is not executable!"
  endif
endfunction

" }}}2
function! s:qpdfview.view() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd = 'qpdfview ' . g:vimtex_view_qpdfview_options
  let exe.cmd .= ' --unique ' . vimtex#util#fnameescape(outfile)
  let exe.cmd .= '\#src:' . vimtex#util#fnameescape(expand('%:p'))
  let exe.cmd .= ':' . line('.')
  let exe.cmd .= ':' . col('.')
  call vimtex#util#execute(exe)
  let self.cmd_view = exe.cmd
endfunction

" }}}2

" {{{1 SumatraPDF
function! s:sumatrapdf.init() dict " {{{2
  if !executable('SumatraPDF')
    echoerr "vimtex viewer SumatraPDF is not executable!"
  endif
endfunction

" }}}2
function! s:sumatrapdf.view() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd = 'SumatraPDF ' . g:vimtex_view_sumatrapdf_options
  let exe.cmd .= ' -forward-search ' . vimtex#util#fnameescape(expand('%:p'))
  let exe.cmd .= ' ' . line('.')
  let exe.cmd .= ' ' . vimtex#util#fnameescape(outfile)
  call vimtex#util#execute(exe)
  let self.cmd_view = exe.cmd
endfunction

" }}}2

" {{{1 Zathura
function! s:zathura.init() dict " {{{2
  if !executable('zathura')
    echoerr "vimtex viewer Zathura is not executable!"
  endif

  if !executable('xdotool')
    call vimtex#echo#warning('vimtex viewer Zathura requires xdotool!')
  endif

  let self.class = 'Zathura'
  let self.xwin_id = 0
  let self.xwin_get_id = function("s:xwin_get_id")
  let self.xwin_exists = function("s:xwin_exists")
  let self.focus_vim = function("s:focus_vim")
endfunction

" }}}2
function! s:zathura.view() dict " {{{2
  if !self.xwin_exists()
    call self.start()
  else
    call self.forward_search()
  endif
endfunction

" }}}2
function! s:zathura.start() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd  = 'zathura ' .  g:vimtex_view_zathura_options
  let exe.cmd .= ' -x "' . exepath(v:progname)
        \ . ' --servername ' . v:servername
        \ . ' --remote +\%{line} \%{input}"'
  let exe.cmd .= ' ' . vimtex#util#fnameescape(outfile)
  call vimtex#util#execute(exe)
  let self.cmd_start = exe.cmd

  call self.xwin_get_id()
  call self.forward_search()
endfunction

" }}}2
function! s:zathura.forward_search() dict " {{{2
  let outfile = g:vimtex#data[b:vimtex.id].out()
  if s:output_not_readable(outfile) | return | endif

  let exe = {}
  let exe.cmd  = 'zathura --synctex-forward '
  let exe.cmd .= line(".")
  let exe.cmd .= ':' . col('.')
  let exe.cmd .= ':' . vimtex#util#fnameescape(expand('%:p'))
  let exe.cmd .= ' ' . vimtex#util#fnameescape(outfile)
  call vimtex#util#execute(exe)
  let self.cmd_forward_search = exe.cmd
endfunction

" }}}2
function! s:zathura.latexmk_callback() dict " {{{2
  if !self.xwin_exists()
    if self.xwin_get_id()
      call self.forward_search()
      call self.focus_vim()
    endif
  endif
endfunction

" }}}2
function! s:zathura.latexmk_append_argument() dict " {{{2
  let cmd  = vimtex#latexmk#add_option('new_viewer_always', '0')
  let cmd .= vimtex#latexmk#add_option('pdf_previewer',
        \ 'start zathura ' . g:vimtex_view_zathura_options
        \ . ' -x \"' . exepath(v:progname)
        \ . ' --servername ' . v:servername
        \ . ' --remote +\%{line} \%{input}\" \%S')

  return cmd
endfunction

" }}}2
" }}}1

" {{{1 Common functionality

function! s:output_not_readable(output) " {{{2
  if !filereadable(a:output)
    call vimtex#echo#warning('vimtex viewer can not read PDF file!')
    return 1
  else
    return 0
  endif
endfunction

" }}}2
function! s:xwin_get_id() dict " {{{2
  if !executable('xdotool') | return 0 | endif
  if self.xwin_id > 0 | return 0 | endif
  sleep 500m

  let cmd = 'xdotool search --class ' . self.class
  let xwin_ids = systemlist(cmd)
  if len(xwin_ids) == 0
    call vimtex#echo#warning(
          \ 'vimtex viewer can not find ' . self.class . ' window ID!')
    let self.xwin_id = 0
  else
    let self.xwin_id = xwin_ids[-1]
  endif

  return self.xwin_id
endfunction

" }}}2
function! s:xwin_exists() dict " {{{2
  if !executable('xdotool') | return 0 | endif

  let cmd = 'xdotool search --class ' . self.class
  if index(systemlist(cmd), self.xwin_id) >= 0
    return 1
  endif

  if self.xwin_id > 0
    let self.xwin_id = 0
  endif

  return 0
endfunction

" }}}2
function! s:xwin_send_keys(keys) dict " {{{2
  if !executable('xdotool') | return | endif

  if a:keys != ''
    let cmd  = 'xdotool key --window ' . self.xwin_id
    let cmd .= ' ' . a:keys
    call system(cmd)
  endif
endfunction

" }}}2
function! s:focus_viewer() dict " {{{2
  if !executable('xdotool') | return | endif

  if self.xwin_exists()
    silent execute '!xdotool windowfocus ' . self.xwin_id
    redraw!
  endif
endfunction

function! s:focus_vim() dict " {{{2
  if !executable('xdotool') | return | endif

  silent execute '!xdotool windowfocus ' . v:windowid
  redraw!
endfunction

" }}}2

" }}}1

" vim: fdm=marker sw=2
