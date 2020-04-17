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
    let l:shared = vimtex#jobs#capture('ldd $(which zathura)')
    if v:shell_error == 0
          \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
      call vimtex#log#warning('Zathura is not linked to libsynctex!')
      let s:zathura.has_synctex = 0
    endif
  endif

  return vimtex#view#_template#apply(deepcopy(s:zathura))
endfunction

" }}}1


let s:zathura = {
      \ 'name' : 'Zathura',
      \ 'has_synctex' : 1,
      \}

function! s:zathura.start(outfile) dict abort " {{{1
  let l:outfile = fnamemodify(a:outfile, ':.')
  let l:cmd  = 'zathura'
  if self.has_synctex
    let l:cmd .= ' -x "' . s:inverse_search_cmd
          \ . ' -c \"VimtexInverseSearch %{line} ''%{input}''\""'
    if g:vimtex_view_forward_search_on_start
      let l:cmd .= ' --synctex-forward '
            \ .  line('.')
            \ .  ':' . col('.')
            \ .  ':' . vimtex#util#shellescape(expand('%:p'))
    endif
  endif
  let l:cmd .= ' ' . g:vimtex_view_zathura_options
  let l:cmd .= ' ' . vimtex#util#shellescape(l:outfile)
  let l:cmd .= '&'
  let self.cmd_start = l:cmd

  call vimtex#jobs#run(self.cmd_start)

  let self.outfile = l:outfile
endfunction

function! s:zathura.exists() dict abort " {{{1
  let pid = self.get_pid()
  return !empty(pid)
endfunction

function! s:zathura.view(file) dict abort " {{{1
  if empty(a:file)
    let outfile = self.out()
  else
    let outfile = a:file
  endif
  if vimtex#view#not_readable(outfile) | return | endif

  if self.exists()
    call self.forward_search(outfile)
  else
    if g:vimtex_view_use_temp_files
      call self.copy_files()
    endif
    call self.start(outfile)
  endif

  if exists('#User#VimtexEventView')
    doautocmd <nomodeline> User VimtexEventView
  endif
endfunction


" }}}1
function! s:zathura.forward_search(outfile) dict abort " {{{1
  if !self.has_synctex | return | endif
  if !filereadable(self.synctex()) | return | endif

  let self.texfile = vimtex#paths#relative(expand('%:p'), b:vimtex.root)
  let self.outfile = fnamemodify(a:outfile, ':.')

  let self.cmd_forward_search = printf(
        \ 'zathura --synctex-forward %d:%d:%s %s &',
        \ line('.'), col('.'),
        \ vimtex#util#shellescape(self.texfile),
        \ vimtex#util#shellescape(self.outfile))

  call vimtex#jobs#run(self.cmd_forward_search)
endfunction

" }}}1
function! s:zathura.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files
    let l:cmd = ' -view=none'
  else
    let l:zathura = 'zathura ' . g:vimtex_view_zathura_options
    if self.has_synctex
      " The inverse search command requires insane amount of quote escapes,
      " because the command is parsed through several layers of interpreting,
      " e.g. perl -> shell, perhaps more.
      let l:zathura .= ' -x \"' . s:inverse_search_cmd
            \ . ' -c \"\\\"\"VimtexInverseSearch \%{line} ''"''"''\%{input}''"''"''\"\\\"\"\" \%S'
    endif

    let l:cmd  = vimtex#compiler#latexmk#wrap_option('new_viewer_always', '0')
    let l:cmd .= vimtex#compiler#latexmk#wrap_option('pdf_previewer', l:zathura)
  endif

  return l:cmd
endfunction

" }}}1
function! s:zathura.get_pid() dict abort " {{{1
  " First try to match full output file name
  let l:outfile = get(self, 'outfile', self.out())
  let l:outfile = fnamemodify(l:outfile, ':.')
  let l:output = vimtex#jobs#capture(
        \ 'pgrep -nf "^zathura.*' . escape(l:outfile, '~\%.') . '"')
  let l:pid = str2nr(join(l:output, ''))
  if !empty(l:pid) | return l:pid | endif

  " Now try to match correct servername as fallback
  let l:output = vimtex#jobs#capture(
        \ 'pgrep -nf "^zathura.+--servername ' . v:servername . '"')
  return str2nr(join(l:output, ''))
endfunction

" }}}1

let s:inverse_search_cmd = get(v:, 'progpath', get(v:, 'progname', ''))
      \ . (has('nvim')
      \   ? ' --headless'
      \   : ' -T dumb --not-a-term -n')
