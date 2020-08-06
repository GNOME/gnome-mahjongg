/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

using Gtk;

public class Mahjongg : Gtk.Application
{
    private GLib.Settings settings;

    private History history;

    private List<Map> maps = new List<Map> ();

    private ApplicationWindow window;
    private Label title;
    private MenuButton menu_button;
    private int window_width;
    private int window_height;
    private bool is_maximized;
    private bool is_tiled;

    private GameView game_view;
    private Button pause_button;
    private Label moves_label;
    private Label clock_label;
    private Dialog? preferences_dialog = null;

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
        { "hamburger",     hamburger_cb    },
        { "quit",          quit_cb         }
    };

    public Mahjongg ()
    {
        Object (application_id: "org.gnome.Mahjongg", flags: ApplicationFlags.FLAGS_NONE);

        add_main_option_entries (option_entries);
    }

    protected override void startup ()
    {
        base.startup ();

        add_action_entries (action_entries, this);
        set_accels_for_action ("app.new-game",  {        "<Control>n"       });
        set_accels_for_action ("app.pause",     {        "<Control>p",
                                                                  "Pause"   });
        set_accels_for_action ("app.hint",      {        "<Control>h"       });
        set_accels_for_action ("app.undo",      {        "<Control>z"       });
        set_accels_for_action ("app.redo",      { "<Shift><Control>z"       });
        set_accels_for_action ("app.help",      {                 "F1"      });
        set_accels_for_action ("app.quit",      {        "<Control>q",
                                                         "<Control>w"       });
        set_accels_for_action ("app.hamburger", {                 "F10"     });

        settings = new GLib.Settings ("org.gnome.Mahjongg");

        load_maps ();

        history = new History (Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history"));
        history.load ();

        window = new ApplicationWindow (this);
        window.map.connect (init_state_watcher);
        window.set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        if (settings.get_boolean ("window-is-maximized"))
            window.maximize ();

        var status_box = new Box (Orientation.HORIZONTAL, 10);

        var group_box = new Box (Orientation.HORIZONTAL, 0);
        var label = new Label (_("Moves Left:"));
        group_box.append (label);
        var spacer = new Label (" ");
        group_box.append (spacer);
        moves_label = new Label ("");
        group_box.append (moves_label);
        status_box.append (group_box);

        clock_label = new Label ("");
        status_box.append (clock_label);

        var vbox = new Box (Orientation.VERTICAL, 0);

        game_view = new GameView ();
        view_click_controller = new GestureClick ();
        view_click_controller.pressed.connect (on_click);
        game_view.add_controller (view_click_controller);
        game_view.set_size_request (600, 400);
        game_view.hexpand = true;
        game_view.vexpand = true;

        title = new Label ("");
        title.get_style_context ().add_class ("title");

        var hbox = new Box (Orientation.HORIZONTAL, 0);
        hbox.get_style_context ().add_class ("linked");

        var undo_button = new Button.from_icon_name ("edit-undo-symbolic");
        undo_button.valign = Align.CENTER;
        undo_button.action_name = "app.undo";
        undo_button.set_tooltip_text (_("Undo your last move"));
        hbox.append (undo_button);

        var redo_button = new Button.from_icon_name ("edit-redo-symbolic");
        redo_button.valign = Align.CENTER;
        redo_button.action_name = "app.redo";
        redo_button.set_tooltip_text (_("Redo your last move"));
        hbox.append (redo_button);

        var hint_button = new Button.from_icon_name ("dialog-question-symbolic");
        hint_button.valign = Align.CENTER;
        hint_button.action_name = "app.hint";
        hint_button.set_tooltip_text (_("Receive a hint for your next move"));

        pause_button = new Button.from_icon_name ("media-playback-pause-symbolic");
        pause_button.valign = Align.CENTER;
        pause_button.action_name = "app.pause";
        pause_button.set_tooltip_text (_("Pause the game"));

        var title_box = new Box (Orientation.VERTICAL, 2);
        title_box.append (title);
        status_box.halign = Align.CENTER;
        title_box.append (status_box);

        var menu = new Menu ();
        var section = new Menu ();
        section.append (_("_New Game"),         "app.new-game");
        section.append (_("_Restart Game"),     "app.restart-game");
        section.append (_("_Scores"),           "app.scores");
        section.freeze ();
        menu.append_section (/* no title */ null, section);
        section = new Menu ();
        section.append (_("_Preferences"),          "app.preferences");
        section.append (_("_Keyboard Shortcuts"),   "win.show-help-overlay");
        section.append (_("_Help"),                 "app.help");
        section.append (_("_About Mahjongg"),       "app.about");
        section.freeze ();
        menu.append_section (/* no title */ null, section);
        menu.freeze ();

        menu_button = new MenuButton ();
        menu_button.valign = Align.CENTER;
        menu_button.set_menu_model (menu);
        menu_button.set_icon_name ("open-menu-symbolic");

        var header_bar = new HeaderBar ();
        header_bar.set_title_widget (title_box);
        header_bar.set_show_title_buttons (true);
        header_bar.pack_start (hbox);
        header_bar.pack_end (menu_button);
        header_bar.pack_end (hint_button);
        header_bar.pack_end (pause_button);
        window.set_titlebar (header_bar);

        vbox.append (game_view);

        window.set_child (vbox);

        settings.changed.connect (conf_value_changed_cb);

        new_game ();

        game_view.grab_focus ();

        conf_value_changed_cb ("tileset");
        conf_value_changed_cb ("bgcolour");
        tick_cb ();
    }

    private void init_state_watcher ()
    {
        Gdk.Surface? nullable_surface = window.get_surface ();      // TODO report bug, get_surface() returns a nullable Surface
        if (nullable_surface == null || !((!) nullable_surface is Gdk.Toplevel))
            assert_not_reached ();
        surface = (Gdk.Toplevel) (!) nullable_surface;
        surface.notify ["state"].connect (on_window_state_event);
        surface.size_changed.connect (on_size_changed);
    }

    private inline void on_size_changed (Gdk.Surface _surface, int width, int height)
    {
        if (is_maximized || is_tiled)
            return;
        window.get_size (out window_width, out window_height);
    }

    private Gdk.Toplevel surface;
    private const Gdk.ToplevelState tiled_state = Gdk.ToplevelState.TILED
                                                | Gdk.ToplevelState.TOP_TILED
                                                | Gdk.ToplevelState.BOTTOM_TILED
                                                | Gdk.ToplevelState.LEFT_TILED
                                                | Gdk.ToplevelState.RIGHT_TILED;
    private inline void on_window_state_event ()
    {
        Gdk.ToplevelState state = surface.get_state ();

        is_maximized =  (state & Gdk.ToplevelState.MAXIMIZED) != 0;
        is_tiled =      (state & tiled_state)                 != 0;
    }

    protected override void shutdown ()
    {
        base.shutdown ();

        /* Save window state */
        settings.delay ();
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", is_maximized);
        settings.apply ();
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

        moves_label.set_text ("%2u".printf (game_view.game.moves_left));
    }

    private void theme_changed_cb (ComboBox widget)
    {
        TreeIter iter;
        widget.get_active_iter (out iter);
        string theme;
        widget.model.get (iter, 1, out theme);
        settings.set_string ("tileset", theme);
    }

    private void conf_value_changed_cb (string key)
    {
        if (key == "tileset")
        {
            var theme = settings.get_string ("tileset");
            game_view.theme = Path.build_filename (DATA_DIRECTORY, "themes", theme);
        }
        else if (key == "bgcolour")
        {
            game_view.set_background (settings.get_string ("bgcolour"));
        }
        else if (key == "mapset")
        {
            /* Prompt user if already made a move */
            if (game_view.game.started)
            {
                var dialog = new MessageDialog (window,
                                                DialogFlags.MODAL,
                                                MessageType.QUESTION,
                                                ButtonsType.NONE,
                                                "%s", _("Do you want to start a new game with this map?"));
                dialog.format_secondary_text (_("If you continue playing the next game will use the new map."));
                dialog.add_buttons (_("_Continue playing"), ResponseType.REJECT,
                                    _("Use _new map"), ResponseType.ACCEPT);
                dialog.set_default_response (ResponseType.ACCEPT);

                dialog.response.connect ((_dialog, response) => {
                        _dialog.destroy ();
                        if (response == ResponseType.ACCEPT)
                            new_game ();
                    });
                dialog.present ();
            }
            else
                new_game ();
        }
    }

    private GestureClick view_click_controller;    // for keeping in memory
    private inline void on_click (GestureClick _view_click_controller, int n_press, double event_x, double event_y)
    {
        /* Cancel pause on click */
        if (game_view.game.paused)
            pause_cb ();
    }

    private void background_changed_cb (ColorButton widget)
    {
        var colour = widget.get_rgba ();
        settings.set_string ("bgcolour", "#%04x%04x%04x".printf ((int) (colour.red * 65536 + 0.5), (int) (colour.green * 65536 + 0.5), (int) (colour.blue * 65536 + 0.5)));
    }

    private void map_changed_cb (ComboBox widget)
    {
        settings.set_string ("mapset", maps.nth_data (widget.active).name);
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

            show_scores (entry);
        }
        else if (!game_view.game.can_move)
        {
            bool allow_shuffle = game_view.game.number_of_movable_tiles () > 1;

            var dialog = new MessageDialog (window,
                                            DialogFlags.MODAL | DialogFlags.DESTROY_WITH_PARENT,
                                            MessageType.INFO,
                                            ButtonsType.NONE,
                                            "%s", _("There are no more moves."));
            dialog.format_secondary_text ("%s%s%s".printf (_("Each puzzle has at least one solution.  You can undo your moves and try and find the solution, restart this game, or start a new one."),
                                                           allow_shuffle ? " " : "",
                                                           allow_shuffle ? _("You can also try to reshuffle the game, but this does not guarantee a solution.") : ""));
            dialog.add_buttons (_("_Undo"), NoMovesDialogResponse.UNDO,
                                _("_Restart"), NoMovesDialogResponse.RESTART,
                                _("_New game"), NoMovesDialogResponse.NEW_GAME,
                                allow_shuffle ? _("_Shuffle") : null, NoMovesDialogResponse.SHUFFLE);

            dialog.response.connect ((_dialog, response) => {
                    /* Shuffling may cause the dialog to appear again immediately,
                       so we destroy BEFORE doing anything with the result. */
                    _dialog.destroy ();

                    switch (response)
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
                        case ResponseType.DELETE_EVENT:
                            break;
                        default:
                            assert_not_reached ();
                    }
                });
            dialog.present ();
        }
    }

    private void show_scores (HistoryEntry? selected_entry)
    {
        var dialog = new ScoreDialog (history, selected_entry, /* show_quit */ true, maps);
        dialog.modal = true;
        dialog.transient_for = window;

        dialog.response.connect ((_dialog, response) => {
                _dialog.destroy ();
                if (response == ResponseType.CLOSE)
                    window.destroy ();
                else
                    new_game ();
            });
        dialog.present ();
    }

    private void preferences_cb ()
    {
        if (preferences_dialog != null)
        {
            preferences_dialog.present ();
            return;
        }

        bool dialogs_use_header;
        Gtk.Settings.get_default ().get ("gtk-dialogs-use-header", out dialogs_use_header);

        preferences_dialog = new Dialog.with_buttons (_("Preferences"),
                                                      window,
                                                      dialogs_use_header ? DialogFlags.USE_HEADER_BAR : 0);
        var dialog_content_area = (Box) preferences_dialog.get_content_area ();
        dialog_content_area.set_spacing (2);
        preferences_dialog.set_resizable (false);
        preferences_dialog.set_default_response (ResponseType.CLOSE);
        preferences_dialog.response.connect (preferences_dialog_response_cb);
        dialog_content_area.margin_top = 10;
        dialog_content_area.margin_start = 10;
        dialog_content_area.margin_end = 10;
        dialog_content_area.margin_bottom = 10;

        var grid = new Grid ();
        grid.set_row_spacing (6);
        grid.set_column_spacing (18);

        var label = new Label.with_mnemonic (_("_Theme:"));
        label.halign = Align.START;
        grid.attach (label, 0, 0, 1, 1);

        var themes = load_themes ();
        var theme_combo = new ComboBox ();
        var theme_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        theme_combo.model = theme_store;
        var renderer = new CellRendererText ();
        theme_combo.pack_start (renderer, true);
        theme_combo.add_attribute (renderer, "text", 0);
        foreach (var theme in themes)
        {
            var tokens = theme.split (".", -1);
            var name = tokens[0];

            TreeIter iter;
            theme_store.append (out iter);
            theme_store.set (iter, 0, name, 1, theme, -1);

            if (theme == settings.get_string ("tileset"))
                theme_combo.set_active_iter (iter);
        }
        theme_combo.changed.connect (theme_changed_cb);
        theme_combo.set_hexpand (true);
        grid.attach (theme_combo, 1, 0, 1, 1);
        label.set_mnemonic_widget (theme_combo);

        label = new Label.with_mnemonic (_("_Layout:"));
        label.halign = Align.START;
        grid.attach (label, 0, 1, 1, 1);

        var map_combo = new ComboBox ();
        var map_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        map_combo.model = map_store;
        renderer = new CellRendererText ();
        map_combo.pack_start (renderer, true);
        map_combo.add_attribute (renderer, "text", 0);
        foreach (var map in maps)
        {
            var display_name = dpgettext2 (null, "mahjongg map name", map.name);

            TreeIter iter;
            map_store.append (out iter);
            map_store.set (iter, 0, display_name, 1, map, -1);

            if (settings.get_string ("mapset") == map.name)
                map_combo.set_active_iter (iter);
        }
        map_combo.changed.connect (map_changed_cb);
        map_combo.set_hexpand (true);
        grid.attach (map_combo, 1, 1, 1, 1);
        label.set_mnemonic_widget (map_combo);

        label = new Label.with_mnemonic (_("_Background color:"));
        label.halign = Align.START;
        grid.attach (label, 0, 2, 1, 1);

        var widget = new ColorButton ();
        widget.set_rgba (game_view.background_color);
        widget.color_set.connect (background_changed_cb);
        widget.set_hexpand (true);
        grid.attach (widget, 1, 2, 1, 1);
        label.set_mnemonic_widget (widget);

        dialog_content_area.append (grid);

        if (!dialogs_use_header)
            preferences_dialog.add_button (_("_Close"), ResponseType.CLOSE);

        preferences_dialog.present ();
    }

    private void preferences_dialog_response_cb (Dialog dialog, int response)
    {
        preferences_dialog.destroy ();
        preferences_dialog = null;
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

    private inline void hamburger_cb ()
    {
        menu_button.active = !menu_button.active;
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

        show_about_dialog (window,
                           "program-name",          _("Mahjongg"),
                           "version",               VERSION,
                           "comments",              _("A matching game played with Mahjongg tiles"),
                           "copyright",             "Copyright © 1998–2008 Free Software Foundation, Inc.",
                           "license-type",          License.GPL_2_0,
                           "authors",               authors,
                           "artists",               artists,
                           "documenters",           documenters,
                           "translator-credits",    _("translator-credits"),
                           "logo-icon-name", "      org.gnome.Mahjongg",
                           "website",               "https://wiki.gnome.org/Apps/Mahjongg");
    }

    private void pause_cb ()
    {
        game_view.game.paused = !game_view.game.paused;
        game_view.game.set_hint (null, null);
        game_view.game.selected_tile = null;

        if (game_view.game.paused)
        {
            pause_button.icon_name = "media-playback-start-symbolic";
            pause_button.set_tooltip_text (_("Unpause the game"));
        }
        else
        {
            pause_button.icon_name = "media-playback-pause-symbolic";
            pause_button.set_tooltip_text (_("Pause the game"));
        }

        update_ui ();
    }

    private void scores_cb ()
    {
        var dialog = new ScoreDialog (history, /* selected entry */ null, /* show quit */ false, maps);
        dialog.modal = true;
        dialog.transient_for = window;

        dialog.present ();
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
        var display_name = dpgettext2 (null, "mahjongg map name", game_view.game.map.name);
        title.set_label (_(display_name));

        update_ui ();

        /* Update clock label */
        tick_cb ();

        /* Reset the pause button in case it was set to resume */
        pause_button.icon_name = "media-playback-pause-symbolic";
    }

    private void tick_cb ()
    {
        var elapsed = 0;
        if (game_view.game != null)
            elapsed = (int) (game_view.game.elapsed + 0.5);
        var hours = elapsed / 3600;
        var minutes = (elapsed - hours * 3600) / 60;
        var seconds = elapsed - hours * 3600 - minutes * 60;
        if (hours > 0)
            clock_label.set_text ("%02d∶\xE2\x80\x8E%02d∶\xE2\x80\x8E%02d".printf (hours, minutes, seconds));
        else
            clock_label.set_text ("%02d∶\xE2\x80\x8E%02d".printf (minutes, seconds));
    }

    private void help_cb ()
    {
        show_uri (window, "help:gnome-mahjongg", Gdk.CURRENT_TIME);
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
        Window.set_default_icon_name ("org.gnome.Mahjongg");

        var app = new Mahjongg ();
        var result = app.run (args);

        GLib.Settings.sync ();

        return result;
    }
}
