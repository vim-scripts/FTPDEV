if !exists("g:ftplugin_dir")
    let g:ftplugin_dir	= globpath(split(&rtp, ',')[0], 'ftplugin') . ',' . globpath(split(&rtp, ',')[0], 'plugin')
endif
try
function! Goto(what,bang,...)
    let grep_flag = ( a:bang == "!" ? 'j' : '' )
    if a:what == 'function'
	let pattern		= '^\s*fu\%[nction]!\=\s\+\%(s:\|<SID>\)\=' .  ( a:0 >=  1 ? a:1 : '' )
    elseif a:what == 'command'
	let pattern		= '^\s*com\%[mand]!\=\s\+.*\s*' .  ( a:0 >=  1 ? a:1 : '' )
    elseif a:what == 'variable'
	let pattern 		= '^\s*let\s\+' . ( a:0 >=  1 ? a:1 : '' )
    elseif a:what == 'map'
	let pattern		= '^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>.*' . ( a:0 >= 1 ? a:1 : '' )
    else
	let pattern 		= '^\s*[ci]\=\%(\%(nore\|un\)a\%[bbrev]\|ab\%[breviate]\)' . ( a:0 >= 1 ? a:1 : '' )
    endif
	let g:pattern	= pattern
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
	let g:filename 	= filename

    let error = 0
    try
	exe 'vimgrep /'.pattern.'/' . grep_flag . ' ' . filename
    catch /E480: No match:/
	echoerr 'E480: No match: ' . pattern
	let error = 1
    endtry
    if !error
	exe 'silent! normal zO'
	exe 'normal zt'
    endif
endfunction
catch /E127/
endtry
" Completion is not working for a very simple reason: we are edditing a vim
" script which might not be sourced.
command! -buffer -bang -nargs=? -complete=function Function 	:call Goto('function', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=? -complete=command Command 	:call Goto('command', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=? -complete=var Variable 		:call Goto('variable', <q-bang>, <q-args>) 
command! -buffer -bang -nargs=? -complete=mapping Map 		:call Goto('map', <q-bang>, <q-args>) 

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
    let g:pos = pos
    if a:flag =~# 'w' || &wrapscan
	if a:flag !~# 'b' && pos == end
	    echohl WarningMsg
	    echo "search hit BOTTOM, continuing at TOP"
	    echohl Normal
	    call cursor(begin)
	    call search('^\s*fun\%[ction]\zs', '')
	    let pos = searchpos('\(' . a:pattern . '\|^\s*endfun\%[ction]\>\)', 'W')
	elseif a:flag =~# 'b' && pos == begin 
	    echohl WarningMsg
	    echo "search hit TOP, continuing at BOTTOM"
	    echohl Normal
	    call cursor(end)
	    let pos = searchpos('\(' . a:pattern . '\|^\s*fun\%[ction]\>\)', 'Wb')
	endif
	if pos == end || pos == begin
	    echohl WarningMsg
	    echo "Pattern: " . a:pattern . " not found." 
	    echohl Normal
	    call cursor(cline, ccol)
	endif
    else
	if pos == end || pos == begin
	    echohl WarningMsg
	    echo "Pattern: " . a:pattern . " not found." 
	    echohl Normal
    	call cursor(cline, ccol)
	endif
    endif
endfunction
function! s:GetSearchArgs(Arg,flags)
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

    let [ pattern, flag ] = s:GetSearchArgs(a:Arg, 'bcenpswW')
    let @/ = pattern
    call histadd("search", pattern)

    if pattern == ""
	echohl ErrorMsg
	echomsg "Enclose the pattern with /.../"
	echohl Normal
	return
    endif

    call SearchInFunction(pattern, flag)
endfunction
command! -buffer -nargs=*	S 	:call Search(<q-args>) | let v:searchforward = ( s:GetSearchArgs(<q-args>, 'bcenpswW')[1] =~# 'b' ? 0 : 1 )
command! -nargs=1 -complete=file PluginDir	:let g:ftplugin_dir='<args>'

try
function! Pgrep(vimgrep_arg)
    let filename	= join(map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)"))
    execute "vimgrep " . a:vimgrep_arg . " " . filename 
endfunction
catch /E127:/
endtry
command! -nargs=1 Pgrep		:call Pgrep(<q-args>)
