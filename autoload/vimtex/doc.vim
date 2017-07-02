" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#doc#init_buffer() " {{{1
  command! -buffer -nargs=? VimtexDoc call vimtex#doc#lookup(<q-args>)

  nnoremap <buffer> <plug>(vimtex-doc-lookup) :VimtexDoc<cr>
endfunction

" }}}1

function! vimtex#doc#lookup(word) " {{{1
  if !empty(a:word)
    let l:package = a:word
  else
    let l:cmd = vimtex#cmd#get_current()
    if get(l:cmd, 'name', '') !=# '\usepackage' | return | endif
    try
      let l:package = l:cmd.args[0].text
    catch
      let l:package = ''
    endtry
  endif

  if empty(l:package) | return | endif

  if empty(vimtex#kpsewhich#find(l:package . '.sty'))
    call vimtex#echo#warning('VimtexDoc failed; package not recognized: ' . l:package)
  else
    silent execute '!xdg-open http://texdoc.net/pkg/' . l:package . '&'
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
