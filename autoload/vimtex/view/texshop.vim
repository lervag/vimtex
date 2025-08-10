" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#texshop#new() abort " {{{1
  return s:viewer.init()
endfunction

" }}}1


let s:viewer = vimtex#view#_template#new({'name': 'TeXShop'})

function! s:viewer.compiler_callback(outfile) dict abort " {{{1
  let cmd = s:make_cmd_view(
        \ a:outfile,
        \ g:vimtex_view_automatic && !has_key(self, 'started_through_callback'),
        \ g:vimtex_view_texshop_sync)
  call vimtex#jobs#run(cmd)
  let self.started_through_callback = 1
endfunction

" }}}1

function! s:viewer._check() dict abort " {{{1
  let l:output = vimtex#jobs#capture(
        \ 'osascript -l JavaScript -e ''Application("TeXShop").id()''')

  if join(l:output) !~# 'TeXShop'
    call vimtex#log#error('TeXShop is not installed!')
    return v:false
  endif

  return v:true
endfunction

" }}}1
function! s:viewer._start(outfile) dict abort " {{{1
  call vimtex#jobs#run(s:make_cmd_view(a:outfile, 1, 1))
endfunction

" }}}1


function! s:make_cmd_view(outfile, open, sync) abort " {{{1
  let l:scriptview = [
        \ 'osascript',
        \ '-e ''set theFile to POSIX file "' . a:outfile . '"''',
        \ '-e ''set thePath to POSIX path of (theFile as alias)''',
        \ '-e ''tell application "TeXShop"''',
        \ '-e ''try''',
        \ '-e ''set theDocs to get documents whose path is thePath''',
        \ '-e ''if (count of theDocs) > 0 then revert(theDocs)''',
        \ '-e ''end try''',
        \ a:open ? '-e ''open theFile''' : '',
        \ g:vimtex_view_texshop_activate ? '-e ''activate''' : '',
        \ '-e ''end tell''',
        \]
  let l:script = join(l:scriptview)

  " Define variables for the source file, line and column numbers:
  let l:sourcefile = shellescape(expand('%'), 1)
  let l:sourcefileFull = expand('%:p')
  let l:linenr = line('.')
  let l:colnr = col('.')

  " The following applescript is based on the release notes for TeXShop 4.25:
  " https://pages.uoregon.edu/koch/texshop/changes_3.html
  let l:scriptsync = [
        \ 'osascript',
        \ '-e ''set currentLine to ' . l:linenr . ' as integer''',
        \ '-e ''set currentCol to ' . l:colnr . ' as integer''',
        \ '-e ''set currentTeXFile to "' . l:sourcefileFull . '"''',
        \ '-e ''set currentPDFFile to "' . a:outfile . '"''',
        \ '-e ''tell application "TeXShop"''',
        \ a:open ? '-e ''  open currentTeXFile''' : '',
        \ '-e ''  set the front_document to the front document''',
        \ '-e ''  tell front_document''',
        \ '-e ''    sync_preview_line theLine currentLine''',
        \ '-e ''    sync_preview_index theIndex currentCol''',
        \ '-e ''    sync_preview_name theName currentTeXFile''',
        \ g:vimtex_view_texshop_activate ? '-e ''activate''' : '',
        \ '-e ''    return 0''',
        \ '-e ''  end tell''',
        \ '-e ''end tell''',
        \]

  if a:sync
    let l:script = join(l:scriptsync)
  endif

  return printf(l:script)
endfunction

" }}}1
