/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/score-dialog.ui")]
public class ScoreDialog : Adw.Dialog {
    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Adw.HeaderBar header_bar;

    [GtkChild]
    private unowned Gtk.MenuButton layout_button;

    [GtkChild]
    private unowned Gtk.Stack content_stack;

    [GtkChild]
    private unowned Gtk.ColumnView score_view;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn player_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn time_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn date_column;

    [GtkChild]
    private unowned Gtk.Stack bottom_stack;

    [GtkChild]
    private unowned Gtk.Button clear_scores_button;

    [GtkChild]
    private unowned Gtk.Button new_game_button;

    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListItem? selected_item = null;
    private ListStore score_model;
    private unowned List<Map> maps;

    private const ActionEntry[] ACTION_ENTRIES = {
        { "layout", null, "s", "''", set_map_cb }
    };

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, List<Map> maps) {
        this.maps = maps;
        this.history = history;
        this.selected_entry = selected_entry;

        set_up_score_view ();
        set_up_layout_menu ();

        if (history.entries.length () > 0) {
            content_stack.visible_child_name = "scores";
            layout_button.visible = true;
            toolbar_view.reveal_bottom_bars = true;
        }

        if (selected_entry != null) {
            set_can_close (false);
            header_bar.show_start_title_buttons = false;
            header_bar.show_end_title_buttons = false;
            bottom_stack.visible_child_name = "new-game";

            var controller = new Gtk.EventControllerFocus ();
            controller.enter.connect (score_view_focus_cb);
            score_view.add_controller (controller);
            focus_widget = score_view;
        }

        clear_scores_button.clicked.connect (clear_scores_cb);

        closed.connect (() => {
            if (selected_entry != null)
                history.save ();
        });
    }

    public void set_map (string name) {
        layout_button.label = get_map_display_name (name);
        score_model.remove_all ();

        var entries = history.entries.copy ();
        entries.sort (compare_entries);

        foreach (var entry in entries) {
            if (entry.name != name)
                continue;

            score_model.append (entry);
        }
    }

    private void set_up_layout_menu () {
        var action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group ("scores", action_group);

        var menu = new Menu ();
        layout_button.menu_model = menu;

        string[] entries = {};
        foreach (var entry in history.entries) {
            if (entry.name in entries)
                continue;

            var display_name = get_map_display_name (entry.name);
            var menu_item = new MenuItem (display_name, null);
            menu_item.set_action_and_target_value ("scores.layout", new Variant.string (entry.name));

            menu.append_item (menu_item);
            entries += entry.name;
        };

        var visible_entry = selected_entry;
        if (visible_entry == null) {
            unowned var entry = history.entries.first ();

            if (entry == null)
                return;

            visible_entry = entry.data;
        }

        var action = (SimpleAction) action_group.lookup_action ("layout");
        action.set_state (new Variant.string (visible_entry.name));
        set_map (visible_entry.name);
    }

    private void set_up_score_view () {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (item_player_setup_cb);
        factory.bind.connect (item_player_bind_cb);
        player_column.factory = factory;

        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (item_time_setup_cb);
        factory.bind.connect (item_time_bind_cb);
        time_column.factory = factory;

        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (item_date_setup_cb);
        factory.bind.connect (item_date_bind_cb);
        date_column.factory = factory;

        score_model = new ListStore (typeof (HistoryEntry));
        score_view.model = new Gtk.NoSelection (score_model);
    }

    private string get_map_display_name (string name) {
        unowned var map = maps.first ();
        var display_name = name;
        do {
            if (map.data.score_name == name) {
                display_name = dpgettext2 (null, "mahjongg map name", map.data.name);
                break;
            }
        }
        while ((map = map.next) != null);
        return display_name;
    }

    private void set_map_cb (SimpleAction action, Variant variant) {
        var name = variant.get_string ();
        action.set_state (variant);
        set_map (name);
    }

    private static int compare_entries (HistoryEntry a, HistoryEntry b) {
        var d = strcmp (a.name, b.name);
        if (d != 0)
            return d;
        if (a.duration != b.duration)
            return (int) a.duration - (int) b.duration;
        return a.date.compare (b.date);
    }

    private void item_player_setup_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var stack = new Gtk.Stack ();
        stack.add_named (new Gtk.Inscription (null), "label");

        var entry = new Gtk.Entry () {
            has_frame = false,
            max_width_chars = 5
        };
        entry.notify["text"].connect (() => {
            var history_entry = ((Gtk.ListItem) list_item).item as HistoryEntry;
            if (entry.text.length <= 0)
                history_entry.player = Environment.get_real_name ();
            else
                history_entry.player = entry.text;
        });
        entry.activate.connect (() => {
            new_game_button.activate ();
        });

        stack.add_named (entry, "entry");
        ((Gtk.ListItem) list_item).child = stack;
    }

    private void item_time_setup_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var label = new Gtk.Inscription (null);
        label.add_css_class ("numeric");
        ((Gtk.ListItem) list_item).child = label;
    }

    private void item_date_setup_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var label = new Gtk.Label (null) {
            xalign = 0
        };
        label.add_css_class ("numeric");
        ((Gtk.ListItem) list_item).child = label;
    }

    private void item_player_bind_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var stack = ((Gtk.ListItem) list_item).child as Gtk.Stack;
        var entry = ((Gtk.ListItem) list_item).item as HistoryEntry;

        if (entry == selected_entry) {
            stack.visible_child_name = "entry";
            var text_entry = (Gtk.Entry) stack.visible_child;
            text_entry.text = entry.player;
            text_entry.add_css_class ("heading");
            selected_item = (Gtk.ListItem) list_item;
        }
        else {
            stack.visible_child_name = "label";
            ((Gtk.Inscription) stack.visible_child).text = entry.player;
        }
    }

    private void item_time_bind_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var label = ((Gtk.ListItem) list_item).child as Gtk.Inscription;
        var entry = ((Gtk.ListItem) list_item).item as HistoryEntry;

        var time_label = "%us".printf (entry.duration);
        if (entry.duration >= 60)
            time_label = "%um %us".printf (entry.duration / 60, entry.duration % 60);
        if (entry == selected_entry)
            label.add_css_class ("heading");

        label.text = time_label;
    }

    private void item_date_bind_cb (Gtk.SignalListItemFactory factory, Object list_item) {
        var label = ((Gtk.ListItem) list_item).child as Gtk.Label;
        var entry = ((Gtk.ListItem) list_item).item as HistoryEntry;

        var date_label = entry.date.format ("%x");
        if (entry == selected_entry)
            label.add_css_class ("heading");

        label.label = date_label;
    }

    private void score_view_focus_cb () {
        uint position;
        var found_item = score_model.find (selected_entry, out position);

        if (!found_item)
            return;

        Idle.add (() => {
            var text_entry = ((Gtk.Stack) selected_item.child).visible_child;
            text_entry.grab_focus ();
            score_view.scroll_to (position, null, Gtk.ListScrollFlags.NONE, null);
            return false;
        });
    }

    private async void clear_scores_cb () {
        var dialog = new Adw.AlertDialog (
            _("Clear All Scores?"),
            _("This will clear every score for every layout.")
        ) {
            default_response = "cancel"
        };
        dialog.add_response ("cancel", _("_Cancel"));
        dialog.add_response ("clear", _("Clear All"));
        dialog.set_response_appearance ("clear", Adw.ResponseAppearance.DESTRUCTIVE);

        var resp_id = yield dialog.choose (this, null);
        switch (resp_id) {
        case "cancel":
            break;
        case "clear":
            toolbar_view.reveal_bottom_bars = false;
            content_stack.visible_child_name = "no-scores";
            layout_button.visible = false;
            layout_button.menu_model = null;
            score_model.remove_all ();

            selected_entry = null;
            selected_item = null;

            history.clear ();
            break;
        default:
            assert_not_reached ();
        }
    }
}
