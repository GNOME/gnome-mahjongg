gnome_mahjongg = executable(
  meson.project_name(),
  resources + [
    'config.vapi',
    'game.vala',
    'game-view.vala',
    'gnome-mahjongg.vala',
    'history.vala',
    'map.vala',
    'score-dialog.vala',
    'window.vala',
  ],
  dependencies: [
    glib_dep,
    gtk_dep,
    adwaita_dep,
    librsvg_dep,
  ],
  vala_args: [ '--pkg=posix' ],
  c_args: [
    '-DAPP_ID="@0@"'.format(app_id),
    '-DVERSION="@0@"'.format(meson.project_version()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DLOCALEDIR="@0@"'.format(localedir),
    '-DDATA_DIRECTORY="@0@"'.format(pkgdatadir),
    '-w'
  ],
  install: true
)
