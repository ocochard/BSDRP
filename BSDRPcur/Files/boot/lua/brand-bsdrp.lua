local drawer = require("drawer")

local bsdrp = {
"  ____   _____ _____  ____  ____            ",
" |  _ \\ / ____|  __ \\|  _ \\|  _ \\           ",
" | |_) | (___ | |  | | |_) | |_) |          ",
" |  _ < \\___ \\| |  | |    /|  __/           ",
" | |_) |____) | |__| | |\\ \\| |              ",
" |     |      |      | | | | |              ",
" |____/|_____/|_____/|_| |_|_| BSDRP_VERSION"
}

drawer.addBrand("bsdrp", {
        graphic = bsdrp,
})

return true
