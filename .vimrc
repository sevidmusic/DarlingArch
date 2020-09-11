set number
set relativenumber
set ruler
set t_Co=256
set path+=**
set wildmenu
set cursorline
call matchadd('colorColumn', '\%81v', 100)
set expandtab
set smarttab
set shiftwidth=4
set tabstop=4
" Remove tailing spaces from files on save
augroup prewrites
   autocmd!
    autocmd BufWritePre,FileWritePre * :%s/\s\+$//e | %s/\r$//e
augroup END
set splitright splitbelow
set wildmode=longest,list,full
set nowrap
syntax on

