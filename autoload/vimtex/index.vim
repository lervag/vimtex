" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#index#open(bufname) abort " {{{1
  let l:winnr = bufwinnr(bufnr(a:bufname))
  if l:winnr >= 0
    let l:prev_winnr = winnr()
    silent execute l:winnr . 'wincmd w'
    let b:index.prev_winnr = l:prev_winnr
    return 1
  else
    return 0
  endif
endfunction

" }}}1
function! vimtex#index#close(bufname) abort " {{{1
  if g:vimtex_index_resize
    silent exe 'set columns -=' . g:vimtex_index_split_width
  endif
  silent execute 'bwipeout' . bufnr(a:bufname)
endfunction

" }}}1
function! vimtex#index#create(index) abort " {{{1
  let l:index = extend(deepcopy(s:index), a:index)
  let l:vimtex = get(b:, 'vimtex', {})

  let l:bufnr = bufnr('')
  if g:vimtex_index_split_pos ==# 'full'
    silent execute 'edit' escape(l:index.name, ' ')
  else
    if g:vimtex_index_resize
      silent exe 'set columns +=' . g:vimtex_index_split_width
    endif
    silent execute
          \ g:vimtex_index_split_pos g:vimtex_index_split_width
          \ 'new' escape(l:index.name, ' ')
  endif
  let l:index.prev_winnr = bufwinnr(l:bufnr)

  let b:index = l:index
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

let s:index = {
      \ 'show_help' : g:vimtex_index_show_help,
      \}

function! s:index.refresh() abort dict " {{{1
  call self.position_save()
  setlocal modifiable
  %delete

  call self.print_help()
  call self.print_entries()

  0delete _
  setlocal nomodifiable
  call self.position_restore()
endfunction

" }}}1
function! s:index.activate(close) abort dict "{{{1
  let n = getpos('.')[1] - 1
  if n < self.help_nlines | return | endif
  let entry = self.entries[n - self.help_nlines]
  let l:vimtex_main = get(b:vimtex, 'tex', '')

  " Save index buffer info for later use
  let toc_bnr = bufnr('%')
  let toc_wnr = winnr()

  " Return to calling window
  silent execute self.prev_winnr . 'wincmd w'

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
    call vimtex#pos#cursor(entry.line, 0)
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
    if bufexists(toc_bnr)
      if g:vimtex_index_resize
        silent exe 'set columns -=' . g:vimtex_index_split_width
      endif
      execute 'bwipeout ' . toc_bnr
    endif
  else
    execute toc_wnr . 'wincmd w'
  endif
endfunction

function! s:index.close() abort dict "{{{1
  if g:vimtex_index_resize
    silent exe 'set columns -=' . g:vimtex_index_split_width
  endif
  bwipeout
endfunction

function! s:index.position_save() abort dict " {{{1
  let self.position = getpos('.')
endfunction

" }}}1
function! s:index.position_restore() abort dict " {{{1
  if self.position[1] <= self.help_nlines
    let self.position[1] = self.help_nlines + 1
  endif
  call vimtex#pos#cursor(self.position)
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

" vim: fdm=marker sw=2
