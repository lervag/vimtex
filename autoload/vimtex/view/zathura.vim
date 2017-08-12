" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#zathura#new() " {{{1
  " Check if the viewer is executable
  if !executable('zathura')
    call vimtex#log#error('Zathura is not executable!')
    return {}
  endif

  " Check if the xdotool is available
  if !executable('xdotool')
    call vimtex#log#warning('Zathura requires xdotool for forward search!')
  endif

  "
  " Use the xwin template
  "
  return vimtex#view#common#apply_xwin_template('Zathura',
        \ vimtex#view#common#apply_common_template(deepcopy(s:zathura)))
endfunction

" }}}1

let s:zathura = {
      \ 'name' : 'Zathura',
      \}

function! s:zathura.start(outfile) dict " {{{1
  let l:cmd  = 'zathura'
  let l:cmd .= ' -x "' . g:vimtex_compiler_progname
        \ . ' --servername ' . v:servername
        \ . ' --remote +\%{line} \%{input}"'
  if g:vimtex_view_forward_search_on_start
    let l:cmd .= ' --synctex-forward '
          \ .  line('.')
          \ .  ':' . col('.')
          \ .  ':' . vimtex#util#shellescape(expand('%:p'))
  endif
  let l:cmd .= ' ' . g:vimtex_view_zathura_options
  let l:cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  let self.process = vimtex#process#start(l:cmd)

  call self.xwin_get_id()
endfunction

" }}}1
function! s:zathura.forward_search(outfile) dict " {{{1
  if !filereadable(self.synctex()) | return | endif

  let l:cmd  = 'zathura --synctex-forward '
  let l:cmd .= line('.')
  let l:cmd .= ':' . col('.')
  let l:cmd .= ':' . vimtex#util#shellescape(expand('%:p'))
  let l:cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  call vimtex#process#run(l:cmd)
  let self.cmd_forward_search = l:cmd
endfunction

" }}}1
function! s:zathura.compiler_callback(status) dict " {{{1
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

  if has_key(self, 'hook_callback')
    call self.hook_callback()
  endif
endfunction

" }}}1
function! s:zathura.latexmk_append_argument() dict " {{{1
  if g:vimtex_view_use_temp_files
    let cmd = ' -view=none'
  else
    let cmd  = vimtex#compiler#latexmk#wrap_option('new_viewer_always', '0')
    let cmd .= vimtex#compiler#latexmk#wrap_option('pdf_previewer',
          \ 'zathura ' . g:vimtex_view_zathura_options
          \ . ' -x \"' . g:vimtex_compiler_progname
          \ . ' --servername ' . v:servername
          \ . ' --remote +\%{line} \%{input}\" \%S')
  endif

  return cmd
endfunction

" }}}1

" vim: fdm=marker sw=2
