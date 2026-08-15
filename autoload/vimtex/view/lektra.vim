" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#lektra#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1
function! vimtex#view#lektra#cmdline(outfile, synctex, start) abort " {{{1
  " Lektra only starts its IPC server when asked to, and it only reuses
  " a running instance through that same server. We therefore always specify
  " a socket name that is unique to the output file. This ensures that both
  " forward searches and repeated view commands are routed to the instance
  " that displays the relevant PDF file.
  let l:cmd = g:vimtex_view_lektra_exe
        \ . ' --single-instance'
        \ . ' --socket ' . vimtex#view#lektra#socket(a:outfile)

  if a:start && !empty(g:vimtex_view_lektra_options)
    let l:cmd .= ' ' . g:vimtex_view_lektra_options
  endif

  if a:synctex && (!a:start || g:vimtex_view_forward_search_on_start)
    " Lektra opens the PDF file if it is not already open, so there is no need
    " to also pass it as a positional argument.
    return l:cmd . ' --synctex-forward ' . vimtex#util#shellescape(printf(
          \ '%s#%s:%d:%d',
          \ fnamemodify(a:outfile, ':p'),
          \ expand('%:p'),
          \ line('.'), col('.')))
  endif

  return l:cmd . ' ' . vimtex#util#shellescape(fnamemodify(a:outfile, ':p'))
endfunction

" }}}1
function! vimtex#view#lektra#socket(outfile) abort " {{{1
  return 'vimtex-lektra-' . sha256(fnamemodify(a:outfile, ':p'))[:15]
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({
      \ 'name': 'lektra',
      \ 'has_synctex': get(g:, 'vimtex_view_lektra_use_synctex', 1),
      \ 'started': v:false,
      \ 'xwin_id': 0,
      \})

function! s:viewer._check() dict abort " {{{1
  if !executable(g:vimtex_view_lektra_exe)
    call vimtex#log#error('lektra is not executable!')
    return v:false
  endif

  " Lektra may be compiled without synctex support, in which case it does not
  " recognize the "--synctex-forward" option at all.
  if self.has_synctex
    let l:help = vimtex#jobs#capture(g:vimtex_view_lektra_exe . ' --help')
    if empty(filter(l:help, 'v:val =~# ''--synctex-forward'''))
      call vimtex#log#warning('Lektra is compiled without synctex support!')
      let self.has_synctex = 0
    endif
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._exists() dict abort " {{{1
  " Note: Lektra works on both Xorg and Wayland, thus we don't rely on xdotool
  "       here. The IPC socket name is unique per PDF file, so a matching
  "       process is a reliable indicator of a running viewer instance.
  "       The "xwin_id" attribute is only kept to allow the inverse search to
  "       refocus Vim through "xdo_focus_vim".
  return executable('pgrep') ? self.get_pid() > 0 : self.started
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  let self.cmd_start
        \ = vimtex#view#lektra#cmdline(a:outfile, self.has_synctex, 1)

  call vimtex#jobs#run(self.cmd_start)

  let self.started = v:true
endfunction

" }}}1
function! s:viewer._forward_search(outfile) dict abort " {{{1
  if !self.has_synctex | return | endif

  let l:root = fnamemodify(a:outfile, ':r')
  if !filereadable(l:root . '.synctex.gz')
        \ && !filereadable(l:root . '.synctex') | return | endif

  let self.cmd_forward_search
        \ = vimtex#view#lektra#cmdline(a:outfile, self.has_synctex, 0)

  call vimtex#jobs#run(self.cmd_forward_search)
endfunction

" }}}1

function! s:viewer.get_pid() dict abort " {{{1
  " Lektra detaches from the terminal by re-executing itself with an implicit
  " "--foreground" flag. Matching on this flag ensures we don't match the shell
  " that was used to start the viewer.
  let l:output = vimtex#jobs#capture(printf(
        \ 'pgrep -nf "lektra --foreground .*--socket %s"',
        \ vimtex#view#lektra#socket(self.out())))
  return str2nr(join(l:output, ''))
endfunction

" }}}1
