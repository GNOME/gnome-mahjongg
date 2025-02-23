# SPDX-FileCopyrightText: 2018-2025 Mahjongg Contributors
# SPDX-License-Identifier: GPL-2.0-or-later

project(
  'gnome-mahjongg', ['vala', 'c'],
  version: '48.rc',
  meson_version: '>= 0.59.0'
)

gnome = import('gnome')
i18n = import('i18n')

# App ID
if get_option('profile') == 'development'
  profile = '.Devel'
else
  profile = ''
endif

base_id = 'org.gnome.Mahjongg'
app_id  = 'org.gnome.Mahjongg@0@'.format(profile)

# Paths
mandir      = get_option('prefix') / get_option('mandir')
localedir   = get_option('prefix') / get_option('localedir')
datadir     = get_option('prefix') / get_option('datadir')
pkgdatadir  = datadir / 'gnome-mahjongg'
bindir      = get_option('prefix') / get_option('bindir')
podir       = meson.project_source_root() / 'po'

# Dependencies
glib_dep    = dependency('glib-2.0', version: '>= 2.40.0')
gio_dep     = dependency('gio-2.0', version: '>= 2.40.0')
gtk_dep     = dependency('gtk4', version: '>= 4.14.0')
adwaita_dep = dependency('libadwaita-1', version: '>= 1.5.0')
librsvg_dep = dependency('librsvg-2.0', version: '>= 2.46.0')

subdir('po')
subdir('data')
subdir('help')
subdir('src')

gnome.post_install(
  gtk_update_icon_cache: true,
  update_desktop_database: true,
  glib_compile_schemas: true,
)
