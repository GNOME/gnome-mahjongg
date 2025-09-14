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
    private unowned Gtk.DropDown layout_dropdown;

    [GtkChild]
    private unowned Adw.WindowTitle title_widget;

    [GtkChild]
    private unowned Gtk.Stack content_stack;

    [GtkChild]
    private unowned Gtk.ColumnView score_view;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn rank_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn time_column;

    [GtkChild]
    private unowned Gtk.ColumnViewColumn player_column;

    [GtkChild]
    private unowned Gtk.Button new_game_button;

    private History history;
    private HistoryEntry? completed_entry;
    private ListStore score_model;
    private Maps maps;

    public ScoreDialog (History history, Maps maps, string selected_layout = "",
                        HistoryEntry? completed_entry = null) {
        this.maps = maps;
        this.history = history;
        this.completed_entry = completed_entry;

        set_up_score_view ();
        set_up_layout_dropdown ();
        set_up_layout_menu (selected_layout);
        clear_scores_button.sensitive = history.length > 0;

        if (completed_entry != null) {
            clear_scores_button.visible = false;
            toolbar_view.reveal_bottom_bars = true;

            header_stack.visible_child_name = "title";
            title_widget.subtitle = _("Layout: %s").printf (maps.get_map_display_name (completed_entry.name));

            this.focus_widget = score_view;
        }
        else
            this.focus_widget = layout_dropdown;

        clear_scores_button.clicked.connect (clear_scores_cb);
        closed.connect (closed_cb);
    }

    private void add_layout (Gtk.StringList model, string layout_name) {
        var display_name = maps.get_map_display_name (layout_name);

        if (find_layout_position (model, display_name) == uint.MAX)
            model.append (display_name);
    }

    private uint find_layout_position (Gtk.StringList model, string display_name) {
        for (var i = 0; i < model.get_n_items (); i++) {
            if (model.get_string (i) == display_name)
                return i;
        }
        return uint.MAX;
    }

    private void set_up_layout_dropdown () {
        unowned var button = layout_dropdown.get_first_child () as Gtk.Button;
        unowned var popover = layout_dropdown.get_last_child () as Gtk.Popover;

        button.set_has_frame (false);
        popover.set_halign (Gtk.Align.CENTER);
    }

    private void set_up_layout_menu (string selected_layout) {
        var display_name = maps.get_map_display_name (selected_layout);
        var model = new Gtk.StringList (null);
        layout_dropdown.model = model;

        foreach (unowned var map in maps)
            add_layout (model, map.score_name);

        foreach (unowned var entry in history)
            add_layout (model, entry.name);

        if (completed_entry != null)
            selected_layout = completed_entry.name;
        else if (selected_layout == "")
            selected_layout = model.get_string (0);

        layout_dropdown.set_selected (find_layout_position (model, display_name));
        layout_dropdown.notify["selected"].connect (layout_selected_cb);
        layout_selected_cb ();
    }

    private void set_up_score_view () {
        set_up_rank_column ();
        set_up_time_column ();
        set_up_player_column ();

        score_model = new ListStore (typeof (HistoryEntry));
        var sort_model = new Gtk.SortListModel (score_model, score_view.sorter);
        score_view.model = new Gtk.NoSelection (sort_model);
        score_view.sort_by_column (rank_column, Gtk.SortType.ASCENDING);

        score_view.sorter.changed.connect (() => {
            /* Scroll to top when resorting. Ensure that the score view is valid,
             * since the sorter can change while destroying the dialog. */
            if (score_view != null)
                score_view.scroll_to (0, null, Gtk.ListScrollFlags.FOCUS, null);
        });

        if (completed_entry == null)
            return;

        var controller = new Gtk.EventControllerFocus ();
        controller.enter.connect (() => {
            Idle.add (() => {
                score_view.scroll_to (completed_entry.rank - 1, null, Gtk.ListScrollFlags.FOCUS, null);
                score_view.child_focus (Gtk.DirectionType.TAB_FORWARD);  // Focus the text entry
                return false;
            });
        });
        score_view.add_controller (controller);
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
            var inscription = new Gtk.Inscription (null);
            inscription.add_css_class ("caption");
            inscription.add_css_class ("numeric");

            list_item.child = inscription;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var inscription = list_item.child as Gtk.Inscription;
            unowned var entry = list_item.item as HistoryEntry;

            inscription.text = entry.rank.to_string ();
        });
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) rank_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) date_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) player_sorter_cb));

        rank_column.sorter = sorter;
        rank_column.factory = factory;
    }

    private void set_up_time_column () {
        var factory = new Gtk.SignalListItemFactory ();

        factory.setup.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            var inscription = new Gtk.Inscription (null);
            inscription.add_css_class ("numeric");

            list_item.child = inscription;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var inscription = list_item.child as Gtk.Inscription;
            unowned var entry = list_item.item as HistoryEntry;

            var time_label = "%us".printf (entry.duration);
            if (entry.duration >= 60)
                time_label = "%um %us".printf (entry.duration / 60, entry.duration % 60);
            if (entry == completed_entry)
                inscription.add_css_class ("heading");

            inscription.text = time_label;
        });

        time_column.sorter = rank_column.sorter;
        time_column.factory = factory;
    }

    private void set_up_player_column () {
        var factory = new Gtk.SignalListItemFactory ();
        var sorter = new Gtk.MultiSorter ();

        factory.setup.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            var stack = new Gtk.Stack ();
            var inscription = new Gtk.Inscription (null) {
                text_overflow = Gtk.InscriptionOverflow.ELLIPSIZE_END,
                valign = Gtk.Align.CENTER
            };
            stack.add_named (inscription, "label");

            if (completed_entry != null) {
                var entry_input = new Gtk.Entry () {
                    has_frame = false,
                    max_width_chars = 5
                };
                unowned var entry_input_weak = entry_input;  // Prevent memory leak

                entry_input.add_css_class ("heading");
                entry_input.notify["text"].connect (() => {
                    unowned var history_entry = list_item.item as HistoryEntry;

                    if (history_entry != completed_entry)
                        return;

                    if (entry_input_weak.text.length <= 0)
                        history_entry.player = Environment.get_real_name ();
                    else
                        history_entry.player = entry_input_weak.text;
                });
                entry_input.activate.connect (() => { new_game_button.activate (); });

                stack.add_named (entry_input, "entry");
            }

            list_item.child = stack;
        });
        factory.bind.connect ((factory, object) => {
            unowned var list_item = object as Gtk.ListItem;
            unowned var stack = list_item.child as Gtk.Stack;
            unowned var entry = list_item.item as HistoryEntry;

            if (entry == completed_entry) {
                stack.visible_child_name = "entry";
                unowned var entry_input = stack.visible_child as Gtk.Entry;
                entry_input.text = entry.player;
            }
            else {
                stack.visible_child_name = "label";
                unowned var inscription = stack.visible_child as Gtk.Inscription;
                inscription.text = entry.player;
                inscription.tooltip_text = "%s\n%s".printf (entry.player, entry.date.format ("%x"));
            }
        });
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) player_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) rank_sorter_cb));
        sorter.append (new Gtk.CustomSorter ((CompareDataFunc<HistoryEntry>) date_sorter_cb));

        player_column.sorter = sorter;
        player_column.factory = factory;
    }

    private void layout_selected_cb () {
        unowned var selected_item = layout_dropdown.selected_item as Gtk.StringObject;
        var selected_name = selected_item.string;
        List<HistoryEntry> entry_list = null;
        HistoryEntry[] entry_array = null;

        foreach (unowned var entry in history)
            if (maps.get_map_display_name (entry.name) == selected_name)
                entry_list.prepend (entry);

        entry_list.sort (player_sorter_cb);
        entry_list.sort (date_sorter_cb);
        entry_list.sort (rank_sorter_cb);

        var rank = 1;
        foreach (unowned var entry in entry_list) {
            entry.rank = rank++;
            entry_array += entry;
        }

        var position = 0;
        var n_removals = score_model.n_items;
        score_model.splice (position, n_removals, entry_array);

        if (score_model.n_items > 0) {
            content_stack.visible_child_name = "scores";
            score_view.scroll_to (position, null, Gtk.ListScrollFlags.FOCUS, null);
            return;
        }
        content_stack.visible_child_name = "no-scores";
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
