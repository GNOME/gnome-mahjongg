// SPDX-FileCopyrightText: 2022-2025 Mahjongg Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/window.ui")]
public class MahjonggWindow : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Adw.WindowTitle title_widget;

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;

    [GtkChild]
    private unowned Gtk.Button pause_button;

    [GtkChild]
    private unowned Gtk.Stack stack;

    private Settings settings;
    private GameView game_view;
    private string? theme;

    private bool _compact;
    public bool compact {
        get { return _compact; }
        set {
            _compact = value;
            if (!value) {
                remove_css_class ("compact");
                return;
            }
            add_css_class ("compact");
        }
    }

    public MahjonggWindow (Gtk.Application application, Settings settings, Maps maps) {
        Object (application: application);
        this.settings = settings;

        var using_cairo = Environment.get_variable ("GSK_RENDERER") == "cairo";
        stack.add_named (new GameView (using_cairo), "primary");
        stack.add_named (new GameView (using_cairo), "secondary");

        /* Tile filters are too slow with the Cairo renderer */
        if (!using_cairo)
            stack.add_css_class ("tile-filter");

        var menu_builder = new Gtk.Builder.from_resource (application.resource_base_path + "/ui/menu.ui");
        unowned var menu_model = menu_builder.get_object ("menu") as MenuModel;
        unowned var layout_menu = menu_builder.get_object ("layout_menu") as Menu;

        layout_menu.remove_all ();

        foreach (unowned var map in maps) {
            var menu_label = maps.get_map_display_name (map.score_name);
            var menu_item = new MenuItem (menu_label, null);
            menu_item.set_action_and_target_value ("app.layout", new Variant.string (map.name));
            layout_menu.append_item (menu_item);
        }
        menu_button.menu_model = menu_model;

        if (APP_ID.has_suffix (".Devel"))
            add_css_class ("devel");

        settings.bind ("window-width", this, "default-width", SettingsBindFlags.DEFAULT);
        settings.bind ("window-height", this, "default-height", SettingsBindFlags.DEFAULT);
        settings.bind ("window-is-maximized", this, "maximized", SettingsBindFlags.DEFAULT);

        settings.changed.connect (conf_value_changed_cb);
        update_theme ();
    }

    public void new_game (Game game, bool rotate_map = false) {
        var transition_type = Gtk.StackTransitionType.NONE;
        var previous_game_view = game_view;

        if (rotate_map) {
            if (settings.get_string ("map-rotation") != "single")
                transition_type = Gtk.StackTransitionType.SLIDE_LEFT;
            else
                transition_type = Gtk.StackTransitionType.CROSSFADE;
        }

        var next_name = (stack.visible_child_name == "primary") ? "secondary" : "primary";
        game_view = stack.get_child_by_name (next_name) as GameView;
        update_theme (previous_game_view);

        if (previous_game_view != null) {
            previous_game_view.game = null;
            previous_game_view.set_theme (null);
        }

        game_view.game = game;
        game.moved.connect (moved_cb);
        game.paused_changed.connect (paused_changed_cb);
        game.tick.connect (tick_cb);

        stack.transition_type = transition_type;
        stack.visible_child = game_view;
    }

    private void update_theme (GameView? previous_game_view = null) {
        var color_scheme = settings.get_enum ("background-color");
        var new_theme = settings.get_string ("tileset");
        var style_manager = Adw.StyleManager.get_default ();

        if (color_scheme != style_manager.color_scheme)
            style_manager.set_color_scheme (color_scheme);

        if (game_view != null) {
            var path = application.resource_base_path + "/themes/";
            var fallback_theme = settings.get_default_value ("tileset").get_string ();
            game_view.set_theme (path + new_theme, previous_game_view, path + fallback_theme);
        }

        if (theme == new_theme)
            return;

        if (theme != null)
            toolbar_view.remove_css_class (theme);

        if (new_theme != null)
            toolbar_view.add_css_class (new_theme);

        theme = new_theme;
    }

    private void conf_value_changed_cb (Settings settings, string key) {
        if (key == "tileset" || key == "background-color")
            update_theme ();
    }

    private void moved_cb () {
        title_widget.subtitle = _("Moves Left: %2u").printf (game_view.game.moves_left);
    }

    private void paused_changed_cb () {
        if (game_view.game.paused) {
            title_widget.subtitle = _("Paused");
            pause_button.icon_name = "media-playback-start-symbolic";
            pause_button.tooltip_text = _("Resume Game");
            toolbar_view.content.add_css_class ("dim-label");
            return;
        }

        pause_button.icon_name = "media-playback-pause-symbolic";
        pause_button.tooltip_text = _("Pause Game");
        toolbar_view.content.remove_css_class ("dim-label");

        if (visible_dialog != null)
            visible_dialog.force_close ();

        moved_cb ();
    }

    private void tick_cb () {
        string clock;
        var elapsed = (int) game_view.game.elapsed;
        var hours = elapsed / 3600;
        var minutes = (elapsed - hours * 3600) / 60;
        var seconds = elapsed - hours * 3600 - minutes * 60;
        if (hours > 0)
            clock = "%02d∶\xE2\x80\x8E%02d∶\xE2\x80\x8E%02d".printf (hours, minutes, seconds);
        else
            clock = "%02d∶\xE2\x80\x8E%02d".printf (minutes, seconds);
        title_widget.title = clock;
    }
}
