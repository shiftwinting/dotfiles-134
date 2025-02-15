" The filename is totally not a reference to Arch'es package manager.

let g:dotfiles#plugman#implementation = 'vim-plug'
let g:dotfiles#plugman#inhibited_plugins = get(g:, 'dotfiles#plugman#inhibited_plugins', {})

let g:dotfiles#plugman#repo_name = 'vim-plug'
let g:dotfiles#plugman#repo = 'junegunn/' . g:dotfiles#plugman#repo_name
let s:stdpath_config = exists('*stdpath') ? stdpath('config') : expand('~/.vim')
let g:dotfiles#plugman#install_path = get(g:, 'dotfiles#plugman#install_path', s:stdpath_config . '/autoload/plug.vim')
let g:dotfiles#plugman#plugins_dir = get(g:, 'dotfiles#plugman#plugins_dir', s:stdpath_config . '/plugged')


function! dotfiles#plugman#derive_name(repo, spec) abort
  " <https://github.com/junegunn/vim-plug/blob/fc2813ef4484c7a5c080021ceaa6d1f70390d920/plug.vim#L715>
  return get(a:spec, 'as', fnamemodify(a:repo, ':t:s?\.git$??'))
endfunction

function! dotfiles#plugman#is_registered(name) abort
  return has_key(g:plugs, a:name) ? v:true : v:false
endfunction

function! dotfiles#plugman#get_installed_dir(name) abort
  return g:plugs[a:name].dir
endfunction

function! dotfiles#plugman#is_inhibited(name) abort
  return has_key(g:dotfiles#plugman#inhibited_plugins, a:name)
endfunction

function! dotfiles#plugman#auto_install() abort
  if !filereadable(g:dotfiles#plugman#install_path)
    execute '!curl -fL' shellescape('https://raw.githubusercontent.com/' . g:dotfiles#plugman#repo . '/master/plug.vim', 1) '--create-dirs -o' shellescape(g:dotfiles#plugman#install_path, 1)
  endif
endfunction

function! dotfiles#plugman#begin() abort
  call plug#begin(g:dotfiles#plugman#plugins_dir)
  call dotfiles#plugman#register(g:dotfiles#plugman#repo, { 'as': g:dotfiles#plugman#repo_name })
endfunction

" For the use by my beloved forkers of this repository.
function! dotfiles#plugman#inhibit(name) abort
  if has_key(g:plugs, a:name)
    echoerr 'Plugin' string(a:name) 'inhibited too late, it has already been registered'
  endif
  let g:dotfiles#plugman#inhibited_plugins[a:name] = 1
endfunction

function! dotfiles#plugman#register(repo, ...) abort
  if a:0 > 1 | throw 'Invalid number of arguments for function (must be 1..2): ' . a:0 | endif
  let spec = get(a:000, 0, {})
  let name = dotfiles#plugman#derive_name(a:repo, spec)
  " Ensure consistency in case the upstream algorithm changes.
  let spec['as'] = name
  if !has_key(g:dotfiles#plugman#inhibited_plugins, name)
    call plug#(a:repo, spec)
  endif
endfunction

function! dotfiles#plugman#end() abort
  call plug#end()
endfunction

function! dotfiles#plugman#check_sync() abort
  " <https://stackoverflow.com/a/13908273/12005228>
  let installed_plugins = map(filter(glob(g:dotfiles#plugman#plugins_dir . '/{,.}*/', 1, 1), 'isdirectory(v:val)'), 'fnamemodify(v:val, ":h:t")')

  " TODO: Perhaps use the old mtime-comparison approach in addition to the
  " current one?
  " <https://github.com/dmitmel/dotfiles/blob/3e272ffaaf3c386e05817a7f08d16e8cf7c4ee5c/nvim/lib/plugins.vim#L88-L108>
  let need_install = {}
  let need_clean = {}
  for name in installed_plugins
    let need_clean[name] = 1
  endfor
  for name in keys(g:plugs)
    if !has_key(g:plugs[name], 'uri')
      continue
    endif
    if has_key(need_clean, name)
      unlet need_clean[name]
    else
      let need_install[name] = 1
    endif
  endfor

  if !empty(need_install) || !empty(need_clean)
    enew
    only
    call append(0, repeat(['PLEASE, RESTART THE EDITOR ONCE PLUGIN INSTALLATION FINISHES!!!'], 5))
    if !empty(need_install)
      PlugInstall --sync
    elseif !empty(need_clean)
      PlugClean
    endif
  endif
endfunction

function! dotfiles#plugman#command_completion(arg_lead, cmd_line, cursor_pos) abort
  return join(keys(g:plugs), "\n")
endfunction
