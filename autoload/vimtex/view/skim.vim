" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#skim#new() " {{{1
  " Check if the displayline tool is executable
  if !executable(s:skim.displayline)
    call vimtex#log#error('Skim (displayline) is not executable!')
    return {}
  endif

  return vimtex#view#common#apply_common_template(deepcopy(s:skim))
endfunction

" }}}1

let s:skim = {
      \ 'name' : 'Skim',
      \ 'displayline' : '/Applications/Skim.app/Contents/SharedSupport/displayline',
      \ 'startskim' : 'open -a Skim',
      \}

function! s:skim.view(file) dict " {{{1
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
        \ '-e ''tell front document to go to TeX line theLine from theSource showing reading bar true''',
        \ '-e ''end tell''',
        \])

  let self.process = vimtex#process#start(l:cmd)

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:skim.compiler_callback(status) dict " {{{1
  if !a:status && g:vimtex_view_use_temp_files < 2
    return
  endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

  if !filereadable(self.out()) | return | endif

  " This opens the Skim viewer if it is not already open (and if
  " g:vimtex_view_automatic is enabled). If a viewer is already open, we use
  " some simple Osascript to make Skim reload the PDF file.
  if empty(system('pgrep Skim'))
    if g:vimtex_view_automatic
      let l:cmd = join([self.startskim, vimtex#util#shellescape(self.out())])
    endif
  else
    let l:cmd = 'osascript'
          \ . ' -e ''tell application "Skim" to revert front document'''
  endif

  let self.process = vimtex#process#start(l:cmd)
endfunction

" }}}1
function! s:skim.latexmk_append_argument() dict " {{{1
  if g:vimtex_view_use_temp_files || g:vimtex_view_automatic
    return ' -view=none'
  else
    return vimtex#compiler#latexmk#wrap_option('pdf_previewer', self.startskim)
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
