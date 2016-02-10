# Makefile
# This is a makefile that conveniently calls Kitura's makefile when Kitura is a dependency
# Should be copied to project's root directory

KITURA_DIR=$(wildcard Packages/Kitura-*)

make:
	make -f ${KITURA_DIR}/Makefile
