

gnome_mahjongg = executable (
  'gnome-mahjongg',
  resources + [
    'config.vapi',
    'game.vala',
    'game-view.vala',
    'gnome-mahjongg.vala',
    'history.vala',
    'map.vala',
    'score-dialog.vala',
    'window.vala',
    'preferences.vala',
  ],
  dependencies: [
    glib_dep,
    gtk_dep,
    adwaita_dep,
    librsvg_dep,
  ],
  vala_args: [ '--pkg=posix' ],
  c_args: [
    '-DVERSION="@0@"'.format (meson.project_version ()),
    '-DGETTEXT_PACKAGE="gnome-mahjongg"',
    '-DLOCALEDIR="@0@"'.format (localedir),
    '-DDATA_DIRECTORY="@0@"'.format (pkgdatadir)
  ],
  install: true
)
