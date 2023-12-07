if exists("b:current_syntax")
    finish
endif

syntax match MyPattern /^\w\+:/

" Set the filetype as 'youtracktelescope'
let b:current_syntax = 'youtracktelescope'
