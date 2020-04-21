all:
	$(MAKE) --directory Tools/unix
	$(MAKE) --directory Source
	$(MAKE) --directory Source/Images

clean:
	$(MAKE) --directory Tools/unix clean
	$(MAKE) --directory Source clean
	$(MAKE) --directory Binary clean

clobber:
	$(MAKE) --directory Tools/unix clobber
	$(MAKE) --directory Source  clobber
	$(MAKE) --directory Binary clobber
	rm -f typescript

diff:
	$(MAKE) --directory diff

