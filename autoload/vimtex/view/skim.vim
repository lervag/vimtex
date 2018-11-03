" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#skim#new() abort " {{{1
  " Check if Skim is installed
  let l:cmd = join([
        \ 'osascript -e ',
        \ '''tell application "Finder" to POSIX path of ',
        \ '(get application file id (id of application "Skim") as alias)''',
        \])

  if system(l:cmd)
    call vimtex#log#error('Skim is not installed!')
    return {}
  endif

  return vimtex#view#common#apply_common_template(deepcopy(s:skim))
endfunction

" }}}1

let s:skim = {
      \ 'name' : 'Skim',
      \ 'startskim' : 'open -a Skim',
      \}

function! s:skim.view(file) dict abort " {{{1
  if empty(a:file)
    let outfile = self.out()

    " Only copy files if they don't exist
    if g:vimtex_view_use_temp_files
          \ && vimtex#view#common#not_readable(outfile)
      call self.copy_files()
    endif
  else
    let outfile = a:file
  endif
  if vimtex#view#common#not_readable(outfile) | return | endif

  let l:cmd = join([
        \ 'osascript',
        \ '-e ''set theLine to ' . line('.') . ' as integer''',
        \ '-e ''set theFile to POSIX file "' . outfile . '"''',
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

  let self.process = vimtex#process#start(l:cmd)

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:skim.compiler_callback(status) dict abort " {{{1
  if !a:status && g:vimtex_view_use_temp_files < 2
    return
  endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

  if !filereadable(self.out()) | return | endif

  let l:cmd = join([
        \ 'osascript',
        \ '-e ''set theFile to POSIX file "' . self.out() . '"''',
        \ '-e ''set thePath to POSIX path of (theFile as alias)''',
        \ '-e ''tell application "Skim"''',
        \ '-e ''try''',
        \ '-e ''set theDocs to get documents whose path is thePath''',
        \ '-e ''if (count of theDocs) > 0 then revert theDocs''',
        \ '-e ''end try''',
        \ '-e ''open theFile''',
        \ '-e ''end tell''',
        \])

  let self.process = vimtex#process#start(l:cmd)

  if has_key(self, 'hook_callback')
    call self.hook_callback()
  endif
endfunction

" }}}1
function! s:skim.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files || g:vimtex_view_automatic
    return ' -view=none'
  else
    return vimtex#compiler#latexmk#wrap_option('pdf_previewer', self.startskim)
  endif
endfunction

" }}}1
