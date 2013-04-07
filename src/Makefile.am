bin_PROGRAMS = gnome-mahjongg

BUILT_SOURCES = resources.c

resources.c: gnome-mahjongg.gresource.xml $(shell $(GLIB_COMPILE_RESOURCES) --generate-dependencies --sourcedir=$(srcdir) $(srcdir)/gnome-mahjongg.gresource.xml)
	$(AM_V_GEN) $(GLIB_COMPILE_RESOURCES) --target=$@ --sourcedir=$(srcdir) --generate-source $<

gnome_mahjongg_SOURCES = 	\
	config.vapi	\
	fixes.vapi	\
	game.vala	\
	game-view.vala	\
	gnome-mahjongg.vala	\
	history.vala	\
	map.vala	\
	$(BUILT_SOURCES)

gnome_mahjongg_VALAFLAGS = \
	--pkg posix \
	--pkg gtk+-3.0 \
	--pkg librsvg-2.0

gnome_mahjongg_CFLAGS = \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DDATA_DIRECTORY=\"$(datadir)/gnome-mahjongg\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	$(GNOME_MAHJONGG_CFLAGS)

gnome_mahjongg_LDADD = \
	$(GNOME_MAHJONGG_LIBS)

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp

EXTRA_DIST = \
	gnome-mahjongg.gresource.xml \
	menu.ui

-include $(top_srcdir)/git.mk
