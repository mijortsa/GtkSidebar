
bin_name = sidebar
src_files = src/Main.vala src/Sidebar.vala
packages = --pkg gtk+-3.0 --pkg gee-0.8
no_c_warnings = -X -w

all:
	valac $(packages) $(src_files) -o $(bin_name) $(no_c_warnings)

.PHONY: run
run: all
	./${bin_name}
