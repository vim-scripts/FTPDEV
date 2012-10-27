" Title:  Vim filetype plugin file
" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" GitHub: https://github.com/coot/ftpdev_vim.git
" License: vim-license, see ':help license'
" Copyright: © Marcin Szamotulski, 2012

fun! ftpdev#Install(bang, ...) "{{{1
    if !exists("b:ftplugin_dir") || !exists("b:ftplugin_dir")
	return
    endif
    if b:ftplugin_dir == b:ftplugin_installdir || 
	    \ empty(b:ftplugin_installdir) || 
	    \ a:bang == "!" && empty(b:ftplugin_dir)
	return
    endif

    let silent = ( a:0 >= 1 ? a:1 : 0 )

    exe 'cd '.fnameescape(b:ftplugin_dir)
    
    if a:bang == "" 
	" Note: this returns non zero list if the buffer is loaded
	" ':h getbufline()'
	let file = getbufline('%', '1', '$')
	let file_name = expand('%:.')
	let install_path = substitute(b:ftplugin_installdir, '\/\s*$', '', '').'/'.file_name
	try
	    call writefile(file, install_path)
	catch /E482/
	    let dir = fnamemodify(install_path, ':h')
	    echohl WarningMsg
	    echom '[ftpdev warning]: making directory "'.dir.'"'
	    echohl None
	    call mkdir(dir, 'p')
	    call writefile(file, install_path)
	endtry
	if !silent
	    echom '[ftpdev]: file installed to: "'.install_path.'".'
	endif
    else
	let install_path = substitute(b:ftplugin_installdir, '\/\s*$', '', '')
	let file_list = filter(split(globpath(b:ftplugin_dir, '**'), "\n"), "!isdirectory(v:val) && !Match(g:ftplugin_noinstall, fnamemodify(v:val, ':.'))")
	for file in file_list
	    if bufloaded(file)
		let file_list = getbufline(file, '1', '$')
	    else
		let file_list = readfile(file)
	    endif
	    let file_name = fnamemodify(file, ':.')
            if !silent
                echo 'Installing: "'.file_name.'" to "'.install_path.'/'.file_name.'"'
            endif
	    try
		call writefile(file_list, install_path.'/'.file_name)
	    catch /E482/
		let dir = fnamemodify(install_path.'/'.file_name, ':h')
		echohl WarningMsg
		echom '[ftpdev warning]: making directory "'.dir.'"'
		echohl None
		call mkdir(dir, 'p')
		call writefile(file_list, install_path.'/'.file_name)
	    endtry
	endfor
    endif
    cd -
endfun
fun! ftpdev#AutoInstall() "{{{1
    if exists("b:ftplugin_autoinstall") && (
		\ type(b:ftplugin_autoinstall) == 1 && !empty(b:ftplugin_autoinstall) && b:ftplugin_autoinstall != 'no' ||
		\ type(b:ftplugin_autoinstall) == 0 && b:ftplugin_autoinstall )
        call ftpdev#Install("", ( b:ftplugin_autoinstall =~ 'sil\%[ent]' ? 1 : 0 ))
    endif
endfun
