".vimrc


filetype plugin indent on

set tabstop=4
" show existing tab with 4 spaces width
set shiftwidth=4
" when indenting with '>', use 4 spaces width
set expandtab
" On pressing tab, insert 4 spaces

"set backspace=indent,eol,start


if has("autocmd")
" Do this if vim has support for autocmd compiled in  
	
	autocmd FileType python compiler pylint
    	" enable Pylint support
    	autocmd BufReadPost *
    	" When editing a file, jump to the last known cursor position
	
endif has("autocmd")

syntax enable
set background=dark
colorscheme solarized
