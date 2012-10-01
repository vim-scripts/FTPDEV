" Title:  Vim filetype plugin file
" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" License: vim-license, see ':help license'
" Copyright: © Marcin Szamotulski, 2012
" GetLatestVimScript: 3322 2 :AutoInstall: FTPDEV
"
" Todo: gd (search in current scope) and gD (search for global definition).
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
let s:vim_dirs = [ "ftplugin", "plugin", "autoload", "compiler", "syntax",
	\ "indent", "colors", "doc", "keymap", "lang", "macros", "print",
	\ "spell", "tools", "tutor", ]
if !exists("g:ftplugin_dir")
    let dir_path = ''
    for dir in s:vim_dirs
	let dir_path = fnamemodify(finddir(dir, expand("%:p:h").';'), ':p')
	if !empty(dir_path)
	    break
	endif
    endfor
    if !empty(dir_path)
	let g:ftplugin_dir = fnamemodify(dir_path, ':h:h')
    else
	let g:ftplugin_dir = expand("%:p:h")
    endif
endif
fun! FTPDEV_GetInstallDir()
    " lcd to g:ftplugin_dir, we want path to be relative to this directory.
    exe 'lcd '.fnameescape(g:ftplugin_dir) 
    " Check only vim files:
    let files = map(filter(split(globpath('.', '**'), '\n'), 'fnamemodify(v:val, ":e") == "vim"'), 'v:val[2:]')
    lcd -
    " Good files to check are those in s:vim_dirs:
    " i.e. in plugin, ftplugin, ... directories.
    let gfiles = []
    for file in files
	if file =~ '^\%('.join(s:vim_dirs, '\|').'\)\>'
	    call add(gfiles, file)
	endif
    endfor
    if len(gfiles)
	let files = gfiles
    endif
    " ipath - install path
    let ipath = ''
    for file in files
	" Find each file in 'runtimepath'
	let ipath = globpath(&rtp, file)
	if !empty(ipath)
	    break
	endif
    endfor
    " Get the install path, count the directory level of file and strip that
    " many directories from the corresponing ipath. This should be the install
    " path.
    let idx = 0
    while file != "."
	let idx += 1
	let file = fnamemodify(file, ':h')
    endwhile
    let ipath = fnamemodify(ipath, repeat(':h', idx))
    return ipath
endfun
if !exists("g:ftplugin_installdir")
    let dir = FTPDEV_GetInstallDir()
    if !empty(dir)
	let g:ftplugin_installdir = dir
    else
	let g:ftplugin_installdir = split(&rtp, ',')[0]
    endif
endif
	    


if !exists("g:ftplugin_notinstall")
    let g:ftplugin_notinstall=['Makefile', '\.tar\%(\.bz2\|\.gz\)\?$', '\.vba$', '.*\.vmb$']
endif
if exists("g:ftplugin_ResetPath") && g:ftplugin_ResetPath == 1
    au! BufEnter *.vim exe "setl path=".substitute(g:ftplugin_dir.",".join(filter(split(globpath(g:ftplugin_dir, '**'), "\n"), "isdirectory(v:val)"), ","), " ", '\\\\\\\ ', 'g')
else
    func! FTPDEV_AddPath()
	let path=map(split(&path, ','), "fnamemodify(v:val, ':p')")
	if index(path,fnamemodify(g:ftplugin_dir, ":p")) == -1 && g:ftplugin_dir != ""
	    let add = join(filter(split(globpath(g:ftplugin_dir, '**'), "\n"), "isdirectory(v:val)"), ",")
	    let add = substitute(add, " ", '\\\\\\\ ', 'g')
	    exe "setl path+=".add
	endif
    endfun
    exe "au! BufEnter ".g:ftplugin_dir."* call FTPDEV_AddPath()"
    exe "au! VimEnter * call FTPDEV_AddPath()"
endif
try
"1}}}

" Vim Settings: 
" vim scripts written on windows works on Linux only if the EOF are dos or unix.
setl fileformats=unix,dos

" FUNCTIONS AND COMMANDS AND MAPS:
fun! <SID>PyGrep(what, files) " {{{1
python << EOF
import vim
import re
import json

what = vim.eval('a:what')
files = vim.eval('a:files')

if what == 'function':
    pat = re.compile('\s*(?:silent!?)?\s*(?:fu|fun|func|funct|functio|function)!?\s')
elif what == 'command':
    pat = re.compile('\s*(?:silent!?)?\s*(?:com|comm|comma|comman|command)!?\s')
elif what == 'variable':
    pat = re.compile('\s*let\s')
elif what == 'maplhs':
    pat = re.compile('\s*[cilnosvx!]?(?:nore)?(?:m|ma|map)\s' )
elif  what == 'maprhs':
    pat = re.compile('\s*[cilnosvx!]?(?:nore)?(?:m|ma|map)' )

loclist = []
for filename in files:
    if vim.eval("bufloaded('%s')" % filename) == '1':
        for buf in vim.buffers:
            if buf.name == filename:
                buf_nr = buf.number
                break
    else:
        buf_nr = 0
        with open(filename) as fo:
            buf = fo.read().splitlines()
    lnr = 0
    buf_len = len(buf)
    while lnr < buf_len:
        lnr += 1
	line = buf[lnr-1]
	if line.startswith('py'):
            # Skip over :python << EOF, :perl << EOF until EOF:
            eof = re.match('(?:py|pyt|pyth|pytho|python|pe|per|perl)\s*<<\s*(\w+)',line).group(1)
            while not line.startswith(eof):
                lnr +=1
                if lnr == buf_len:
                    break
                line = buf[lnr-1]
            if lnr == buf_len:
                break
            lnr += 1
            line = buf[lnr-1]
        match = re.match(pat, line)
        if match:
            loclist.append({
                "bufnr" : buf_nr,
                "filename" : filename,
                "lnum" : lnr,
                "text" : line
                })
vim.command("let loclist=%s" % json.dumps(loclist))
EOF
return loclist
endfun
fun! Goto(what,bang,...) "{{{1
    let pattern = (a:0 >= 1 ? 
		\ (a:1 =~ '.*\ze\s\+\d\+$' ? matchstr(a:1, '.*\ze\s\+\d\+$') : a:1)
		\ : 'no_arg') 
    let line	= (a:0 >= 1 ? 
		\ (a:1 =~ '.*\ze\s\+\d\+$' ? matchstr(a:1, '.*\s\+\zs\d\+$') : 0) 
		\ : 0)
    " Go to a:2 lines below
    let grep_flag = ( a:bang == "!" ? 'j' : '' )
    if a:what == 'function'
	if !has("python")
	    let pattern		= '^\s*\%(silent!\=\)\=\s*fu\%[nction]!\=\s\+\%(s:\|<\csid>\|\f\+\#\)\=' .  ( a:0 >=  1 ? pattern : '' )
	else
	    let cpat		= '^\s*\%(silent!\=\)\=\s*fu\%[nction]!\=\s\+\%(s:\|<\csid>\)\=\zs[^(]*'
	    let pattern		= ( a:0 >=  1 ? pattern : '' )
	endif
    elseif a:what == 'command'
	if !has("python")
	    let pattern		= '^\s*\%(silent!\=\)\=\s*com\%[mand]!\=\%(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*'.( a:0 >= 1 ? pattern : '' )
	else
	    let cpat		= '^\s*\%(silent!\=\)\=\s*com\%[mand]!\=\%(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*\zs\S*'
	    let pattern		= ( a:0 >= 1 ? pattern : '' )
	endif
    elseif a:what == 'variable'
	if !has("python")
	    let pattern 	= '^\s*let\s\+' . ( a:0 >=  1 ? pattern : '' )
	else
	    let cpat 		= '^\s*let\s\+\zs[^\s=]*'
	    let pattern 	= ( a:0 >=  1 ? pattern : '' )
	endif
    elseif a:what == 'maplhs'
	let cpat		= '^\s*[cilnosvx!]\?\%(nore\)\?m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\?\zs\S*'
	let pattern		= ( a:0 >= 1 ? pattern : '' )
	if !has("python")
	    let pattern		=  '^\s*[cilnosvx!]\?\%(nore\)\?m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\?'.pattern
	endif
    elseif a:what == 'maprhs'
	let cpat		= '^\s*[cilnosvx!]\?\%(nore\)\?m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\s\+\<\S\+\>\s\+\%(<plug>\)\?\zs.*'
	let pattern		= ( a:0 >= 1 ? pattern : '' )
	if !has("python")
	    let pattern		=  '^\s*[cilnosvx!]\?\%(nore\)\?m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\s\+\<\S\+\>\s\+\%(<plug>\)\?'.pattern
	endif
    else
	let pattern 		= '^\s*[ci]\=\%(\%(nore\|un\)a\%[bbrev]\|ab\%[breviate]\)' . ( a:0 >= 1 ? pattern : '' )
    endif
    let files			= map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)")
    let filename		= join(files)

    if has("python")
        call map(files, 'fnamemodify(v:val, ":p")')
        if !exists("s:loclist")
            let loclist = <SID>PyGrep(a:what, files)
        else
            let loclist = s:loclist
            unlet s:loclist
        endif
	let nloclist = []
	for loc in loclist
	    let loc['m_text'] = matchstr(loc['text'], cpat)
	    call add(nloclist, loc)
	endfor
        let loclist = nloclist
        call filter(loclist, 'v:val["m_text"] =~ pattern')
        call setloclist(0, loclist)
        try
            ll
            let error = 0
        catch /E42/
            let error = 1
        endtry
    else
	let error = 0
        if !exists("s:loclist")
            try
                exe 'silent! lvimgrep /'.pattern.'/' . grep_flag . ' ' . filename
            catch /E480:/
                echoerr 'E480: No match: ' . pattern
                let error = 1
            endtry
        endif
    endif

    if len(getloclist(".")) >= 2
	llist
    endif
    if !error
	exe 'silent! normal zv'
	if a:what == 'function'
	    exe 'normal zt'
	endif
    endif

    " Goto lines below
    if line
	exe "normal ".line."j"
    endif
endfun
catch /E127/
endtry
" Completion is not working for a very simple reason: we are edditing a vim
" script which might not be sourced.
com! -buffer -bang -nargs=? -complete=customlist,FuncCompl Function 	:call Goto('function', <q-bang>, <q-args>) 
try
fun! FuncCompl(A,B,C) "{{{1
    let files = map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)")
    let filename = join(files)
    if has("python")
        let loclist = <SID>PyGrep('function', files)
        let s:loclist = deepcopy(loclist)
    else
        let saved_loclist=getloclist(0)
        try
            exe 'lvimgrep /^\s*fun\%[ction]/gj '.filename
        catch /E480:/
        endtry
        let loclist = getloclist(0)
        let s:loclist = deepcopy(loclist)
        call setloclist(0, saved_loclist)
    endif
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*fun\%[ction]!\=\s*\(<\csid>\|\cs:\)\=\zs.*\ze\s*('')')
    call filter(loclist, "v:val =~ a:A")
    if !has("python")
	call map(loclist, 'v:val.''\>''')
    else
	call map(loclist, '"^".v:val."\\>"')
    endif
    return loclist
endfun
catch /E127/
endtry
try
fun! CommandCompl(A,B,C) "{{{1
    let files = map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)")
    let filename = join(files)
    if has("python")
        let loclist = <SID>PyGrep('command', files)
        let s:loclist = deepcopy(loclist)
    else
        let saved_loclist=getloclist(0)
        try
            exe 'lvimgrep /^\s*com\%[mand]/gj '.filename
        catch /E480:/
        endtry
        let loclist = getloclist(0)
        call setloclist(0, saved_loclist)
    endif
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*com\%[mand]!\=\(\s*-buffer\s*\|\s*-nargs=[01*?+]\s*\|\s*-complete=\S\+\s*\|\s*-bang\s*\|\s*-range=\=[\d%]*\s*\|\s*-count=\d\+\s*\|\s*-bar\s*\|\s*-register\s*\)*\s*\zs\w*\>\ze'')')
    if !has("python")
	call map(loclist, 'v:val.''\>''')
    else
	call map(loclist, '"^".v:val."\\>"')
    endif
    return join(loclist, "\n")
endfun
catch /E127/
endtry
try
fun! MapRhsCompl(A,B,C) "{{{1
    let files = map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)")
    let filename = join(files)
    if has("python")
        let loclist = <SID>PyGrep('maprhs', files)
        let s:loclist = deepcopy(loclist)
    else
        let saved_loclist=getloclist(0)
        try
            exe 'lvimgrep /^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>/gj '.filename
        catch /E480:/
        endtry
        let loclist = getloclist(0)
	call setloclist(0, saved_loclist)
    endif
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\=\zs.*'')')
    call map(loclist, 'matchstr(v:val, ''\S\+\s\+\%(<plug>\)\?\zs.*'')')
    call filter(loclist, 'v:val =~ a:A')
    call map(loclist, 'escape(v:val, "[]")')
    return loclist
endfun
catch /E127/
endtry
try
fun! MapLhsCompl(A,B,C) "{{{1
    let files = map(split(globpath(g:ftplugin_dir, '**/*vim'), "\n"), "fnameescape(v:val)")
    let filename = join(files)
    if has("python")
        let loclist = <SID>PyGrep('maplhs', files)
        let s:loclist = deepcopy(loclist)
    else
        let saved_loclist=getloclist(0)
        try
            exe 'lvimgrep /^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>/gj '.filename
        catch /E480:/
        endtry
        let loclist = getloclist(0)
        call setloclist(0, saved_loclist)
    endif
    call map(loclist, 'get(v:val, "text", "")')  
    call map(loclist, 'matchstr(v:val, ''^\s*[cilnosvx!]\=\%(nore\)\=m\%[ap]\>\s\+\%(\%(<buffer>\|<silent>\|<unique>\|<expr>\)\s*\)*\(<plug>\)\=\zs\S*\ze'')')
    call map(loclist, 'escape(v:val, "[]")')
    return join(loclist, "\n")
endfun
catch /E127/
endtry "}}}1
com! -buffer -bang -nargs=? -complete=custom,CommandCompl 	Command 	:call Goto('command', <q-bang>, <q-args>) 
com! -buffer -bang -nargs=?  			     	Variable 	:call Goto('variable', <q-bang>, <q-args>) 
com! -buffer -bang -nargs=? -complete=custom,MapLhsCompl 	MapLhs 		:call Goto('maplhs', <q-bang>, <q-args>) 
com! -buffer -bang -nargs=? -complete=customlist,MapRhsCompl 	MapRhs 		:call Goto('maprhs', <q-bang>, <q-args>) 

" Search in current function
fun! SearchInFunction(pattern, flag) "{{{1

    let [ cline, ccol ] = [ line("."), col(".") ]
    if a:flag =~# 'b\|w' || &wrapscan
	let begin = searchpairpos('^\s*fun\%[ction]\>', '', '^\s*endfun\%[ction]\>', 'bWn')
    endif
    if a:flag !~# 'b' || a:flag =~# 'w' || &wrapscan
	let end = searchpairpos('^\s*fun\%[ction]\>', '', '^\s*endfun\%[ction]\>', 'Wn')
    endif
    if a:flag !~# 'b'
	let pos = searchpos('\(' . a:pattern . ( a:pattern =~ '\\v' ? '|^\s*endfun%[ction]>)' : '\|^\s*endfun\%[ction]\>\)' ), 'W')
    else
	let pos = searchpos('\(' . a:pattern . ( a:pattern =~ '\\v' ? '|^\s*endfun%[ction]>)' : '\|^\s*endfun\%[ction]\>\)' ), 'Wb')
    endif

    let msg="" 
    if a:flag =~# 'w' || &wrapscan
	if a:flag !~# 'b' && pos == end
	    let msg="search hit BOTTOM, continuing at TOP"
	    call cursor(begin)
	    call search('^\s*fun\%[ction]\zs', '')
	    let pos = searchpos('\(' . a:pattern . ( a:pattern =~ '\\v' ? '|^\s*endfun%[ction]>)' : '\|^\s*endfun\%[ction]\>\)' ), 'W')
	elseif a:flag =~# 'b' && pos == begin 
	    let msg="search hit TOP, continuing at BOTTOM"
	    call cursor(end)
	    let pos = searchpos('\(' . a:pattern . ( a:pattern =~ '\\v' ? '|^\s*endfun%[ction]>)' : '\|^\s*endfun\%[ction]\>\)' ), 'Wb')
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
endfun
fun! <SID>GetSearchArgs(Arg,flags) "{{{1
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
endfun
fun! Search(Arg) "{{{1

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
endfun "}}}1
com! -buffer -nargs=*	S 	:call Search(<q-args>) | let v:searchforward = ( <SID>GetSearchArgs(<q-args>, 'bcenpswW')[1] =~# 'b' ? 0 : 1 )

nmap <silent> <buffer> <C-N>				:call SearchInFunction(@/,'')<CR>
nmap <silent> <buffer> <C-P> 				:call SearchInFunction(@/,'b')<CR>
nmap <silent> <buffer> gn 				:call SearchInFunction(@/,( v:searchforward ? '' : 'b'))<CR>
nmap <silent> <buffer> gN				:call SearchInFunction(@/,(!v:searchforward ? '' : 'b'))<CR>
fun! <SID>PluginDir(...) "{{{1
    if a:0 == 0 
	echo g:ftplugin_dir
    else
	let g:ftplugin_dir=a:1
    endif
endfun "}}}1
com! -nargs=? -complete=file PluginDir	:call <SID>PluginDir(<f-args>)

try
fun! Pgrep(vimgrep_arg) "{{{1
    let filename	= join(filter(map(split(globpath(g:ftplugin_dir, '**/*'), "\n"), "fnameescape(v:val)"),"!isdirectory(v:val)"))
    try
	execute "lvimgrep " . a:vimgrep_arg . " " . filename 
    catch /E480:/
	echohl ErrorMsg
	redraw
	echo "E480: No match: ".a:vimgrep_arg
	echohl Normal
    endtry
endfun
catch /E127:/
endtry
com! -nargs=1 Pgrep		:call Pgrep(<q-args>)

fun! ListFunctions(bang) "{{{1
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
endfun
com! -bang ListFunctions 	:echo ListFunctions(<q-bang>)

fun! ListCommands(bang) "{{{1
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
endfun
com! -bang ListCommands 	:echo ListCommands(<q-bang>)

nmap	]#	:call searchpair('^[^"]*\<\zsif\>', '^[^"]*\<\zselse\%(if\)\=\>', '^[^"]*\<\zsendif\>')<CR>
nmap	[#	:call searchpair('^[^"]*\<\zsif\>', '^[^"]*\<\zselse\%(if\)\=\>', '^[^"]*\<\zsendif\>', 'b')<CR>

fun! <SID>Install(bang) "{{{1

    if g:ftplugin_dir = g:ftplugin_installdir
	return
    endif

    exe 'lcd '.fnameescape(g:ftplugin_dir)
    
    if a:bang == "" 
	" Note: this returns non zero list if the buffer is loaded
	" ':h getbufline()'
	let file_name = expand('%:.')
	let file = getbufline('%', '1', '$')
	let install_path = substitute(g:ftplugin_installdir, '\/\s*$', '', '').'/'.file_name
	call writefile(file, install_path)
	echom 'File installed to: "'.install_path.'".'
    else
	let install_path = substitute(g:ftplugin_installdir, '\/\s*$', '', '')
	let file_list = filter(split(globpath(g:ftplugin_dir, '**'), "\n"), "!isdirectory(v:val) && !Match(g:ftplugin_notinstall, fnamemodify(v:val, ':.'))")
	for file in file_list
	    if bufloaded(file)
		let file_list = getbufline(file, '1', '$')
	    else
		let file_list = readfile(file)
	    endif
	    let file_name = fnamemodify(file, ':.')
	    echo 'Installing: "'.file_name.'" to "'.install_path.'/'.file_name.'"'
	    try
		call writefile(file_list, install_path.'/'.file_name)
	    catch /E482/
		let dir = fnamemodify(install_path.'/'.file_name, ':h')
		echohl WarningMsg
		echom 'Making directory "'.dir.'"'
		echohl None
		call mkdir(dir, 'p')
		call writefile(file_list, install_path.'/'.file_name)
	    endtry
	endfor
    endif
    lcd -
endfun
fun! Match(pattern_list, element) "{{{2
    let match = 0
    for pattern in a:pattern_list
	if a:element =~ pattern || a:element == pattern
	    let match = 1
	    break
	endif
    endfor
    return match
endfun "}}}2
com! -bang Install 	:call <SID>Install(<q-bang>)

fun! Evaluate(mode) "{{{1
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
endfun
com! -buffer -range Eval	:call Evaluate(mode())
"}}}1
" Print table tools:
fun! <SID>FormatListinColumns(list,s) "{{{1
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
endfun 

fun! <SID>PrintTable(list, spaces) "{{{1
" Take list format it with atplib#FormatListinColumns and then with
" atplib#Table (which makes columns of equal width)

    " a:list 	- list to print
    " a:spaces 	- nr of spaces between columns 

    let list = atplib#FormatListinColumns(a:list, a:spaces)
    let nr_of_columns = max(map(copy(list), 'len(v:val)'))
    let spaces_list = ( nr_of_columns == 1 ? [0] : map(range(1,nr_of_columns-1), 'a:spaces') )

    let g:spaces_list = spaces_list
    let g:nr_of_columns=nr_of_columns
    
    return atplib#Table(list, spaces_list)
endfun

fun! <SID>LocalDeclaration(variable) "{{{1
python << EOF
import vim
import re

var = vim.eval('a:variable')
buf = vim.current.buffer
idx = vim.current.window.cursor[0]-1
col = vim.current.window.cursor[1]

var_pat = re.compile(r'^(\s*let\s*)%s\b' % var)
endfun_pat = re.compile(r'^\s*(?:endf|endfu|endfun|endfunc|endfunct|endfuncti|endfunctio|endfunction)\b')
fun_pat = re.compile(r'^\s*(?:fu|fun|func|funct|functi|functio|function)\b')

def jump(idx): # {{{2
    global buf
    while idx >= 0:
        idx -= 1
        line = buf[idx]
        if re.match(fun_pat, line):
            idx = -1
            return (-1, -1)
        if re.match(endfun_pat, line):
            idx -= 1
            line = buf[idx]
            m = re.match(fun_pat, line)
            while not m and idx >= 0:
                idx -= 1
                line = buf[idx]
                m = re.match(fun_pat, line)
        if re.match(var_pat, line):
            col = line.index(var)
            return (idx, col)
    else:
        return (-1, -1) # }}}2

(n_idx, n_col) = jump(idx)
while n_idx != -1:
    (idx, col) = (n_idx, n_col)
    (n_idx, n_col) = jump(idx)

vim.command("let lnr=%s" % (idx+1))
vim.command("let col=%s" % (col+1))
EOF
let g:lnr = lnr
let g:col = col
if lnr
    call setpos(".", [0, lnr, col, 0])
endif
endfun
if has("python")
    nnoremap <silent> gd :call <SID>LocalDeclaration(expand("<cword>"))<CR>
endif
