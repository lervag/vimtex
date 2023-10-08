" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#zathura#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1
function! vimtex#view#zathura#check(viewer) abort " {{{1
  " Check if Zathura is executable
  if !executable('zathura')
    call vimtex#log#error('Zathura is not executable!')
    return v:false
  endif

  " Check if Zathura has libsynctex
  if g:vimtex_view_zathura_check_libsynctex && executable('ldd')
    let l:shared = vimtex#jobs#capture('ldd $(which zathura)')
    if v:shell_error == 0
          \ && empty(filter(l:shared, 'v:val =~# ''libsynctex'''))
      call vimtex#log#warning('Zathura is not linked to libsynctex!')
      if has_key(a:viewer, 'has_synctex')
        let a:viewer.has_synctex = 0
      endif
    endif
  endif

  return v:true
endfunction

" }}}1
function! vimtex#view#zathura#cmdline(outfile, synctex, start) abort " {{{1
  let l:cmd  = 'zathura'

  if a:start
    let l:cmd .= ' ' . g:vimtex_view_zathura_options
    if a:synctex
      let l:cmd .= printf(
            \ ' -x "%s -c \"VimtexInverseSearch %%{line} ''%%{input}''\""',
            \ s:inverse_search_cmd)
    endif
  endif

  if a:synctex && (a:start != 1 || g:vimtex_view_forward_search_on_start)
    let l:cmd .= printf(
          \ ' --synctex-forward %d:%d:%s',
          \ line('.'), col('.'),
          \ vimtex#util#shellescape(expand('%:p')))
  endif

  return l:cmd . ' '
        \ . vimtex#util#shellescape(vimtex#paths#relative(a:outfile, getcwd()))
        \ . '&'
endfunction

let s:inverse_search_cmd = get(g:, 'vimtex_callback_progpath',
      \                        get(v:, 'progpath', get(v:, 'progname', '')))
      \ . (has('nvim')
      \   ? ' --headless'
      \   : ' -T dumb --not-a-term -n')

" }}}1


let s:viewer = vimtex#view#_template#new({
      \ 'name': 'Zathura',
      \ 'has_synctex': 1,
      \ 'xwin_id': 0,
      \})

function! s:viewer._check() dict abort " {{{1
  return vimtex#view#zathura#check(self)
endfunction

" }}}1
function! s:viewer._exists() dict abort " {{{1
  return self.xdo_exists()
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  let self.cmd_start
        \ = vimtex#view#zathura#cmdline(a:outfile, self.has_synctex, 1)

  call vimtex#jobs#run(self.cmd_start)

  call timer_start(500, { _ -> self.xdo_get_id() })
endfunction

" }}}1
function! s:viewer._forward_search(outfile) dict abort " {{{1
  if !self.has_synctex | return | endif

  let l:synctex_file = fnamemodify(a:outfile, ':r') . '.synctex.gz'
  if !filereadable(l:synctex_file) | return | endif

  let self.cmd_forward_search
        \ = vimtex#view#zathura#cmdline(a:outfile, self.has_synctex, 0)

  call vimtex#jobs#run(self.cmd_forward_search)
endfunction

" }}}1

function! s:viewer.get_pid() dict abort " {{{1
  " First try to match full output file name
  let l:outfile = fnamemodify(get(self, 'outfile', self.out()), ':t')
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
