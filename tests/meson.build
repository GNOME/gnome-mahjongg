# SPDX-FileCopyrightText: 2025 Mahjongg Contributors
# SPDX-License-Identifier: GPL-2.0-or-later

tests = {
    'test-game': [
        srcdir / 'game.vala',
        srcdir / 'game-save.vala',
        srcdir / 'map.vala',
    ],
    'test-map': [
        srcdir / 'map.vala',
    ]
}

foreach test_name, sources : tests
  test_bin = executable(test_name,
    sources + ['@0@.vala'.format(test_name)],
    dependencies: [
      gio_dep,
      glib_dep,
    ],
  )
  test(test_name, test_bin)
endforeach
