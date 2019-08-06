project ('gnome-mahjongg', ['vala', 'c'],
         version: '3.33.90',
         license: 'GPLv3+',
         default_options: [
             'warning_level=1',
             'buildtype=debugoptimized',
         ],
         meson_version: '>= 0.37.1')

gnome = import ('gnome')
i18n = import ('i18n')

# Paths
mandir = join_paths (get_option ('prefix'), get_option ('mandir'))
localedir = join_paths (get_option ('prefix'), get_option ('localedir'))
datadir = join_paths (get_option ('prefix'), get_option ('datadir'))
pkgdatadir = join_paths (datadir, 'gnome-mahjongg')

# Dependencies
glib_dep = dependency ('glib-2.0', version: '>= 2.40.0')
gtk_dep = dependency ('gtk+-3.0', version: '>= 3.13.2')
librsvg_dep = dependency ('librsvg-2.0', version: '>= 2.32.0')

subdir ('po')
subdir ('data')
subdir ('help')
subdir ('src')
meson.add_install_script ('data/meson_post_install.py')
