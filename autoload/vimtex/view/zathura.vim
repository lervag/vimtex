" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#zathura#new() abort " {{{1
  " Check if the viewer is executable
  if !executable('zathura')
    call vimtex#log#error('Zathura is not executable!')
    return {}
  endif

  if executable('ldd')
    let l:shared = split(system('ldd =zathura'))
    if v:shell_error == 0
          \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
      call vimtex#log#warning('Zathura is not linked to libsynctex!')
      let s:zathura.has_synctex = 0
    endif
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
      \ 'has_synctex' : 1,
      \}

function! s:zathura.start(outfile) dict abort " {{{1
  let l:cmd  = 'zathura'
  if self.has_synctex
    let l:cmd .= ' -x "' . g:vimtex_compiler_progname
          \ . ' --servername ' . v:servername
          \ . ' --remote-expr '
          \ .     '\"vimtex#view#reverse_goto(%{line}, ''%{input}'')\""'
    if g:vimtex_view_forward_search_on_start
      let l:cmd .= ' --synctex-forward '
            \ .  line('.')
            \ .  ':' . col('.')
            \ .  ':' . vimtex#util#shellescape(expand('%:p'))
    endif
  endif
  let l:cmd .= ' ' . g:vimtex_view_zathura_options
  let l:cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  let self.process = vimtex#process#start(l:cmd)

  call self.xwin_get_id()
  let self.outfile = a:outfile
endfunction

" }}}1
function! s:zathura.forward_search(outfile) dict abort " {{{1
  if !self.has_synctex | return | endif
  if !filereadable(self.synctex()) | return | endif

  let l:cmd  = 'zathura --synctex-forward '
  let l:cmd .= line('.')
  let l:cmd .= ':' . col('.')
  let l:cmd .= ':' . vimtex#util#shellescape(expand('%:p'))
  let l:cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  call vimtex#process#run(l:cmd)
  let self.cmd_forward_search = l:cmd
  let self.outfile = a:outfile
endfunction

" }}}1
function! s:zathura.compiler_callback(status) dict abort " {{{1
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
function! s:zathura.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files
    let cmd = ' -view=none'
  else
    let zathura = 'zathura ' . g:vimtex_view_zathura_options
    if self.has_synctex
      let zathura .= ' -x \"' . g:vimtex_compiler_progname
          \ . ' --servername ' . v:servername
          \ . ' --remote +\%{line} \%{input}\" \%S'
    endif

    let cmd  = vimtex#compiler#latexmk#wrap_option('new_viewer_always', '0')
    let cmd .= vimtex#compiler#latexmk#wrap_option('pdf_previewer', zathura)
  endif

  return cmd
endfunction

" }}}1
function! s:zathura.get_pid() dict abort " {{{1
  " First try to match full output file name
  let cmd = 'pgrep -nf "zathura.*'
        \ . escape(get(self, 'outfile', self.out()), '~\%.') . '"'
  let pid = str2nr(system(cmd)[:-2])

  " Now try to match correct servername as fallback
  if empty(pid)
    let cmd = 'pgrep -nf "zathura.+--servername ' . v:servername . '"'
    let pid = str2nr(system(cmd)[:-2])
  endif

  return pid
endfunction

" }}}1
