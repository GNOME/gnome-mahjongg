# SPDX-FileCopyrightText: 2018-2025 Mahjongg Contributors
# SPDX-License-Identifier: GPL-2.0-or-later

# Icon files
install_data(
  'icons' / 'hicolor' / 'scalable' / '@0@.svg'.format(app_id),
  install_dir: datadir / 'icons' / 'hicolor' / 'scalable' / 'apps'
)
install_data(
  'icons' / 'hicolor' / 'symbolic' / '@0@-symbolic.svg'.format(base_id),
  install_dir: datadir / 'icons' / 'hicolor' / 'symbolic' / 'apps',
  rename: '@0@-symbolic.svg'.format(app_id)
)

# GSchema file
gschema_conf = configuration_data()
gschema_conf.set('app-id', app_id)
gschema_conf.set('base-id-slashed', '/' + base_id.replace('.', '/'))
gschema_conf.set('gettext-package', meson.project_name())

configure_file(
  input: '@0@.gschema.xml.in'.format(base_id),
  output: '@0@.gschema.xml'.format(app_id),
  install: true,
  install_dir: datadir / 'glib-2.0' / 'schemas',
  configuration: gschema_conf
)

# DBus service file
service_conf = configuration_data()
service_conf.set('app-id', app_id)
service_conf.set('bindir', bindir)
service_conf.set('exec-name', meson.project_name())

configure_file(
  input: '@0@.service.in'.format(base_id),
  output: '@0@.service'.format(app_id),
  install: true,
  install_dir: datadir / 'dbus-1' / 'services',
  configuration: service_conf
)

# Desktop file
desktop_conf = configuration_data()
desktop_conf.set('app-id', app_id)
desktop_conf.set('exec-name', meson.project_name())

desktop_file = i18n.merge_file(
  input: configure_file(
    input: '@0@.desktop.in.in'.format(base_id),
    output: '@BASENAME@',
    configuration: desktop_conf
  ),
  output: '@0@.desktop'.format(app_id),
  install: true,
  install_dir: datadir / 'applications',
  po_dir: podir,
  type: 'desktop'
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop', desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

# MetaInfo file
metainfo_conf = configuration_data()
metainfo_conf.set('app-id', app_id)
metainfo_conf.set('developer-id', app_id.to_lower())
metainfo_conf.set('gettext-package', meson.project_name())

metainfo_file = i18n.merge_file(
  input: configure_file(
    input: '@0@.metainfo.xml.in.in'.format(base_id),
    output: '@BASENAME@',
    configuration: metainfo_conf
  ),
  output: '@0@.metainfo.xml'.format(app_id),
  install: true,
  install_dir: datadir / 'metainfo',
  po_dir: podir
)

appstreamcli = find_program('appstreamcli', required: false)
if appstreamcli.found()
  test(
    'validate-metainfo', appstreamcli,
    args: [
      'validate', '--no-net', '--explain', metainfo_file.full_path()
    ]
  )
endif

# Resources
resources_conf = configuration_data()
resources_conf.set('app-id', app_id)
resources_conf.set('base-id-slashed', '/' + base_id.replace('.', '/'))
resources = gnome.compile_resources(
  'resources',
  configure_file(
    input: '@0@.gresource.xml.in'.format(base_id),
    output: '@BASENAME@',
    configuration: resources_conf,
  ),
  source_dir : meson.current_source_dir(),
  dependencies: metainfo_file,
)

# Man page
install_man('@0@.6'.format(meson.project_name()))
