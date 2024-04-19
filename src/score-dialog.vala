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
    private unowned Gtk.ComboBox layouts;

    [GtkChild]
    private unowned Gtk.TreeView scores;

    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore size_model;
    private Gtk.ListStore score_model;
    private unowned List<Map> maps;

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_quit = false, List<Map> maps)
    {
        this.maps = maps;
        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;

        size_model = new Gtk.ListStore (2, typeof (string), typeof (string));
        layouts.changed.connect (size_changed_cb);
        layouts.model = size_model;
        var renderer = new Gtk.CellRendererText ();
        layouts.pack_start (renderer, true);
        layouts.add_attribute (renderer, "text", 0);

        score_model = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (int));

        renderer = new Gtk.CellRendererText ();
        scores.insert_column_with_attributes (-1, _("Date"), renderer, "text", 0, "weight", 2);
        renderer = new Gtk.CellRendererText ();
        renderer.xalign = 1.0f;
        scores.insert_column_with_attributes (-1, _("Time"), renderer, "text", 1, "weight", 2);
        scores.model = score_model;

        foreach (var entry in history.entries)
            entry_added_cb (entry);

        set_can_close (!show_quit);
        header_bar.set_show_start_title_buttons (!show_quit);
        header_bar.set_show_end_title_buttons (!show_quit);
        toolbar_view.set_reveal_bottom_bars (show_quit);
    }

    public void set_map (string name)
    {
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

    private static int compare_entries (HistoryEntry a, HistoryEntry b)
    {
        var d = strcmp (a.name, b.name);
        if (d != 0)
            return d;
        if (a.duration != b.duration)
            return (int) a.duration - (int) b.duration;
        return a.date.compare (b.date);
    }

    private void size_changed_cb (Gtk.ComboBox combo)
    {
        Gtk.TreeIter iter;
        if (!combo.get_active_iter (out iter))
            return;

        string name;
        combo.model.get (iter, 1, out name);
        set_map (name);
    }

    private void entry_added_cb (HistoryEntry entry)
    {
        /* Ignore if already have an entry for this */
        Gtk.TreeIter iter;
        var have_size_entry = false;
        if (size_model.get_iter_first (out iter))
        {
            do
            {
                string name;
                size_model.get (iter, 1, out name);
                if (name == entry.name)
                {
                    have_size_entry = true;
                    break;
                }
            } while (size_model.iter_next (ref iter));
        }

        if (!have_size_entry)
        {
            unowned List<Map> map = maps.first ();
            string display_name = entry.name;
            do
            {
                if (map.data.score_name == display_name)
                {
                    display_name = dpgettext2 (null, "mahjongg map name", map.data.name);
                    break;
                }
            }
            while ((map = map.next) != null);

            size_model.append (out iter);
            size_model.set (iter, 0, display_name, 1, entry.name);

            /* Select this entry if don't have any */
            if (layouts.get_active () == -1)
                layouts.set_active_iter (iter);

            /* Select this entry if the same category as the selected one */
            if (selected_entry != null && entry.name == selected_entry.name)
                layouts.set_active_iter (iter);
        }
    }
}
