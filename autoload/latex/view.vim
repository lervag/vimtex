" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latex#view#init(initialized) " {{{1
  call latex#util#set_default('g:latex_view_enabled', 1)
  if !g:latex_view_enabled | return | endif

  "
  " Set default options
  "
  call latex#util#set_default('g:latex_view_general_options', '')
  call latex#util#set_default_os_specific('g:latex_view_general_viewer',
        \ {
        \   'linux' : 'xdg-open',
        \   'mac'   : 'open',
        \ })
  call latex#util#set_default('g:latex_view_method', '')
  call latex#util#set_default('g:latex_view_mupdf_options', '')
  call latex#util#set_default('g:latex_view_mupdf_send_keys', '')
  call latex#util#set_default('g:latex_view_okular_options', '')
  call latex#util#set_default('g:latex_view_sumatrapdf_options', '')
  call latex#util#error_deprecated('g:latex_viewer')

  "
  " Set view functions
  "
  let data = g:latex#data[b:latex.id]
  if g:latex_view_method == 'mupdf'
    call s:init_mupdf()
    let data.view = function('latex#view#mupdf')
    let data.rsearch = function('latex#view#mupdf_rsearch')
  elseif g:latex_view_method == 'okular'
    call s:init_okular()
    let data.view = function('latex#view#okular')
  elseif g:latex_view_method == 'sumatrapdf'
    call s:init_sumatrapdf()
    let data.view = function('latex#view#sumatrapdf')
  else
    call s:init_general()
    let data.view = function('latex#view#general')
  endif

  "
  " Define commands
  "
  command! -buffer VimLatexView call g:latex#data[b:latex.id].view()
  if has_key(data, 'rsearch')
    command! -buffer -nargs=* VimLatexRSearch
          \ call g:latex#data[b:latex.id].rsearch()
  endif

  "
  " Define mappings
  "
  if g:latex_mappings_enabled
    nnoremap <silent><buffer> <localleader>lv
          \ :call g:latex#data[b:latex.id].view()<cr>

    if has_key(data, 'rsearch')
      nnoremap <silent><buffer> <localleader>lr
            \ :call g:latex#data[b:latex.id].rsearch()<cr>
    endif
  endif
endfunction

"}}}1
function! latex#view#general() " {{{1
  let exe = {}
  let exe.cmd = g:latex_view_general_viewer

  let outfile = g:latex#data[b:latex.id].out()
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif
  let exe.cmd .= ' ' . g:latex_view_general_options
  let exe.cmd .= ' ' . latex#util#fnameescape(outfile)

  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd
endfunction

"}}}1
function! latex#view#mupdf() "{{{1
  if !s:mupdf_exists_win()
    call s:mupdf_start()
  elseif s:mupdf_forward_search
    call s:mupdf_forward_search()
  endif
endfunction

" }}}1
function! latex#view#mupdf_poststart() "{{{1
  " First get the window id
  if g:latex#data[b:latex.id].mupdf_id == 0
    let mupdf_ids = []
    if executable('xdotool')
      let cmd  = 'xdotool search --class MuPDF'
      let mupdf_ids = systemlist(cmd)
    endif
    if len(mupdf_ids) == 0
      echomsg "Couldn't find MuPDF window ID!"
      let g:latex#data[b:latex.id].mupdf_id = 0
    else
      let g:latex#data[b:latex.id].mupdf_id = mupdf_ids[-1]
    endif
  endif

  " Next return focus to vim and send some keys to mupdf if desired
  if executable('xdotool')
    if g:latex_view_mupdf_send_keys != ''
      let cmd  = 'xdotool key --window ' . g:latex#data[b:latex.id].mupdf_id
      let cmd .= ' ' . g:latex_view_mupdf_send_keys
      call system(cmd)
    endif

    silent execute '!xdotool windowfocus ' . v:windowid
  endif

  " Finally do a forward search
  if s:mupdf_forward_search
    call s:mupdf_forward_search()
  endif
endfunction

"}}}1
function! latex#view#mupdf_rsearch() "{{{1
  if !s:mupdf_exists_win()
    echomsg "Can't search backwards: Is the PDF file open?"
    return
  endif

  let data = g:latex#data[b:latex.id]
  let outfile = data.out()
  let mupdf_id = data.mupdf_id
  let data.mupdf_rsearch = {}

  " Get page number
  let cmd  = "xdotool getwindowname " . mupdf_id
  let cmd .= " | sed 's:.* - \\([0-9]*\\)/.*:\\1:'"
  let cmd .= " | tr -d '\n'"
  let mupdf_page = system(cmd)
  let data.mupdf_rsearch.page = mupdf_page
  let data.mupdf_rsearch.page_cmd = cmd
  if mupdf_page <= 0 | return | endif

  " Get file
  let cmd  = "synctex edit "
  let cmd .= "-o \"" . mupdf_page . ":288:108:" . outfile . "\""
  let cmd .= "| grep 'Input:' | sed 's/Input://' "
  let cmd .= "| head -n1 | tr -d '\n' 2>/dev/null"
  let mupdf_infile = system(cmd)
  let data.mupdf_rsearch.infile = mupdf_infile
  let data.mupdf_rsearch.infile_cmd = cmd

  " Get line
  let cmd  = "synctex edit "
  let cmd .= "-o \"" . mupdf_page . ":288:108:" . outfile . "\""
  let cmd .= "| grep -m1 'Line:' | sed 's/Line://' "
  let cmd .= "| head -n1 | tr -d '\n'"
  let line = system(cmd)
  let data.mupdf_rsearch.line = line
  let data.mupdf_rsearch.line_cmd = cmd

  " Go to file and line
  silent exec "edit " . mupdf_infile
  if line > 0
    silent exec ":" . line
    " Unfold, move to top line to correspond to top pdf line, and go to end of
    " line in case the corresponding pdf line begins on previous pdf page.
    normal! zvztg_
  endif
endfunction

" }}}1
function! latex#view#sumatrapdf() "{{{1
  let outfile = g:latex#data[b:latex.id].out()
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  let exe = {}
  let exe.cmd = 'SumatraPDF ' . g:latex_view_sumatrapdf_options
  let exe.cmd .= ' -forward-search ' . latex#util#fnameescape(expand('%:p'))
  let exe.cmd .= ' ' . line('.')
  let exe.cmd .= ' ' . latex#util#fnameescape(outfile)

  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd
endfunction

" }}}1
function! latex#view#okular() "{{{1
  let outfile = g:latex#data[b:latex.id].out()
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  let exe = {}
  let exe.cmd = 'okular ' . g:latex_view_okular_options
  let exe.cmd .= ' --unique ' . latex#util#fnameescape(outfile)
  let exe.cmd .= '\#src:' . line('.') . latex#util#fnameescape(expand('%:p'))

  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd
endfunction

" }}}1

function! s:init_general() "{{{1
  if !executable(g:latex_view_general_viewer)
    echoerr "General viewer is not available!"
    echoerr "g:latex_view_general_viewer = "
          \ . g:latex_view_general_viewer
  endif
endfunction

" }}}1
function! s:init_mupdf() "{{{1
  if !executable('mupdf')
    echoerr "MuPDF is not available!"
  endif

  " Check if forward search is possible
  let s:mupdf_forward_search = executable('synctex') && executable('xdotool')

  " Initialize mupdf_id
  if !has_key(g:latex#data[b:latex.id], 'mupdf_id')
    let g:latex#data[b:latex.id].mupdf_id = 0
  endif
endfunction

" }}}1
function! s:init_sumatrapdf() "{{{1
  if !executable('SumatraPDF')
    echoerr "SumatraPDF is not available!"
  endif
endfunction

"}}}1
function! s:init_okular() "{{{1
  if !executable('okular')
    echoerr "okular is not available!"
  endif
endfunction

"}}}1

function! s:mupdf_exists_win() "{{{1
  if executable('xdotool')
    let cmd  = 'xdotool search --class MuPDF'
    let mupdf_ids = systemlist(cmd)
    for id in mupdf_ids
      if id == g:latex#data[b:latex.id].mupdf_id | return 1 | endif
    endfor
  endif

  return 0
endfunction

"}}}1
function! s:mupdf_forward_search() "{{{1
  let outfile = g:latex#data[b:latex.id].out()

  let l:cmd = "synctex view -i "
        \ . (line(".") + 1) . ":"
        \ . (col(".") + 1) . ":"
        \ . latex#util#fnameescape(expand("%:p"))
        \ . " -o " . latex#util#fnameescape(outfile)
        \ . " | grep -m1 'Page:' | sed 's/Page://' | tr -d '\n'"
  let l:page = system(l:cmd)
  let g:latex#data[b:latex.id].cmds.view_mupdf_synctex = l:cmd
  let g:latex#data[b:latex.id].cmds.view_mupdf_synctex_page = l:page

  if l:page > 0
    let exe = {}
    let exe.cmd  = 'xdotool'
    let exe.cmd .= ' type --window ' . g:latex#data[b:latex.id].mupdf_id
    let exe.cmd .= ' "' . l:page . 'g"'
    call latex#util#execute(exe)
    let g:latex#data[b:latex.id].cmds.view_mupdf_xdotool = exe.cmd
  endif
endfunction

"}}}1
function! s:mupdf_start() "{{{1
  let outfile = g:latex#data[b:latex.id].out()
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  " Start MuPDF
  let exe = {}
  let exe.cmd  = 'mupdf ' .  g:latex_view_mupdf_options
  let exe.cmd .= ' ' . latex#util#fnameescape(outfile)
  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd

  call latex#view#mupdf_poststart()
endfunction

"}}}1

" vim: fdm=marker sw=2
