" display line numbers on the sidebar
set number

" Display current line and column on the bottom bar
set ruler

" Set tabs to be 2 spaces wide
set tabstop=2
set shiftwidth=2

" Automatically indent code when going to the next line
set autoindent

" Expand tab characters to be spaces.
set expandtab

" highlight search results
set hlsearch

" start search without having to submit
set incsearch

" allow mouse for pasting etc
set mouse=a

"Keep 7 lines visible at the top and bottom of the screen when scrolling
set so=7

" use n and N to center the next search result on the screen
nmap n nzz
nmap N Nzz

" show whitespace
set list
set listchars=tab:>.,trail:.

" Flash on the screen instead of making the bell sound
"set noerrorbells
"set visualbell

filetype on
syntax on

" for mirroring two-peice characters
"inoremap ( ()<left>
"inoremap [ []<left>
"inoremap { {}<left>
inoremap {<CR> {<CR>}<ESC>0
inoremap {;<CR> {<CR>};<ESC>0
inoremap {<CR> {<CR>}<C-o>O

" highlighting the limit column
set colorcolumn=80
highlight ColorColumn ctermbg=8 guibg=darkgrey

" allow for jumping through words with control arrow
inoremap <C-Right> <C-\><C-O>w
inoremap <C-Left> <C-\><C-O>b
inoremap <C-BS> <C-\><C-O>b

" highlight the current line
set cursorline
"highlight CursorLine ctermbg=17 cterm=bold guifg=white guibg=darkgrey gui=bold

"colorscheme onedark
" highlight CursorColumn ctermfg=white ctermbg=yellow cterm=bold guifg=white guibg=yellow gui=bold