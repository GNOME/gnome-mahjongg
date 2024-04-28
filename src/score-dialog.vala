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
    private unowned Gtk.TreeView scores;

    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore score_model;
    private unowned List<Map> maps;

    private const GLib.ActionEntry[] action_entries =
    {
        { "layout", null, "s", "''", set_map_cb }
    };

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_quit = false, List<Map> maps)
    {
        this.maps = maps;
        this.history = history;
        this.selected_entry = selected_entry;

        var action_group = new GLib.SimpleActionGroup ();
        action_group.add_action_entries (action_entries, this);
        insert_action_group ("scores", action_group);

        var visible_entry = selected_entry;
        if (visible_entry == null)
            visible_entry = history.entries.first ().data;

        score_model = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (int));

        var renderer = new Gtk.CellRendererText ();
        scores.insert_column_with_attributes (-1, _("Date"), renderer, "text", 0, "weight", 2);
        renderer = new Gtk.CellRendererText ();
        renderer.xalign = 1.0f;
        scores.insert_column_with_attributes (-1, _("Time"), renderer, "text", 1, "weight", 2);
        scores.model = score_model;

        var menu = new GLib.Menu ();
        layout_button.set_menu_model (menu);

        foreach (var entry in history.entries)
        {
            var display_name = get_map_display_name (entry.name);
            var menu_item = new MenuItem (display_name, null);
            menu_item.set_action_and_target_value ("scores.layout", new Variant.string (entry.name));
            menu.append_item (menu_item);
        };

        set_can_close (!show_quit);
        header_bar.set_show_start_title_buttons (!show_quit);
        header_bar.set_show_end_title_buttons (!show_quit);
        toolbar_view.set_reveal_bottom_bars (show_quit);

        if (visible_entry != null)
        {
            var action = (SimpleAction) action_group.lookup_action ("layout");
            action.set_state (new Variant.string (visible_entry.name));
            set_map (visible_entry.name);

            stack.set_visible_child (scores);
            layout_button.set_visible (true);
        }
    }

    public string get_map_display_name (string name)
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

    public void set_map (string name)
    {
        layout_button.set_label (get_map_display_name (name));
        score_model.clear ();

        var entries = history.entries.copy ();
        entries.sort (compare_entries);

        foreach (var entry in entries)
        {
            if (entry.name != name)
                continue;

            var date_label = entry.date.format ("%x");

            var time_label = "%us".printf (entry.duration);
            if (entry.duration >= 60)
                time_label = "%um %us".printf (entry.duration / 60, entry.duration % 60);

            int weight = Pango.Weight.NORMAL;
            if (entry == selected_entry)
                weight = Pango.Weight.BOLD;

            Gtk.TreeIter iter;
            score_model.append (out iter);
            score_model.set (iter, 0, date_label, 1, time_label, 2, weight);

            if (entry == selected_entry)
            {
                var piter = iter;
                if (score_model.iter_previous (ref piter))
                {
                    var ppiter = piter;
                    if (score_model.iter_previous (ref ppiter))
                        piter = ppiter;
                }
                else
                    piter = iter;
                scores.scroll_to_cell (score_model.get_path (piter), null, false, 0, 0);
            }
        }
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
}
