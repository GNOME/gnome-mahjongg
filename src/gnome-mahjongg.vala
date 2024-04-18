/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class Mahjongg : Adw.Application
{
    private Settings settings;

    private History history;

    private List<Map> maps = new List<Map> ();

    private MahjonggWindow window;

    private GameView game_view;

    private const OptionEntry[] option_entries =
    {
        { "version", 'v', 0, OptionArg.NONE, null, N_("Print release version and exit"), null },
        { null }
    };

    private const GLib.ActionEntry[] action_entries =
    {
        { "new-game",      new_game_cb     },
        { "undo",          undo_cb         },
        { "redo",          redo_cb         },
        { "hint",          hint_cb         },
        { "pause",         pause_cb        },
        { "restart-game",  restart_game_cb },
        { "scores",        scores_cb       },
        { "preferences",   preferences_cb  },
        { "help",          help_cb         },
        { "about",         about_cb        },
        { "quit",          quit_cb         }
    };

    public Mahjongg ()
    {
        Object (application_id: "org.gnome.Mahjongg", flags: ApplicationFlags.DEFAULT_FLAGS);

        add_main_option_entries (option_entries);
    }

    protected override void startup ()
    {
        base.startup ();

        add_action_entries (action_entries, this);
        set_accels_for_action ("app.new-game",  {        "<Primary>n"       });
        set_accels_for_action ("app.pause",     {        "<Primary>p",
                                                                  "Pause"   });
        set_accels_for_action ("app.hint",      {        "<Primary>h"       });
        set_accels_for_action ("app.undo",      {        "<Primary>z"       });
        set_accels_for_action ("app.redo",      { "<Shift><Primary>z"       });
        set_accels_for_action ("app.help",      {                 "F1"      });
        set_accels_for_action ("app.quit",      {        "<Primary>q",
                                                         "<Primary>w"       });

        settings = new Settings ("org.gnome.Mahjongg");
        load_maps ();

        history = new History (Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history"));
        history.load ();

        game_view = new GameView ();
        view_click_controller = new Gtk.GestureClick ();
        view_click_controller.pressed.connect (on_click);
        game_view.add_controller (view_click_controller);

        window = new MahjonggWindow (this, game_view);

        settings.bind("window-width", window, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind("window-height", window, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind("window-is-maximized", window, "maximized", SettingsBindFlags.DEFAULT);
    }

    protected override int handle_local_options (GLib.VariantDict options)
    {
        if (options.contains ("version"))
        {
            /* NOTE: Is not translated so can be easily parsed */
            stderr.printf ("%1$s %2$s\n", "gnome-mahjongg", VERSION);
            return Posix.EXIT_SUCCESS;
        }

        /* Activate */
        return -1;
    }

    public override void activate ()
    {
        window.present ();

        settings.changed.connect (conf_value_changed_cb);

        new_game ();

        game_view.grab_focus ();

        conf_value_changed_cb (settings, "tileset");
        conf_value_changed_cb (settings, "background-color");
        tick_cb ();
    }

    private void update_ui ()
    {
        var pause_action = lookup_action ("pause") as SimpleAction;
        var hint_action = lookup_action ("hint") as SimpleAction;
        var undo_action = lookup_action ("undo") as SimpleAction;
        var redo_action = lookup_action ("redo") as SimpleAction;

        pause_action.set_enabled (game_view.game.started);

        if (game_view.game.paused)
        {
            hint_action.set_enabled (false);
            undo_action.set_enabled (false);
            redo_action.set_enabled (false);
        }
        else
        {
            hint_action.set_enabled (game_view.game.moves_left > 0);
            undo_action.set_enabled (game_view.game.can_undo);
            redo_action.set_enabled (game_view.game.can_redo);
        }

        /* Update clock/moves left label */
        tick_cb ();
    }

    private void conf_value_changed_cb (Settings settings, string key)
    {
        if (key == "tileset")
        {
            var theme = settings.get_string ("tileset");
            game_view.theme = Path.build_filename (DATA_DIRECTORY, "themes", theme);
        }
        else if (key == "mapset")
        {
            /* Prompt user if already made a move */
            if (game_view.game.started)
            {
                var dialog = new Gtk.MessageDialog (window,
                                                    Gtk.DialogFlags.MODAL,
                                                    Gtk.MessageType.QUESTION,
                                                    Gtk.ButtonsType.NONE,
                                                    "%s", _("Do you want to start a new game with this map?"));
                dialog.format_secondary_text (_("If you continue playing the next game will use the new map."));
                dialog.add_buttons (_("_Continue playing"), Gtk.ResponseType.REJECT,
                                    _("Use _new map"), Gtk.ResponseType.ACCEPT,
                                    null);
                dialog.set_default_response (Gtk.ResponseType.ACCEPT);
                dialog.response.connect ( (resp_id) => {
                    if (resp_id == Gtk.ResponseType.ACCEPT)
                        new_game ();
                    dialog.destroy ();
                });
                dialog.present ();
            }
            else
                new_game ();
        }
        else if (key == "background-color")
        {
            var style_manager = Adw.StyleManager.get_default ();
            var color_scheme = settings.get_enum ("background-color");

            style_manager.set_color_scheme (color_scheme);
        }
    }

    private Gtk.GestureClick view_click_controller;    // for keeping in memory
    private inline void on_click (Gtk.GestureClick _view_click_controller, int n_press, double event_x, double event_y)
    {
        /* Cancel pause on click */
        if (game_view.game.paused)
            pause_cb ();
    }

    enum NoMovesDialogResponse
    {
        UNDO,
        SHUFFLE,
        RESTART,
        NEW_GAME
    }

    private void moved_cb ()
    {
        update_ui ();

        if (game_view.game.complete)
        {
            var date = new DateTime.now_local ();
            var duration = (uint) (game_view.game.elapsed + 0.5);
            var entry = new HistoryEntry (date, game_view.game.map.score_name, duration);
            history.add (entry);
            history.save ();
            show_scores (entry, true);
        }
        else if (!game_view.game.can_move)
        {
            bool allow_shuffle = game_view.game.number_of_movable_tiles () > 1;

            var dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                                Gtk.MessageType.INFO,
                                                Gtk.ButtonsType.NONE,
                                                "%s", _("There are no more moves."));
            dialog.format_secondary_text ("%s%s%s".printf (_("Each puzzle has at least one solution.  You can undo your moves and try and find the solution, restart this game, or start a new one."),
                                                           allow_shuffle ? " " : "",
                                                           allow_shuffle ? _("You can also try to reshuffle the game, but this does not guarantee a solution.") : ""));
            dialog.add_buttons (_("_Undo"), NoMovesDialogResponse.UNDO,
                                _("_Restart"), NoMovesDialogResponse.RESTART,
                                _("_New game"), NoMovesDialogResponse.NEW_GAME,
                                allow_shuffle ? _("_Shuffle") : null, NoMovesDialogResponse.SHUFFLE);

            dialog.response.connect ( (resp_id) => {
                /* Shuffling may cause the dialog to appear again immediately,
                   so we destroy BEFORE doing anything with the result. */
                switch (resp_id)
                {
                case NoMovesDialogResponse.UNDO:
                    undo_cb ();
                    break;
                case NoMovesDialogResponse.SHUFFLE:
                    shuffle_cb ();
                    break;
                case NoMovesDialogResponse.RESTART:
                    restart_game ();
                    break;
                case NoMovesDialogResponse.NEW_GAME:
                    new_game ();
                    break;
                case Gtk.ResponseType.DELETE_EVENT:
                    break;
                default:
                    assert_not_reached ();
                }
                dialog.destroy ();
            });
            dialog.present ();
        }
    }

    private void show_scores (HistoryEntry? selected_entry = null, bool show_quit = false)
    {
        var dialog = new ScoreDialog (history, selected_entry, show_quit, maps);
        dialog.modal = true;
        dialog.transient_for = window;
        dialog.response.connect ((resp_id) => {
            if (resp_id == Gtk.ResponseType.CLOSE)
                window.destroy ();
            else if (resp_id == Gtk.ResponseType.OK)
                new_game ();
            dialog.destroy ();
        });

        dialog.present ();
    }

    private void preferences_cb ()
    {
        var preferences = new PreferencesWindow (settings);
        preferences.populate_themes (load_themes ());
        preferences.populate_layouts (maps);
        preferences.populate_backgrounds ();
        preferences.present (window);
    }

    private List<string> load_themes ()
    {
        List<string> themes = null;

        Dir dir;
        try
        {
            dir = Dir.open (Path.build_filename (DATA_DIRECTORY, "themes"));
        }
        catch (FileError e)
        {
            return themes;
        }

        while (true)
        {
            var s = dir.read_name ();
            if (s == null)
                break;

            if (s.has_suffix (".xpm") || s.has_suffix (".svg") || s.has_suffix (".gif") ||
                s.has_suffix (".png") || s.has_suffix (".jpg") || s.has_suffix (".xbm"))
                themes.append (s);
        }

        return themes;
    }

    private void hint_cb ()
    {
        var matches = game_view.game.find_matches (game_view.game.selected_tile);

        /* No match, find any random match as if nothing was selected */
        if (matches.length () == 0)
        {
            if (game_view.game.selected_tile == null)
                return;
            matches = game_view.game.find_matches ();
        }

        var n = Random.int_range (0, (int) matches.length ());
        var match = matches.nth_data (n);
        game_view.game.set_hint (match.tile0, match.tile1);

        update_ui ();
    }

    private void shuffle_cb ()
    {
        game_view.game.shuffle_remaining ();
    }

    private void about_cb ()
    {
        string[] authors =
        {
            _("Main game:"),
            "Francisco Bustamante",
            "Max Watson",
            "Heinz Hempe",
            "Michael Meeks",
            "Philippe Chavin",
            "Callum McKenzie",
            "Robert Ancell",
            "Günther Wagner",
            "",
            _("Maps:"),
            "Rexford Newbould",
            "Krzysztof Foltman",
            null
        };

        string[] artists =
        {
            _("Tiles:"),
            "Jonathan Buzzard",
            "Jim Evans",
            "Richard Hoelscher",
            "Gonzalo Odiard",
            "Max Watson",
            null
        };

        string[] documenters =
        {
            "Tiffany Antopolski",
            "Chris Beiser",
            null
        };

        Gtk.show_about_dialog (window,
                               "program-name", _("Mahjongg"),
                               "version", VERSION,
                               "comments",
                               _("A matching game played with Mahjongg tiles"),
                               "copyright", "Copyright © 1998–2008 Free Software Foundation, Inc.",
                               "license-type", Gtk.License.GPL_2_0,
                               "authors", authors,
                               "artists", artists,
                               "documenters", documenters,
                               "translator-credits", _("translator-credits"),
                               "logo-icon-name", "org.gnome.Mahjongg",
                               "website", "https://gitlab.gnome.org/GNOME/gnome-mahjongg",
                               null);
    }

    private void pause_cb ()
    {
        game_view.game.paused = !game_view.game.paused;
        game_view.game.set_hint (null, null);
        game_view.game.selected_tile = null;

        if (game_view.game.paused)
        {
            window.pause ();
        }
        else
        {
            window.unpause ();
        }

        update_ui ();
    }

    private void scores_cb ()
    {
        show_scores ();
    }

    private void new_game_cb ()
    {
        new_game ();
    }

    private void restart_game_cb ()
    {
        restart_game ();
    }

    private void quit_cb ()
    {
        window.destroy ();
    }

    private void redo_cb ()
    {
        if (game_view.game.paused)
            return;

        game_view.game.redo ();
        update_ui ();
    }

    private void undo_cb ()
    {
        game_view.game.undo ();
        update_ui ();
    }

    private void restart_game ()
    {
        game_view.game.reset ();
        if (game_view.game.paused)
            pause_cb ();
        update_ui ();
    }

    private void new_game ()
    {
        Map? map = null;
        foreach (var m in maps)
        {
            if (m.name == settings.get_string ("mapset"))
            {
                map = m;
                break;
            }
        }
        if (map == null)
            map = maps.nth_data (0);

        game_view.game = new Game (map);
        game_view.game.moved.connect (moved_cb);
        game_view.game.tick.connect (tick_cb);

        /* Set window title */
        window.set_map_title (game_view);

        update_ui ();

        /* Reset the pause button in case it was set to resume */
        window.unpause ();
    }

    private void tick_cb ()
    {
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

        window.set_subtitle (game_view, clock);
    }

    private void help_cb ()
    {
        Gtk.show_uri (window, "help:gnome-mahjongg", Gdk.CURRENT_TIME);
    }

    private void load_maps ()
    {
        maps = null;

        /* Add the builtin map */
        maps.append (new Map.builtin ());

        Dir dir;
        try
        {
            dir = Dir.open (Path.build_filename (DATA_DIRECTORY, "maps"));
        }
        catch (FileError e)
        {
            return;
        }
        while (true)
        {
            var filename = dir.read_name ();
            if (filename == null)
                break;

            if (!filename.has_suffix (".map"))
                continue;

            var loader = new MapLoader ();
            var path = Path.build_filename (DATA_DIRECTORY, "maps", filename);
            try
            {
                loader.load (path);
            }
            catch (Error e)
            {
                warning ("Could not load map %s: %s\n", path, e.message);
                continue;
            }
            foreach (var map in loader.maps)
                maps.append (map);
        }
    }

    public static int main (string[] args)
    {
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
        Intl.bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
        Intl.textdomain (GETTEXT_PACKAGE);

        Environment.set_application_name (_("Mahjongg"));
        Gtk.Window.set_default_icon_name ("org.gnome.Mahjongg");

        typeof(GameView).ensure();
        var app = new Mahjongg ();
        var result = app.run (args);

        Settings.sync ();

        return result;
    }
}
