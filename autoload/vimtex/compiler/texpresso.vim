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
  let self.start = function('s:compiler_start', [self.start])
  let self.stop = function('s:compiler_stop', [self.stop])
  call add(self.hooks, function('s:texpresso_process_message'))
endfunction
" }}}1

function! s:compiler.__build_cmd(passed_options) abort dict " {{{1
  return 'texpresso ' . join(self.options)
        \ . ' ' . vimtex#util#shellescape(self.file_info.target_basename)
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

function! s:compiler_start(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)

  augroup vimtex_compiler
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call b:vimtex.compiler.texpresso_synctex_forward()
    autocmd ColorScheme <buffer> call b:vimtex.compiler.texpresso_theme()
  augroup END

  if has('nvim')
    lua << trim EOF
      vim.api.nvim_buf_attach(0, false, {
        on_lines = function(e, buf, _tick, first, oldlast, newlast)
          local job = vim.b[buf].vimtex.compiler.job
          if vim.fn.jobwait({job}, 0)[1] ~= -1 then
            return true
          end
          local path = vim.api.nvim_buf_get_name(buf)
          local count = oldlast - first
          local lines = ""
          if first < newlast then
            lines = table.concat(vim.api.nvim_buf_get_lines(buf, first, newlast, false), "\n") .. "\n"
          end
          local msg = vim.json.encode({"change-lines", path, first, count, lines})
          vim.fn.chansend(job, {msg, ""})
        end
      })
    EOF
  else
    let self.listener_id = listener_add(function(self.texpresso_listener, [], self))
  endif

  call self.texpresso_theme()
  call self.texpresso_reload()
endfunction
" }}}1

function! s:compiler_stop(super, ...) abort dict " {{{1
  call call(a:super, a:000, self)
  if !has('nvim')
    call listener_remove(self.listener_id)
    unlet self.listener_id
  endif

  autocmd! vimtex_compiler * <buffer>
endfunction
" }}}1

function! s:compiler.texpresso_listener(bufnr, start, end, added, changes) abort dict " {{{1
  let l:path = fnamemodify(bufname(a:bufnr), ":p")
  call self.texpresso_send("change-lines", l:path, a:start - 1, a:end - a:start,  s:get_buffer_lines(a:bufnr, a:start, a:end - 1 + a:added))
endfunction
" }}}1

function! s:compiler.texpresso_theme() abort dict " {{{1
  " let l:colors = hlget('Normal', v:true)
  " TODO: Convert colors to rgb tuples
  " call self.texpresso_send("theme", [], [])
endfunction
" }}}1

function! s:compiler.texpresso_reload() abort dict " {{{1
  let l:path = fnamemodify(bufname(), ":p")
  call self.texpresso_send("open", l:path, s:get_buffer_lines("%", 1, '$'))
endfunction
" }}}1

function! s:compiler.texpresso_synctex_forward() abort dict "{{{1
  let l:path = fnamemodify(bufname(), ":p")
  let l:lnum = getpos('.')[1]
  call self.texpresso_send("synctex-forward", l:path, l:lnum - 1)
endfunction
" }}}1

function! s:compiler.texpresso_send(...) abort dict " {{{1
  if !self.is_running() | return | endif
  if has('nvim')
    call chansend(self.job, json_encode(a:000) .. "\n")
  else
    call ch_sendraw(self.job, json_encode(a:000) .. "\n")
  endif
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
      " TODO: truncate qf list
      call setqflist(getqflist()[:l:count], 'r')
    endif
  elseif l:msg[0] ==# 'append-lines'
    let l:name = l:msg[1]
    let l:lines = l:msg[2:]
    if name ==# 'out'
      " TODO: parse lines and append to qf list
      echom l:lines
      call setqflist([], 'a', { 'lines': l:lines, 'efm': '%t%*[^:]: %f:%l: %m' })
    endif
  elseif l:msg[0] ==# 'flush'
  else
    " TODO: handle other types of messages
  endif
endfunction
" }}}1
