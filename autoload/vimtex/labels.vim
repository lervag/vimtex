" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#labels#init(initialized) " {{{1
  call vimtex#util#set_default('g:vimtex_labels_enabled', 1)
  if !g:vimtex_labels_enabled | return | endif

  " Set some constants
  let s:name = 'Table of labels (vimtex)'

  " Define commands
  command! -buffer VimtexLabelsOpen   call vimtex#labels#open()
  command! -buffer VimtexLabelsToggle call vimtex#labels#toggle()

  " Define mappings
  nnoremap <buffer> <plug>(vimtex-labels-open)   :call vimtex#labels#open()<cr>
  nnoremap <buffer> <plug>(vimtex-labels-toggle) :call vimtex#labels#toggle()<cr>
endfunction

" }}}1
function! vimtex#labels#open() " {{{1
  if vimtex#index#open(s:name) | return | endif

  let s:preamble = 1

  let index = {}
  let index.name            = s:name
  let index.entries         = s:gather_labels(b:vimtex.tex)
  let index.all_entries     = deepcopy(index.entries)
  let index.hook_init_post  = function('s:index_hook_init_post')
  let index.help            = [
        \ 'c:       clear filters',
        \ 'f:       filter',
        \ ]
  let index.clear_filter    = function('s:index_clear_filter')
  let index.filter          = function('s:index_filter')
  let index.syntax          = function('s:index_syntax')

  call vimtex#index#create(index)
endfunction

function! vimtex#labels#toggle() " {{{1
  if vimtex#index#open(s:name)
    call vimtex#index#close(s:name)
  else
    call vimtex#labels#open()
    silent execute 'wincmd w'
  endif
endfunction

" }}}1

function! s:index_clear_filter() dict "{{{1
  let self.entries = copy(self.all_entries)
  call self.refresh()
endfunction

" }}}1
function! s:index_filter() dict "{{{1
  let filter = input('filter by: ')
  let self.entries = filter(self.entries, 'v:val.title =~# filter') 
  call self.refresh()
endfunction

" }}}1
function! s:index_hook_init_post() dict " {{{1
  nnoremap <buffer> <silent> c :call b:index.clear_filter()<cr>
  nnoremap <buffer> <silent> f :call b:index.filter()<cr>
endfunction

" }}}1
function! s:index_syntax() dict " {{{1
  syntax match VimtexLabelsHelp /^.*: .*/
  syntax match VimtexLabelsLine /^.*$/      contains=@Tex
  syntax match VimtexLabelsChap /^chap:.*$/ contains=@Tex
  syntax match VimtexLabelsEq   /^eq:.*$/   contains=@Tex
  syntax match VimtexLabelsFig  /^fig:.*$/  contains=@Tex
  syntax match VimtexLabelsSec  /^sec:.*$/  contains=@Tex
  syntax match VimtexLabelsTab  /^tab:.*$/  contains=@Tex

  highlight link VimtexLabelsHelp helpVim
  highlight link VimtexLabelsLine Todo
  highlight link VimtexLabelsChap PreProc
  highlight link VimtexLabelsEq   Statement
  highlight link VimtexLabelsFig  Identifier
  highlight link VimtexLabelsSec  Type
  highlight link VimtexLabelsTab  String
endfunction

" }}}1

" {{{1 TOL variables

let s:preamble = 1
let s:re_input = '\v^\s*\\%(input|include)\s*\{'
let s:re_input_file = s:re_input . '\zs[^\}]+\ze}'
let s:re_label = '\v\\label\{'
let s:re_label_title = s:re_label . '\zs.{-}\ze\}?\s*$'

" }}}1

function! s:gather_labels(file) " {{{1
  let tac = []
  let lnum = 0
  for line in readfile(a:file)
    let lnum += 1

    if line =~# '\v^\s*\\begin\{document\}'
      let s:preamble = 0
    endif

    if line =~# s:re_input && !s:preamble
      call extend(tac, s:gather_labels(s:gather_labels_input(line, a:file)))
      continue
    endif

    if line =~# s:re_label
      call add(tac, {
            \ 'title' : matchstr(line, s:re_label_title),
            \ 'file'  : a:file,
            \ 'line'  : lnum,
            \ })
      continue
    endif
  endfor

  return tac
endfunction

" }}}1
function! s:gather_labels_input(line, file) " {{{1
  let l:file = matchstr(a:line, s:re_input_file)

  " Trim whitespaces from beginning and end of string
  let l:file = substitute(l:file, '^\s*', '', '')
  let l:file = substitute(l:file, '\s*$', '', '')

  " Ensure file has extension
  if l:file !~# '.tex$'
    let l:file .= '.tex'
  endif

  " Only return full path names
  if l:file !~# '\v^(\/|[A-Z]:)'
    let l:file = fnamemodify(a:file, ':p:h') . '/' . l:file
  endif

  " Only return filename if it is readable
  if filereadable(l:file)
    return l:file
  else
    return ''
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
