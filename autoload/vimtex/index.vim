" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#index#new(index) abort " {{{1
  return extend(a:index, deepcopy(s:index), 'keep')
endfunction

" }}}1

let s:index = {
      \ 'show_help' : g:vimtex_index_show_help,
      \}

function! s:index.open() abort dict " {{{1
  if self.is_open() | return | endif

  let self.calling_file = expand('%:p')
  let self.calling_line = line('.')

  if has_key(self, 'update')
    call self.update(0)
  endif

  if g:vimtex_index_mode > 1
    call setloclist(0, map(deepcopy(self.entries), '{
          \ ''lnum'': v:val.line,
          \ ''filename'': v:val.file,
          \ ''text'': v:val.title,
          \}'))
    try
      call setloclist(0, [], 'r', {'title': self.name})
    catch
    endtry
    if g:vimtex_index_mode == 4 | lopen | endif
  endif

  if g:vimtex_index_mode < 3
    call self.create()
  endif
endfunction

" }}}1
function! s:index.create() abort dict " {{{1
  let l:bufnr = bufnr('')
  let l:winid = win_getid()
  let l:vimtex = get(b:, 'vimtex', {})

  if g:vimtex_index_split_pos ==# 'full'
    silent execute 'edit' escape(self.name, ' ')
  else
    if g:vimtex_index_resize
      silent exe 'set columns +=' . g:vimtex_index_split_width
    endif
    silent execute
          \ g:vimtex_index_split_pos g:vimtex_index_split_width
          \ 'new' escape(self.name, ' ')
  endif

  let self.prev_bufnr = l:bufnr
  let self.prev_winid = l:winid
  let b:index = self
  let b:vimtex = l:vimtex

  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal concealcursor=nvic
  setlocal conceallevel=0
  setlocal cursorline
  setlocal nobuflisted
  setlocal nolist
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal tabstop=8

  if g:vimtex_index_hide_line_numbers
    setlocal nonumber
    setlocal norelativenumber
  endif

  if b:index.show_help
    nnoremap <silent><buffer> gg gg}j
  endif
  nnoremap <silent><buffer> <esc>OA k
  nnoremap <silent><buffer> <esc>OB j
  nnoremap <silent><buffer> <esc>OC k
  nnoremap <silent><buffer> <esc>OD j
  nnoremap <silent><buffer> q             :call b:index.close()<cr>
  nnoremap <silent><buffer> <esc>         :call b:index.close()<cr>
  nnoremap <silent><buffer> <space>       :call b:index.activate(0)<cr>
  nnoremap <silent><buffer> <2-leftmouse> :call b:index.activate(0)<cr>
  nnoremap <silent><buffer> <cr>          :call b:index.activate(1)<cr>

  call self.syntax()
  call self.refresh()

  if has_key(self, 'hook_init_post')
    call self.hook_init_post()
  endif
endfunction

" }}}1
function! s:index.goto() abort dict " {{{1
  if self.is_open()
    let l:prev_winid = win_getid()
    silent execute bufwinnr(bufnr(self.name)) . 'wincmd w'
    let b:index.prev_winid = l:prev_winid
  endif
endfunction

" }}}1
function! s:index.toggle() abort dict " {{{1
  if self.is_open()
    call self.close()
  else
    call self.open()
    call win_gotoid(self.prev_winid)
  endif
endfunction

" }}}1
function! s:index.is_open() abort dict " {{{1
  return bufwinnr(bufnr(self.name)) >= 0
endfunction

" }}}1
function! s:index.refresh() abort dict " {{{1
  let l:index_winnr = bufwinnr(bufnr(self.name))
  let l:buf_winnr = bufwinnr(bufnr(''))

  if l:index_winnr < 0
    return
  elseif l:buf_winnr != l:index_winnr
    silent execute l:index_winnr . 'wincmd w'
  endif

  call self.position_save()
  setlocal modifiable
  %delete

  call self.print_help()
  call self.print_entries()

  0delete _
  setlocal nomodifiable
  call self.position_restore()

  if l:buf_winnr != l:index_winnr
    silent execute l:buf_winnr . 'wincmd w'
  endif
endfunction

" }}}1
function! s:index.activate(close) abort dict "{{{1
  let n = vimtex#pos#get_cursor_line() - 1
  if n < self.help_nlines | return | endif
  let entry = self.entries[n - self.help_nlines]
  let self.prev_index = n + 1
  let l:vimtex_main = get(b:vimtex, 'tex', '')

  " Save index winnr info for later use
  let index_winnr = winnr()

  " Return to calling window
  call win_gotoid(self.prev_winid)

  " Get buffer number, add buffer if necessary
  let bnr = bufnr(entry.file)
  if bnr == -1
    execute 'badd ' . fnameescape(entry.file)
    let bnr = bufnr(entry.file)
  endif

  " Set bufferopen command
  "   The point here is to use existing open buffer if the user has turned on
  "   the &switchbuf option to either 'useopen' or 'usetab'
  let cmd = 'buffer! '
  if &switchbuf =~# 'usetab'
    for i in range(tabpagenr('$'))
      if index(tabpagebuflist(i + 1), bnr) >= 0
        let cmd = 'sbuffer! '
        break
      endif
    endfor
  elseif &switchbuf =~# 'useopen'
    if bufwinnr(bnr) > 0
      let cmd = 'sbuffer! '
    endif
  endif

  " Open file buffer
  execute 'keepalt' cmd bnr

  " Go to entry line
  if has_key(entry, 'line')
    call vimtex#pos#set_cursor(entry.line, 0)
  endif

  " If relevant, enable vimtex stuff
  if get(entry, 'link', 0) && !empty(l:vimtex_main)
    let b:vimtex_main = l:vimtex_main
    call vimtex#init()
  endif

  " Ensure folds are opened
  normal! zv

  " Keep or close index window (based on options)
  if a:close
    call self.close()
  else
    " Return to index window
    execute index_winnr . 'wincmd w'
  endif
endfunction

function! s:index.close() abort dict " {{{1
  let self.fold_level = &l:foldlevel

  if g:vimtex_index_resize
    silent exe 'set columns -=' . g:vimtex_index_split_width
  endif

  if g:vimtex_index_split_pos ==# 'full'
    silent execute 'buffer' self.prev_bufnr
  else
    silent execute 'bwipeout' bufnr(self.name)
  endif
endfunction

" }}}1
function! s:index.position_save() abort dict " {{{1
  let self.position = vimtex#pos#get_cursor()
endfunction

" }}}1
function! s:index.position_restore() abort dict " {{{1
  if self.position[1] <= self.help_nlines
    let self.position[1] = self.help_nlines + 1
  endif
  call vimtex#pos#set_cursor(self.position)
endfunction

" }}}1
function! s:index.print_entries() abort dict " {{{1
  for entry in self.entries
    call append('$', printf('%s', entry.title))
  endfor
endfunction

" }}}1
function! s:index.print_help() abort dict " {{{1
  let self.help_nlines = 0
  if self.show_help
    call append('$', '<Esc>/q: close')
    call append('$', '<Space>: jump')
    call append('$', '<Enter>: jump and close')
    if has_key(self, 'help')
      for helpstring in self.help
        call append('$', helpstring)
      endfor
      let self.help_nlines += len(self.help)
    endif
    call append('$', '')
    let self.help_nlines += 4
  endif
endfunction

" }}}1
function! s:index.syntax() abort dict " {{{1
  syntax match VimtexIndexHelp /^.*: .*/
  syntax match VimtexIndexLine /^  .*$/ contains=@Tex
endfunction

" }}}1
