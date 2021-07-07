" VimTeX - LaTeX plugin for Vim
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
  catch /VimTeX: Requirements not met/
    call vimtex#log#warning(
          \ 'Quickfix state not initialized!',
          \ 'Please see :help g:vimtex_quickfix_method')
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
  if !exists('b:vimtex.qf.addqflist') | return | endif

  try
    call vimtex#qf#setqflist()
  catch /VimTeX: No log file found/
    if a:force
      call vimtex#log#warning('No log file found')
    endif
    if g:vimtex_quickfix_mode > 0
      cclose
    endif
    return
  catch
    call vimtex#log#error('Something went wrong when parsing log files!')
    if g:vimtex_quickfix_mode > 0
      cclose
    endif
    return
  endtry

  if empty(getqflist())
    if a:force
      call vimtex#log#info('No errors!')
    endif
    if g:vimtex_quickfix_mode > 0
      cclose
    endif
    return
  endif

  "
  " There are two options that determine when to open the quickfix window.  If
  " forced, the quickfix window is always opened when there are errors or
  " warnings (forced typically imply that the functions is called from the
  " normal mode mapping).  Else the behaviour is based on the settings.
  "
  let l:errors_or_warnings = s:qf_has_errors()
        \ || g:vimtex_quickfix_open_on_warning

  if a:force || (g:vimtex_quickfix_mode > 0 && l:errors_or_warnings)
    let s:previous_window = win_getid()
    botright cwindow
    if g:vimtex_quickfix_mode == 2
      redraw
      call win_gotoid(s:previous_window)
    endif
    if g:vimtex_quickfix_autoclose_after_keystrokes > 0
      augroup vimtex_qf_autoclose
        autocmd!
        autocmd CursorMoved,CursorMovedI * call s:qf_autoclose_check()
      augroup END
    endif
    redraw
  endif
endfunction

" }}}1
function! vimtex#qf#setqflist(...) abort " {{{1
  if !exists('b:vimtex.qf.addqflist') | return | endif

  if a:0 > 0 && !empty(a:1)
    let l:tex = a:1
    let l:log = fnamemodify(l:tex, ':r') . '.log'
    let l:blg = fnamemodify(l:tex, ':r') . '.blg'
    let l:jump = 0
  else
    let l:tex = b:vimtex.tex
    let l:log = b:vimtex.log()
    let l:blg = b:vimtex.ext('blg')
    let l:jump = g:vimtex_quickfix_autojump
  endif

  try
    " Initialize the quickfix list
    " Note: Only create new list if the current list is not a VimTeX qf list
    if get(getqflist({'title': 1}), 'title') =~# 'VimTeX'
      call setqflist([], 'r')
    else
      call setqflist([])
    endif

    " Parse LaTeX errors
    call b:vimtex.qf.addqflist(l:tex, l:log)

    " Parse bibliography errors
    if has_key(b:vimtex.packages, 'biblatex')
      call vimtex#qf#biblatex#addqflist(l:blg)
    else
      call vimtex#qf#bibtex#addqflist(l:blg)
    endif

    " Ignore entries if desired
    if !empty(g:vimtex_quickfix_ignore_filters)
      let l:qflist = getqflist()
      for l:re in g:vimtex_quickfix_ignore_filters
        call filter(l:qflist, 'v:val.text !~# l:re')
      endfor
      call setqflist(l:qflist, 'r')
    endif

    " Set title if supported
    try
      call setqflist([], 'r', {'title': 'VimTeX errors (' . b:vimtex.qf.name . ')'})
    catch
    endtry

    " Jump to first error if wanted
    if l:jump
      cfirst
    endif
  catch /VimTeX: No log file found/
    throw 'VimTeX: No log file found'
  endtry
endfunction

" }}}1
function! vimtex#qf#inquire(file) abort " {{{1
  try
    call vimtex#qf#setqflist(a:file)
    return s:qf_has_errors()
  catch
    return 0
  endtry
endfunction

" }}}1

function! vimtex#qf#is_open() abort " {{{1
  redir => l:bufstring
  silent! ls!
  redir END

  let l:buflist = filter(split(l:bufstring, '\n'), 'v:val =~# ''Quickfix''')

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


function! s:qf_has_errors() abort " {{{1
  return len(filter(getqflist(), 'v:val.type ==# ''E''')) > 0
endfunction

" }}}1
function! s:qf_autoclose_check() abort " {{{1
  if get(s:, 'keystroke_counter') == 0
    let s:keystroke_counter = g:vimtex_quickfix_autoclose_after_keystrokes
  endif

  redir => l:bufstring
  silent! ls!
  redir END

  if empty(filter(split(l:bufstring, '\n'), 'v:val =~# ''%a- .*Quickfix'''))
    let s:keystroke_counter -= 1
  else
    let s:keystroke_counter = g:vimtex_quickfix_autoclose_after_keystrokes + 1
  endif

  if s:keystroke_counter == 0
    cclose
    autocmd! vimtex_qf_autoclose
    augroup! vimtex_qf_autoclose
  endif
endfunction

" }}}1
