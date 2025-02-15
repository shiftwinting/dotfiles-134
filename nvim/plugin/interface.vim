" The default mapping for clearing the screen is <CTRL-L> which I override to
" move around windows, and the :mode command is unintitively named at best.
" However, vim-sensible overrides the default mapping to also do :nohlsearch
" and :diffupdate. The first one doesn't exactly match the purpose of the key,
" but the latter may be useful.
" <https://github.com/tpope/vim-sensible/blob/2d9f34c09f548ed4df213389caa2882bfe56db58/plugin/sensible.vim#L35>
command! -bar ClearScreen exe 'mode' | if has('diff') | exe 'diffupdate' | endif

" Replicate the behavior of Zsh's complist module under my configuration.
" 1st <Tab> - complete till the longest common prefix (longest).
" 2nd <Tab> - list the matches, but don't select or complete anything yet (list).
" 3rd <Tab> - start the selection menu (i.e. wildmenu), select and complete the first match (full).
set wildmenu wildmode=longest,list,full

" always show the sign column
set signcolumn=yes

" Show the currently typed editing command (or the size of the Visual-mode
" selected area) in the bottom right corner.
set showcmd

" enable bell everywhere
set belloff=

set title
let s:username = $USER
let s:hostname = substitute(hostname(), '\v^([^.]*).*$', '\1', '')  " get hostname up to the first '.'
let &titlestring = $USER . '@' . s:hostname . ': %F%m (' . (has('nvim') ? 'nvim' : 'vim') . ')'

" Yes, I occasionally use mouse. Sometimes it is handy for switching windows/buffers
set mouse=a
" <RightMouse> pops up a context menu
" <S-LeftMouse> extends a visual selection
set mousemodel=popup

" Crank up the command-line history size to the maximum!
let &history = max([&history, 10000])


" Buffers {{{

  set hidden

  " open diffs in vertical splits by default
  set diffopt+=vertical

  " Don't print filename and cursor position when switching between files.
  set shortmess+=F

  " buffer navigation {{{
    nnoremap <silent> <Tab>   <Cmd>bnext<CR>
    nnoremap <silent> <S-Tab> <Cmd>bprev<CR>
    nnoremap <silent> gb      <Cmd>buffer#<CR>
  " }}}

  " ask for confirmation when closing unsaved buffers
  set confirm

  " Bbye with confirmation, or fancy buffer closer {{{
    function! s:CloseBuffer(cmd) abort
      let cmd = a:cmd
      if &confirm && &modified
        let fname = expand('%')
        if empty(fname)
          " <https://github.com/neovim/neovim/blob/47f99d66440ae8be26b34531989ac61edc1ad9fe/src/nvim/ex_docmd.c#L9327-L9337>
          let fname = 'Untitled'
        endif
        " <https://github.com/neovim/neovim/blob/a282a177d3320db25fa8f854cbcdbe0bc6abde7f/src/nvim/ex_cmds2.c#L1400>
        let answer = confirm("Save changes to \"".fname."\"?", "&Yes\n&No\n&Cancel")
        if answer ==# 1      " Yes
          write
        elseif answer ==# 2  " No
          let cmd .= '!'
        else                 " Cancel/Other
          return
        endif
      endif
      execute cmd
    endfunction
  " }}}

  " closing buffers {{{
    " NOTE: Don't use :Bwipeout! For example, it breaks qflist/loclist
    " switching because when these lists are loaded, they also create (but not
    " load) buffers for all of the mentioned files, and should a buffer be
    " deleted entirely, switching to that buffer starts to fail with E92.
    nnoremap <silent> <BS>  <Cmd>call <SID>CloseBuffer('Bdelete')<CR>
    nnoremap <silent> <Del> <Cmd>call <SID>CloseBuffer('Bdelete')<bar>quit<CR>
  " }}}

" }}}


" Windows {{{

  " Smooth horizontal scrolling, basically.
  set sidescroll=1

  " When `wrap` is on and the last line doesn't fit on the screen, display it
  " partially with @@@ at the end.
  set display+=lastline

  for s:key in ['h', 'j', 'k', 'l']
    for s:mode in ['n', 'x']
      execute s:mode.'noremap <C-'.s:key.'> <C-w>'.s:key
    endfor
  endfor

  " switch to previous window
  nnoremap <C-\> <C-w>p
  xnoremap <C-\> <C-w>p

  " don't automatically make all windows the same size
  set noequalalways

  nnoremap <silent> <A-BS> <Cmd>quit<CR>

  " Split-and-go-back. Particularly useful after go-to-definition.
  nnoremap <leader>v <Cmd>vsplit<CR><C-O>

" }}}


" Airline (statusline) {{{

  " Always show the statusline (even if there is only one window).
  set laststatus=2

  function! s:on_airline_toggled(is_on)
    let &g:showmode = !a:is_on
    let &g:ruler = !a:is_on
  endfunction
  augroup dotfiles_airline
    autocmd!
    autocmd User AirlineToggledOff call s:on_airline_toggled(0)
    autocmd User AirlineToggledOn  call s:on_airline_toggled(1)
  augroup END
  call s:on_airline_toggled(0)

  let g:airline_theme = 'dotfiles'
  let g:airline_symbols = {
    \ 'readonly': 'RO',
    \ 'whitespace': '',
    \ 'colnr': ' :',
    \ 'linenr': ' :',
    \ 'maxlinenr': ' ',
    \ 'branch': '',
    \ 'notexists': ' [?]',
    \ }

  " <https://github.com/vim-airline/vim-airline/issues/1779>
  let g:airline_highlighting_cache = 1

  let g:airline_extensions = [
    \ 'quickfix',
    \ 'fzf',
    \ 'term',
    \ 'whitespace',
    \ 'wordcount',
    \ 'tabline',
    \ 'dotfiles_tweaks',
    \ 'dotfiles_filesize',
    \ ]
  if dotfiles#plugman#is_registered('vim-fugitive')
    let g:airline_extensions += ['branch', 'fugitiveline']
  endif
  if dotfiles#plugman#is_registered('vim-gitgutter') || dotfiles#plugman#is_registered('vim-signify')
    let g:airline_extensions += ['hunks']
  endif
  if dotfiles#plugman#is_registered('coc.nvim')
    let g:airline_extensions += ['coc', 'dotfiles_coclist']
  endif
  if dotfiles#plugman#is_registered('vim-obsession')
    let g:airline_extensions += ['obsession']
  endif

  let g:airline_detect_iminsert = 1
  let g:airline#extensions#tabline#left_sep = ' '
  let g:airline#extensions#tabline#left_alt_sep = ''

" }}}


" FZF {{{
  nnoremap <silent> <F1>      <Cmd>Helptags<CR>
  nnoremap <silent> <leader>f <Cmd>Files<CR>
  nnoremap <silent> <leader>b <Cmd>Buffers<CR>
  " <https://github.com/junegunn/fzf/blob/764316a53d0eb60b315f0bbcd513de58ed57a876/src/tui/tui.go#L496-L515>
  let $FZF_DEFAULT_OPTS = '--color=16'
  let g:fzf_layout = { 'down': '~40%' }
  let g:fzf_preview_window = ['right:noborder', 'ctrl-/']

  command! -bar -bang -nargs=0 FilesRuntime Files<bang> $VIMRUNTIME
  command! -bar -bang -nargs=* -complete=custom,dotfiles#plugman#command_completion FilesPlugins
    \ if empty(<q-args>)
    \|  execute 'Files<bang>' fnameescape(dotfiles#plugman#plugins_dir)
    \|elseif dotfiles#plugman#is_registered(<q-args>)
    \|  execute 'Files<bang>' fnameescape(dotfiles#plugman#get_installed_dir(<q-args>))
    \|else
    \|  echohl WarningMsg
    \|  echomsg 'Plugin not found: ' . string(<q-args>)
    \|  echohl None
    \|endif
" }}}


" quickfix/location list {{{
  nmap [q <Plug>(qf_qf_previous)
  nmap ]q <Plug>(qf_qf_next)
  nmap [l <Plug>(qf_loc_previous)
  nmap ]l <Plug>(qf_loc_next)
  nmap Q <Plug>(qf_qf_toggle)
  let g:qf_mapping_ack_style = 1
" }}}


nnoremap <silent> <F9> <Cmd>make!<CR>


if exists('*api_info')
  command! -bar -bang NvimApiCheatSheet call dotfiles#nvim_api_cheat_sheet#print()
endif


" uptime {{{
  function! Uptime() abort
    let time = float2nr(localtime() - g:dotfiles_boot_localtime)
    let d = time / 60 / 60 / 24
    let h = time / 60 / 60 % 24
    let m = time / 60 % 60
    let s = time % 60
    return (d > 0 ? printf('%dd ', d) : '') . printf('%02d:%02d:%02d', h, m, s)
  endfunction
  command! -bar Uptime echo Uptime()
" }}}
