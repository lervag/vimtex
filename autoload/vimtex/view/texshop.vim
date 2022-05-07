" texshop.vim
"
" SHORT DESCRIPTION
" Support for TeXShop as a pdf viewer on Mac OS X 
" in conjunction with Karl Yngve Lervåg's vimtex
" package for vim. 
"
" LONG DESCRIPTION 
" texshop.vim aims to support TeXShop as a viewer,
" following the approach suggested by TeXShop developer
" Richard Koch for interaction with external editors
" in TeXShop release notes for versions 4.24 and 4.25:  
" https://pages.uoregon.edu/koch/texshop/changes_3.html
" 
" texshop.vim calls TeXShop directly via an embedded
" AppleScript rather than calling an intermediary
" bash script (which is what was described by Koch). 
" Note that when TeXShop is used as a viewer for
" PDF files created via a .tex file, with 
" an external editor, it wants to know about the .tex
" file rather than the PDF (as TeXShop is able to trigger
" compilation on its own, with a built-in console and
" Goto error button, which takes the user directly to the 
" correct line in the corresponding .tex file, in the
" preferred text editor, provided it is set up correctly.).
"
" SETTING UP TeXShop TO INTERACT WITH MacVim
"
" Setup for TeXShop to interact correctly with MacVim
"
" 1. TeXShop requires the following preferences to be set:
"
" defaults write TeXShop OtherEditorSync YES
" defaults write TeXShop UseExternalEditor -bool true 
"
" 2. When using an external editor with TeXShop, it 
" expects to find a script /usr/local/bin/othereditor
" which it can call when syncing to the .tex file. The
" content of the script should be as follows: 
"  
" #!/bin/bash
" TEXLINE=$1
" TEXFILE=$2
" /usr/local/bin/mvim --remote-silent +$TEXLINE "$TEXFILE" 
" 
" This file needs to be executable:
" chmod +x /usr/local/bin/othereditor
"
" 3. .vimrc should contain set the vimtex_view_method to 'texshop' 
" let g:vimtex_view_method='texshop'
" and, depending on whether the pdf window is to be activated 
" (brought to the foreground) upon compilation completion or
" request for view update, set the variable to true (1) or false (0): 
" let g:vimtex_view_texshop_activate=1 
" Note that the first time the tex is compiled,
" TeXShop will be ready but the document won't be visible until 
" <localleader>lv is called to show the document (if the variable is
" set to 1, the focus will be on the window, if it is 9 it will
" remain in the background.)
"
" SUPPORTED FEATURES
"
" 1. Command-click (in TeXShop) in a PDF created with pdftex 
" compilation option --synctex=1 will take user to MacVim
" at the corresponding line in the .tex source code.
" 2. <localleader>lv within MacVim will take user to the 
" corresponding place in the PDF, within TeXShop.
" 3. If the PDF is compiled with TeXShop and an error arises,
" the 'Goto Error' button in TeXShop's compilation console 
" window (or using the keyboard shortcut ⌘^E) will take the
" user to the error line in MacVim.  
"
" CREATION HISTORY
" Nov 1 2020 This file (texshop.vim) was created by Michael Liebling
" and is largely based on skim.vim (from the vimtex
" package) and the scripts described in the TeXShop
" release notes for version 4.24 and 4.25.
" Minor parts were also inspired from a former latex-suite
" implementation.

function! vimtex#view#texshop#new() abort " {{{1
  " Check if TeXShop is installed
  let l:cmd = join([
        \ 'osascript -e ',
        \ '''tell application "Finder" to POSIX path of ',
        \ '(get application file id (id of application "TeXShop") as alias)''',
        \])

  if system(l:cmd)
    call vimtex#log#error('TeXShop is not installed!')
    return {}
  endif

  augroup vimtex_view_texshop
    autocmd!
    autocmd User VimtexEventCompileSuccess
            \ call vimtex#view#texshop#compiler_callback()
  augroup END

  return vimtex#view#common#apply_common_template(deepcopy(s:texshop))
endfunction

" }}}1
function! vimtex#view#texshop#compiler_callback() abort " {{{1
  if !exists('b:vimtex.viewer') | return | endif
  let self = b:vimtex.viewer
  if !filereadable(self.out()) | return | endif

  let l:cmd = join([
        \ 'osascript',
        \ '-e ''set theFile to POSIX file "' . self.out() . '"''',
        \ '-e ''set thePath to POSIX path of (theFile as alias)''',
        \ '-e ''tell application "TeXShop"''',
        \ '-e ''try''',
        \ '-e ''set theDocs to get documents whose path is thePath''',
        \ '-e ''if (count of theDocs) > 0 then revert theDocs''',
        \ '-e ''end try''',
        \ '-e ''open theFile''',
        \ '-e ''end tell''',
        \])

  let b:vimtex.viewer.process = vimtex#process#start(l:cmd)
endfunction

" }}}1

let s:texshop = {
      \ 'name' : 'TeXShop',
      \ 'starttexshop' : 'open -a TeXShop',
      \}

function! s:texshop.view(file) dict abort " {{{1
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

" Define variables for the source file, line and column numbers: 
  let sourcefile = shellescape(expand('%'), 1)
  let sourcefileFull = shellescape(expand('%:p'), 1)
  let linenr = line('.')
  let colnr = col('.')

" The applescript described in 
" https://pages.uoregon.edu/koch/texshop/changes_3.html 
" (Release notes for TeXShop 4.25) is directly integrated
" below: 
  let l:cmd = join([
        \ 'osascript',
        \ '-e ''set MyAppVarLine to ' . linenr . ' as integer''',
        \ '-e ''set MyAppVarCol to ' . colnr . ' as integer''',
        \ '-e ''set MyAppVarTeXFile to "' . sourcefileFull . '"''',
        \ '-e ''set MyAppVarPDFFile to "' . outfile . '"''',
        \ '-e ''tell application "TeXShop"''',
        \ '-e ''  open MyAppVarTeXFile''',
        \ '-e ''  set the front_document to the front document''',
        \ '-e ''  tell front_document''',
        \ '-e ''    sync_preview_line theLine MyAppVarLine''',
        \ '-e ''    sync_preview_index theIndex MyAppVarCol''',
        \ '-e ''    sync_preview_name theName MyAppVarTeXFile''',
        \ g:vimtex_view_texshop_activate ? '-e ''activate''' : '',
        \ '-e ''    return 0''',
        \ '-e ''  end tell''',
        \ '-e ''end tell''',
        \])
" An alternative way of defining the command could have been
" to use a bash script that encapsulates the Applescript (has
" the advantage that the bashscript can be tested on its own) 
"  let l:cmd = '/usr/local/bin/ExternalSync '
"  let l:cmd .= join([linenr, colnr , sourcefileFull, outfile])

  let self.process = vimtex#process#start(l:cmd)

  if exists('#User#VimtexEventView')
    doautocmd <nomodeline> User VimtexEventView
  endif
endfunction

" }}}1
function! s:texshop.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files || g:vimtex_view_automatic
    return ' -view=none'
  else
    return vimtex#compiler#latexmk#wrap_option('pdf_previewer', self.starttexshop)
  endif
endfunction

" }}}1
