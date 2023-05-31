project ('gnome-mahjongg', ['vala', 'c'],
         version: '3.40.1',
         license: 'GPLv3+',
         default_options: [
             'warning_level=1',
             'buildtype=debugoptimized',
         ],
         meson_version: '>= 0.57.0')

gnome = import ('gnome')
i18n = import ('i18n')

# Paths
mandir      = join_paths (get_option ('prefix'), get_option ('mandir'))
localedir   = join_paths (get_option ('prefix'), get_option ('localedir'))
datadir     = join_paths (get_option ('prefix'), get_option ('datadir'))
pkgdatadir  = join_paths (datadir, 'gnome-mahjongg')
bindir      = join_paths (get_option ('prefix'), get_option ('bindir'))

# Dependencies
glib_dep    = dependency ('glib-2.0', version: '>= 2.40.0')
gio_dep     = dependency ('gio-2.0', version: '>= 2.40.0')
gtk_dep     = dependency ('gtk4', version: '>= 4.5.0')
adwaita_dep = dependency ('libadwaita-1')
librsvg_dep = dependency ('librsvg-2.0', version: '>= 2.46.0')

subdir ('po')
subdir ('data')
subdir ('help')
subdir ('src')
