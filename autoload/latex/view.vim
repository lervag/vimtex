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

  if g:latex_view_method == 'mupdf'
    call s:check_method_mupdf()
    let g:latex#data[b:latex.id].view = function('latex#view#mupdf')
  elseif g:latex_view_method == 'sumatrapdf'
    call s:check_method_sumatrapdf()
    let g:latex#data[b:latex.id].view = function('latex#view#sumatrapdf')
  else
    call s:check_method_general()
    let g:latex#data[b:latex.id].view = function('latex#view#general')
  endif

  command! -buffer -nargs=* VimLatexView call latex#view#view('<args>')

  if g:latex_mappings_enabled
    nnoremap <silent><buffer> <localleader>lv :call latex#view#view()<cr>
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
  if !filereadable(outfile)
    echomsg "Can't view: Output file is not readable!"
    return
  endif

  " Open if not already open
  let pgrep = 'pgrep -nf "^mupdf.*'
        \ .  fnamemodify(g:latex#data[b:latex.id].out(), ':t')
        \ . '"'
  if !system(pgrep)[:-2]
    let exe = {}
    let exe.cmd  = 'mupdf ' .  g:latex_view_mupdf_options
    let exe.cmd .= ' ' . shellescape(outfile)
    call latex#util#execute(exe)
    let g:latex#data[b:latex.id].cmds.view = exe.cmd
  endif

  " Do forward search if possible
  if !s:mupdf_forward_search | finish | endif

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
    let exe.cmd = 'xdotool search --class mupdf type --window \%1 "'
          \ . l:page . 'g"'
    call latex#util#execute(exe)
    let g:latex#data[b:latex.id].cmds.view_mupdf_xdotool = exe.cmd
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

" vim: fdm=marker sw=2
