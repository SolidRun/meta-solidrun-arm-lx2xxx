# project was moved from intel to yoctoproject
SRC_URI:remove = "git://github.com/intel/${BPN};branch=master;protocol=https"
SRC_URI:append = " git://github.com/yoctoproject/bmaptool;branch=main;protocol=https"
