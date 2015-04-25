all: sounds.so dir.so usleep.so

clean:
	rm *.o *.so
	rm ../*.so

sounds.so: sounds.h sounds.c
	clang -fobjc-arc -fmodules -fmodules-prune-interval=86400 -fmodules-prune-after=345600 -o sounds.o -c sounds.c
	clang -shared -o sounds.so sounds.o -framework Foundation -framework CoreAudio -fobjc-arc -fobjc-link-runtime -lluajit -Lluajit
	mv sounds.so ..

dir.so: dir.c
	clang -shared -o dir.so dir.c -lluajit -Lluajit
	mv dir.so ..

usleep.so: usleep.c
	clang -shared -o usleep.so usleep.c -lluajit -Lluajit
	mv usleep.so ..
