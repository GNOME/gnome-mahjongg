// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class Mahjongg : Adw.Application {
    private Game game;
    private GameSave game_save;
    private Maps maps;
    private History history;
    private Settings settings;

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
        { "layout-progression", null, "s", "''", layout_progression_cb },
        { "background-color", null, "s", "''", background_color_cb },
        { "theme", null, "s", "''", theme_cb },
        { "rules", rules_cb },
        { "about", about_cb },
        { "quit", quit }
    };

    public Mahjongg () {
        Object (
            application_id: APP_ID,
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
        maps = new Maps ();
        maps.load ();

        var history_path = Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history");
        history = new History (history_path);
        history.load ();

        new MahjonggWindow (this, settings, maps);

        var layout = settings.get_string ("mapset");
        if (layout == "Difficult") {
            // Migrate old layout name
            layout = "Taipei";
            settings.set_string ("mapset", layout);
        }
        unowned var layout_action = lookup_action ("layout") as SimpleAction;
        layout_action.set_state (new Variant.@string (layout));

        var layout_progression = settings.get_string ("map-rotation");
        unowned var layout_progression_action = lookup_action ("layout-progression") as SimpleAction;
        layout_progression_action.set_state (new Variant.@string (layout_progression));

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

        var save_path = Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "gamesave");
        game_save = new GameSave (save_path);

        var rotate_map = (layout_progression == "random");
        var restore = true;
        new_game (rotate_map, restore);
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
        if (active_window == null)
            create_window ();

        active_window.present ();
    }

    public override void shutdown () {
        if (game != null) {
            game.destroy_timers ();
            game_save.write (game);
        }
        settings.apply ();
        base.shutdown ();
    }

    private bool attempt_move_cb () {
        /* Cancel pause on click */
        if (game.paused) {
            game.paused = false;
            return false;
        }
        return true;
    }

    private async void moved_cb () {
        unowned var hint_action = lookup_action ("hint") as SimpleAction;
        unowned var undo_action = lookup_action ("undo") as SimpleAction;
        unowned var redo_action = lookup_action ("redo") as SimpleAction;

        hint_action.set_enabled (game.moves_left > 0);
        undo_action.set_enabled (game.can_undo);
        redo_action.set_enabled (game.can_redo);

        if (game.inspecting)
            return;

        unowned var pause_action = lookup_action ("pause") as SimpleAction;
        pause_action.set_enabled (game.started);

        if (game.complete) {
            var date = new DateTime.now_local ();
            var duration = (uint) game.elapsed;
            var player = Environment.get_real_name ();
            var completed_entry = history.add (date, game.map.score_name, duration, player);

            game_save.delete ();
            show_scores (completed_entry.name, completed_entry);
        }
        else if (!game.can_move) {
            var can_shuffle = game.can_shuffle;
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

            var resp_id = yield dialog.choose (active_window, null);
            switch (resp_id) {
            case "reshuffle":
                shuffle_cb ();
                break;
            case "new_game":
                new_game ();
                break;
            case "quit":
                game_save.delete ();
                quit ();
                break;
            default:
                break;
            }
        }
    }

    private void paused_changed_cb () {
        unowned var hint_action = lookup_action ("hint") as SimpleAction;
        unowned var undo_action = lookup_action ("undo") as SimpleAction;
        unowned var redo_action = lookup_action ("redo") as SimpleAction;

        if (game.paused) {
            hint_action.set_enabled (false);
            undo_action.set_enabled (false);
            redo_action.set_enabled (false);
        }
        else {
            hint_action.set_enabled (game.moves_left > 0);
            undo_action.set_enabled (game.can_undo);
            redo_action.set_enabled (game.can_redo);
        }
    }

    private void show_scores (string selected_layout = "", HistoryEntry? completed_entry = null) {
        new ScoreDialog (history, maps, selected_layout, completed_entry)
            .present (active_window);
    }

    private async void _layout_cb (SimpleAction action, Variant variant) {
        var layout = variant.get_string ();
        if (settings.get_string ("mapset") != layout) {
            if (game.started) {
                var dialog = new Adw.AlertDialog (
                    _("Change Layout?"),
                    _("This will end your current game.")
                ) {
                    default_response = "cancel"
                };
                dialog.add_response ("cancel", _("_Cancel"));
                dialog.add_response ("change_layout", _("Change _Layout"));
                dialog.set_response_appearance ("change_layout", Adw.ResponseAppearance.DESTRUCTIVE);

                var resp_id = yield dialog.choose (active_window, null);
                if (resp_id != "change_layout")
                    return;
            }

            settings.set_string ("mapset", layout);
            settings.apply ();

            // Load a new game if the layout was manually changed.
            var rotate_map = false;
            new_game (rotate_map);
        }
        action.set_state (variant);
    }

    private void layout_cb (SimpleAction action, Variant variant) {
        _layout_cb.begin (action, variant);
    }

    private void layout_progression_cb (SimpleAction action, Variant variant) {
        var layout_progression = variant.get_string ();
        action.set_state (variant);

        if (settings.get_string ("map-rotation") != layout_progression) {
            settings.set_string ("map-rotation", layout_progression);
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
        game.show_hint ();
    }

    private void shuffle_cb () {
        game.shuffle_remaining ();
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
                "Jaye Evins",
                "Richard Hoelscher",
                "Gonzalo Odiard",
                "Max Watson",
                "Jakub Steiner",
                "Rossano Rossi",
                "Tobias Bernard"
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
        about_dialog.present (active_window);
    }

    private void pause_cb () {
        game.paused = !game.paused;
    }

    private void scores_cb () {
        show_scores (game.map.score_name);
    }

    private void new_game_cb () {
        new_game ();
    }

    private void restart_game_cb () {
        game.restart ();
        game_save.delete ();
    }

    private void redo_cb () {
        game.redo ();
    }

    private void undo_cb () {
        game.undo ();
    }

    private unowned Map next_map (bool rotate_map) {
        unowned var map = maps.get_map_by_name (settings.get_string ("mapset"));

        // Map wasn't found. Get the default (first) map.
        if (map == null)
            map = maps.get_map_at_position (0);

        if (rotate_map) {
            switch (settings.get_string ("map-rotation")) {
            case "sequential":
                map = maps.get_next_map (map);
                break;
            case "random":
                map = maps.get_random_map ();
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

    private void new_game (bool rotate_map = true, bool restore = false) {
        var window = active_window as MahjonggWindow;
        Map map = null;

        if (restore) {
            restore = game_save.load (maps);
            map = game_save.map;
        } else {
            game_save.delete ();
        }
        if (map == null)
            map = next_map (rotate_map);

        if (game != null)
            game.destroy_timers ();

        game = new Game (map);
        window.new_game (game, rotate_map);

        game.attempt_move.connect (attempt_move_cb);
        game.moved.connect (moved_cb);
        game.paused_changed.connect (paused_changed_cb);

        if (restore)
            game.restore (game_save);
        else
            game.generate ();
    }

    private void rules_cb () {
        new RulesDialog ()
            .present (active_window);
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
