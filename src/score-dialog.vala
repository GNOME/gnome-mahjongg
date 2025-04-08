// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/score-dialog.ui")]
public class ScoreDialog : Adw.Dialog {
    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Gtk.Button clear_scores_button;

    [GtkChild]
    private unowned Gtk.Stack header_stack;

    [GtkChild]
    private unowned Gtk.MenuButton layout_button;

    [GtkChild]
    private unowned Adw.WindowTitle title_widget;

    [GtkChild]
    private unowned Gtk.Stack content_stack;

    [GtkChild]
    private unowned Gtk.ColumnView score_view;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn rank_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn player_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn time_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn date_column;

    [GtkChild]
    private unowned Gtk.Button new_game_button;

    private History history;
    private HistoryEntry? completed_entry;
    private Gtk.ListItem? selected_item;
    private ListStore score_model;
    private unowned List<Map> maps;
    private string[] layout_names;

    private const ActionEntry[] ACTION_ENTRIES = {
        { "layout", null, "s", "''", set_map_cb }
    };

    private string score_map {
        set {
            var sorted_entries = history.entries.copy ();
            sorted_entries.sort (player_sorter_cb);
            sorted_entries.sort (date_sorter_cb);
            sorted_entries.sort (rank_sorter_cb);

            layout_button.label = get_map_display_name (value);
            score_model.remove_all ();

            foreach (unowned var entry in sorted_entries) {
                if (entry.name == value)
                    score_model.append (entry);
            }

            if (score_model.n_items > 0) {
                content_stack.visible_child_name = "scores";
                score_view.scroll_to (0, null, Gtk.ListScrollFlags.FOCUS, null);
                return;
            }
            content_stack.visible_child_name = "no-scores";
        }
    }

    public ScoreDialog (History history, List<Map> maps, string selected_layout = "",
                        HistoryEntry? completed_entry = null) {
        this.maps = maps;
        this.history = history;
        this.completed_entry = completed_entry;

        set_up_score_view ();
        set_up_layout_menu (selected_layout);
        clear_scores_button.sensitive = history.entries.length () > 0;

        if (completed_entry != null) {
            clear_scores_button.visible = false;
            toolbar_view.reveal_bottom_bars = true;

            header_stack.visible_child_name = "title";
            title_widget.subtitle = _("Layout: %s").printf (get_map_display_name (completed_entry.name));

            var controller = new Gtk.EventControllerFocus ();
            controller.enter.connect (score_view_focus_cb);
            score_view.add_controller (controller);
            focus_widget = score_view;
        }

        clear_scores_button.clicked.connect (clear_scores_cb);
        closed.connect (closed_cb);
    }

    private void add_layout (Menu menu, string layout_name) {
        if (layout_name in layout_names)
            return;

        var display_name = get_map_display_name (layout_name);
        var menu_item = new MenuItem (display_name, null);
        menu_item.set_action_and_target_value ("scores.layout", new Variant.string (layout_name));

        menu.append_item (menu_item);
        layout_names += layout_name;
    }

    private void set_up_layout_menu (string selected_layout) {
        var action_group = new SimpleActionGroup ();
        action_group.add_action_entries (ACTION_ENTRIES, this);
        insert_action_group ("scores", action_group);

        var menu = new Menu ();
        layout_button.menu_model = menu;

        foreach (unowned var map in maps)
            add_layout (menu, map.score_name);

        foreach (unowned var entry in history.entries)
            add_layout (menu, entry.name);

        if (completed_entry != null)
            selected_layout = completed_entry.name;
        else if (selected_layout == "")
            selected_layout = maps.first ().data.score_name;

        unowned var action = action_group.lookup_action ("layout") as SimpleAction;
        action.set_state (new Variant.string (selected_layout));
        score_map = selected_layout;
    }

    private void set_up_score_view () {
        set_up_rank_column ();
        set_up_player_column ();
        set_up_time_column ();
        set_up_date_column ();

        score_model = new ListStore (typeof (HistoryEntry));
        var sort_model = new Gtk.SortListModel (score_model, score_view.sorter);
        score_view.model = new Gtk.NoSelection (sort_model);
        score_view.sort_by_column (rank_column, Gtk.SortType.ASCENDING);

        score_view.sorter.changed.connect (() => {
            /* Scroll to top when resorting */
            score_view.scroll_to (0, null, Gtk.ListScrollFlags.FOCUS, null);
        });
    }

    private static int rank_sorter_cb (HistoryEntry entry1, HistoryEntry entry2) {
        return (int) (entry1.duration > entry2.duration) - (int) (entry1.duration < entry2.duration);
    }

    private static int player_sorter_cb (HistoryEntry entry1, HistoryEntry entry2) {
        return strcmp (entry1.player, entry2.player);
    }

    private static int date_sorter_cb (HistoryEntry entry1, HistoryEntry entry2) {
        return entry2.date.compare (entry1.date);
    }

    private void set_up_rank_column () {
        var factory = new Gtk.SignalListItemFactory ();
        var sorter = new Gtk.MultiSorter ();

        factory.setup.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            var label = new Gtk.Label (null) {
                width_chars = 3,
                xalign = 0
            };
            label.add_css_class ("caption");
            label.add_css_class ("numeric");
            list_item.child = label;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var label = list_item.child as Gtk.Label;
            unowned var entry = list_item.item as HistoryEntry;

            uint position;
            score_model.find (entry, out position);

            label.label = (position + 1).to_string ();
        });
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) rank_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) date_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) player_sorter_cb));

        rank_column.sorter = sorter;
        rank_column.factory = factory;
    }

    private static void connect_entry_input (Gtk.Entry entry_input, Gtk.ListItem list_item) {
        /* Static method to avoid issues with circular references
           https://gitlab.gnome.org/GNOME/vala/-/issues/957 */

        entry_input.notify["text"].connect (() => {
            unowned var history_entry = list_item.item as HistoryEntry;
            if (entry_input.text.length <= 0)
                history_entry.player = Environment.get_real_name ();
            else
                history_entry.player = entry_input.text;
        });
    }

    private void set_up_player_column () {
        var factory = new Gtk.SignalListItemFactory ();
        var sorter = new Gtk.MultiSorter ();

        factory.setup.connect ((factory, object) => {
            var stack = new Gtk.Stack ();
            stack.add_named (new Gtk.Inscription (null), "label");

            unowned var list_item = object as Gtk.ListItem;
            var entry_input = new Gtk.Entry () {
                has_frame = false,
                max_width_chars = 5
            };

            connect_entry_input (entry_input, list_item);
            entry_input.activate.connect (() => {
                new_game_button.activate ();
            });

            stack.add_named (entry_input, "entry");
            list_item.child = stack;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var stack = list_item.child as Gtk.Stack;
            unowned var entry = list_item.item as HistoryEntry;

            if (entry == completed_entry) {
                stack.visible_child_name = "entry";
                unowned var text_entry = stack.visible_child as Gtk.Entry;
                text_entry.text = entry.player;
                text_entry.add_css_class ("heading");
                selected_item = list_item;
            }
            else {
                stack.visible_child_name = "label";
                unowned var inscription = stack.visible_child as Gtk.Inscription;
                inscription.text = entry.player;
            }
        });
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) player_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) rank_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) date_sorter_cb));

        player_column.sorter = sorter;
        player_column.factory = factory;
    }

    private void set_up_time_column () {
        var factory = new Gtk.SignalListItemFactory ();

        factory.setup.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            var label = new Gtk.Inscription (null);

            label.add_css_class ("numeric");
            list_item.child = label;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var label = list_item.child as Gtk.Inscription;
            unowned var entry = list_item.item as HistoryEntry;

            var time_label = "%us".printf (entry.duration);
            if (entry.duration >= 60)
                time_label = "%um %us".printf (entry.duration / 60, entry.duration % 60);
            if (entry == completed_entry)
                label.add_css_class ("heading");

            label.text = time_label;
        });

        time_column.sorter = rank_column.sorter;
        time_column.factory = factory;
    }

    private void set_up_date_column () {
        var factory = new Gtk.SignalListItemFactory ();
        var sorter = new Gtk.MultiSorter ();

        factory.setup.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            var label = new Gtk.Label (null) { xalign = 0 };

            label.add_css_class ("numeric");
            list_item.child = label;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var label = list_item.child as Gtk.Label;
            unowned var entry = list_item.item as HistoryEntry;

            var date_label = entry.date.format ("%x");
            if (entry == completed_entry)
                label.add_css_class ("heading");

            label.label = date_label;
        });
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) date_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) rank_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) player_sorter_cb));

        date_column.sorter = sorter;
        date_column.factory = factory;
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
        score_map = name;
    }

    private void score_view_focus_cb () {
        uint position;
        var found_item = score_model.find (completed_entry, out position);

        if (!found_item)
            return;

        Idle.add (() => {
            unowned var stack = selected_item.child as Gtk.Stack;
            unowned var text_entry = stack.visible_child;
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
        case "clear":
            toolbar_view.reveal_bottom_bars = false;
            content_stack.visible_child_name = "no-scores";
            clear_scores_button.sensitive = false;
            score_model.remove_all ();

            completed_entry = null;
            selected_item = null;

            history.clear ();
            break;
        default:
            break;
        }
    }

    private void closed_cb () {
        if (completed_entry != null)
            history.save ();
    }
}
