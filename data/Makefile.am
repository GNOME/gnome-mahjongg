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

gsettings_in_file = org.gnome.gnome-mahjongg.gschema.xml.in
gsettings_SCHEMAS = $(gsettings_in_file:.xml.in=.xml)
@INTLTOOL_XML_NOMERGE_RULE@
@GSETTINGS_RULES@

man_MANS = gnome-mahjongg.6

desktop_in_files = mahjongg.desktop.in.in
desktopdir = $(datadir)/applications
desktop_DATA = $(desktop_in_files:.desktop.in.in=.desktop)

appdatadir = $(datadir)/appdata
appdata_DATA = gnome-mahjongg.appdata.xml

EXTRA_DIST = \
	$(appdata_DATA)		\
	$(theme_DATA)		\
	$(gsettings_in_file)	\
	$(man_MANS)	\
	$(map_DATA)		\
	translatable_game_names.h

CLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)
DISTCLEANFILES = $(desktop_DATA) $(gsettings_SCHEMAS)

@INTLTOOL_DESKTOP_RULE@

-include $(top_srcdir)/git.mk
