function! health#vimtex#check() abort
  call vimtex#init_options()

  call health#report_start('vimtex')

  call s:check_view()
endfunction

function! s:check_view() abort " {{{1
  call health#report_info('Viewer set to: ' . g:vimtex_view_method)
  call s:check_view_{g:vimtex_view_method}()

  if executable('xdotool') && !executable('pstree')
    call health#report_warn('pstree is not available',
          \ 'vimtex#view#reverse_goto is better if pstree is available.')
  endif
endfunction

" }}}1
function! s:check_view_general() abort " {{{1
  if executable(g:vimtex_view_general_viewer)
    call health#report_ok('General viewer should work properly!')
  else
    call health#report_error(
          \ 'Selected viewer is not executable!',
          \ '- Selection: ' . g:vimtex_view_general_viewer,
          \ '- Please see :h g:vimtex_view_general_viewer')
  endif
endfunction

" }}}1
function! s:check_view_zathura() abort " {{{1
  let l:ok = 1

  if !executable('zathura')
    call health#report_error('Zathura is not executable!')
    let l:ok = 0
  endif

  if !executable('xdotool')
    call health#report_warn('Zathura requires xdotool for forward search!')
    let l:ok = 0
  endif

  if l:ok
    call health#report_ok('Zathura should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_mupdf() abort " {{{1
  let l:ok = 1

  if !executable('mupdf')
    call health#report_error('MuPDF is not executable!')
    let l:ok = 0
  endif

  if !executable('xdotool')
    call health#report_warn('MuPDF requires xdotool for forward search!')
    let l:ok = 0
  endif

  if !executable('synctex')
    call health#report_warn('MuPDF requires synctex for forward search!')
    let l:ok = 0
  endif

  if l:ok
    call health#report_ok('MuPDF should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_skim() abort " {{{1
  let l:cmd = join([
        \ 'osascript -e ',
        \ '''tell application "Finder" to POSIX path of ',
        \ '(get application file id (id of application "Skim") as alias)''',
        \])
  
  if system(l:cmd)
    call health#report_error('Skim is not installed!')
  else
    call health#report_ok('Skim viewer should work!')
  endif
endfunction

" }}}1
