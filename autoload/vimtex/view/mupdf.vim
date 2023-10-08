" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#mupdf#new() abort " {{{1
  " Add reverse search mapping
  nnoremap <buffer> <plug>(vimtex-reverse-search)
        \ :<c-u>call b:vimtex.viewer.reverse_search()<cr>

  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({
      \ 'name': 'MuPDF',
      \ 'xwin_id': 0,
      \})

function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  if g:vimtex_view_automatic && !has_key(self, 'started_through_callback')
    let self.started_through_callback = 1
    call self._start(a:outfile)
  endif

  if has_key(self, 'job') && self.job.get_pid() > 0
    call self.job.signal_hup()
  endif
endfunction

" }}}1
function! s:viewer.reverse_search() dict abort " {{{1
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let l:outfile = self.out()
  if !filereadable(l:outfile) || !self.xdo_exists()
    call vimtex#log#warning('Reverse search failed (is MuPDF open?)')
    return
  endif

  " Get page number
  let self.cmd_getpage
        \ = 'xdotool getwindowname ' . self.xwin_id
        \ . "| sed 's:.* - \\([0-9]*\\)/.*:\\1:'"
        \ . "| tr -d '\n'"
  let self.page = vimtex#jobs#capture(self.cmd_getpage)[0]
  if self.page <= 0 | return | endif

  " Get file
  let self.cmd_getfile  = 'synctex edit '
        \ . "-o \"" . self.page . ':288:108:' . l:outfile . "\""
        \ . "| grep 'Input:' | sed 's/Input://' "
        \ . "| head -n1 | tr -d '\n' 2>/dev/null"
  let self.file = vimtex#jobs#capture(self.cmd_getfile)[0]

  " Get line
  let self.cmd_getline  = 'synctex edit '
        \ . "-o \"" . self.page . ':288:108:' . l:outfile . "\""
        \ . "| grep -m1 'Line:' | sed 's/Line://' "
        \ . "| head -n1 | tr -d '\n'"
  let self.line = vimtex#jobs#capture(self.cmd_getline)[0]

  " Go to file and line
  silent exec 'edit ' . fnameescape(self.file)
  if self.line > 0
    silent exec ':' . self.line
    " Unfold, move to top line to correspond to top pdf line, and go to end of
    " line in case the corresponding pdf line begins on previous pdf page.
    normal! zvztg_
  endif
endfunction

" }}}1

function! s:viewer._check() dict abort " {{{1
  " Check if MuPDF is executable
  if !executable('mupdf')
    call vimtex#log#error('MuPDF is not executable!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._exists() dict abort " {{{1
  return self.xdo_exists()
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  let l:cmd = 'mupdf'
  if !empty(g:vimtex_view_mupdf_options)
    let l:cmd .= ' ' . g:vimtex_view_mupdf_options
  endif
  let l:cmd .= ' ' . vimtex#util#shellescape(a:outfile)
  let self.cmd_start = l:cmd

  let self.job = vimtex#jobs#start(self.cmd_start, {'detached': v:true})
  if g:vimtex_view_forward_search_on_start
    call self._forward_search(a:outfile)
  endif

  call timer_start(500, self._start_post)
endfunction

" }}}1
function! s:viewer._start_post(_timer_id) dict abort " {{{1
  call self.xdo_get_id()
  call self.xdo_send_keys(g:vimtex_view_mupdf_send_keys)
endfunction

" }}}1
function! s:viewer._forward_search(outfile) dict abort " {{{1
  if !executable('xdotool') | return | endif
  if !executable('synctex') | return | endif

  let self.cmd_synctex_view = 'synctex view -i '
        \ . (line('.') + 1) . ':'
        \ . (col('.') + 1) . ':'
        \ . vimtex#util#shellescape(expand('%:p'))
        \ . ' -o ' . vimtex#util#shellescape(a:outfile)
        \ . " | grep -m1 'Page:' | sed 's/Page://' | tr -d '\n'"
  let self.page = vimtex#jobs#capture(self.cmd_synctex_view)[0]

  if self.page > 0
    let self.cmd_forward_search = 'xdotool'
          \ . ' type --window ' . self.xwin_id
          \ . ' "' . self.page . 'g"'
    call vimtex#jobs#run(self.cmd_forward_search)
  endif

  call self.xdo_focus_viewer()
endfunction

" }}}1
