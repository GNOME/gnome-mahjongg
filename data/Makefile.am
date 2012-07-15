SUBDIRS = icons

mapdir = $(datadir)/gnome-mahjongg/maps
map_DATA = \
	mahjongg.map

themedir = $(datadir)/gnome-mahjongg/themes
theme_DATA = \
	smooth.png	\
	postmodern.svg

gsettings_in_file = org.gnome.gnome-mahjongg.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

man_MANS = gnome-mahjongg.6

desktop_in_files = gnome-mahjongg.desktop.in.in
desktopdir = $(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in.in=.desktop)

EXTRA_DIST = \
	$(theme_DATA)		\
	$(gsettings_in_file)	\
	$(man_MANS)	\
	$(map_DATA)		\
	translatable_game_names.h

CLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)
DISTCLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)

install-scorefiles-local:
	-$(mkinstalldirs) $(DESTDIR)$(scoredir)
	-for i in easy difficult confounding pyramid tictactoe cloud dragon bridges ziggurat; do \
		touch $(DESTDIR)$(scoredir)/gnome-mahjongg.$$i.scores; \
		chown $(scores_user):$(scores_group) $(DESTDIR)$(scoredir)/gnome-mahjongg.$$i.scores; \
		chmod 664 $(DESTDIR)$(scoredir)/gnome-mahjongg.$$i.scores; \
	done

install-data-local: install-scorefiles-local

@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
