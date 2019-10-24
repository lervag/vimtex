" vimtex - LaTeX plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimtex#view#general#new() abort " {{{1
  " Check if the viewer is executable
  " * split to ensure that we handle stuff like "gio open"
  let l:exe = get(split(g:vimtex_view_general_viewer), 0, '')
  if empty(l:exe) || !executable(l:exe)
    call vimtex#log#warning(
          \ 'Selected viewer is not executable!',
          \ '- Selection: ' . g:vimtex_view_general_viewer .
          \ '- Executable: ' . l:exe .
          \ '- Please see :h g:vimtex_view_general_viewer')
    return {}
  endif

  " Start from standard template
  let l:viewer = vimtex#view#common#apply_common_template(deepcopy(s:general))

  " Add callback hook
  if exists('g:vimtex_view_general_callback')
    let l:viewer.compiler_callback = function(g:vimtex_view_general_callback)
  endif

  return l:viewer
endfunction

" }}}1

let s:general = {
      \ 'name' : 'General'
      \}

function! s:general.view(file) dict abort " {{{1
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

  " Update the path for Windows on cygwin
  if executable('cygpath')
    let outfile = join(
          \ vimtex#process#capture('cygpath -aw "' . outfile . '"'), '')
  endif

  if vimtex#view#common#not_readable(outfile) | return | endif

  " Parse options
  let l:cmd  = g:vimtex_view_general_viewer
  let l:cmd .= ' ' . g:vimtex_view_general_options

  " Substitute magic patterns
  let l:cmd = substitute(l:cmd, '@line', line('.'), 'g')
  let l:cmd = substitute(l:cmd, '@col', col('.'), 'g')
  let l:cmd = substitute(l:cmd, '@tex',
        \ vimtex#util#shellescape(expand('%:p')), 'g')
  let l:cmd = substitute(l:cmd, '@pdf', vimtex#util#shellescape(outfile), 'g')

  " Start the view process
  let self.process = vimtex#process#start(l:cmd, {'silent': 0})

  if has_key(self, 'hook_view')
    call self.hook_view()
  endif
endfunction

" }}}1
function! s:general.latexmk_append_argument() dict abort " {{{1
  if g:vimtex_view_use_temp_files
    return ' -view=none'
  else
    let l:option = g:vimtex_view_general_viewer
    if !empty(g:vimtex_view_general_options_latexmk)
      let l:option .= ' '
      let l:option .= substitute(g:vimtex_view_general_options_latexmk,
            \                    '@line', line('.'), 'g')
    endif
    return vimtex#compiler#latexmk#wrap_option('pdf_previewer', l:option)
  endif
endfunction

" }}}1
function! s:general.compiler_callback(status) dict abort " {{{1
  if !a:status && g:vimtex_view_use_temp_files < 2
    return
  endif

  if g:vimtex_view_use_temp_files
    call self.copy_files()
  endif

  if has_key(self, 'hook_callback')
    call self.hook_callback()
  endif
endfunction

" }}}1
