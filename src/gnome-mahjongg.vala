/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class Mahjongg : Adw.Application {
    private Settings settings;

    private History history;

    private List<Map> maps = new List<Map> ();

    private MahjonggWindow window;
    private ScoreDialog score_dialog;

    private GameView game_view;

    private const OptionEntry[] OPTION_ENTRIES = {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print release version and exit"), null },
        { null }
    };

    private const ActionEntry[] ACTION_ENTRIES = {
        { "new-game", new_game_cb },
        { "undo", undo_cb },
        { "redo", redo_cb },
        { "hint", hint_cb },
        { "pause", pause_cb },
        { "restart-game", restart_game_cb },
        { "scores", scores_cb },
        { "layout", null, "s", "''", layout_cb },
        { "layout-rotation", null, "s", "''", layout_rotation_cb },
        { "background-color", null, "s", "''", background_color_cb },
        { "theme", null, "s", "''", theme_cb },
        { "help", help_cb },
        { "about", about_cb },
        { "quit", quit_cb }
    };

    public Mahjongg () {
        Object (
            application_id: APP_ID,
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/org/gnome/Mahjongg"
        );
        add_main_option_entries (OPTION_ENTRIES);
    }

    protected override void startup () {
        base.startup ();

        add_action_entries (ACTION_ENTRIES, this);
        set_accels_for_action ("app.new-game", { "<Primary>n" });
        set_accels_for_action ("app.restart-game", { "<Primary>r" });
        set_accels_for_action ("app.pause", { "<Primary>p", "Pause" });
        set_accels_for_action ("app.hint", { "<Primary>h" });
        set_accels_for_action ("app.undo", { "<Primary>z" });
        set_accels_for_action ("app.redo", { "<Shift><Primary>z" });
        set_accels_for_action ("app.help", { "F1" });
        set_accels_for_action ("app.quit", { "<Primary>q", "<Primary>w" });

        settings = new Settings (get_application_id ());
        load_maps ();

        history = new History (Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history"));
        history.load ();

        var using_cairo = Environment.get_variable ("GSK_RENDERER") == "cairo";
        game_view = new GameView (using_cairo);
        view_click_controller = new Gtk.GestureClick ();
        view_click_controller.pressed.connect (on_click);
        game_view.add_controller (view_click_controller);

        window = new MahjonggWindow (this, game_view, maps);

        var layout = settings.get_string ("mapset");
        var layout_action = (SimpleAction) lookup_action ("layout");
        layout_action.set_state (new Variant.@string (layout));

        var layout_rotation = settings.get_string ("map-rotation");
        var layout_rotation_action = (SimpleAction) lookup_action ("layout-rotation");
        layout_rotation_action.set_state (new Variant.@string (layout_rotation));

        var background_color = settings.get_string ("background-color");
        var background_color_action = (SimpleAction) lookup_action ("background-color");
        background_color_action.set_state (new Variant.@string (background_color));

        var theme = settings.get_string ("tileset");
        if (theme == "postmodern.svg" || theme == "smooth.png" || theme == "educational.png")
            // Migrate old theme names
            settings.set_string ("tileset", theme.split (".")[0]);

        var theme_action = (SimpleAction) lookup_action ("theme");
        theme_action.set_state (new Variant.@string (theme));

        settings.changed.connect (conf_value_changed_cb);

        conf_value_changed_cb.begin (settings, "background-color");
        conf_value_changed_cb.begin (settings, "tileset");

        settings.bind ("window-width", window, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-is-maximized", window, "maximized", SettingsBindFlags.DEFAULT);

        new_game ();
    }

    protected override int handle_local_options (VariantDict options) {
        if (options.contains ("version")) {
            /* NOTE: Is not translated so can be easily parsed */
            stderr.printf ("%1$s %2$s\n", "gnome-mahjongg", VERSION);
            return Posix.EXIT_SUCCESS;
        }

        /* Activate */
        return -1;
    }

    public override void activate () {
        window.present ();
    }

    private void update_ui () {
        var pause_action = lookup_action ("pause") as SimpleAction;
        var hint_action = lookup_action ("hint") as SimpleAction;
        var undo_action = lookup_action ("undo") as SimpleAction;
        var redo_action = lookup_action ("redo") as SimpleAction;

        pause_action.set_enabled (game_view.game.started);

        if (game_view.game.paused) {
            hint_action.set_enabled (false);
            undo_action.set_enabled (false);
            redo_action.set_enabled (false);
        }
        else {
            var moves_left = game_view.game.moves_left;

            hint_action.set_enabled (moves_left > 0);
            undo_action.set_enabled (game_view.game.can_undo);
            redo_action.set_enabled (game_view.game.can_redo);
            window.update_moves_left (moves_left);
        }
    }

    private async void conf_value_changed_cb (Settings settings, string key) {
        if (key == "tileset") {
            string previous_theme = null;

            if (game_view.theme != null)
                previous_theme = Path.get_basename (game_view.theme);

            var theme = settings.get_string ("tileset");
            var theme_path = "/org/gnome/Mahjongg/themes/";
            game_view.theme = theme_path + theme;

            if (game_view.theme == null) {
                /* Failed to load theme, fall back to default */
                theme = settings.get_default_value ("tileset").get_string ();
                game_view.theme = theme_path + theme;
            }

            if (previous_theme != null)
                window.remove_css_class (previous_theme);

            window.add_css_class (theme);
        }
        else if (key == "background-color") {
            var style_manager = Adw.StyleManager.get_default ();
            var color_scheme = settings.get_enum ("background-color");

            style_manager.set_color_scheme (color_scheme);
        }
    }

    private Gtk.GestureClick view_click_controller;    // for keeping in memory
    private inline void on_click (Gtk.GestureClick _controller, int n_press, double event_x, double event_y) {
        /* Cancel pause on click */
        if (game_view.game.paused)
            pause_cb ();
    }

    private async void moved_cb () {
        update_ui ();

        if (game_view.game.complete) {
            var date = new DateTime.now_local ();
            var duration = (uint) (game_view.game.elapsed + 0.5);
            var player = Environment.get_real_name ();
            var entry = new HistoryEntry (date, game_view.game.map.score_name, duration, player);
            history.add (entry);
            history.save ();
            show_scores (entry);
        }
        else if (!game_view.game.can_move) {
            bool allow_shuffle = game_view.game.number_of_movable_tiles () > 1;

            var dialog = new Adw.AlertDialog (
                _("No Moves Left"),
                allow_shuffle ?
                    _("You can undo your moves and try to find a solution, or reshuffle the remaining tiles.") :
                    _("You can undo your moves and try to find a solution, or start a new game.")
            ) {
                default_response = "continue"
            };
            dialog.add_response ("continue", _("_Continue"));

            if (allow_shuffle) {
                dialog.add_response ("reshuffle", _("_Reshuffle"));
            }
            else {
                dialog.add_response ("new_game", _("_New Game"));
            };
            dialog.add_response ("quit", _("_Quit"));
            dialog.set_response_appearance ("quit", Adw.ResponseAppearance.DESTRUCTIVE);

            var resp_id = yield dialog.choose (window, null);
            switch (resp_id) {
            case "reshuffle":
                shuffle_cb ();
                break;
            case "new_game":
                new_game ();
                break;
            case "quit":
                window.destroy ();
                break;
            default:
                break;
            }
        }
    }

    private void show_scores (HistoryEntry? selected_entry = null) {
        score_dialog = new ScoreDialog (history, selected_entry, maps);
        score_dialog.present (window);
    }

    private void layout_cb (SimpleAction action, Variant variant) {
        var layout = variant.get_string ();
        action.set_state (variant);
        if (settings.get_string ("mapset") != layout) {
            settings.set_string ("mapset", layout);
            // Load a new game iff the layout was manually changed.
            new_game (false);
        }
    }

    private void layout_rotation_cb (SimpleAction action, Variant variant) {
        var layout_rotation = variant.get_string ();
        action.set_state (variant);
        if (settings.get_string ("map-rotation") != layout_rotation)
            settings.set_string ("map-rotation", layout_rotation);
    }

    private void background_color_cb (SimpleAction action, Variant variant) {
        var background_color = variant.get_string ();
        action.set_state (variant);
        if (settings.get_string ("background-color") != background_color)
            settings.set_string ("background-color", background_color);
    }

    private void theme_cb (SimpleAction action, Variant variant) {
        var theme = variant.get_string ();
        action.set_state (variant);
        if (settings.get_string ("tileset") != theme)
            settings.set_string ("tileset", theme);
    }

    private void hint_cb () {
        var matches = game_view.game.find_matches (game_view.game.selected_tile);

        /* No match, find any random match as if nothing was selected */
        if (matches.length () == 0) {
            if (game_view.game.selected_tile == null)
                return;
            matches = game_view.game.find_matches ();
        }

        var n = Random.int_range (0, (int) matches.length ());
        var match = matches.nth_data (n);
        game_view.game.set_hint (match.tile0, match.tile1);

        update_ui ();
    }

    private void shuffle_cb () {
        game_view.game.shuffle_remaining ();
    }

    private void about_cb () {
        string[] developers = {
            "Francisco Bustamante",
            "Max Watson",
            "Heinz Hempe",
            "Michael Meeks",
            "Philippe Chavin",
            "Callum McKenzie",
            "Rexford Newbould",
            "Krzysztof Foltman",
            "Robert Ancell",
            "Michael Catanzaro",
            "Mario Wenzel",
            "Arnaud Bonatti",
            "Jeremy Bicha",
            "Alberto Ruiz",
            "Günther Wagner",
            "Mathias Bonn",
            null
        };

        string[] artists = {
            "Jonathan Buzzard",
            "Jim Evans",
            "Richard Hoelscher",
            "Gonzalo Odiard",
            "Max Watson",
            "Jakub Steiner",
            null
        };

        string[] documenters = {
            "Tiffany Antopolski",
            "Chris Beiser",
            "Andre Klapper",
            null
        };

        var about_dialog = new Adw.AboutDialog.from_appdata ("/org/gnome/Mahjongg/metainfo.xml", VERSION) {
            copyright = """Copyright © 1998–2025 Mahjongg Contributors
Copyright © 1998–2008 Free Software Foundation, Inc.""",
            developers = developers,
            artists = artists,
            documenters = documenters,
            translator_credits = _("translator-credits"),
        };
        about_dialog.present (window);
    }

    private void pause_cb () {
        game_view.game.paused = !game_view.game.paused;
        game_view.game.set_hint (null, null);
        game_view.game.selected_tile = null;

        if (game_view.game.paused) {
            window.pause ();
        }
        else {
            window.unpause ();
            tick_cb ();
        }

        update_ui ();
    }

    private void scores_cb () {
        show_scores ();
    }

    private void new_game_cb () {
        new_game ();
    }

    private void restart_game_cb () {
        restart_game ();
    }

    private void quit_cb () {
        window.destroy ();
    }

    private void redo_cb () {
        if (game_view.game.paused)
            return;

        game_view.game.redo ();
        update_ui ();
    }

    private void undo_cb () {
        game_view.game.undo ();
        update_ui ();
    }

    private void restart_game () {
        game_view.game.reset ();
        if (game_view.game.paused)
            pause_cb ();
        update_ui ();
    }

    private Map find_map () {
        foreach (var m in maps) {
            if (m.name == settings.get_string ("mapset")) {
                return m;
            }
        }
        // Map wasn't found. Return the default (first) map.
        return maps.nth_data (0);
    }

    private Map get_next_map (bool rotate_map) {
        var map = find_map ();
        if (rotate_map) {
            switch (settings.get_string ("map-rotation")) {
            case "sequential":
                var map_index = (maps.index (map) + 1) % (int) maps.length ();
                map = maps.nth_data (map_index);
                break;
            case "random":
                var map_index = Random.int_range (0, (int) maps.length ());
                map = maps.nth_data (map_index);
                break;
            }
        }

        if (settings.get_string ("mapset") != map.name) {
            var layout_action = (SimpleAction) lookup_action ("layout");
            layout_action.set_state (new Variant.@string (map.name));
            settings.set_string ("mapset", map.name);
        }
        return map;
    }

    /**
     * Starts a new game.
     *
     * @param rotate_map If starting a new game should automatically rotate the
     * map according to the ``map-rotation`` setting.
     */
    private void new_game (bool rotate_map = true) {
        var map = get_next_map (rotate_map);

        game_view.game = new Game (map);
        game_view.game.moved.connect (moved_cb);
        game_view.game.tick.connect (tick_cb);

        tick_cb ();
        update_ui ();

        if (score_dialog != null)
            score_dialog.force_close ();

        /* Reset the pause button in case it was set to resume */
        window.unpause ();
    }

    private void tick_cb () {
        string clock;
        var elapsed = 0;
        if (game_view.game != null)
            elapsed = (int) (game_view.game.elapsed + 0.5);
        var hours = elapsed / 3600;
        var minutes = (elapsed - hours * 3600) / 60;
        var seconds = elapsed - hours * 3600 - minutes * 60;
        if (hours > 0)
            clock = "%02d∶\xE2\x80\x8E%02d∶\xE2\x80\x8E%02d".printf (hours, minutes, seconds);
        else
            clock = "%02d∶\xE2\x80\x8E%02d".printf (minutes, seconds);

        window.update_clock (clock);
    }

    private void help_cb () {
        var display = Gdk.Display.get_default ();
        var context = display.get_app_launch_context ();

        GLib.AppInfo.launch_default_for_uri_async.begin ("help:gnome-mahjongg", context, null, (obj, res) => {
            try {
                GLib.AppInfo.launch_default_for_uri_async.end (res);
            } catch (Error error) {
                warning ("Could not open help: %s", error.message);
            }
        });

    }

    private void load_maps () {
        maps = null;

        /* Add the builtin map */
        maps.append (new Map.builtin ());

        Dir dir;
        try {
            dir = Dir.open (Path.build_filename (DATA_DIRECTORY, "maps"));
        }
        catch (FileError e) {
            return;
        }

        while (true) {
            var filename = dir.read_name ();
            if (filename == null)
                break;

            if (!filename.has_suffix (".map"))
                continue;

            var loader = new MapLoader ();
            var path = Path.build_filename (DATA_DIRECTORY, "maps", filename);
            try {
                loader.load (path);
            }
            catch (Error e) {
                warning ("Could not load map %s: %s\n", path, e.message);
                continue;
            }
            foreach (var map in loader.maps)
                maps.append (map);
        }
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Environment.set_application_name (_("Mahjongg"));
        Gtk.Window.set_default_icon_name (APP_ID);

        typeof (GameView).ensure ();
        var app = new Mahjongg ();
        var result = app.run (args);

        Settings.sync ();

        return result;
    }
}
