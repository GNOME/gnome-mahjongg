bin_PROGRAMS = gnome-mahjongg

gnome_mahjongg_SOURCES = 	\
	config.vapi	\
	fixes.vapi	\
	game.vala	\
	game-view.vala	\
	gnome-mahjongg.vala	\
	history.vala	\
	map.vala

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

-include $(top_srcdir)/git.mk
