foreach size: [ '16x16', '22x22', '24x24', '32x32', '48x48' ]
    install_data (join_paths ('icons', 'hicolor', size, 'org.gnome.Mahjongg.png'),
                  install_dir: join_paths (datadir, 'icons', 'hicolor', size, 'apps'))
endforeach
install_data (join_paths ('icons', 'hicolor', 'scalable', 'org.gnome.Mahjongg.svg'),
              install_dir: join_paths (datadir, 'icons', 'hicolor', 'scalable', 'apps'))
install_data (join_paths ('icons', 'hicolor', 'scalable', 'org.gnome.Mahjongg-symbolic.svg'),
              install_dir: join_paths (datadir, 'icons', 'hicolor', 'scalable', 'apps'))

install_data ('org.gnome.Mahjongg.gschema.xml',
              install_dir: join_paths (datadir, 'glib-2.0', 'schemas'))

install_data ('mahjongg.map', install_dir: join_paths (pkgdatadir, 'maps'))

install_data ('maya.png', install_dir: join_paths (pkgdatadir, 'themes'))
install_data ('postmodern.svg', install_dir: join_paths (pkgdatadir, 'themes'))
install_data ('smooth.png', install_dir: join_paths (pkgdatadir, 'themes'))
install_data ('edu_kang_xi.png', install_dir: join_paths (pkgdatadir, 'themes'))

i18n.merge_file ('desktop-file',
                 input: 'org.gnome.Mahjongg.desktop.in',
                 output: 'org.gnome.Mahjongg.desktop',
                 install: true,
                 install_dir: join_paths (datadir, 'applications'),
                 po_dir: '../po',
                 type: 'desktop')

i18n.merge_file ('appdata-file',
                 input: 'org.gnome.Mahjongg.appdata.xml.in',
                 output: 'org.gnome.Mahjongg.appdata.xml',
                 install: true,
                 install_dir: join_paths (datadir, 'metainfo'),
                 po_dir: '../po')

install_man ('gnome-mahjongg.6')
