// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class Mahjongg : Adw.Application {
    private History history;
    private GameSave game_save;
    private MapLoader map_loader;

    private Settings settings;
    private MahjonggWindow window;
    private GameView game_view;
    private GameView primary_game_view;
    private GameView secondary_game_view;

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
        { "rules", rules_cb },
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
        set_accels_for_action ("app.rules", { "F1" });
        set_accels_for_action ("app.quit", { "<Primary>q" });
        set_accels_for_action ("window.close", { "<Primary>w" });

        settings = new Settings (application_id);
        settings.delay ();
    }

    private void create_window () {
        map_loader = new MapLoader ();
        map_loader.load_builtin ();
        map_loader.load_folder (Path.build_filename (DATA_DIRECTORY, "maps"));

        history = new History (Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history"));
        history.load ();

        window = new MahjonggWindow (this, map_loader);

        var using_cairo = Environment.get_variable ("GSK_RENDERER") == "cairo";
        primary_game_view = new GameView (using_cairo);
        secondary_game_view = new GameView (using_cairo);
        window.add_game_view (primary_game_view);
        window.add_game_view (secondary_game_view);

        var layout = settings.get_string ("mapset");
        unowned var layout_action = lookup_action ("layout") as SimpleAction;
        layout_action.set_state (new Variant.@string (layout));

        var layout_rotation = settings.get_string ("map-rotation");
        unowned var layout_rotation_action = lookup_action ("layout-rotation") as SimpleAction;
        layout_rotation_action.set_state (new Variant.@string (layout_rotation));

        var background_color = settings.get_string ("background-color");
        unowned var background_color_action = lookup_action ("background-color") as SimpleAction;
        background_color_action.set_state (new Variant.@string (background_color));

        var theme = settings.get_string ("tileset");
        if (theme == "postmodern.svg" || theme == "smooth.png" || theme == "educational.png") {
            // Migrate old theme names
            theme = theme.split (".")[0];
            settings.set_string ("tileset", theme);
        }
        unowned var theme_action = lookup_action ("theme") as SimpleAction;
        theme_action.set_state (new Variant.@string (theme));
        update_theme ();

        settings.bind ("window-width", window, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-is-maximized", window, "maximized", SettingsBindFlags.DEFAULT);

        var rotate_map = (layout_rotation == "random");

        var save_path = Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "gamesave");
        game_save = new GameSave (save_path);

        if (game_save.exists ()) {
            restore_game (rotate_map);
        } else {
            new_game (rotate_map);
        }

        settings.changed.connect (conf_value_changed_cb);
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
        if (window == null)
            create_window ();

        window.present ();
    }

    public override void shutdown () {
        if (game_view != null)
            game_view.game.destroy_timers ();

        if (game_view.game.started && game_view.game.can_move && !game_view.game.inspecting)
            game_save.write (game_view.game);

        settings.apply ();
        base.shutdown ();
    }

    private void update_theme (GameView? previous_game_view = null) {
        var color_scheme = settings.get_enum ("background-color");
        var theme = settings.get_string ("tileset");
        var style_manager = Adw.StyleManager.get_default ();

        style_manager.set_color_scheme (color_scheme);

        if (game_view != null) {
            var path = resource_base_path + "/themes/";
            var fallback_theme = settings.get_default_value ("tileset").get_string ();
            game_view.set_theme (path + theme, previous_game_view, path + fallback_theme);
        }
        window.theme = theme;
    }

    private void update_ui () {
        unowned var pause_action = lookup_action ("pause") as SimpleAction;
        unowned var hint_action = lookup_action ("hint") as SimpleAction;
        unowned var undo_action = lookup_action ("undo") as SimpleAction;
        unowned var redo_action = lookup_action ("redo") as SimpleAction;

        pause_action.set_enabled (game_view.game.started && !game_view.game.inspecting);

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
            window.moves_left = moves_left;
        }
    }

    private void conf_value_changed_cb (Settings settings, string key) {
        if (key == "tileset" || key == "background-color")
            update_theme ();
    }

    private bool attempt_move_cb () {
        /* Cancel pause on click */
        if (game_view.game.paused) {
            pause_cb ();
            return false;
        }
        return true;
    }

    private async void moved_cb () {
        update_ui ();

        if (game_view.game.inspecting)
            return;

        if (game_view.game.complete) {
            var date = new DateTime.now_local ();
            var duration = (uint) game_view.game.elapsed;
            var player = Environment.get_real_name ();
            var completed_entry = new HistoryEntry (date, game_view.game.map.score_name, duration, player);
            history.add (completed_entry);
            history.save ();
            game_save.delete ();
            show_scores (completed_entry.name, completed_entry);
        }
        else if (!game_view.game.can_move) {
            var can_shuffle = game_view.game.can_shuffle;
            var dialog = new Adw.AlertDialog (
                _("No Moves Left"),
                can_shuffle ?
                    _("You can undo your moves and try to find a solution, or reshuffle the remaining tiles.") :
                    _("You can undo your moves and try to find a solution, or start a new game.")
            ) {
                default_response = "continue"
            };
            dialog.add_response ("quit", _("_Quit"));
            dialog.set_response_appearance ("quit", Adw.ResponseAppearance.DESTRUCTIVE);
            dialog.add_response ("new_game", _("_New Game"));

            if (can_shuffle)
                dialog.add_response ("reshuffle", _("_Reshuffle"));

            dialog.add_response ("continue", _("_Continue"));

            var resp_id = yield dialog.choose (window, null);
            switch (resp_id) {
            case "reshuffle":
                shuffle_cb ();
                break;
            case "new_game":
                new_game ();
                break;
            case "quit":
                game_save.delete ();
                window.destroy ();
                break;
            default:
                break;
            }
        }
    }

    private void show_scores (string selected_layout = "", HistoryEntry? completed_entry = null) {
        new ScoreDialog (history, map_loader, selected_layout, completed_entry).present (window);
    }

    private void layout_cb (SimpleAction action, Variant variant) {
        var layout = variant.get_string ();
        action.set_state (variant);

        if (settings.get_string ("mapset") != layout) {
            settings.set_string ("mapset", layout);
            settings.apply ();

            // Load a new game if the layout was manually changed.
            new_game (false);
        }
    }

    private void layout_rotation_cb (SimpleAction action, Variant variant) {
        var layout_rotation = variant.get_string ();
        action.set_state (variant);

        if (settings.get_string ("map-rotation") != layout_rotation) {
            settings.set_string ("map-rotation", layout_rotation);
            settings.apply ();
        }
    }

    private void background_color_cb (SimpleAction action, Variant variant) {
        var background_color = variant.get_string ();
        action.set_state (variant);

        if (settings.get_string ("background-color") != background_color) {
            settings.set_string ("background-color", background_color);
            settings.apply ();
        }
    }

    private void theme_cb (SimpleAction action, Variant variant) {
        var theme = variant.get_string ();
        action.set_state (variant);

        if (settings.get_string ("tileset") != theme) {
            settings.set_string ("tileset", theme);
            settings.apply ();
        }
    }

    private void hint_cb () {
        var match = game_view.game.next_hint ();
        game_view.game.set_hint (match);
        update_ui ();
    }

    private void shuffle_cb () {
        game_view.game.shuffle_remaining ();
    }

    private void about_cb () {
        var about_dialog = new Adw.AboutDialog.from_appdata (resource_base_path + "/metainfo.xml", VERSION) {
            copyright = """Copyright © 1998–2025 Mahjongg Contributors
Copyright © 1998–2008 Free Software Foundation, Inc.""",
            developers = {
                "Francisco Bustamante",
                "Max Watson",
                "Heinz Hempe",
                "Michael Meeks",
                "Philippe Chavin",
                "Callum McKenzie",
                "Robert Ancell",
                "Michael Catanzaro",
                "Mario Wenzel",
                "Arnaud Bonatti",
                "Jeremy Bicha",
                "Alberto Ruiz",
                "Günther Wagner",
                "Mathias Bonn",
                "K Davis",
                "François Godin"
            },
            artists = {
                "Jonathan Buzzard",
                "Jim Evans",
                "Richard Hoelscher",
                "Gonzalo Odiard",
                "Max Watson",
                "Jakub Steiner"
            },
            documenters = {
                "Tiffany Antopolski",
                "Chris Beiser",
                "Andre Klapper"
            },
            translator_credits = _("translator-credits"),
        };
        about_dialog.add_credit_section (_("Layouts by"), {
            "Rexford Newbould",
            "Krzysztof Foltman",
            "Sapphire Becker"
        });
        about_dialog.present (window);
    }

    private void pause_cb () {
        game_view.game.paused = !game_view.game.paused;

        if (game_view.game.paused)
            window.pause ();
        else
            window.unpause ();

        update_ui ();
    }

    private void scores_cb () {
        show_scores (game_view.game.map.score_name);
    }

    private void new_game_cb () {
        new_game ();
    }

    private void restart_game_cb () {
        restart_game ();
    }

    private void quit_cb () {
        if (window != null)
            window.close ();
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

    private unowned Map next_map (bool rotate_map) {
        unowned var map = map_loader.get_map_by_name (settings.get_string ("mapset"));

        // Map wasn't found. Get the default (first) map.
        if (map == null)
            map = map_loader.get_map_at_position (0);

        if (rotate_map) {
            switch (settings.get_string ("map-rotation")) {
            case "sequential":
                map = map_loader.get_next_map (map);
                break;
            case "random":
                map = map_loader.get_random_map ();
                break;
            }
        }

        if (settings.get_string ("mapset") != map.name) {
            unowned var layout_action = lookup_action ("layout") as SimpleAction;
            layout_action.set_state (new Variant.@string (map.name));
            settings.set_string ("mapset", map.name);
        }
        return map;
    }

    private void new_game_view (bool rotate_map = false) {
        var transition_type = Gtk.StackTransitionType.NONE;
        var previous_game_view = game_view;

        if (rotate_map) {
            if (settings.get_string ("map-rotation") != "single")
                transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            else
                transition_type = Gtk.StackTransitionType.CROSSFADE;
        }

        game_view = (game_view == primary_game_view) ? secondary_game_view : primary_game_view;
        update_theme (previous_game_view);

        if (previous_game_view != null) {
            previous_game_view.game.destroy_timers ();
            previous_game_view.game = null;
            previous_game_view.set_theme (null);
        }

        window.set_game_view (game_view, transition_type);
    }

    private void new_game (bool rotate_map = true) {
        new_game_view (rotate_map);
        game_save.delete ();
        initialize_game (next_map (rotate_map));
    }

    private void restore_game (bool rotate_map = true) {
        new_game_view (rotate_map);

        if (!game_save.load ()) {
            initialize_game (next_map (rotate_map));
            return;
        }

        var map = map_loader.get_map_by_name (game_save.map_name);
        if (map == null) {
            warning ("Map '%s' not found in available maps.\n", game_save.map_name);
            initialize_game (next_map (rotate_map));
            return;
        }

        initialize_game (map, game_save.is_valid (map));
    }

    private void initialize_game (Map map, bool resuming = false) {
        if (game_view.game != null)
            return;

        game_view.game = new Game (map);

        if (resuming) {
            game_view.game.restore (game_save);
            window.pause ();
        } else {
            game_view.game.generate ();
            window.unpause ();
        }

        game_view.game.attempt_move.connect (attempt_move_cb);
        game_view.game.moved.connect (moved_cb);
        game_view.game.tick.connect (tick_cb);

        tick_cb ();
        update_ui ();
    }

    private void restart_game () {
        game_view.game.restart ();
        game_save.delete ();
        if (game_view.game.paused)
            pause_cb ();
        update_ui ();
    }

    private void tick_cb () {
        string clock;
        var elapsed = (int) game_view.game.elapsed;
        var hours = elapsed / 3600;
        var minutes = (elapsed - hours * 3600) / 60;
        var seconds = elapsed - hours * 3600 - minutes * 60;
        if (hours > 0)
            clock = "%02d∶\xE2\x80\x8E%02d∶\xE2\x80\x8E%02d".printf (hours, minutes, seconds);
        else
            clock = "%02d∶\xE2\x80\x8E%02d".printf (minutes, seconds);

        window.clock = clock;
    }

    private void rules_cb () {
        new RulesDialog ().present (window);
    }

    public static int main (string[] args) {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Environment.set_application_name (_("Mahjongg"));

        typeof (GameView).ensure ();
        var app = new Mahjongg ();
        var result = app.run (args);

        Settings.sync ();

        return result;
    }
}
