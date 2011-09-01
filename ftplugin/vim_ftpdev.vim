" Title:  Vim filetype plugin file
" :
" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" Last Change:
" GetLatestVimScript: 3322 2 :AutoInstall: FTPDEV
" Copyright Statement: {{{1
" 	  This file is a part of Automatic Tex Plugin for Vim.
"
"     Automatic Tex Plugin for Vim is free software: you can redistribute it
"     and/or modify it under the terms of the GNU General Public License as
"     published by the Free Software Foundation, either version 3 of the
"     License, or (at your option) any later version.
" 
"     Automatic Tex Plugin for Vim is distributed in the hope that it will be
"     useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
"     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
"     General Public License for more details.
" 
"     You should have received a copy of the GNU General Public License along
"     with Automatic Tex Plugin for Vim.  If not, see <http://www.gnu.org/licenses/>.
"
"     This licence applies to all files shipped with Automatic Tex Plugin.


"{{{1 GLOBAL VARIABLES
if !exists("g:ftplugin_dir")
    let g:ftplugin_dir	= globpath(split(&rtp, ',')[0], 'ftplugin') . ',' . globpath(split(&rtp, ',')[0], 'plugin')
endif
if !exists("g:ftplugin_installdir")
    let g:ftplugin_installdir=split(&runtimepath,",")[0]
endif
if !exists("g:ftplugin_notinstall")
    let g:ftplugin_notinstall=['Makefile', '.*\.tar\.\%(bz2\|gz\)$', '.*\.vba$']
endif
if exists("g:ftplugin_ResetPath") && g:ftplugin_ResetPath == 1
    au! BufEnter * let &l:path=g:ftplugin_dir.",".join(filter(split(globpath(g:ftplugin_dir.'**', '*'), "\n"), "isdirectory(v:val)"), ",")
else
    function! FTPLUGIN_AddPath()
	let path=map(split(&path, ','), "fnamemodify(v:val, ':p')")
	if index(path,fnamemodify(g:ftplugin_dir, ":p")) == -1
	    let &l:path=( len(path)==0 ? g:ftplugin_dir : &path.",".g:ftplugin_dir.",".join(filter(split(globpath(g:ftplugin_dir.'**', '*'), "\n"), "isdirectory(v:val)"), ",") )
	endif
    endfunction
    exe "au! BufEnter ".g:ftplugin_dir."* call FTPLUGIN_AddPath()"
    exe "au! VimEnter * call FTPLUGIN_AddPath()"
endif
try
"1}}}

" FUNCTIONS AND COMMANDS:
function! Goto(what,bang,...) 
    let g:a	= (a:0 >= 1 ? a:1 : "")
    let pattern = (a:0 >= 1 ? 
		\ (a:1 =~ '.*\ze\s\+\d\+$' ? matchstr(a:1, '.*\ze\s\+\d\+$') : a:1)
		\ : 'no_arg') 
    let line	= (a:0 >= 1 ? 
		\ (a:1 =~ '.*\ze\s\+\d\+$' ? matchstr(a:1, '.*\s\+\zs\d\+$') : 0) 
		\ : 0)
    	let g:pattern_arg 	= pattern
	let g:line_arg		= line
    " Go to a:2 lines below
    let g:line = line
    let grep_flag = ( a:bang == "!" ? 'j' : '' )
    if a:what == 'function'
	let pattern		= '^\s*\%(silent!\=\)\=\s*fu\%[nction]!\=\s\+\%(s:\|<\csid>\)\=' .  ( a:0 >=  1 ? pattern : '' )
    elseif a:what == 'command'
	let pattern		= '^\s*\%(silent!\=\)\=\s*com\%[mand]!\=\%(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*'.( a:0 >= 1 ? pattern : '' )
    elseif a:what == 'variable'
	let pattern 		= '^\s*let\s\+' . ( a:0 >=  1 ? pattern : '' )
    elseif a:what == 'maplhs'
	let pattern		= '^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\=' . ( a:0 >= 1 ? pattern : '' )
    elseif a:what == 'maprhs'
	let pattern		= '^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\s\+\<\S\+\>\s\+\%(<plug>\)\=' . ( a:0 >= 1 ? pattern : '' )
    else
	let pattern 		= '^\s*[ci]\=\%(\%(nore\|un\)a\%[bbrev]\|ab\%[breviate]\)' . ( a:0 >= 1 ? pattern : '' )
    endif
    let g:pattern		= pattern
    let filename		= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))

    let error = 0
    try
	exe 'silent! vimgrep /'.pattern.'/' . grep_flag . ' ' . filename
    catch /E480:/
	echoerr 'E480: No match: ' . pattern
	let error = 1
    endtry

    if len(getqflist()) >= 2
	clist
    endif
    if !error
	exe 'silent! normal zO'
	exe 'normal zt'
    endif

    " Goto lines below
    if line
	exe "normal ".line."j"
    endif
endfunction
catch /E127/
endtry
" Completion is not working for a very simple reason: we are edditing a vim
" script which might not be sourced.
command! -buffer -bang -nargs=? -complete=custom,FuncCompl Function 	:call Goto('function', <q-bang>, <q-args>) 
function! FuncCompl(A,B,C)
    let saved_loclist=getloclist(0)
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
    try
	exe 'lvimgrep /^\s*fun\%[ction]/gj '.filename
    catch /E480:/
    endtry
    let loclist = getloclist(0)
    call setloclist(0, saved_loclist)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*fun\%[ction]!\=\s*\(<\csid>\|\cs:\)\=\zs.*\ze\s*('')')
    call map(loclist, 'v:val.''\>''')
    return join(loclist, "\n")
endfunction
function! CommandCompl(A,B,C)
    let saved_loclist=getloclist(0)
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
    try
	exe 'lvimgrep /^\s*com\%[mand]/gj '.filename
    catch /E480:/
    endtry
    let loclist = getloclist(0)
    call setloclist(0, saved_loclist)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*com\%[mand]!\=\(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*\zs\w*\>\ze'')')
    call map(loclist, 'v:val.''\>''')
    return join(loclist, "\n")
endfunction
function! MapRhsCompl(A,B,C)
    let saved_loclist=getloclist(0)
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
    try
	exe 'lvimgrep /^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>/gj '.filename
    catch /E480:/
    endtry
    let loclist = getloclist(0)
    call setloclist(0, saved_loclist)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\=\zs.*'')')
    call map(loclist, 'matchstr(v:val, ''\S\+\s\+\zs.*'')')
    call map(loclist, 'escape(v:val, "[]")')
    return join(loclist, "\n")
endfunction
function! MapLhsCompl(A,B,C)
    let saved_loclist=getloclist(0)
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
    try
	exe 'lvimgrep /^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>/gj '.filename
    catch /E480:/
    endtry
    let loclist = getloclist(0)
    call setloclist(0, saved_loclist)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\=\zs\S*\ze'')')
    call map(loclist, 'escape(v:val, "[]")')
    return join(loclist, "\n")
endfunction
command! -buffer -bang -nargs=? -complete=custom,CommandCompl Command 	:call Goto('command', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=?  			Variable 	:call Goto('variable', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=? -complete=custom,MapLhsCompl MapLhs 		:call Goto('maplhs', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=? -complete=custom,MapRhsCompl MapRhs 		:call Goto('maprhs', <q-bang>, <q-args>) 

" Search in current function
function! SearchInFunction(pattern, flag) 

    let [ cline, ccol ] = [ line("."), col(".") ]
    if a:flag =~# 'b\|w' || &wrapscan
	let begin = searchpairpos('^\s*fun\%[ction]\>', '', '^\s*endfun\%[ction]\>', 'bWn')
    endif
    if a:flag !~# 'b' || a:flag =~# 'w' || &wrapscan
	let end = searchpairpos('^\s*fun\%[ction]\>', '', '^\s*endfun\%[ction]\>', 'Wn')
    endif
    if a:flag !~# 'b'
	let pos = searchpos('\(' . a:pattern . '\|^\s*endfun\%[ction]\>\)', 'W')
    else
	let pos = searchpos('\(' . a:pattern . '\|^\s*fun\%[ction]\>\)', 'Wb')
    endif

    let msg="" 
    if a:flag =~# 'w' || &wrapscan
	if a:flag !~# 'b' && pos == end
	    let msg="search hit BOTTOM, continuing at TOP"
	    call cursor(begin)
	    call search('^\s*fun\%[ction]\zs', '')
	    let pos = searchpos('\(' . a:pattern . '\|^\s*endfun\%[ction]\>\)', 'W')
	elseif a:flag =~# 'b' && pos == begin 
	    let msg="search hit TOP, continuing at BOTTOM"
	    call cursor(end)
	    let pos = searchpos('\(' . a:pattern . '\|^\s*fun\%[ction]\>\)', 'Wb')
	endif
	if pos == end || pos == begin
	    let msg="Pattern: " . a:pattern . " not found." 
	    call cursor(cline, ccol)
	endif
    else
	if pos == end || pos == begin
	    let msg="Pattern: " . a:pattern . " not found." 
    	call cursor(cline, ccol)
	endif
    endif

    if msg != ""
	    echohl WarningMsg
	redraw
	exe "echomsg '".msg."'"
	    echohl Normal
    endif
endfunction
function! <SID>GetSearchArgs(Arg,flags)
    if a:Arg =~ '^\/'
	let pattern 	= matchstr(a:Arg, '^\/\zs.*\ze\/')
	let flag	= matchstr(a:Arg, '\/.*\/\s*\zs['.a:flags.']*\ze\s*$')
    elseif a:Arg =~ '^\i' && a:Arg !~ '^\w'
	let pattern 	= matchstr(a:Arg, '^\(\i\)\zs.*\ze\1')
	let flag	= matchstr(a:Arg, '\(\i\).*\1\s*\zs['.a:flags.']*\ze\s*$')
    else
	let pattern	= matchstr(a:Arg, '^\zs\S*\ze')
	let flag	= matchstr(a:Arg, '^\S*\s*\zs['.a:flags.']*\ze\s*$')
    endif
    return [ pattern, flag ]
endfunction
function! Search(Arg)

    let [ pattern, flag ] = <SID>GetSearchArgs(a:Arg, 'bcenpswW')
    let @/ = pattern
    call histadd("search", pattern)

    if pattern == ""
	echohl ErrorMsg
	redraw
	echomsg "Enclose the pattern with /.../"
	echohl Normal
	return
    endif

    call SearchInFunction(pattern, flag)
endfunction
command! -buffer -nargs=*	S 	:call Search(<q-args>) | let v:searchforward = ( <SID>GetSearchArgs(<q-args>, 'bcenpswW')[1] =~# 'b' ? 0 : 1 )
" my vim doesn't distinguish <C-n> and <C-N>:
nmap <silent> <buffer> <C-N>				:call SearchInFunction(@/,'')<CR>
nmap <silent> <buffer> <C-P> 				:call SearchInFunction(@/,'b')<CR>
nmap <silent> <buffer> gn 				:call SearchInFunction(@/,( v:searchforward ? '' : 'b'))<CR>
nmap <silent> <buffer> gN				:call SearchInFunction(@/,(!v:searchforward ? '' : 'b'))<CR>
function! PluginDir(...)
    if a:0 == 0 
	echo g:ftplugin_dir
    else
	let g:ftplugin_dir=a:1
    endif
endfunction
command! -nargs=? -complete=file PluginDir	:call PluginDir(<f-args>)

try
function! Pgrep(vimgrep_arg)
    let filename	= join(filter(map(split(globpath(g:ftplugin_dir, '**/*'), "\n"), "fnameescape(v:val)"),"!isdirectory(v:val)"))
    try
	execute "vimgrep " . a:vimgrep_arg . " " . filename 
    catch /E480:/
	echohl ErrorMsg
	redraw
	echo "E480: No match: ".a:vimgrep_arg
	echohl Normal
    endtry
endfunction
catch /E127:/
endtry
command! -nargs=1 Pgrep		:call Pgrep(<q-args>)

function! ListFunctions(bang)
    try
	lvimgrep /^\s*fun\%[ction]/gj %
    catch /E480:/
	echohl ErrorMsg
	redraw
	echo "E480: No match: ".a:vimgrep_arg
	echohl Normal
    endtry
    let loclist = getloclist(0)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*fun\%[ction]!\=\s*\zs.*\ze\s*('')')
    if a:bang == "!"
	call sort(loclist)
    endif
    return join(<SID>PrintTable(loclist, 2), "\n")
endfunction
command! -bang ListFunctions 	:echo ListFunctions(<q-bang>)

function! ListCommands(bang)
    try
	lvimgrep /^\s*com\%[mmand]/gj %
    catch /E480:/
	echohl ErrorMsg
	redraw
	echo "E480: No match: ".a:vimgrep_arg
	echohl Normal
    endtry
    let loclist = getloclist(0)
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'substitute(v:val, ''^\s*'', '''', '''')')
    if a:bang == "!"
	call sort(loclist)
    endif
    let cmds = []
    for raw_cmd in loclist 
	let pattern = '^\s*com\%[mand]!\=\%(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*\zs\w*\ze'
	call add(cmds, matchstr(raw_cmd, pattern))
    endfor

    return join(cmds, "\n")
endfunction
command! -bang ListCommands 	:echo ListCommands(<q-bang>)

nmap	Gn	:call searchpair('^[^"]*\<\zsif\>', '^[^"]*\<\zselse\%(if\)\=\>', '^[^"]*\<\zsendif\>')<CR>
nmap	GN	:call searchpair('^[^"]*\<\zsif\>', '^[^"]*\<\zselse\%(if\)\=\>', '^[^"]*\<\zsendif\>', 'b')<CR>

function! <SID>Install(bang)

    let cwd = getcwd()
    exe 'lcd '.g:ftplugin_dir
    
    if a:bang == "" 
	" Note: this returns non zero list if the buffer is loaded
	" ':h getbufline()'
	let file_name = fnamemodify(bufname(""), ":.")
	let file		= getbufline( '%', '1', '$')
	call writefile( file, $HOME . "/.vim/" . file_name)
    else
	for file in filter(split(globpath(g:ftplugin_dir, "**"), "\n"), "!isdirectory(v:val) && <SID>Index(g:ftplugin_notinstall, fnamemodify(v:val, ':.')) == -1")
	    echo file
	    if bufloaded(file)
		let file_list		= getbufline( file, '1', '$')
	    else
		let file_list		= readfile( file)
	    endif
	    let file_name = fnamemodify(file, ":.")
	    call writefile(file_list, substitute(g:ftplugin_installdir, '\/$', '', '')."/".file_name)
	endfor
    endif
    exe "lcd ".cwd
endfunction
function! <SID>Index(list, pattern)
    let ind = -1
    for element in a:list
	let ind += 1
	if element =~ a:pattern || element == a:pattern
	    return ind
	endif
    endfor
    return -1
endfunction
command! -bang Install 	:call <SID>Install(<q-bang>)

function! Evaluate(mode)
    let saved_pos	= getpos(".")
    let saved_reg	= @e
    if a:mode == "n"
	if strpart(getline(line(".")), col(".")-1) =~ '[bg]:'
	    let end_pos = searchpos('[bg]:\w*\zs\>', 'cW')
	else
	    let end_pos = searchpos('\ze\>', 'cW')
	endif
	let end_pos[1] -= 1 
	call cursor(saved_pos[1], saved_pos[2])
	normal! v
	call cursor(end_pos)
	normal! "ey
	let expr = @e
    elseif a:mode ==? 'v'
	let beg_pos = getpos("'<")
	let end_pos = getpos("'>")
	call cursor(beg_pos[1], beg_pos[2])
	normal! v 
	call cursor(end_pos[1], end_pos[2])
	normal! "ey
	let expr= @e
    endif
    let @e = saved_reg
    try
	echo expr."=".string({expr})
    catch /E121:/
	echomsg "variable ".expr." undefined"
    endtry
endfunction
command! -buffer -range Eval	:call Evaluate(mode())

" Print table tools:
function! <SID>FormatListinColumns(list,s) "{{{1
    " take a list and reformat it into many columns
    " a:s is the number of spaces between columns
    " for example of usage see atplib#PrintTable
    let max_len=max(map(copy(a:list), 'len(v:val)'))
"     let g:list=a:list
"     let g:max_len=max_len+a:s
    let new_list=[]
    let k=&l:columns/(max_len+a:s)
"     let g:k=k
    let len=len(a:list)
    let column_len=len/k
    for i in range(0, column_len)
	let entry=[]
	for j in range(0,k)
	    call add(entry, get(a:list, i+j*(column_len+1), ""))
	endfor
	call add(new_list,entry)
    endfor
    return new_list
endfunction 

function! <SID>PrintTable(list, spaces) "{{{1
" Take list format it with atplib#FormatListinColumns and then with
" atplib#Table (which makes columns of equal width)

    " a:list 	- list to print
    " a:spaces 	- nr of spaces between columns 

    let list = atplib#FormatListinColumns(a:list, a:spaces)
    let nr_of_columns = max(map(copy(list), 'len(v:val)'))
    let spaces_list = ( nr_of_columns == 1 ? [0] : map(range(1,nr_of_columns-1), 'a:spaces') )

    let g:spaces_list=spaces_list
    let g:nr_of_columns=nr_of_columns
    
    return atplib#Table(list, spaces_list)
endfunction
