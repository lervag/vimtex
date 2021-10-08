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
    let l:shared = vimtex#jobs#capture("sh -c 'ldd $(which zathura)'")
    if v:shell_error == 0
          \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
      call vimtex#log#warning('Zathura is not linked to libsynctex!')
      let s:zathura.has_synctex = 0
    endif
  endif

  " Use the xwin template
  return vimtex#view#_template_xwin#apply(deepcopy(s:zathura))
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
  let self.job = vimtex#jobs#start(l:cmd)

  call self.xwin_get_id()
  let self.outfile = a:outfile
endfunction

" }}}1
function! s:zathura.forward_search(outfile) dict abort " {{{1
  if !self.has_synctex | return | endif
  if !filereadable(self.synctex()) | return | endif

  let self.texfile = vimtex#paths#relative(expand('%:p'), b:vimtex.root)
  let self.outfile = vimtex#paths#relative(a:outfile, getcwd())

  let self.cmd_forward_search = printf(
        \ 'zathura --synctex-forward %d:%d:%s %s',
        \ line('.'), col('.'),
        \ vimtex#util#shellescape(self.texfile),
        \ vimtex#util#shellescape(self.outfile))
  call vimtex#jobs#run(self.cmd_forward_search)
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
          \ . ' --remote-expr \"\\\"\"vimtex#view#reverse_goto(\%{line}, ''"''"''\%{input}''"''"'')\"\\\"\"\" \%S'
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
  let l:output = vimtex#jobs#capture(
        \ 'pgrep -nf "^zathura.*' . escape(l:outfile, '~\%.') . '"')[0]
  let l:pid = str2nr(l:output)
  if !empty(l:pid) | return l:pid | endif

  " Now try to match correct servername as fallback
  let l:output = vimtex#jobs#capture(
        \ 'pgrep -nf "^zathura.+--servername ' . v:servername . '"')[0]
  return str2nr(l:output)
endfunction

" }}}1
