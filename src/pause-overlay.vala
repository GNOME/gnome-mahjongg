// SPDX-FileCopyrightText: 2026 Mahjongg Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/pause-overlay.ui")]
public class PauseOverlay : Gtk.Box {
    [GtkChild]
    private unowned Gtk.Button resume_button;

    [GtkChild]
    private unowned Gtk.Button quit_button;

    public new void show (bool resuming_game = false) {
        quit_button.visible = !resuming_game;
        visible = true;
        resume_button.grab_focus ();
    }

    public new void hide () {
        visible = false;
    }
}
