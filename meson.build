project ('gnome-mahjongg', ['vala', 'c'],
         version: '3.38.0',
         license: 'GPLv3+',
         default_options: [
             'warning_level=1',
             'buildtype=debugoptimized',
         ],
         meson_version: '>= 0.49.0')

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
gtk_dep     = dependency ('gtk+-3.0', version: '>= 3.14.0')
librsvg_dep = dependency ('librsvg-2.0', version: '>= 2.32.0')

subdir ('po')
subdir ('data')
subdir ('help')
subdir ('src')
