# Package

version       = "0.1.0"
author        = "Mike Belanger"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["strength_tracker"]



# Dependencies

requires "nim >= 1.1.1"

# Tasks

task frontend, "compiles test front-end":
    exec "nim js src/frontend/main_page.nim"
    mkDir "public/js"
    cpFile "src/frontend/main_page.js", "public/js/main_page.js"