" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#qf#init_buffer() abort " {{{1
  " Set compiler (this defines the errorformat)
  compiler latexmk

  " Define commands
  command! -buffer VimtexErrors  call vimtex#qf#toggle()
  command! -buffer VimtexLacheck call vimtex#qf#lacheck()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-errors)  :call vimtex#qf#toggle()<cr>
  nnoremap <buffer> <plug>(vimtex-lacheck) :call vimtex#qf#lacheck()<cr>
endfunction

" }}}1

function! vimtex#qf#toggle() " {{{1
  if s:qf.is_open
    let s:qf.is_open = 0
    cclose
  else
    call vimtex#qf#open(1)
  endif
endfunction

" }}}1
function! vimtex#qf#open(force) " {{{1
  if !exists('b:vimtex') | return | endif
  cclose

  let log = b:vimtex.log()
  if empty(log)
    if a:force
      call vimtex#echo#status(['latexmk errors: ',
            \ ['VimtexWarning', 'No log file found']])
    endif
    return
  endif

  " Store winnr of current window in order to jump back later
  call s:window_save()

  " Save path for fixing quickfix entries
  let s:qf.is_active = 1
  let s:qf.main = b:vimtex.tex

  if g:vimtex_quickfix_autojump
    execute 'cfile' fnameescape(log)
  else
    execute 'cgetfile' fnameescape(log)
  endif

  if empty(getqflist())
    if a:force
      call vimtex#echo#status(['latexmk errors: ',
            \ ['VimtexSuccess', 'No errors!']])
    endif
    return
  endif

  "
  " There are two options that determine when to open the quickfix window.  If
  " forced, the quickfix window is always opened when there are errors or
  " warnings (forced typically imply that the functions is called from the
  " normal mode mapping).  Else the behaviour is based on the settings.
  "
  let s:qf.is_open = a:force
        \ || (g:vimtex_quickfix_mode > 0
        \     && (g:vimtex_quickfix_open_on_warning
        \         || s:log_contains_error(log)))

  if s:qf.is_open
    botright cwindow
    if g:vimtex_quickfix_mode == 2
      call s:window_restore()
    endif
    redraw
  endif
endfunction

" }}}1
function! vimtex#qf#inquire(...) " {{{1
  if !exists('b:vimtex') | return | endif

  let l:log = a:0 > 0 ? a:1.log : b:vimtex.log()
  if empty(l:log) | return 0 | endif

  let s:qf.is_active = 1
  let s:qf.main = a:0 > 0 ? a:1.tex : b:vimtex.tex
  execute 'cgetfile ' . fnameescape(l:log)

  return !empty(getqflist())
endfunction

" }}}1
function! vimtex#qf#lacheck() " {{{1
  compiler lacheck

  silent lmake %
  lwindow
  silent redraw
  wincmd p

  compiler latexmk
endfunction

" }}}1

function! s:log_contains_error(logfile) " {{{1
  let lines = readfile(a:logfile)
  let lines = filter(lines, 'v:val =~# ''^.*:\d\+: ''')
  let lines = vimtex#util#uniq(map(lines, 'matchstr(v:val, ''^.*\ze:\d\+:'')'))
  let lines = map(lines, 'fnamemodify(v:val, '':p'')')
  let lines = filter(lines, 'filereadable(v:val)')
  return len(lines) > 0
endfunction

" }}}1
function! s:window_save() " {{{1
  if exists('*win_gotoid')
    let s:previous_window = win_getid()
  else
    let w:vimtex_remember_window = 1
  endif
endfunction

" }}}1
function! s:window_restore() " {{{1
  if exists('*win_gotoid')
    call win_gotoid(s:previous_window)
  else
    for l:winnr in range(1, winnr('$'))
      if getwinvar(l:winnr, 'vimtex_remember_window')
        execute l:winnr . 'wincmd p'
      endif
    endfor
  endif
endfunction

" }}}1

"
" Define a state object for the quickfix window in order to fix paths if
" necessary (the autocmd will fire on all filetypes, but the state object
" ensures that the function is only run for LaTeX files)
"
let s:qf = {
      \ 'is_open' : 0,
      \ 'is_active' : 0,
      \ 'title' : 'Vimtex errors',
      \ 'main' : b:vimtex.tex,
      \ 'root' : b:vimtex.root,
      \}

function! s:qf.fix_paths() abort dict " {{{1
  if !self.is_active | return | endif

  " Set quickfix title
  let w:quickfix_title = self.title

  let l:qflist = getqflist()
  for l:qf in l:qflist
    " For errors and warnings that don't supply a file, the basename of the
    " main file is used. However, if the working directory is not the root of
    " the LaTeX project, than this results in bufnr = 0.
    if l:qf.bufnr == 0
      let l:qf.bufnr = bufnr(s:qf.main)
      continue
    endif

    " The buffer names of all file:line type errors are relative to the root of
    " the main LaTeX file.
    let l:file = fnamemodify(
          \ simplify(self.root . '/' . bufname(l:qf.bufnr)), ':.')
    if !filereadable(l:file) | continue | endif
    if !bufexists(l:file)
      execute 'badd' l:file
    endif
    let l:qf.bufnr = bufnr(l:file)
  endfor
  call setqflist(l:qflist, 'r', {'title': self.title})

  let self.is_active = 0
endfunction

" }}}1


" {{{1 Initialize module

augroup vimtex_quickfix_fix_dirs
  au!
  au QuickFixCmdPost c*file call s:qf.fix_paths()
augroup END

" }}}1

" vim: fdm=marker sw=2
