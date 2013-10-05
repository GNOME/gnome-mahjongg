SUBDIRS = icons

mapdir = $(datadir)/gnome-mahjongg/maps
map_DATA = \
	mahjongg.map

themedir = $(datadir)/gnome-mahjongg/themes
theme_DATA = \
	default.png	\
	default2.png	\
	greek-letters.png \
	maya.png	\
	postmodern.svg	\
	seta.png	\
	smooth.png

gsettings_SCHEMAS = org.gnome.gnome-mahjongg.gschema.xml
@GSETTINGS_RULES@

man_MANS = gnome-mahjongg.6

desktopdir = $(datadir)/applications
desktop_in_files = mahjongg.desktop.in
desktop_DATA = $(desktop_in_files:.desktop.in=.desktop)
@INTLTOOL_DESKTOP_RULE@

appdatadir = $(datadir)/appdata
appdata_DATA = gnome-mahjongg.appdata.xml

EXTRA_DIST = \
	$(appdata_DATA)		\
	$(desktop_in_files)	\
	$(theme_DATA)		\
	$(gsettings_SCHEMAS)	\
	$(man_MANS)	\
	$(map_DATA)		\
	translatable_game_names.h

CLEANFILES = $(desktop_DATA)

check-local: $(appdata_DATA) $(desktop_DATA)
	$(APPDATA_VALIDATE) $(appdata_DATA)
	$(DESKTOP_FILE_VALIDATE) $(desktop_DATA)

-include $(top_srcdir)/git.mk
