" Allow '.' to repeat macros. Finally!
" Taken from here: 
" https://vi.stackexchange.com/questions/11210/can-i-repeat-a-macro-with-the-dot-operator
" 
" When . repeats g@, repeat the last macro.
fun! AtRepeat(_)
    " If no count is supplied use the one saved in s:atcount.
    " Otherwise save the new count in s:atcount, so it will be
    " applied to repeats.
    let s:atcount = v:count ? v:count : s:atcount
    " feedkeys() rather than :normal allows finishing in Insert
    " mode, should the macro do that. @@ is remapped, so 'opfunc'
    " will be correct, even if the macro changes it.
    call feedkeys(s:atcount.'@@')
endfun

fun! AtSetRepeat(_)
    set operatorfunc=AtRepeat
endfun

" Called by g@ being invoked directly for the first time. Sets
" 'opfunc' ready for repeats with . by calling AtSetRepeat().
fun! AtInit()
    " Make sure setting 'opfunc' happens here, after initial playback
    " of the macro recording, in case 'opfunc' is set there.
    set operatorfunc=AtSetRepeat
    return 'g@l'
endfun

" Enable calling a function within the mapping for @
nno <expr> <plug>@init AtInit()
" A macro could, albeit unusually, end in Insert mode.
ino <expr> <plug>@init "\<c-o>".AtInit()

fun! AtReg()
    let s:atcount = v:count1
    let l:c = nr2char(getchar())
    return '@'.l:c."\<plug>@init"
endfun


" The following code allows pressing . immediately after
" recording a macro to play it back.
nmap <expr> @ AtReg()
fun! QRepeat(_)
    call feedkeys('@'.s:qreg)
endfun

fun! QSetRepeat(_)
    set operatorfunc=QRepeat
endfun

fun! QStop()
    set operatorfunc=QSetRepeat
    return 'g@l'
endfun

nno <expr> <plug>qstop QStop()
ino <expr> <plug>qstop "\<c-o>".QStop()

let s:qrec = 0
fun! QStart()
    if s:qrec == 1
        let s:qrec = 0
        return "q\<plug>qstop"
    endif
    let s:qreg = nr2char(getchar())
    if s:qreg =~# '[0-9a-zA-Z"]'
        let s:qrec = 1
    endif
    return 'q'.s:qreg
endfun

" Finally, remap q! Recursion is actually useful here I think,
" otherwise I would use 'nnoremap'.
nmap <expr> q QStart()
