" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#misc#init_buffer() " {{{1
  command! -buffer -bang        VimtexInfo                                call vimtex#misc#info(<q-bang> == '!')
  command! -buffer              VimtexReload                              call vimtex#misc#reload()
  command! -buffer -bang        VimtexCountWords                          call vimtex#misc#wc('', <q-bang> == '!')
  command! -buffer -bang        VimtexCountLetters                        call vimtex#misc#wc('', <q-bang> == '!', 1)
  command! -buffer -bang -range VimtexCountSelectedWords   <line1>,<line2>call vimtex#misc#wc('cmd', <q-bang> == '!')
  command! -buffer -bang -range VimtexCountSelectedLetters <line1>,<line2>call vimtex#misc#wc('cmd', <q-bang> == '!', 1)

  nnoremap <buffer> <plug>(vimtex-info)      :VimtexInfo<cr>
  nnoremap <buffer> <plug>(vimtex-info-full) :VimtexInfo!<cr>
  nnoremap <buffer> <plug>(vimtex-reload)    :VimtexReload<cr>
endfunction

" }}}1

function! vimtex#misc#info(global) abort " {{{1
  if a:global
    for l:data in values(g:vimtex_data)
      call vimtex#echo#pprint(l:data)
    endfor
  else
    call vimtex#echo#pprint(b:vimtex)
  endif
endfunction

" }}}1
function! vimtex#misc#wc(type, detailed, ...) abort range " {{{1
  if empty(a:type)
    let l:file = b:vimtex
  else
    let l:file = vimtex#parser#selection_to_texfile(a:type)
  endif

  " Run texcount, save output to lines variable
  let cmd  = 'cd ' . vimtex#util#shellescape(l:file.root)
  let cmd .= '; texcount -nosub -sum '
  let cmd .= a:0 > 0 ? '-letter ' : ''
  let cmd .= a:detailed > 0 ? '-inc ' : '-merge '
  let cmd .= vimtex#util#shellescape(l:file.base)
  let lines = split(system(cmd), '\n')

  " Create wordcount window
  if bufnr('TeXcount') >= 0
    bwipeout TeXcount
  endif
  split TeXcount

  " Add lines to buffer
  for line in lines
    call append('$', printf('%s', line))
  endfor
  0delete _

  " Set mappings
  nnoremap <buffer> <silent> q :bwipeout<cr>

  " Set buffer options
  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal cursorline
  setlocal nobuflisted
  setlocal nolist
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal tabstop=8
  setlocal nomodifiable

  " Set highlighting
  syntax match TexcountText  /^.*:.*/ contains=TexcountValue
  syntax match TexcountValue /.*:\zs.*/
  highlight link TexcountText  VimtexMsg
  highlight link TexcountValue Constant
endfunction

" }}}1
" {{{1 function! vimtex#misc#reload()
if get(s:, 'reload_guard', 1)
  function! vimtex#misc#reload() abort
    let s:reload_guard = 0

    for l:file in glob(fnamemodify(s:file, ':h') . '/../**/*.vim', 0, 1)
      execute 'source' l:file
    endfor

    call remove(g:vimtex_data, b:vimtex_id)
    call vimtex#init()

    " Reload indent file
    if exists('b:did_vimtex_indent')
      unlet b:did_indent
      runtime indent/tex.vim
    endif

    call vimtex#echo#info('reloaded')
    unlet s:reload_guard
  endfunction
endif

" }}}1

let s:file = expand('<sfile>')

" vim: fdm=marker sw=2
