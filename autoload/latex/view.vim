" LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! latex#view#init(initialized) " {{{1
  if !g:latex_view_enabled | return | endif

  call latex#util#error_deprecated('g:latex_viewer')
  call latex#util#set_default('g:latex_view_method', '')
  call latex#util#set_default('g:latex_view_mupdf_options', '')
  call latex#util#set_default('g:latex_view_sumatrapdf_options', '')
  call latex#util#set_default('g:latex_view_general_viewer', 'xdg-open')
  call latex#util#set_default('g:latex_view_general_options', '')

  let data = g:latex#data[b:latex.id]
  if g:latex_view_method == 'mupdf'
    call s:check_method_mupdf()
    let data.view = function('latex#view#mupdf')
    let data.rsearch = function('latex#view#mupdf_rsearch')
  elseif g:latex_view_method == 'sumatrapdf'
    call s:check_method_sumatrapdf()
    let data.view = function('latex#view#sumatrapdf')
  else
    call s:check_method_general()
    let data.view = function('latex#view#general')
  endif

  command! -buffer -nargs=* VimLatexView call latex#view#view('<args>')
  if has_key(data, 'rsearch')
    command! -buffer -nargs=* VimLatexRSearch
          \ call g:latex#data[b:latex.id].rsearch()
  endif

  if g:latex_mappings_enabled
    nnoremap <silent><buffer> <localleader>lv :call latex#view#view()<cr>

    if has_key(data, 'rsearch')
      nnoremap <silent><buffer> <localleader>lr
            \ :call g:latex#data[b:latex.id].rsearch()<cr>
    endif
  endif
endfunction

"}}}1
function! latex#view#view(...) " {{{1
  if a:0 > 0
    let args = join(a:000, ' ')
  else
    let args = ''
  endif

  call g:latex#data[b:latex.id].view(args)
endfunction

" }}}1
function! latex#view#general(args) " {{{1
  let exe = {}
  let exe.cmd = g:latex_view_general_viewer

  if a:args != ''
    let exe.cmd .= ' ' . a:args
  else
    let outfile = g:latex#data[b:latex.id].out()
    if !filereadable(outfile)
      echomsg "Can't view: Output file is not readable!"
      return
    endif
    let exe.cmd .= ' ' . g:latex_view_general_options
    let exe.cmd .= ' ' . shellescape(outfile)
  endif

  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd
endfunction

"}}}1
function! latex#view#mupdf(args) "{{{1
  let outfile = g:latex#data[b:latex.id].out()

  if !has_key(g:latex#data[b:latex.id],'mupdf_id')
    let g:latex#data[b:latex.id].mupdf_id = 0
  endif
  " mupdf already running?
  if !s:exists_mupdf_win(g:latex#data[b:latex.id].mupdf_id)
    call s:start_mupdf(outfile)
  endif

  let mupdf_id = g:latex#data[b:latex.id].mupdf_id

  " Do forward search if possible and mupdf running
  if !s:mupdf_forward_search || mupdf_id == 0 | return | endif

  let l:cmd = "synctex view -i "
        \ . (line(".") + 1) . ":"
        \ . (col(".") + 1) . ":"
        \ . shellescape(expand("%:p"))
        \ . " -o " . shellescape(outfile)
        \ . " | grep -m1 'Page:' | sed 's/Page://' | tr -d '\n'"
  let l:page = system(l:cmd)
  let g:latex#data[b:latex.id].cmds.view_mupdf_synctex = l:cmd
  let g:latex#data[b:latex.id].cmds.view_mupdf_synctex_page = l:page

  if l:page > 0
    let exe = {}
    let exe.cmd = 'xdotool type --window ' .mupdf_id. ' "'
          \ . l:page . 'g"'
    call latex#util#execute(exe)
    let g:latex#data[b:latex.id].cmds.view_mupdf_xdotool = exe.cmd
  endif
endfunction

" }}}1
function! latex#view#mupdf_rsearch() "{{{1
  let data = g:latex#data[b:latex.id]

  let data.mupdf_rsearch = {}
  let outfile = data.out()

  if !has_key(data,'mupdf_id') || data.mupdf_id == 0|| !s:exists_mupdf_win(data.mupdf_id)
    echomsg "Can't search backwards: Open PDF from Vim first!"
    return
  endif

  let mupdf_id = data.mupdf_id

  let data.mupdf_rsearch = {}
  let outfile = data.out()

  " Get page number
  let cmd  = "xdotool getwindowname " . mupdf_id
  let cmd .= " | sed 's:.* - \\([0-9]*\\)/.*:\\1:' | tr -d '\n'"
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
  endif
endfunction

" }}}1
function! latex#view#sumatrapdf(args) "{{{1
  let outfile = g:latex#data[b:latex.id].out()
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  let exe = {}
  let exe.cmd = 'SumatraPDF ' . g:latex_view_sumatrapdf_options
  " SumatraPDF will ignore '-forward-search' if a pdfsync
  " or SyncTeX (either gzipped or normal) file isn't present
  let exe.cmd .= ' -forward-search ' . shellescape(expand('%:p'))
  let exe.cmd .= ' ' . line('.')
  let exe.cmd .= ' ' . shellescape(outfile)

  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd
endfunction

" }}}1

function! s:check_method_general() "{{{1
  if !executable(g:latex_view_general_viewer)
    echoerr "General viewer is not available!"
    echoerr "g:latex_view_general_viewer = "
          \ . g:latex_view_general_viewer
  endif
endfunction

" }}}1
function! s:check_method_mupdf() "{{{1
  if !executable('mupdf')
    echoerr "MuPDF is not available!"
  endif

  " Check if forward search is possible
  let s:mupdf_forward_search = executable('synctex') && executable('xdotool')
endfunction

" }}}1
function! s:check_method_sumatrapdf() "{{{1
  if !executable('SumatraPDF')
    echoerr "SumatraPDF is not available!"
  endif
endfunction

"}}}1

function! s:exists_mupdf_win(id) "{{{1
  let cmd  = 'xdotool search --class MuPDF'
  let mupdf_ids = systemlist(cmd)

  for id in mupdf_ids
    if id == a:id | return 1 | endif
  endfor

  return 0
endfunction
"}}}1

function! s:start_mupdf(outfile) "{{{1
  let outfile = a:outfile
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  let exe = {}
  let exe.cmd  = 'mupdf ' .  g:latex_view_mupdf_options
  let exe.cmd .= ' ' . shellescape(outfile)
  call latex#util#execute(exe)
  let g:latex#data[b:latex.id].cmds.view = exe.cmd

  " Get window ID
  " sleep
  let cmd  = 'xdotool search --class MuPDF'
  let mupdf_ids = systemlist(cmd)

  if len(mupdf_ids) == 0
    let g:latex#data[b:latex.id].mupdf_id = 0
  else
    let g:latex#data[b:latex.id].mupdf_id = mupdf_ids[-1]
  endif

endfunction
"}}}1

" vim: fdm=marker sw=2
