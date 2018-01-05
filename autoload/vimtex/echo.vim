" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#echo#echo(message) " {{{1
  echohl VimtexMsg
  echo a:message
  echohl None
endfunction

" }}}1
function! vimtex#echo#input(opts) " {{{1
  if has_key(a:opts, 'info')
    call vimtex#echo#formatted(a:opts.info)
  endif

  let l:args = [get(a:opts, 'prompt', '> ')]
  if has_key(a:opts, 'complete')
    let l:args += ['', a:opts.complete]
  endif

  echohl VimtexMsg
  let l:reply = call('input', l:args)
  echohl None
  return l:reply
endfunction

" }}}1
function! vimtex#echo#formatted(parts) " {{{1
  echo ''
  try
    for part in a:parts
      if type(part) == type('')
        echohl VimtexMsg
        echon part
      else
        execute 'echohl' part[0]
        echon part[1]
      endif
      unlet part
    endfor
  finally
    echohl None
  endtry
endfunction

" }}}1
