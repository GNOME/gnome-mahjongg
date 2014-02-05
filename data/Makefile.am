SUBDIRS = icons

mapdir = $(datadir)/gnome-mahjongg/maps
map_DATA = \
	mahjongg.map

themedir = $(datadir)/gnome-mahjongg/themes
theme_DATA = \
	maya.png	\
	postmodern.svg	\
	smooth.png

gsettings_SCHEMAS = org.gnome.gnome-mahjongg.gschema.xml
@GSETTINGS_RULES@

man_MANS = gnome-mahjongg.6

desktopdir = $(datadir)/applications
desktop_in_files = gnome-mahjongg.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_in_files = gnome-mahjongg.appdata.xml.in
appdata_DATA = $(appdata_in_files:.xml.in=.xml)
@INTLTOOL_XML_RULE@

EXTRA_DIST = \
	$(appdata_in_files)	\
	$(desktop_in_files)	\
	$(theme_DATA)		\
	$(gsettings_SCHEMAS)	\
	$(man_MANS)	\
	$(map_DATA)		\
	translatable_game_names.h

CLEANFILES = \
	$(appdata_DATA)	\
	$(desktop_DATA)

check-local: $(appdata_DATA) $(desktop_DATA)
	$(APPDATA_VALIDATE) $(appdata_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

-include $(top_srcdir)/git.mk
