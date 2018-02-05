SUBDIRS = icons

mapdir = $(datadir)/gnome-mahjongg/maps
map_DATA = \
	mahjongg.map

themedir = $(datadir)/gnome-mahjongg/themes
theme_DATA = \
	maya.png	\
	postmodern.svg	\
	smooth.png	\
	edu_kang_xi.png

gsettings_SCHEMAS = org.gnome.mahjongg.gschema.xml
@GSETTINGS_RULES@

man_MANS = gnome-mahjongg.6

desktopdir = $(datadir)/applications
desktop_in_files = gnome-mahjongg.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
$(desktop_DATA): $(desktop_in_files)
		$(AM_V_GEN)$(MSGFMT) --desktop --template $< -d $(top_srcdir)/po -o $@

appstream_in_files = gnome-mahjongg.appdata.xml.in
appstream_XML = $(appstream_in_files:.xml.in=.xml)
@APPSTREAM_XML_RULES@
$(appstream_XML): $(appstream_in_files)
		$(AM_V_GEN)$(MSGFMT) --xml --template $< -d $(top_srcdir)/po -o $@

EXTRA_DIST = \
	$(appstream_in_files)	\
	$(desktop_in_files)	\
	$(theme_DATA)		\
	$(gsettings_SCHEMAS)	\
	$(man_MANS)	\
	$(map_DATA)		\
	translatable_game_names.h

CLEANFILES = \
	$(appstream_XML)	\
	$(desktop_DATA)

check-local: $(desktop_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

DISTCHECK_CONFIGURE_FLAGS = --enable-appdata-check

-include $(top_srcdir)/git.mk
