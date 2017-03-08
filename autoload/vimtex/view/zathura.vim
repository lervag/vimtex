" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#zathura#new() " {{{1
  "
  " Set default options
  "
  call vimtex#util#set_default('g:vimtex_view_zathura_options', '')

  "
  " Check if the viewer is executable
  "
  if !executable('zathura')
    call vimtex#echo#warning('Zathura is not executable!')
    call vimtex#echo#echo('- vimtex viewer will not work!')
    call vimtex#echo#wait()
    return {}
  endif

  "
  " Check if the xdotool is available
  "
  if !executable('xdotool')
    call vimtex#echo#warning('Zathura requires xdotool for forward search!')
  endif

  "
  " Use the xwin template
  "
  return vimtex#view#common#apply_xwin_template('Zathura',
        \ vimtex#view#common#apply_common_template(deepcopy(s:zathura)))
endfunction

" }}}1

let s:zathura = {}

function! s:zathura.start(outfile) dict " {{{1
  let exe = {}
  let exe.cmd  = 'zathura'
  let exe.cmd .= ' -x "' . g:vimtex_latexmk_progname
        \ . ' --servername ' . v:servername
        \ . ' --remote +\%{line} \%{input}"'
  let exe.cmd .= ' ' . g:vimtex_view_zathura_options
  let exe.cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  call vimtex#util#execute(exe)
  let self.cmd_start = exe.cmd

  call self.xwin_get_id()
  call self.forward_search(a:outfile)
endfunction

" }}}1
function! s:zathura.forward_search(outfile) dict " {{{1
  if !filereadable(self.synctex()) | return | endif

  let exe = {}
  let exe.cmd  = 'zathura --synctex-forward '
  let exe.cmd .= line('.')
  let exe.cmd .= ':' . col('.')
  let exe.cmd .= ':' . vimtex#util#shellescape(expand('%:p'))
  let exe.cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  call vimtex#util#execute(exe)
  let self.cmd_forward_search = exe.cmd
endfunction

" }}}1
function! s:zathura.latexmk_callback(status) dict " {{{1
  if !a:status | return | endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

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
    let cmd  = vimtex#latexmk#add_option('new_viewer_always', '0')
    let cmd .= vimtex#latexmk#add_option('pdf_previewer',
          \ 'zathura ' . g:vimtex_view_zathura_options
          \ . ' -x \"' . g:vimtex_latexmk_progname
          \ . ' --servername ' . v:servername
          \ . ' --remote +\%{line} \%{input}\" \%S')
  endif

  return cmd
endfunction

" }}}1

" vim: fdm=marker sw=2
