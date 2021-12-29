" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#skim#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({'name': 'Skim'})

function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  call vimtex#jobs#run(s:make_cmd_view(a:outfile, g:vimtex_view_skim_sync))
endfunction

" }}}1

function! s:viewer._check() dict abort " {{{1
  let l:output = vimtex#jobs#capture(
        \ 'osascript -l JavaScript -e ''Application("Skim").id()''')

  if l:output[0] !~# '^net.sourceforge.skim-app'
    call vimtex#log#error('Skim is not installed!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  call vimtex#jobs#run(s:make_cmd_view(a:outfile, 1))
endfunction

" }}}1


function! s:make_cmd_view(outfile, sync) abort " {{{1
  let cmd_view = join([ 'osascript -l JavaScript -e ''',
        \ 'var app = Application("Skim");',
        \ 'var theFile = Path("' . a:outfile . '");',
        \ 'try { var theDocs = app.documents.whose({ file: { _equals: theFile }});',
        \ 'if (theDocs.length > 0) app.revert(theDocs) }',
        \ 'catch (e) {};',
        \ 'app.open(theFile);' ])
  if a:sync
    let cmd_view .= join([
          \ 'app.documents[0].go({ to: app.texLines[' . (line('.')-1) . '],',
          \ 'from: Path("'. expand('%:p') . '")',
          \ (g:vimtex_view_skim_reading_bar ? ', showingReadingBar: true' : ''),
          \ '});' ])
  endif
  if g:vimtex_view_skim_activate
    let cmd_view .= 'app.activate();'
  endif
  return cmd_view . ''''
endfunction

