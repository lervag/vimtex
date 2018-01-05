" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#labels#init_buffer() abort " {{{1
  if !g:vimtex_labels_enabled | return | endif

  command! -buffer VimtexLabelsOpen   call b:vimtex.labels.open()
  command! -buffer VimtexLabelsToggle call b:vimtex.labels.toggle()

  nnoremap <buffer> <plug>(vimtex-labels-open)   :call b:vimtex.labels.open()<cr>
  nnoremap <buffer> <plug>(vimtex-labels-toggle) :call b:vimtex.labels.toggle()<cr>
endfunction

" }}}1
function! vimtex#labels#init_state(state) abort " {{{1
  if !g:vimtex_labels_enabled | return | endif

  let a:state.labels = vimtex#index#new(deepcopy(s:labels))
endfunction

" }}}1

function! vimtex#labels#get_entries() abort " {{{1
  if !has_key(b:vimtex, 'labels') | return [] | endif

  return b:vimtex.labels.update(0)
endfunction

" }}}1
function! vimtex#labels#refresh() abort " {{{1
  if has_key(b:vimtex, 'labels')
    call b:vimtex.labels.update(1)
  endif
endfunction

" }}}1

let s:labels = {
      \ 'name' : 'Table of labels (vimtex)',
      \ 'help' : [
      \   'c:       clear filters',
      \   'f:       filter',
      \   'u:       update',
      \ ],
      \}

function! s:labels.update(force) abort dict " {{{1
  if has_key(self, 'entries') && !g:vimtex_labels_refresh_always && !a:force
    return self.entries
  endif

  call self.parse()

  if a:force && self.is_open()
    call self.refresh()
  endif

  return self.entries
endfunction

" }}}1
function! s:labels.parse(...) abort dict " {{{1
  if a:0 > 0
    let l:file = a:1
  elseif exists('b:vimtex')
    let l:file = b:vimtex.tex
  else
    return []
  endif

  let self.entries = []
  let l:preamble = 1
  for [l:file, l:lnum, l:line] in vimtex#parser#tex(l:file)
    if l:line =~# '\v^\s*\\begin\{document\}'
      let l:preamble = 0
      continue
    endif

    if l:preamble
      continue
    endif

    if l:line =~# '\v\\label\{'
      call add(self.entries, {
            \ 'title' : matchstr(l:line, '\v\\label\{\zs.{-}\ze\}'),
            \ 'file'  : l:file,
            \ 'line'  : l:lnum,
            \ })
    endif
  endfor

  let self.all_entries = deepcopy(self.entries)
endfunction

" }}}1

"
" Index related methods
"

function! s:labels.hook_init_post() dict " {{{1
  nnoremap <buffer> <silent> c :call b:index.clear_filter()<cr>
  nnoremap <buffer> <silent> f :call b:index.filter()<cr>
  nnoremap <buffer> <silent> u :call b:index.update(1)<cr>
endfunction

" }}}1
function! s:labels.clear_filter() dict "{{{1
  let self.entries = copy(self.all_entries)
  call self.refresh()
endfunction

" }}}1
function! s:labels.filter() dict "{{{1
  let filter = input('filter by: ')
  let self.entries = filter(self.entries, 'v:val.title =~# filter') 
  call self.refresh()
endfunction

" }}}1
function! s:labels.syntax() dict " {{{1
  syntax match VimtexLabelsLine /^.*$/      contains=@Tex
  syntax match VimtexLabelsChap /^chap:.*$/ contains=@Tex
  syntax match VimtexLabelsEq   /^eq:.*$/   contains=@Tex
  syntax match VimtexLabelsFig  /^fig:.*$/  contains=@Tex
  syntax match VimtexLabelsSec  /^sec:.*$/  contains=@Tex
  syntax match VimtexLabelsTab  /^tab:.*$/  contains=@Tex
  syntax match VimtexLabelsHelp /^.*: .*/
endfunction

" }}}1
