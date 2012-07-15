bin_PROGRAMS = gnome-mahjongg

gnome_mahjongg_SOURCES = 	\
	config.vapi	\
	fixes.vapi	\
	game.vala	\
	game-view.vala	\
	gnome-mahjongg.vala	\
	map.vala

gnome_mahjongg_VALAFLAGS = \
	--pkg posix \
	--pkg gtk+-3.0 \
	--vapidir $(top_srcdir)/libgames-support \
	--pkg GnomeGamesSupport-1.0

gnome_mahjongg_CFLAGS = \
	-I$(top_srcdir)/libgames-support \
	-DVERSION=\"$(VERSION)\" \
	-DGETTEXT_PACKAGE=\"$(GETTEXT_PACKAGE)\" \
	-DDATA_DIRECTORY=\"$(datadir)/gnome-mahjongg\" \
	-DLOCALEDIR=\"$(datadir)/locale\" \
	$(GTK_CFLAGS) \
	$(RSVG_CFLAGS)

gnome_mahjongg_LDADD = \
	$(top_builddir)/libgames-support/libgames-support.la \
	$(GTK_LIBS)	\
	$(RSVG_LIBS) \
	$(INTLLIBS)

install-exec-hook:
	-if test "$(setgid)" = "true"; then \
	  chgrp $(scores_group) $(DESTDIR)$(bindir)/gnome-mahjongg && chmod 2555 $(DESTDIR)$(bindir)/gnome-mahjongg ;\
	fi

CLEANFILES = \
	$(patsubst %.vala,%.c,$(filter %.vala, $(SOURCES))) \
	*_vala.stamp

-include $(top_srcdir)/git.mk
