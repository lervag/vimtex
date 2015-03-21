" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#index#init(initialized) " {{{1
  call vimtex#util#set_default('g:vimtex_index_hide_line_numbers', 1)
  call vimtex#util#set_default('g:vimtex_index_resize', 0)
  call vimtex#util#set_default('g:vimtex_index_show_help', 1)
  call vimtex#util#set_default('g:vimtex_index_split', 'vert leftabove 30')
endfunction

" }}}1
function! vimtex#index#open(bufname) " {{{1
  let winnr = bufwinnr(bufnr(a:bufname))
  if winnr >= 0
    silent execute winnr . 'wincmd w'
    return 1
  else
    return 0
  endif
endfunction

" }}}1
function! vimtex#index#close(bufname) " {{{1
  if g:vimtex_index_resize
    silent exe 'set columns -=' . g:vimtex_toc_width
  endif
  silent execute 'bwipeout' . bufnr(a:bufname)
endfunction

" }}}1
function! vimtex#index#create(index) " {{{1
  let default = {
        \ 'refresh'       : function('s:actions_refresh'),
        \ 'activate'      : function('s:actions_activate'),
        \ 'close'         : function('s:actions_close'),
        \ 'print_entries' : function('s:print_entries'),
        \ 'print_help'    : function('s:print_help'),
        \ 'syntax'        : function('s:syntax'),
        \ 'show_help'     : g:vimtex_index_show_help,
        \ }
  for [key, FnVal] in items(default)
    if !has_key(a:index, key)
      let a:index[key] = FnVal
    endif
    unlet FnVal
  endfor

  if g:vimtex_index_resize
    silent exe 'set columns +=' . g:vimtex_index_width
  endif
  silent execute g:vimtex_index_split 'new' escape(a:index.name, ' ')
  let b:index = a:index

  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal concealcursor=nvic
  setlocal conceallevel=0
  setlocal cursorline
  setlocal listchars=
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

  nnoremap <silent><buffer> G G{k
  nnoremap <silent><buffer> <esc>OA k
  nnoremap <silent><buffer> <esc>OB j
  nnoremap <silent><buffer> <esc>OC k
  nnoremap <silent><buffer> <esc>OD j
  nnoremap <silent><buffer> q             :call b:index.close()<cr>
  nnoremap <silent><buffer> <esc>         :call b:index.close()<cr>
  nnoremap <silent><buffer> <space>       :call b:index.activate(0)<cr>
  nnoremap <silent><buffer> <leftrelease> :call b:index.activate(0)<cr>
  nnoremap <silent><buffer> <cr>          :call b:index.activate(1)<cr>
  nnoremap <silent><buffer> <2-leftmouse> :call b:index.activate(1)<cr>

  call b:index.syntax()
  call b:index.refresh()

  if has_key(b:index, 'hook_init_post')
    call b:index.hook_init_post()
    unlet b:index.hook_init_post
  endif
endfunction

" }}}1

function! s:actions_refresh() dict " {{{1
  let pos_saved = getpos('.')
  setlocal modifiable
  %delete

  call self.print_entries()
  call self.print_help()

  0delete _
  setlocal nomodifiable
  call setpos('.', pos_saved)
endfunction

" }}}1
function! s:actions_activate(close) dict "{{{1
  let n = getpos('.')[1] - 1
  if n >= len(self.entries)
    return
  endif
  let entry = self.entries[n]

  " Save index buffer info for later use
  let toc_bnr = bufnr('%')
  let toc_wnr = winnr()

  " Return to calling window
  wincmd w

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
  execute cmd bnr

  " Go to entry line
  call setpos('.', [0, entry.line, 0, 0])

  " Ensure folds are opened
  normal! zv

  " Keep or close index window (based on options)
  if a:close
    if g:vimtex_index_resize
      silent exe 'set columns -=' . g:vimtex_index_width
    endif
    execute 'bwipeout ' . toc_bnr
  else
    execute toc_wnr . 'wincmd w'
  endif
endfunction

function! s:actions_close() dict "{{{1
  if g:vimtex_index_resize
    silent exe 'set columns -=' . g:vimtex_index_width
  endif
  bwipeout
endfunction

function! s:print_entries() dict " {{{1
  for entry in self.entries
    call append('$', printf('  %s', entry.title))
  endfor
endfunction

" }}}1
function! s:print_help() dict " {{{1
  if self.show_help
    call append('$', '')
    call append('$', '<Esc>/q: close')
    call append('$', '<Space>: jump')
    call append('$', '<Enter>: jump and close')
    if has_key(self, 'hook_print_help')
      call self.hook_print_help()
    endif
  endif
endfunction

" }}}1
function! s:syntax() dict " {{{1
  syntax match IndexLine /^.*$/ contains=@Tex
  syntax match IndexHelp /^.*: .*/

  highlight link IndexLine ModeMsg
  highlight link IndexHelp helpVim
endfunction

" }}}1

" vim: fdm=marker sw=2
