// SPDX-FileCopyrightText: 2025 Mahjongg Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/rules-dialog.ui")]
public class RulesDialog : Adw.PreferencesDialog {
    [GtkChild]
    private unowned Gtk.Image game_image;

    public RulesDialog () {
        game_image.icon_name = "%s-symbolic".printf (APP_ID);
    }
}
