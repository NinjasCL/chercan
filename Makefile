WREN_VERSION = 0.3.0
DIST = docs

.PHONY: serve build wm wl

b build:
	rm -rf dist/
	mkdir -p dist/
	cp -a static/ dist/
	# Find all the content files and pass them to the build without extension
	# https://unix.stackexchange.com/a/283915
	find content -maxdepth 1 -name "*.wren" | rev | cut -f 2- -d "." | rev | xargs -I{} ./wren chercan/build.wren {}

	# github pages
	rm -rf ${DIST}
	mv -f dist ${DIST}

s serve:
	make build
	python3 -m http.server -d ${DIST}

wm wren-macos:
	wget https://github.com/wren-lang/wren-cli/releases/download/${WREN_VERSION}/wren_cli-mac-${WREN_VERSION}.zip
	unzip -o wren_cli-mac-${WREN_VERSION}.zip
	rm -f wren_cli-mac-${WREN_VERSION}.zip
	rm -f readme.md
	mv wren_cli wren

wl wren-linux:
	wget https://github.com/wren-lang/wren-cli/releases/download/${WREN_VERSION}/wren_cli-linux-${WREN_VERSION}.zip
	unzip -o wren_cli-linux-${WREN_VERSION}.zip
	rm -f wren_cli-linux-${WREN_VERSION}.zip
	rm -f wren_cli-linux-${WREN_VERSION}/readme.md
	mv wren_cli-linux-${WREN_VERSION}/wren_cli wren
	rm -rf wren_cli-linux-${WREN_VERSION}
