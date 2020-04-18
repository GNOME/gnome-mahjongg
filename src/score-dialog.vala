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

public class ScoreDialog : Dialog
{
    private History history;
    private HistoryEntry? selected_entry = null;
    private Gtk.ListStore size_model;
    private Gtk.ListStore score_model;
    private ComboBox size_combo;
    private TreeView scores;
    private unowned List<Map> maps;

    public ScoreDialog (History history, HistoryEntry? selected_entry = null, bool show_quit = false, List<Map> maps)
    {
        this.maps = maps;
        this.history = history;
        history.entry_added.connect (entry_added_cb);
        this.selected_entry = selected_entry;

        if (show_quit)
        {
            add_button (_("_Quit"), ResponseType.CLOSE);
            add_button (_("New Game"), ResponseType.OK);
        }
        else
            add_button (_("OK"), ResponseType.DELETE_EVENT);
        set_size_request (200, 300);

        var vbox = new Box (Orientation.VERTICAL, 5);
        vbox.margin_top = 6;
        vbox.margin_start = 6;
        vbox.margin_end = 6;
        vbox.margin_bottom = 6;
        get_content_area ().append (vbox);

        var hbox = new Box (Orientation.HORIZONTAL, 6);
        vbox.append (hbox);

        var label = new Label (_("Layout:"));
        hbox.append (label);

        size_model = new Gtk.ListStore (2, typeof (string), typeof (string));

        size_combo = new ComboBox ();
        size_combo.changed.connect (size_changed_cb);
        size_combo.model = size_model;
        var renderer = new CellRendererText ();
        size_combo.pack_start (renderer, true);
        size_combo.add_attribute (renderer, "text", 0);
        hbox.append (size_combo);

        var scroll = new ScrolledWindow ();
        scroll.has_frame = true;
        scroll.set_policy (PolicyType.NEVER, PolicyType.AUTOMATIC);
        scroll.hexpand = true;
        scroll.vexpand = true;
        vbox.append (scroll);

        score_model = new Gtk.ListStore (3, typeof (string), typeof (string), typeof (int));

        scores = new TreeView ();
        renderer = new CellRendererText ();
        scores.insert_column_with_attributes (-1, _("Date"), renderer, "text", 0, "weight", 2);
        renderer = new CellRendererText ();
        renderer.xalign = 1.0f;
        scores.insert_column_with_attributes (-1, _("Time"), renderer, "text", 1, "weight", 2);
        scores.model = score_model;
        scroll.set_child (scores);

        foreach (var entry in history.entries)
            entry_added_cb (entry);
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

            TreeIter iter;
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

    private void size_changed_cb (ComboBox combo)
    {
        TreeIter iter;
        if (!combo.get_active_iter (out iter))
            return;

        string name;
        combo.model.get (iter, 1, out name);
        set_map (name);
    }

    private void entry_added_cb (HistoryEntry entry)
    {
        /* Ignore if already have an entry for this */
        TreeIter iter;
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
            if (size_combo.get_active () == -1)
                size_combo.set_active_iter (iter);

            /* Select this entry if the same category as the selected one */
            if (selected_entry != null && entry.name == selected_entry.name)
                size_combo.set_active_iter (iter);
        }
    }
}
