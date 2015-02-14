
bin_name = sidebar
src_files = src/Main.vala src/Sidebar.vala
packages = --pkg gtk+-3.0 --pkg gee-0.8

all:
	valac ${packages} ${src_files} -o ${bin_name}

.PHONY: run
run: all
	./${bin_name}
