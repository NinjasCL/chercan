WREN_VERSION = 0.3.0
DIST = docs

.PHONY: build asciidoc build-all serve wren-macos wren-linux

ba build-all:
	@make asciidoc
	@make build

b build:
# Prepare the build dir
	@rm -rf dist/
	@mkdir -p dist/
	@cp -a static/ dist/
# Find all the content files and pass them to the build without extension
# Only supports root level files. Because Wren CLI does not have mkdir yet.
# https://unix.stackexchange.com/a/283915
	@find content -maxdepth 1 -name "*.wren" | rev | cut -f 2- -d "." | rev | xargs -I{} ./wren chercan/build.wren {}

# Github pages
	@rm -rf ${DIST}
	@mv -f dist ${DIST}

a asciidoc:
# Compile all asciidoc files first
	@find content -maxdepth 2 -name "*.adoc" | xargs asciidoctor

s serve:
	@make build
	python3 -m http.server -d ${DIST}

wm wren-macos:
	@wget https://github.com/wren-lang/wren-cli/releases/download/${WREN_VERSION}/wren_cli-mac-${WREN_VERSION}.zip
	@unzip -o wren_cli-mac-${WREN_VERSION}.zip
	@rm -f wren_cli-mac-${WREN_VERSION}.zip
	@rm -f readme.md
	@mv wren_cli wren
	@ls

wl wren-linux:
	@wget https://github.com/wren-lang/wren-cli/releases/download/${WREN_VERSION}/wren_cli-linux-${WREN_VERSION}.zip
	@unzip -o wren_cli-linux-${WREN_VERSION}.zip
	@rm -f wren_cli-linux-${WREN_VERSION}.zip
	@rm -f wren_cli-linux-${WREN_VERSION}/readme.md
	@mv wren_cli-linux-${WREN_VERSION}/wren_cli wren
	@rm -rf wren_cli-linux-${WREN_VERSION}
	@ls
