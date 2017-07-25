" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#init_buffer() abort " {{{1
  if !g:vimtex_quickfix_enabled | return | endif

  command! -buffer VimtexErrors  call vimtex#qf#toggle()

  nnoremap <buffer> <plug>(vimtex-errors)  :call vimtex#qf#toggle()<cr>
endfunction

" }}}1
function! vimtex#qf#init_state(state) abort " {{{1
  if !g:vimtex_quickfix_enabled | return | endif

  try
    let l:qf = vimtex#qf#{g:vimtex_quickfix_method}#new()
    call l:qf.init(a:state)
    unlet l:qf.init
    let a:state.qf = l:qf
  catch /vimtex: Requirements not met/
    call vimtex#echo#warning('Please see :help g:vimtex_quickfix_method')
    call vimtex#echo#wait()
  endtry
endfunction

" }}}1

function! vimtex#qf#toggle() abort " {{{1
  if vimtex#qf#is_open()
    cclose
  else
    call vimtex#qf#open(1)
  endif
endfunction

" }}}1
function! vimtex#qf#open(force) abort " {{{1
  if !exists('b:vimtex.qf.setqflist') | return | endif

  try
    call b:vimtex.qf.setqflist('', g:vimtex_quickfix_autojump)
  catch /Vimtex: No log file found/
    if a:force
      call vimtex#echo#status(['vimtex: ',
            \ ['VimtexWarning', 'No log file found']])
    endif
    cclose
    return
  endtry

  if empty(getqflist())
    if a:force
      call vimtex#echo#status(['vimtex: ', ['VimtexSuccess', 'No errors!']])
    endif
    cclose
    return
  endif

  "
  " There are two options that determine when to open the quickfix window.  If
  " forced, the quickfix window is always opened when there are errors or
  " warnings (forced typically imply that the functions is called from the
  " normal mode mapping).  Else the behaviour is based on the settings.
  "
  let l:errors_or_warnings = s:qf_has_errors() || g:vimtex_quickfix_open_on_warning

  if a:force || (g:vimtex_quickfix_mode > 0 && l:errors_or_warnings)
    call s:window_save()
    botright cwindow
    if g:vimtex_quickfix_mode == 2
      call s:window_restore()
    endif
    redraw
  elseif !l:errors_or_warnings
    cclose
  endif
endfunction

" }}}1
function! vimtex#qf#inquire(file) abort " {{{1
  if !exists('b:vimtex.qf.setqflist') | return 0 | endif

  try
    call b:vimtex.qf.setqflist(a:file, 0)
  catch /Vimtex: No log file found/
    return 0
  endtry

  return s:qf_has_errors()
endfunction

" }}}1

function! vimtex#qf#is_open() abort " {{{1
  redir => l:buflist
  silent! ls!
  redir END

  let l:buflist = filter(split(l:buflist, '\n'), 'v:val =~# ''Quickfix''')

  for l:line in l:buflist
    let l:bufnr = str2nr(matchstr(l:line, '^\s*\zs\d\+'))
    if bufwinnr(l:bufnr) >= 0
          \ && getbufvar(l:bufnr, '&buftype', '') ==# 'quickfix'
      return 1
    endif
  endfor

  return 0
endfunction

" }}}1

function! s:window_save() abort " {{{1
  if exists('*win_gotoid')
    let s:previous_window = win_getid()
  else
    let w:vimtex_remember_window = 1
  endif
endfunction

" }}}1
function! s:window_restore() abort " {{{1
  if exists('*win_gotoid')
    call win_gotoid(s:previous_window)
  else
    for l:winnr in range(1, winnr('$'))
      if getwinvar(l:winnr, 'vimtex_remember_window')
        execute l:winnr . 'wincmd p'
        unlet! w:vimtex_remember_window
      endif
    endfor
  endif
endfunction

" }}}1

function! s:qf_has_errors() abort " {{{1
  return len(filter(getqflist(), 'v:val.type ==# ''E''')) > 0
endfunction

" }}}1

" vim: fdm=marker sw=2
