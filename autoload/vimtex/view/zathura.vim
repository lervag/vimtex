" VimTeX - LaTeX plugin for Vim
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

  if g:vimtex_view_zathura_check_libsynctex && executable('ldd')
    let l:shared = split(system("sh -c 'ldd $(which zathura)'"))
    if v:shell_error == 0
          \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
      call vimtex#log#warning('Zathura is not linked to libsynctex!')
      let s:zathura.has_synctex = 0
    endif
  endif

  augroup vimtex_view_zathura
    autocmd!
    autocmd User VimtexEventCompileSuccess
            \ call vimtex#view#zathura#compiler_callback()
  augroup END

  " Use the xwin template
  return vimtex#view#common#apply_xwin_template('Zathura',
        \ vimtex#view#common#apply_common_template(deepcopy(s:zathura)))
endfunction

" }}}1
function! vimtex#view#zathura#compiler_callback() abort " {{{1
  if !exists('b:vimtex.viewer') | return | endif
  let self = b:vimtex.viewer
  if !filereadable(self.out()) | return | endif

  if g:vimtex_view_automatic && !has_key(self, 'started_through_callback')
    "
    " Search for existing window created by latexmk
    " Note: It may be necessary to wait some time before it is opened and
    "       recognized. Sometimes it is very quick, other times it may take
    "       a second. This way, we don't block longer than necessary.
    "
    for l:dummy in range(30)
      let l:xwin_exists = self.xwin_exists()
      if l:xwin_exists | break | endif
      sleep 50m
    endfor

    if !l:xwin_exists
      call self.start(self.out())
      let self.started_through_callback = 1
    endif
  endif
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

  let self.texfile = vimtex#paths#relative(expand('%:p'), b:vimtex.root)
  let self.outfile = vimtex#paths#relative(a:outfile, getcwd())

  let l:cmd  = 'zathura --synctex-forward '
  let l:cmd .= line('.')
  let l:cmd .= ':' . col('.')
  let l:cmd .= ':' . vimtex#util#shellescape(self.texfile)
  let l:cmd .= ' ' . vimtex#util#shellescape(self.outfile)
  call vimtex#process#run(l:cmd)
  let self.cmd_forward_search = l:cmd
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
  let l:outfile = fnamemodify(get(self, 'outfile', self.out()), ':t')
  let l:cmd = 'pgrep -nf "^zathura.*' . escape(l:outfile, '~\%.') . '"'
  let l:pid = str2nr(system(l:cmd)[:-2])

  " Now try to match correct servername as fallback
  if empty(l:pid)
    let l:cmd = 'pgrep -nf "^zathura.+--servername ' . v:servername . '"'
    let l:pid = str2nr(system(l:cmd)[:-2])
  endif

  return l:pid
endfunction

" }}}1
