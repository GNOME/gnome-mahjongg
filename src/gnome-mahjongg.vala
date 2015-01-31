/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class Mahjongg : Gtk.Application
{
    private Settings settings;

    private History history;

    private List<Map> maps = null;

    private Gtk.ApplicationWindow window;
    private Gtk.Label title;
    private int window_width;
    private int window_height;
    private bool is_maximized;

    private GameView game_view;
    private Gtk.Button pause_button;
    private Gtk.Label moves_label;
    private Gtk.Label clock_label;
    private Gtk.Dialog? preferences_dialog = null;

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
        Object (application_id: "org.gnome.gnome-mahjongg", flags: ApplicationFlags.FLAGS_NONE);

        add_main_option_entries (option_entries);
    }

    protected override void startup ()
    {
        base.startup ();

        add_action_entries (action_entries, this);
        set_accels_for_action ("app.pause", {"Pause"});
        set_accels_for_action ("app.hint", {"<Primary>h"});
        set_accels_for_action ("app.undo", {"<Primary>z"});
        set_accels_for_action ("app.redo", {"<Primary><Shift>z"});

        settings = new Settings ("org.gnome.mahjongg");

        var builder = new Gtk.Builder ();
        try {
            builder.add_from_resource ("/org/gnome/mahjongg/ui/menu.ui");
        } catch (Error e) {
            error ("loading menu builder file: %s", e.message);
        }

        load_maps ();

        history = new History (Path.build_filename (Environment.get_user_data_dir (), "gnome-mahjongg", "history"));
        history.load ();

        window = new Gtk.ApplicationWindow (this);
        window.size_allocate.connect (size_allocate_cb);
        window.window_state_event.connect (window_state_event_cb);
        window.set_default_size (settings.get_int ("window-width"), settings.get_int ("window-height"));
        if (settings.get_boolean ("window-is-maximized"))
            window.maximize ();

        var status_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);

        var group_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        var label = new Gtk.Label (_("Moves Left:"));
        group_box.pack_start (label, false, false, 0);
        var spacer = new Gtk.Label (" ");
        group_box.pack_start (spacer, false, false, 0);
        moves_label = new Gtk.Label ("");
        group_box.pack_start (moves_label, false, false, 0);
        status_box.pack_start (group_box, false, false, 0);

        clock_label = new Gtk.Label ("");
        status_box.pack_start (clock_label, false, false, 0);

        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

        game_view = new GameView ();
        game_view.button_press_event.connect (view_button_press_event);
        game_view.set_size_request (600, 400);

        title = new Gtk.Label ("");
        title.get_style_context ().add_class ("title");

        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        hbox.get_style_context ().add_class ("linked");

        var undo_button = new Gtk.Button.from_icon_name ("edit-undo-symbolic", Gtk.IconSize.BUTTON);
        undo_button.valign = Gtk.Align.CENTER;
        undo_button.action_name = "app.undo";
        undo_button.set_tooltip_text (_("Undo your last move"));
        hbox.pack_start (undo_button);

        var redo_button = new Gtk.Button.from_icon_name ("edit-redo-symbolic", Gtk.IconSize.BUTTON);
        redo_button.valign = Gtk.Align.CENTER;
        redo_button.action_name = "app.redo";
        redo_button.set_tooltip_text (_("Redo your last move"));
        hbox.pack_start (redo_button);

        var hint_button = new Gtk.Button.from_icon_name ("dialog-question-symbolic", Gtk.IconSize.BUTTON);
        hint_button.valign = Gtk.Align.CENTER;
        hint_button.action_name = "app.hint";
        hint_button.set_tooltip_text (_("Receive a hint for your next move"));

        pause_button = new Gtk.Button.from_icon_name ("media-playback-pause-symbolic", Gtk.IconSize.BUTTON);
        pause_button.valign = Gtk.Align.CENTER;
        pause_button.action_name = "app.pause";
        pause_button.set_tooltip_text (_("Pause the game"));

        var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
        title_box.pack_start (title, false, false, 0);
        status_box.halign = Gtk.Align.CENTER;
        title_box.pack_start (status_box, false, false, 0);

        bool shell_shows_menubar;
        Gtk.Settings.get_default ().get ("gtk-shell-shows-menubar", out shell_shows_menubar);

        if (!shell_shows_menubar)
        {
            var app_menu = builder.get_object ("appmenu") as MenuModel;
            set_app_menu (app_menu);
        }
        else
        {
            var menu = new Menu ();
            var mahjongg_menu = new Menu ();
            menu.append_submenu (_("_Mahjongg"), mahjongg_menu);
            mahjongg_menu.append (_("_New Game"), "app.new-game");
            mahjongg_menu.append (_("_Restart Game"), "app.restart-game");
            mahjongg_menu.append (_("_Scores"), "app.scores");
            mahjongg_menu.append (_("_Preferences"), "app.preferences");
            mahjongg_menu.append (_("_Quit"), "app.quit");
            var help_menu = new Menu ();
            menu.append_submenu (_("_Help"), help_menu);
            help_menu.append (_("_Contents"), "app.help");
            help_menu.append (_("_About"), "app.about");
            set_menubar (menu);
        }

        var header_bar = new Gtk.HeaderBar ();
        header_bar.set_custom_title (title_box);
        header_bar.pack_start (hbox);
        header_bar.pack_end (hint_button);
        header_bar.pack_end (pause_button);

        var desktop = Environment.get_variable ("XDG_CURRENT_DESKTOP");
        if (!is_desktop ("Unity"))
        {
            header_bar.set_show_close_button (true);
            window.set_titlebar (header_bar);
        }
        else
        {
            vbox.pack_start (header_bar, false, false, 0);
        }

        vbox.pack_start (game_view, true, true, 0);

        window.add (vbox);
        window.show_all ();

        settings.changed.connect (conf_value_changed_cb);

        new_game ();

        game_view.grab_focus ();

        conf_value_changed_cb (settings, "tileset");
        conf_value_changed_cb (settings, "bgcolour");
        tick_cb ();
    }

    private bool is_desktop (string name)
    {
        var desktop_name_list = Environment.get_variable ("XDG_CURRENT_DESKTOP");
        if (desktop_name_list == null)
            return false;

        foreach (var n in desktop_name_list.split (":"))
            if (n == name)
                return true;

        return false;
    }

    private void size_allocate_cb (Gtk.Allocation allocation)
    {
        if (is_maximized)
            return;
        window_width = allocation.width;
        window_height = allocation.height;
    }

    private bool window_state_event_cb (Gdk.EventWindowState event)
    {
        if ((event.changed_mask & Gdk.WindowState.MAXIMIZED) != 0)
            is_maximized = (event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0;
        return false;
    }

    protected override void shutdown ()
    {
        base.shutdown ();

        /* Save window state */
        settings.set_int ("window-width", window_width);
        settings.set_int ("window-height", window_height);
        settings.set_boolean ("window-is-maximized", is_maximized);
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

    private void theme_changed_cb (Gtk.ComboBox widget)
    {
        Gtk.TreeIter iter;
        widget.get_active_iter (out iter);
        string theme;
        widget.model.get (iter, 1, out theme);
        settings.set_string ("tileset", theme);
    }

    private void conf_value_changed_cb (Settings settings, string key)
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
                var response = dialog.run ();
                if (response == Gtk.ResponseType.ACCEPT)
                    new_game ();
                dialog.destroy ();
            }
            else
                new_game ();
        }
    }

    private bool view_button_press_event (Gtk.Widget widget, Gdk.EventButton event)
    {
        /* Cancel pause on click */
        if (game_view.game.paused)
        {
            game_view.game.paused = false;
            return true;
        }

        return false;
    }

    private void background_changed_cb (Gtk.ColorButton widget)
    {
        var colour = widget.get_rgba ();
        settings.set_string ("bgcolour", "#%04x%04x%04x".printf ((int) (colour.red * 65536 + 0.5), (int) (colour.green * 65536 + 0.5), (int) (colour.blue * 65536 + 0.5)));
    }

    private void map_changed_cb (Gtk.ComboBox widget)
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

            if (show_scores (entry, true) == Gtk.ResponseType.CLOSE)
                window.destroy ();
            else
                new_game ();
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

            var result = dialog.run ();
            /* Shuffling may cause the dialog to appear again immediately,
               so we destroy BEFORE doing anything with the result. */
            dialog.destroy ();

            switch (result)
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
        }
    }

    private int show_scores (HistoryEntry? selected_entry = null, bool show_quit = false)
    {
        var dialog = new ScoreDialog (history, selected_entry, show_quit);
        dialog.modal = true;
        dialog.transient_for = window;

        var result = dialog.run ();
        dialog.destroy ();

        return result;
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

        preferences_dialog = new Gtk.Dialog.with_buttons (_("Preferences"),
                                                          window,
                                                          dialogs_use_header ? Gtk.DialogFlags.USE_HEADER_BAR : 0,
                                                          null);
        preferences_dialog.set_border_width (5);
        var dialog_content_area = (Gtk.Box) preferences_dialog.get_content_area ();
        dialog_content_area.set_spacing (2);
        preferences_dialog.set_resizable (false);
        preferences_dialog.set_default_response (Gtk.ResponseType.CLOSE);
        preferences_dialog.response.connect (preferences_dialog_response_cb);

        var grid = new Gtk.Grid ();
        grid.border_width = 5;
        grid.set_row_spacing (6);
        grid.set_column_spacing (18);

        var label = new Gtk.Label.with_mnemonic (_("_Theme:"));
        label.set_alignment (0, 0.5f);
        grid.attach (label, 0, 0, 1, 1);

        var themes = load_themes ();
        var theme_combo = new Gtk.ComboBox ();
        var theme_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        theme_combo.model = theme_store;
        var renderer = new Gtk.CellRendererText ();
        theme_combo.pack_start (renderer, true);
        theme_combo.add_attribute (renderer, "text", 0);
        foreach (var theme in themes)
        {
            var tokens = theme.split (".", -1);
            var name = tokens[0];

            Gtk.TreeIter iter;
            theme_store.append (out iter);
            theme_store.set (iter, 0, name, 1, theme, -1);

            if (theme == settings.get_string ("tileset"))
                theme_combo.set_active_iter (iter);
        }
        theme_combo.changed.connect (theme_changed_cb);
        theme_combo.set_hexpand (true);
        grid.attach (theme_combo, 1, 0, 1, 1);
        label.set_mnemonic_widget (theme_combo);

        label = new Gtk.Label.with_mnemonic (_("_Layout:"));
        label.set_alignment (0, 0.5f);
        grid.attach (label, 0, 1, 1, 1);

        var map_combo = new Gtk.ComboBox ();
        var map_store = new Gtk.ListStore (2, typeof (string), typeof (string));
        map_combo.model = map_store;
        renderer = new Gtk.CellRendererText ();
        map_combo.pack_start (renderer, true);
        map_combo.add_attribute (renderer, "text", 0);
        foreach (var map in maps)
        {
            var display_name = dpgettext2 (null, "mahjongg map name", map.name);

            Gtk.TreeIter iter;
            map_store.append (out iter);
            map_store.set (iter, 0, display_name, 1, map, -1);

            if (settings.get_string ("mapset") == map.name)
                map_combo.set_active_iter (iter);
        }
        map_combo.changed.connect (map_changed_cb);
        map_combo.set_hexpand (true);
        grid.attach (map_combo, 1, 1, 1, 1);
        label.set_mnemonic_widget (map_combo);

        label = new Gtk.Label.with_mnemonic (_("_Background color:"));
        label.set_alignment (0, 0.5f);
        grid.attach (label, 0, 2, 1, 1);

        var widget = new Gtk.ColorButton ();
        widget.set_rgba (game_view.background_color);
        widget.color_set.connect (background_changed_cb);
        widget.set_hexpand (true);
        grid.attach (widget, 1, 2, 1, 1);
        label.set_mnemonic_widget (widget);

        dialog_content_area.pack_start (grid, true, true, 0);

        if (!dialogs_use_header)
            preferences_dialog.add_button (_("_Close"), Gtk.ResponseType.CLOSE);

        preferences_dialog.show_all ();
    }

    private void preferences_dialog_response_cb (Gtk.Dialog dialog, int response)
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
                               "logo-icon-name", "gnome-mahjongg",
                               "website", "https://wiki.gnome.org/Apps/Mahjongg",
                               null);
    }

    private void pause_cb ()
    {
        game_view.game.paused = !game_view.game.paused;
        game_view.game.set_hint (null, null);
        game_view.game.selected_tile = null;

        var pause_image = (Gtk.Image) pause_button.image;
        if (game_view.game.paused)
        {
            pause_image.icon_name = "media-playback-start-symbolic";
            pause_button.set_tooltip_text (_("Unpause the game"));
        }
        else
        {
            pause_image.icon_name = "media-playback-pause-symbolic";
            pause_button.set_tooltip_text (_("Pause the game"));
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
        var display_name = dpgettext2 (null, "mahjongg map name", game_view.game.map.name);
        title.set_label (_(display_name));

        update_ui ();

        /* Update clock label */
        tick_cb ();

        /* Reset the pause button in case it was set to resume */
        var pause_image = (Gtk.Image) pause_button.image;
        pause_image.icon_name = "media-playback-pause-symbolic";
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
        try
        {
            Gtk.show_uri (window.get_screen (), "help:gnome-mahjongg", Gtk.get_current_event_time ());
        }
        catch (Error e)
        {
            warning ("Failed to show help: %s", e.message);
        }
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
        Gtk.Window.set_default_icon_name ("gnome-mahjongg");

        var app = new Mahjongg ();
        var result = app.run (args);

        Settings.sync ();

        return result;
    }
}
