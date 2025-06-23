# upstream renamed branch "master" to "main", breaking fetch :(
SRC_URI:remove = "git://github.com/cracklib/cracklib;protocol=https;branch=master"
SRC_URI:append = " git://github.com/cracklib/cracklib;protocol=https;branch=main"
