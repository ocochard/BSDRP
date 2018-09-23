: brand ( x y -- ) \ "bsdrp" [wide] logo in B/W (7 rows x 42 columns)

    2dup at-xy ."  ____   _____ _____  ____  ____  " 1+
    2dup at-xy ." |  _ \ / ____|  __ \|  _ \|  _ \ " 1+
    2dup at-xy ." | |_) | (___ | |  | | |_) | |_) |" 1+
    2dup at-xy ." |  _ < \___ \| |  | |    /|  __/ " 1+
    2dup at-xy ." | |_) |____) | |__| | |\ \| |    " 1+
    2dup at-xy ." |     |      |      | | | | |    " 1+
         at-xy ." |____/|_____/|_____/|_| |_|_| BSDRP_VERSION"

    \ Put the cursor back at the bottom
    0 25 at-xy
;
