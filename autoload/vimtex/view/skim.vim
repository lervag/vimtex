" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#skim#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({
      \ 'name' : 'Skim',
      \ 'startskim' : 'open -a Skim',
      \})

function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  let self.cmd_view_callback = join([
        \ 'osascript',
        \ '-e ''set theFile to POSIX file "' . a:outfile . '"''',
        \ '-e ''set thePath to POSIX path of (theFile as alias)''',
        \ '-e ''tell application "Skim"''',
        \ '-e ''try''',
        \ '-e ''set theDocs to get documents whose path is thePath''',
        \ '-e ''if (count of theDocs) > 0 then revert theDocs''',
        \ '-e ''end try''',
        \ '-e ''open theFile''',
        \ '-e ''end tell''',
        \])

  call vimtex#jobs#run(self.cmd_view_callback)
endfunction

" }}}1

function! s:viewer._check() dict abort " {{{1
  " Check if Skim is installed
  let l:output = vimtex#jobs#capture(
        \ 'osascript -e '
        \ . '''tell application "Finder" to get id of application "Skim"''')

  if l:output[0] !~# '^net.sourceforge.skim-app'
    call vimtex#log#error('Skim is not installed!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  let self.cmd_view = join([
        \ 'osascript',
        \ '-e ''set theLine to ' . line('.') . ' as integer''',
        \ '-e ''set theFile to POSIX file "' . a:outfile . '"''',
        \ '-e ''set thePath to POSIX path of (theFile as alias)''',
        \ '-e ''set theSource to POSIX file "' . expand('%:p') . '"''',
        \ '-e ''tell application "Skim"''',
        \ '-e ''try''',
        \ '-e ''set theDocs to get documents whose path is thePath''',
        \ '-e ''if (count of theDocs) > 0 then revert theDocs''',
        \ '-e ''end try''',
        \ '-e ''open theFile''',
        \ '-e ''tell front document to go to TeX line theLine from theSource',
        \ g:vimtex_view_skim_reading_bar ? 'showing reading bar true''' : '''',
        \ g:vimtex_view_skim_activate ? '-e ''activate''' : '',
        \ '-e ''end tell''',
        \])

  call vimtex#jobs#run(self.cmd_view)
endfunction

" }}}1
function! s:viewer._latexmk_append_argument() dict abort " {{{1
  return vimtex#compiler#latexmk#wrap_option('pdf_previewer', self.startskim)
endfunction

" }}}1
