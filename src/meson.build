# SPDX-FileCopyrightText: 2018-2025 Mahjongg Contributors
# SPDX-License-Identifier: GPL-2.0-or-later

gnome_mahjongg = executable(
  meson.project_name(),
  resources + files(
    'config.vapi',
    'game.vala',
    'game-save.vala',
    'game-view.vala',
    'gnome-mahjongg.vala',
    'history.vala',
    'map.vala',
    'rules-dialog.vala',
    'score-dialog.vala',
    'window.vala',
  ),
  dependencies: [
    glib_dep,
    gtk_dep,
    adwaita_dep,
    librsvg_dep,
    libm_dep,
  ],
  vala_args: [ '--pkg=posix' ],
  c_args: [
    '-DAPP_ID="@0@"'.format(app_id),
    '-DVERSION="@0@"'.format(meson.project_version()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DLOCALEDIR="@0@"'.format(localedir),
    '-w'
  ],
  install: true
)
