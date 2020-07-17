CC             = clang++

.PHONY: help clean

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_\.-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

builtins.o: just.js lib/*.js ## compile builtins js
	ld -r -b binary just.js lib/websocket.js lib/inspector.js lib/loop.js lib/require.js lib/path.js lib/repl.js lib/fs.js -o builtins.o

deps: ## download v8 lib and headers
	mkdir -p deps
	curl -L -o deps/v8.tar.gz https://github.com/just-js/libv8/raw/master/v8.tar.gz
	tar -zxvf deps/v8.tar.gz

runtime: builtins.o deps/v8/libv8_monolith.a ## build runtime
	$(CC) -c -std=c++11 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -O3 -g -march=native -mtune=native -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -static -flto -pthread -m64 -Wl,--start-group deps/v8/libv8_monolith.a just.o builtins.o -Wl,--end-group -ldl -o just
	rm *.o

clean: ## tidy up
	rm -f *.o
	rm -f just

uninstall: ## remove just and build deps
	sudo rm -f /usr/local/bin/just
	rm -fr deps
	make clean

install: ## install
	sudo cp -f just /usr/local/bin/
	
.DEFAULT_GOAL := help