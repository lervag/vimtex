" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#compiler#texpresso#init(options) abort " {{{1
  return s:compiler.new(a:options)
endfunction

" }}}1

let s:compiler = vimtex#compiler#_template#new({
      \ 'name' : 'texpresso',
      \ 'continuous': 1,
      \ 'options' : [
      \   '-json',
      \   '-lines'
      \ ],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('texpresso')
    call vimtex#log#warning('texpresso is not executable!')
    let self.enabled = v:false
  endif
endfunction
" }}}1

function! s:compiler.__init() abort dict " {{{1
  augroup vimtex_compiler
    autocmd!
    autocmd User VimtexEventCompileStarted call s:start_listening()
    autocmd User VimtexEventCompileStopped call s:stop_listening()
    autocmd CursorMoved call s:texpresso_synctex_forward_hook()
    autocmd ColorScheme call s:texpresso_theme()
  augroup END
endfunction
" }}}1

function! s:get_buffer_lines(bufnr, start, end) abort " {{{1
  let l:lines = getbufline(a:bufnr, a:start, a:end)
  if empty(l:lines)
    return ''
  else
    return join(l:lines, "\n") .. "\n"
  endif
endfunction
" }}}1

function! s:start_listening() abort " {{{1
  if has('nvim')
    " call nvim_buf_attach(0, v:false, { 'on_lines': function('s:on_lines') })
  else
    let s:listener_id = listener_add(function('s:listener'))
  endif

  call s:texpresso_theme()
  call s:texpresso_reload()
endfunction
" }}}1

function! s:stop_listening() abort " {{{1
  call job_stop(s:listener_id)
  unlet s:listener_id
endfunction
" }}}1

function! s:listener(bufnr, start, end, added, changes) abort " {{{1
  let l:path = fnamemodify(bufname(a:bufnr), ":p")
  call s:texpresso_send("change-lines", l:path, a:start - 1, a:end - a:start,  s:get_buffer_lines(a:bufnr, a:start, a:end - 1 + a:added))
endfunction
" }}}1

function! s:texpresso_theme() abort " {{{1
  " let l:colors = hlget('Normal', v:true)
  " TODO: Convert colors to rgb tuples
  " call s:texpresso_send("theme", [], [])
endfunction
" }}}1

function! s:texpresso_reload() abort " {{{1
  let l:path = fnamemodify(bufname(), ":p")
  call s:texpresso_send("open", l:path, s:get_buffer_lines("%", 1, '$'))
endfunction
" }}}1

function! s:texpresso_synctex_forward_hook() abort "{{{1
  if !b:vimtex.compiler.is_running() | return | endif
  let l:path = fnamemodify(bufname(), ":p")
  let l:lnum = getpos('.')[1]
  call s:texpresso_send("synctex-forward", l:path, l:lnum - 1)
endfunction
" }}}1

function! s:texpresso_send(...) abort " {{{1
  if has('nvim')
    call chansend(b:vimtex.compiler.job, json_encode(a:000) .. "\n\n")
  else
    call ch_sendraw(b:vimtex.compiler.job, json_encode(a:000) .. "\n\n")
  endif
endfunction
" }}}1

function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  return 'texpresso ' . join(self.options)
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction

" }}}1
