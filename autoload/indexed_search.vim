let s:ScheduledEcho = ''
let s:DelaySearchIndex = 0
let g:IndSearchUT = &ut


function! s:milli_since(start)
    " Use it like this:
    "   :let s = reltime()
    "   :sleep 100m
    "   :let time_passed = s:milli_since(s)
    " This would result in a Float which represents the milliseconds passed.

    let rel_time = reltimestr(reltime(a:start))
    let [sec, milli] = map(split(rel_time, '\ze\.'), 'str2float(v:val)')
    return (sec + milli) * 1000
endfunction


func! s:ScheduleEcho(msg,highlight)

    "if &ut > 50 | let g:IndSearchUT=&ut | let &ut=50 | endif
    "if &ut > 100 | let g:IndSearchUT=&ut | let &ut=100 | endif
    if &ut > 200 | let g:IndSearchUT=&ut | let &ut=200 | endif
    " 061116 &ut is sometimes not restored and drops permanently to 50. But how ?

    let s:ScheduledEcho      = a:msg
    let use_colors = !exists('g:indexed_search_colors') || g:indexed_search_colors
    let s:ScheduledHighlight = ( use_colors ? a:highlight : "None" )

    aug IndSearchEcho

    au CursorHold *
      \ exe 'set ut='.g:IndSearchUT |
      \ if s:DelaySearchIndex | call indexed_search#ShowCurrentSearchIndex(0,'') |
      \    let s:ScheduledEcho = s:Msg | let s:ScheduledHighlight = s:Highlight |
      \    let s:DelaySearchIndex = 0 | endif |
      \ if s:ScheduledEcho != ""
      \ | exe "echohl ".s:ScheduledHighlight | echo s:ScheduledEcho | echohl None
      \ | let s:ScheduledEcho='' |
      \ endif |
      \ aug IndSearchEcho | exe 'au!' | aug END | aug! IndSearchEcho
    " how about moving contents of this au into function

    aug END
endfun " s:ScheduleEcho

func! s:CountCurrentSearchIndex(force, cmd)
" sets globals -> s:Msg , s:Highlight
    let s:Msg = '' | let s:Highlight = ''
    let builtin_errmsg = ""

    " echo "" | " make sure old msg is erased
    if a:cmd == '!'
        " if cmd is '!', we do not execute any command but report
        " last errmsg
        if v:errmsg != ""
            echohl Error
            echomsg v:errmsg
            echohl None
        endif
    elseif a:cmd != ''
        let v:errmsg = ""

        silent! exe "norm! ".a:cmd

        if v:errmsg != ""
            echohl Error
            echomsg v:errmsg
            echohl None
        endif

        if line('$') >= g:search_index_max
            " for large files, preserve original error messages and add nothing
            return ""
        endif
    else
    endif

    if !a:force && line('$') >= g:search_index_max
        let too_slow=1
        " when too_slow, we'll want to switch the work over to CursorHold
        return ""
    endif
    if @/ == '' | return "" | endif
    if version >= 700
		let save = winsaveview()
    endif
    let line = line('.')
    let vcol = virtcol('.')
    norm gg0
    let num = 0    " total # of matches in the buffer
    let exact = -1
    let after = 0
    let too_slow = 0 " if too_slow, we'll want to switch the work over to CursorHold
    let s_opt = 'Wc'
    while search(@/, s_opt) && ( num <= g:search_index_maxhit  || a:force)
        let num = num + 1
        if line('.') == line && virtcol('.') == vcol
            let exact = num
        elseif line('.') < line || (line('.') == line && virtcol('.') < vcol)
            let after = num
        endif
        let s_opt = 'W'
    endwh
    if version >= 700
		call winrestview(save)
	else
		exe line
		exe "norm! ".vcol."|"
    endif
    if !a:force && num > g:search_index_maxhit
        if exact >= 0
            let too_slow=1 "  if too_slow, we'll want to switch the work over to CursorHold
            let num=">".(num-1)
        else
            let s:Msg = ">".(num-1)." matches"
            if v:errmsg != ""
                let s:Msg = ""  " avoid overwriting builtin errmsg with our ">1000 matches"
            endif
            return ""
        endif
    endif



    "           Messages Summary
    "
    " Short Message            Long Message
    " -------------------------------------------
    " %d of %d matches         Match %d of %d
    " Last of %d matches       <-same
    " First of %d matches      <-same
    " No matchess              <-same
    " -------------------------------------------
    let s:Highlight = "Directory"
    if num == "0"
        let s:Highlight = "Error"
        let prefix = "No matches "
    elseif exact == 1 && num==1
        " s:Highlight remains default
        "let prefix = "At single match"
        let prefix = "Single match"
    elseif exact == 1
        let s:Highlight = "Search"
        "let prefix = "At 1st  match, # 1 of " . num
        "let prefix = "First match, # 1 of " . num
        let prefix = "First of " . num . " matches "
    elseif exact == num
        let s:Highlight = "LineNr"
        "let prefix = "Last match, # ".num." of " . num
        "let prefix = "At last match, # ".num." of " . num
        let prefix = "Last of " . num . " matches "
    elseif exact >= 0
        "let prefix = "At # ".exact." match of " . num
        "let prefix = "Match # ".exact." of " . num
        "let prefix = "# ".exact." match of " . num
        if exists('g:indexed_search_shortmess') && g:indexed_search_shortmess
            let prefix = exact." of " . num . " matches "
        else
            let prefix = "Match ".exact." of " . num
        endif
    elseif after == 0
        let s:Highlight = "MoreMsg"
        let prefix = "Before first match, of ".num." matches "
        if num == 1
            let prefix = "Before single match"
        endif
    elseif after == num
        let s:Highlight = "WarningMsg"
        let prefix = "After last match of ".num." matches "
        if num == 1
            let prefix = "After single match"
        endif
    else
        let prefix = "Between matches ".after."-".(after+1)." of ".num
    endif
    let s:Msg = prefix . "  /".@/ . "/"
    return ""
endfunc


func! indexed_search#DelaySearchIndex(force,cmd)
    let s:DelaySearchIndex = 1
    call s:ScheduleEcho('','')
endfunc

func! indexed_search#ShowCurrentSearchIndex(force, cmd)
    " NB: function saves and restores @/ and direction
    " this used to cause me many troubles

    call s:CountCurrentSearchIndex(a:force, a:cmd) " -> s:Msg, s:Highlight

    if s:Msg != ""
        call s:ScheduleEcho(s:Msg, s:Highlight )
    endif
endfun
