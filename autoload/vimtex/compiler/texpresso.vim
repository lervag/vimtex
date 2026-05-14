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
      \ 'stdin_pipe': 1,
      \ 'options' : [],
      \})

function! s:compiler.__check_requirements() abort dict " {{{1
  if !executable('texpresso')
    call vimtex#log#warning('texpresso is not executable!')
    let self.enabled = v:false
  endif
endfunction
" }}}1

function! s:compiler.__init() abort dict " {{{1
  let self.start = function('s:compiler_start', [self.start])
  let self.stop = function('s:compiler_stop', [self.stop])
  call add(self.hooks, function('s:texpresso_process_message'))
endfunction
" }}}1

function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  let l:options = ['-json', '-lines'] + self.options
  return 'texpresso ' . join(l:options)
        \ . (empty(a:passed_options) ? '' : ' ' . trim(a:passed_options))
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
endfunction
" }}}1

if has('nvim')
  let s:nvim_attach = luaeval("require('vimtex.compiler.texpresso').attach")
endif

function! s:compiler_start(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)

  augroup vimtex_compiler_texpresso
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call b:vimtex.compiler.texpresso_synctex_forward()
    autocmd ColorScheme <buffer> call b:vimtex.compiler.texpresso_theme()
  augroup END

  if has('nvim')
    let self.nvim_detach = s:nvim_attach()
  else
    let self.listener_id = listener_add(function(self.texpresso_listener, [], self))
  endif

  call self.texpresso_theme()
  call self.texpresso_reload()
endfunction
" }}}1

function! s:compiler_stop(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)
  if has('nvim')
    call self.nvim_detach()
    unlet self.nvim_detach
  else
    call listener_remove(self.listener_id)
    unlet self.listener_id
  endif

  autocmd! vimtex_compiler_texpresso * <buffer>
endfunction
" }}}1

function! s:compiler.texpresso_listener(bufnr, start, end, added, changes) abort dict " {{{1
  let l:path = fnamemodify(bufname(a:bufnr), ":p")
  let l:lines = getbufline(a:bufnr, a:start, a:end - 1 + a:added)
  call self.texpresso_send("change-lines", l:path, a:start - 1, a:end - a:start,  s:join_lines(l:lines))
endfunction
" }}}1

function! s:compiler.texpresso_theme() abort dict " {{{1
  let l:normal_id = synIDtrans(hlID('Normal'))
  let l:fg = synIDattr(l:normal_id, 'fg#')
  let l:bg = synIDattr(l:normal_id, 'bg#')
  
  if l:fg ==# '' || l:bg ==# ''
    return
  endif

  call self.texpresso_send("theme", s:convert_color(l:bg), s:convert_color(l:fg))
endfunction
" }}}1

function! s:compiler.texpresso_reload() abort dict " {{{1
  let l:path = fnamemodify(bufname(), ":p")
  call self.texpresso_send("open", l:path, s:join_lines(getline(1, '$')))
endfunction
" }}}1

function! s:compiler.texpresso_synctex_forward() abort dict "{{{1
  let l:path = fnamemodify(bufname(), ":p")
  let l:lnum = getpos('.')[1]
  let l:prev_key = 'texpresso_synctex_forward_previous'
  if has_key(self, l:prev_key) && self[l:prev_key] == [l:path, l:lnum]
    return
  endif
  let self.texpresso_synctex_forward_previous = [l:path, l:lnum]
  call self.texpresso_send("synctex-forward", l:path, l:lnum)
endfunction
" }}}1

function! s:compiler.texpresso_previous_page() abort dict "{{{1
  call self.texpresso_send("previous-page")
endfunction
"}}}1

function! s:compiler.texpresso_next_page() abort dict "{{{1
  call self.texpresso_send("next-page")
endfunction
"}}}1

function! s:compiler.texpresso_send(...) abort dict " {{{1
  if !self.is_running() | return | endif
  try
    if has('nvim')
      call chansend(self.job, json_encode(a:000) .. "\n")
    else
      call ch_sendraw(self.job, json_encode(a:000) .. "\n")
    endif
  catch
    " chansend/ch_sendraw can fail transiently on startup before the process
    " has opened its stdin. An unhandled exception here causes Neovim to close
    " the channel, which sends EOF to texpresso and terminates it prematurely.
  endtry
endfunction
" }}}1

function! s:texpresso_process_message(json) abort " {{{1
  try
    let l:msg = json_decode(a:json)
  catch
    " FIXME: hooks receive messages from both stdout and stderr, so
    " sometimes parsing can fail.
    return
  endtry

  if type(l:msg) != v:t_list || empty(l:msg)
    return
  endif

  " echom l:msg

  if l:msg[0] ==# 'synctex'
    let l:path = l:msg[1]
    let l:lnum = l:msg[2]
    call vimtex#view#inverse_search(l:lnum, l:path)
  elseif l:msg[0] ==# 'truncate-lines'
    let l:name = l:msg[1]
    let l:count = l:msg[2]
    if name ==# 'out'
      call setqflist(slice(getqflist(), 0, l:count), 'r')
    endif
  elseif l:msg[0] ==# 'append-lines'
    let l:name = l:msg[1]
    let l:lines = l:msg[2:]
    if name ==# 'out'
      call setqflist([], 'a', { 'lines': l:lines, 'efm': '%t%*[^:]: %f:%l: %m' })
    endif
  elseif l:msg[0] ==# 'flush'
  else
    " TODO: handle other types of messages
  endif
endfunction

" }}}1

function s:join_lines(lines) abort " {{{1
  return a:lines == [] ? '' : join(a:lines, "\n") .. "\n"
endfunction

" }}}1

function s:convert_color(color) abort " {{{1
  if a:color =~# '^#'
    let l:hex = a:color
  else
    let l:hex = s:cterm_to_hex(str2nr(a:color))
  endif
  return [str2nr(l:hex[1:2], 16) / 255.0,
        \ str2nr(l:hex[3:4], 16) / 255.0,
        \ str2nr(l:hex[5:6], 16) / 255.0]
endfunction

" }}}1

function s:cterm_to_hex(n) abort " {{{1
  if a:n < 16
    let l:system = [
          \ '#000000', '#800000', '#008000', '#808000',
          \ '#000080', '#800080', '#008080', '#c0c0c0',
          \ '#808080', '#ff0000', '#00ff00', '#ffff00',
          \ '#0000ff', '#ff00ff', '#00ffff', '#ffffff']
    return l:system[a:n]
  elseif a:n < 232
    let l:i = a:n - 16
    let l:levels = [0, 95, 135, 175, 215, 255]
    let l:r = l:levels[l:i / 36]
    let l:g = l:levels[(l:i / 6) % 6]
    let l:b = l:levels[l:i % 6]
    return printf('#%02x%02x%02x', l:r, l:g, l:b)
  else
    let l:v = 8 + (a:n - 232) * 10
    return printf('#%02x%02x%02x', l:v, l:v, l:v)
  endif
endfunction

" }}}1
