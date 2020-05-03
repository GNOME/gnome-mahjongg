hicolordir = datadir / 'icons' / 'hicolor'

install_data ('icons' / 'hicolor' / 'scalable' / 'org.gnome.Mahjongg.svg',
              install_dir: hicolordir / 'scalable' / 'apps')
install_data ('icons' / 'hicolor' / 'symbolic' / 'org.gnome.Mahjongg-symbolic.svg',
              install_dir: hicolordir / 'symbolic' / 'apps')

schemasdir = gio_dep.get_pkgconfig_variable(
  'schemasdir',
  define_variable : [
    'datadir',
    get_option('datadir')
  ]
)

install_data ('org.gnome.Mahjongg.gschema.xml',
              install_dir: schemasdir)

install_data ('mahjongg.map', install_dir: join_paths (pkgdatadir, 'maps'))
install_data ('postmodern.svg', install_dir: join_paths (pkgdatadir, 'themes'))
install_data ('smooth.png', install_dir: join_paths (pkgdatadir, 'themes'))
install_data ('edu_kang_xi.png', install_dir: join_paths (pkgdatadir, 'themes'))

desktop_file = i18n.merge_file (
  'desktop-file',
  input:       'org.gnome.Mahjongg.desktop.in',
  output:      'org.gnome.Mahjongg.desktop',
  install:     true,
  install_dir: datadir / 'applications',
  po_dir:      '../po',
  type:        'desktop'
)

desktop_file_validate = find_program('desktop-file-validate', required: false)
if desktop_file_validate.found()
  test(
    'validate-desktop',
    desktop_file_validate,
    args: [
      desktop_file.full_path()
    ]
  )
endif

appdata_file = i18n.merge_file ('appdata-file',
                 input: 'org.gnome.Mahjongg.appdata.xml.in',
                 output: 'org.gnome.Mahjongg.appdata.xml',
                 install: true,
                 install_dir: join_paths (datadir, 'metainfo'),
                 po_dir: '../po')
appstream_util = find_program('appstream-util', required: false)
if appstream_util.found()
  test(
    'validate-appdata', appstream_util,
    args: [
      'validate-relax', '--nonet', appdata_file.full_path()
    ]
  )
endif

install_man ('gnome-mahjongg.6')

resources = gnome.compile_resources ('resources', 'org.gnome.Mahjongg.gresource.xml',
                                     source_dir: '.',
                                     c_name: 'resources')

# Compile GSettings schemas

if get_option('compile-schemas').enabled()
  compileschemas = gio_dep.get_pkgconfig_variable('glib_compile_schemas')
  meson.add_install_script(compileschemas, get_option('prefix') / schemasdir)
endif

# Rebuild icon cache

if get_option('update-icon-cache').enabled()
  updateiconcache = find_program('gtk-update-icon-cache')
  meson.add_install_script(updateiconcache.path(), '-t', '-f', get_option('prefix') / hicolordir / 'scalable')
  meson.add_install_script(updateiconcache.path(), '-t', '-f', get_option('prefix') / hicolordir / 'symbolic')
endif

# Make D-Bus activatable
service_conf = configuration_data()
service_conf.set('bindir', bindir)

service = 'org.gnome.Mahjongg.service'

configure_file (
  input: service + '.in',
  output: service,
  install: true,
  install_dir: join_paths (datadir, 'dbus-1', 'services'),
  configuration: service_conf
)
