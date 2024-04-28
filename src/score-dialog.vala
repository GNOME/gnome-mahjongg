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
public class ScoreDialog : Adw.Dialog
{
    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Adw.HeaderBar header_bar;

    [GtkChild]
    private unowned Gtk.MenuButton layout_button;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.ColumnView score_view;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn date_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn time_column;

    private History history;
    private HistoryEntry? selected_entry = null;
    private ListStore score_model;
    private unowned List<Map> maps;

    private const ActionEntry[] action_entries =
    {
        { "layout", null, "s", "''", set_map_cb }
    };

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_quit = false, List<Map> maps)
    {
        this.maps = maps;
        this.history = history;
        this.selected_entry = selected_entry;

        set_can_close (!show_quit);
        header_bar.set_show_start_title_buttons (!show_quit);
        header_bar.set_show_end_title_buttons (!show_quit);
        toolbar_view.set_reveal_bottom_bars (show_quit);

        set_up_score_view ();
        set_up_layout_menu ();

        if (history.entries.length() > 0)
        {
            stack.set_visible_child_name ("scores");
            layout_button.set_visible (true);
        }

        if (selected_entry != null)
        {
            var controller = new Gtk.EventControllerFocus ();
            controller.enter.connect (score_view_focus_cb);
            score_view.add_controller (controller);
            focus_widget = score_view;
        }
    }

    public void set_map (string name)
    {
        layout_button.set_label (get_map_display_name (name));
        score_model.remove_all ();

        var entries = history.entries.copy ();
        entries.sort (compare_entries);

        foreach (var entry in entries)
        {
            if (entry.name != name)
                continue;

            score_model.append (entry);
        }
    }

    private void set_up_layout_menu ()
    {
        var action_group = new SimpleActionGroup ();
        action_group.add_action_entries (action_entries, this);
        insert_action_group ("scores", action_group);

        var menu = new Menu ();
        layout_button.set_menu_model (menu);

        string[] entries = {};
        foreach (var entry in history.entries)
        {
            if (entry.name in entries)
                continue;

            var display_name = get_map_display_name (entry.name);
            var menu_item = new MenuItem (display_name, null);
            menu_item.set_action_and_target_value ("scores.layout", new Variant.string (entry.name));

            menu.append_item (menu_item);
            entries += entry.name;
        };

        var visible_entry = selected_entry;
        if (visible_entry == null)
        {
            unowned var entry = history.entries.first ();

            if (entry == null)
                return;

            visible_entry = entry.data;
        }

        var action = (SimpleAction) action_group.lookup_action ("layout");
        action.set_state (new Variant.string (visible_entry.name));
        set_map (visible_entry.name);
    }

    private void set_up_score_view ()
    {
        var factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (item_date_setup_cb);
        factory.bind.connect (item_date_bind_cb);
        date_column.factory = factory;

        factory = new Gtk.SignalListItemFactory ();
        factory.setup.connect (item_time_setup_cb);
        factory.bind.connect (item_time_bind_cb);
        time_column.factory = factory;

        score_model = new ListStore (typeof (HistoryEntry));
        score_view.model = new Gtk.NoSelection (score_model);
    }

    private string get_map_display_name (string name)
    {
        unowned var map = maps.first ();
        var display_name = name;
        do
        {
            if (map.data.score_name == name)
            {
                display_name = dpgettext2 (null, "mahjongg map name", map.data.name);
                break;
            }
        }
        while ((map = map.next) != null);
        return display_name;
    }

    private void set_map_cb (SimpleAction action, Variant variant)
    {
        var name = variant.get_string();
        action.set_state (variant);
        set_map (name);
    }

    private static int compare_entries (HistoryEntry a, HistoryEntry b)
    {
        var d = strcmp (a.name, b.name);
        if (d != 0)
            return d;
        if (a.duration != b.duration)
            return (int) a.duration - (int) b.duration;
        return a.date.compare (b.date);
    }

    private void item_date_setup_cb(Gtk.SignalListItemFactory factory, Object list_item)
    {
        var label = new Gtk.Inscription(null);
        ((Gtk.ListItem) list_item).child = label;
    }

    private void item_time_setup_cb(Gtk.SignalListItemFactory factory, Object list_item)
    {
        var label = new Gtk.Label(null);
        label.use_markup = true;
        label.xalign = 0;
        ((Gtk.ListItem) list_item).child = label;
    }

    private void item_date_bind_cb(Gtk.SignalListItemFactory factory, Object list_item)
    {
        var inscription = ((Gtk.ListItem) list_item).child as Gtk.Inscription;
        var entry = ((Gtk.ListItem) list_item).item as HistoryEntry;

        var date_label = entry.date.format ("%x");
        if (entry == selected_entry)
            date_label = "<b>%s</b>".printf (date_label);

        inscription.markup = date_label;
    }

    private void item_time_bind_cb(Gtk.SignalListItemFactory factory, Object list_item)
    {
        var label = ((Gtk.ListItem) list_item).child as Gtk.Label;
        var entry = ((Gtk.ListItem) list_item).item as HistoryEntry;

        var time_label = "%us".printf (entry.duration);
        if (entry.duration >= 60)
            time_label = "%um %us".printf (entry.duration / 60, entry.duration % 60);
        if (entry == selected_entry)
            time_label = "<b>%s</b>".printf (time_label);

        label.label = time_label;
    }

    private void score_view_focus_cb ()
    {
        uint position;
        var found_item = score_model.find (selected_entry, out position);

        if (!found_item)
            return;

        Idle.add (() => {
            score_view.scroll_to (position, null, Gtk.ListScrollFlags.FOCUS, null);
            return false;
        });
    }
}
