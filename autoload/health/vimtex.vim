function! health#vimtex#check() abort
  call vimtex#options#init()

  call v:lua.vim.health.start('VimTeX')

  call s:check_general()
  call s:check_plugin_clash()
  call s:check_view()
  call s:check_compiler()
endfunction

function! s:check_general() abort " {{{1
  if !has('nvim') || v:version < 800
    call v:lua.vim.health.warn('VimTeX works best with Vim 8 or neovim')
  else
    call v:lua.vim.health.ok('Vim version should have full support!')
  endif

  if !executable('bibtex')
    call v:lua.vim.health.warn('bibtex is not executable!',
          \ 'bibtex is required for cite completions.')
  endif
  if !executable('biber')
    call v:lua.vim.health.warn(
          \ 'biber is not executable!',
          \ 'Biber is often required so this may give unexpected problems.')
  endif
endfunction

" }}}1

function! s:check_compiler() abort " {{{1
  if !g:vimtex_compiler_enabled | return | endif

  if !executable(g:vimtex_compiler_method)
    let l:ind = '        '
    call v:lua.vim.health.error(printf(
          \ '|g:vimtex_compiler_method| (`%s`) is not executable!',
          \ g:vimtex_compiler_method))
    return
  endif

  call v:lua.vim.health.ok('Compiler should work!')
endfunction

" }}}1

function! s:check_plugin_clash() abort " {{{1
  " Note: This duplicates the code in after/ftplugin/tex.vim
  let l:scriptnames = vimtex#util#command('scriptnames')

  let l:latexbox = !empty(filter(copy(l:scriptnames), "v:val =~# 'latex-box'"))
  if l:latexbox
    call v:lua.vim.health.warn('Conflicting plugin detected: LaTeX-Box')
    call v:lua.vim.health.info('VimTeX does not work as expected when LaTeX-Box is installed!')
    call v:lua.vim.health.info('Please disable or remove it to use VimTeX!')
  endif
endfunction

" }}}1

function! s:check_view() abort " {{{1
  call s:check_view_{g:vimtex_view_method}()

  if executable('xdotool') && !executable('pstree')
    call v:lua.vim.health.warn('pstree is not available',
          \ 'vimtex#view#inverse_search is better if pstree is available.')
  endif
endfunction

" }}}1
function! s:check_view_general() abort " {{{1
  if executable(g:vimtex_view_general_viewer)
    call v:lua.vim.health.ok('General viewer should work properly!')
  else
    call v:lua.vim.health.error(
          \ 'Selected viewer is not executable!',
          \ '- Selection: ' . g:vimtex_view_general_viewer,
          \ '- Please see :h g:vimtex_view_general_viewer')
  endif
endfunction

" }}}1
function! s:check_view_zathura() abort " {{{1
  let l:ok = 1

  if !executable('zathura')
    call v:lua.vim.health.error('Zathura is not executable!')
    let l:ok = 0
  endif

  if !executable('xdotool')
    call v:lua.vim.health.warn('Zathura requires xdotool for forward search!')
    let l:ok = 0
  endif

  if l:ok
    call v:lua.vim.health.ok('Zathura should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_zathura_simple() abort " {{{1
  let l:ok = 1

  if !executable('zathura')
    call v:lua.vim.health.error('Zathura is not executable!')
    let l:ok = 0
  endif

  if l:ok
    call v:lua.vim.health.ok('Zathura should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_mupdf() abort " {{{1
  let l:ok = 1

  if !executable('mupdf')
    call v:lua.vim.health.error('MuPDF is not executable!')
    let l:ok = 0
  endif

  if !executable('xdotool')
    call v:lua.vim.health.warn('MuPDF requires xdotool for forward search!')
    let l:ok = 0
  endif

  if !executable('synctex')
    call v:lua.vim.health.warn('MuPDF requires synctex for forward search!')
    let l:ok = 0
  endif

  if l:ok
    call v:lua.vim.health.ok('MuPDF should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_sioyek() abort " {{{1
  let l:ok = 1

  if !executable(g:vimtex_view_sioyek_exe)
    call v:lua.vim.health.error('Sioyek is not executable!')
    let l:ok = 0
  endif

  if l:ok
    call v:lua.vim.health.ok('Sioyek should work properly!')
  endif
endfunction

" }}}1
function! s:check_view_skim() abort " {{{1
  call vimtex#jobs#run(join([
        \ 'osascript -e ',
        \ '''tell application "Finder" to POSIX path of ',
        \ '(get application file id (id of application "Skim") as alias)''',
        \]))

  if v:shell_error == 0
    call v:lua.vim.health.ok('Skim viewer should work!')
  else
    call v:lua.vim.health.error('Skim is not installed!')
  endif
endfunction

" }}}1
function! s:check_view_texshop() abort " {{{1
  let l:cmd = join([
        \ 'osascript -e ',
        \ '''tell application "Finder" to POSIX path of ',
        \ '(get application file id (id of application "TeXShop") as alias)''',
        \])

  if system(l:cmd)
    call v:lua.vim.health.error('TeXShop is not installed!')
  else
    call v:lua.vim.health.ok('TeXShop viewer should work!')
  endif
endfunction

" }}}1
