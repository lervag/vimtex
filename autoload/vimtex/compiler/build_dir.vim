" VimTeX - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" This module provides some common utilize functions for setting the build_dir
" option. It allows to avoid redundant code in the various compilers.

function! vimtex#compiler#build_dir#materialize(self) abort " {{{1
  if type(a:self.build_dir) != v:t_func | return | endif

  try
    let a:self.build_dir = a:self.build_dir()
  catch
    call vimtex#log#error(
          \ 'Could not expand build_dir function!',
          \ v:exception)
    let a:self.build_dir = ''
  endtry
endfunction

" }}}1
function! vimtex#compiler#build_dir#respect_envvar(self) abort " {{{1
  " Specifying the build_dir by environment variable should override the
  " current value.
  if empty($VIMTEX_OUTPUT_DIRECTORY) | return | endif

  if !empty(a:self.build_dir)
        \ && (a:self.build_dir !=# $VIMTEX_OUTPUT_DIRECTORY)
    call vimtex#log#warning(
          \ 'Setting VIMTEX_OUTPUT_DIRECTORY overrides build_dir!',
          \ 'Changed build_dir from: ' . a:self.build_dir,
          \ 'Changed build_dir to: ' . $VIMTEX_OUTPUT_DIRECTORY)
  endif

  let a:self.build_dir = $VIMTEX_OUTPUT_DIRECTORY
endfunction

" }}}1
