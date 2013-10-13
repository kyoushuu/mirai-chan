## Process this file with automake to produce Makefile.in

## Created by Anjuta



AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(localedir)"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(pkgdatadir)"\" \
	$(MIRAI_CHAN_CFLAGS)

AM_CFLAGS = \
	 -Wall \
	 -g

bin_PROGRAMS = mirai-chan

mirai_chan_SOURCES = \
	config.vapi \
	main.vala \
	irc-bot.vala

mirai_chan_VALAFLAGS = \
	--pkg gio-2.0


mirai_chan_LDFLAGS = \
	-Wl,--export-dynamic

mirai_chan_LDADD = \
	$(MIRAI_CHAN_LIBS)

