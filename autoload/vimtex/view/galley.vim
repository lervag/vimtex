" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#galley#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({'name': 'Galley'})

function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  call s:view(
        \ a:outfile,
        \ g:vimtex_view_automatic && !has_key(self, 'started_through_callback'),
        \ g:vimtex_view_galley_sync)
  let self.started_through_callback = 1
endfunction

" }}}1

function! s:viewer._check() dict abort " {{{1
  let l:output = vimtex#jobs#capture(
        \ 'osascript -l JavaScript -e ''Application("GalleyPDF").id()''')

  if join(l:output) !~# 'com.github.munepi.galley'
    call vimtex#log#error('Galley is not installed!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  call s:view(a:outfile, 1, 1)
endfunction

" }}}1


function! s:view(outfile, open, sync) abort " {{{1
  " Galley uses a custom URL scheme (galleypdf://) for editor integration.
  " We open the PDF with `open -a GalleyPDF` and perform forward search through
  " the `galleypdf://forward` endpoint. See https://github.com/munepi/Galley
  " for more details.
  let l:background = g:vimtex_view_galley_activate ? '' : '-g '

  if a:open
    call vimtex#jobs#run(printf('open %s-a GalleyPDF %s',
          \ l:background,
          \ vimtex#util#shellescape(a:outfile)))
  endif

  if a:sync
    " Note: We pass the 1-indexed column from Vim. This is always positive,
    "       which avoids Galley's "column 0" workaround (shifting to line + 1).
    let l:url = printf(
          \ 'galleypdf://forward?line=%d&column=%d&pdfpath=%s&srcpath=%s',
          \ line('.'), col('.'),
          \ vimtex#util#url_encode(a:outfile),
          \ vimtex#util#url_encode(expand('%:p')))
    call vimtex#jobs#run(printf('open %s"%s"', l:background, l:url))
  endif
endfunction

" }}}1
