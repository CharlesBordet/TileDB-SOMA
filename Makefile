# This Makefile captures common developer build and test use cases.

MAKEFLAGS += --no-print-directory

# print help by default
help:

# install 
# -------------------------------------------------------------------

# set default variable values, if non-null
build ?= Release

.PHONY: install
install: clean
	@./scripts/bld --prefix=${prefix} --tiledb=${tiledb} --build=${build}
	@TILEDB_PATH=${tiledb} pip install -v -e apis/python

.PHONY: r-build
r-build: clean
	@./scripts/bld --prefix=${prefix} --tiledb=${tiledb} --build=${build} --r-build

# incremental compile and update python install
# -------------------------------------------------------------------
.PHONY: update
update:
	cd build && make -j && make install-libtiledbsoma
	cp dist/lib/lib* apis/python/src/tiledbsoma/

# test
# -------------------------------------------------------------------
.PHONY: test
test: data
	ctest --test-dir build/libtiledbsoma -C Release --verbose --rerun-failed --output-on-failure
	pytest apis/python/tests 

.PHONY: data
data:
	rm -rvf test/soco
	./apis/python/devtools/ingestor \
		--soco \
		-o test/soco \
		-n \
		data/pbmc3k_processed.h5ad \
		data/10x-pbmc-multiome-v1.0/subset_100_100.h5ad

# format
# -------------------------------------------------------------------
.PHONY: check-format
check-format:
	 @./scripts/run-clang-format.sh . clang-format 0 \
		`find libtiledbsoma -name "*.cc" -or -name "*.h"`

.PHONY: format
format:
	 @./scripts/run-clang-format.sh . clang-format 1 \
		`find libtiledbsoma -name "*.cc" -or -name "*.h"`

# clean
# -------------------------------------------------------------------
.PHONY: clean
clean:
	@rm -rf build dist

.PHONY: cleaner
cleaner:
	@printf "*** dry-run mode: remove -n to actually remove files\n"
	git clean -ffdx -e .vscode -e test/tiledbsoma -n

# help
# -------------------------------------------------------------------
define HELP
Usage: make rule [options]

Rules:
  install [options]   Build C++ library and install python module
  r-build [options]   Build C++ static library with "#define R_BUILD" for R
  update              Incrementally build C++ library and update python module
  test                Run tests
  check-format        Run C++ format check
  format              Run C++ format
  clean               Remove build artifacts

Options:
  build=BUILD_TYPE    Cmake build type = Release|Debug|RelWithDebInfo|Coverage [Release]
  prefix=PREFIX       Install location [${PWD}/dist]
  tiledb=TILEDB_DIST  Absolute path to custom TileDB build 

Examples:
  Install Release build

    make install

  Install Debug build of libtiledbsoma and libtiledb

    make install build=Debug

  Install Release build with custom libtiledb

    make install tiledb=$$PWD/../TileDB/dist

  Incrementally build C++ changes and update the python module

    make update


endef 
export HELP

.PHONY: help
help:
	@printf "$${HELP}"

