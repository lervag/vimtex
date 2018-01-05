" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#debug#stacktrace(...) " {{{1
  "
  " This function builds on Luc Hermite's answer on Stack Exchange:
  " http://vi.stackexchange.com/a/6024/21
  "

  "
  " Get stack and exception
  "
  if empty(v:throwpoint)
    try
      throw 'dummy'
    catch
      let l:stack = reverse(split(v:throwpoint, '\.\.'))[1:]
      let l:exception = 'Manual stacktrace'
    endtry
  else
    let l:stack = reverse(split(v:throwpoint, '\.\.'))
    let l:exception = v:exception
  endif

  "
  " Build the quickfix entries
  "
  let l:qflist = []
  let l:files = {}
  for l:func in l:stack
    try
      let [l:name, l:offset] = (l:func =~# '\S\+\[\d')
            \ ? matchlist(l:func, '\(\S\+\)\[\(\d\+\)\]')[1:2]
            \ : matchlist(l:func, '\(\S\+\), line \(\d\+\)')[1:2]
    catch
      let l:name = l:func
      let l:offset = 0
    endtry

    if l:name =~# '\v(\<SNR\>|^)\d+_'
      let l:sid = matchstr(l:name, '\v(\<SNR\>|^)\zs\d+\ze_')
      let l:name  = substitute(l:name, '\v(\<SNR\>|^)\d+_', 's:', '')
      let l:filename = map(
            \ vimtex#util#command('scriptnames'),
            \ 'split(v:val, "\\v:=\\s+")[1]')[l:sid-1]
    else
      let l:name = l:name
      let l:filename = matchstr(
            \ vimtex#util#command('verbose function ' . l:name)[1],
            \ '.\{-}\s\+\zs\f\+$')
    endif

    let l:filename = fnamemodify(l:filename, ':p')
    if filereadable(l:filename)
      if !has_key(l:files, l:filename)
        let l:files[l:filename] = reverse(readfile(l:filename))
      endif

      let l:lnum = l:offset + len(l:files[l:filename])
            \ - match(l:files[l:filename], '^\s*fu\%[nction]!\=\s\+' . l:name)
      let l:text = len(l:qflist) == 0 ? l:exception : '#' . len(l:qflist)

      call add(l:qflist, {
            \ 'filename': l:filename,
            \ 'function': l:name,
            \ 'lnum': l:lnum,
            \ 'text': l:text,
            \})
    endif
  endfor

  if a:0 > 0
    call setqflist(l:qflist)
    execute 'copen' len(l:qflist) + 2
    wincmd p
  endif

  return l:qflist
endfunction

" }}}1
