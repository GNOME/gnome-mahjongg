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

    public string clock {
        set {
            title_widget.title = value;
        }
    }

    public uint moves_left {
        set {
            title_widget.subtitle = _("Moves Left: %2u").printf (value);
        }
    }

    private string? _theme;
    public string? theme {
        set {
            if (_theme == value)
                return;
            if (_theme != null)
                toolbar_view.remove_css_class (_theme);
            if (value != null)
                toolbar_view.add_css_class (value);
            _theme = value;
        }
    }

    public MahjonggWindow (Gtk.Application application, List<Map> maps) {
        Object (application: application);

        var menu_builder = new Gtk.Builder.from_resource (application.resource_base_path + "/ui/menu.ui");
        unowned var menu_model = menu_builder.get_object ("menu") as MenuModel;
        unowned var layout_menu = menu_builder.get_object ("layout_menu") as Menu;

        layout_menu.remove_all ();

        foreach (unowned var map in maps) {
            var menu_label = dpgettext2 (null, "mahjongg map name", map.name);
            var menu_item = new MenuItem (menu_label, null);
            menu_item.set_action_and_target_value ("app.layout", new Variant.string (map.name));
            layout_menu.append_item (menu_item);
        }

        if (APP_ID.has_suffix (".Devel"))
            add_css_class ("devel");

        menu_button.menu_model = menu_model;
    }

    public void add_game_view (GameView game_view) {
        stack.add_child (game_view);
    }

    public void set_game_view (GameView game_view, Gtk.StackTransitionType transition_type) {
        stack.transition_type = transition_type;
        stack.visible_child = game_view;
    }

    public void pause () {
        title_widget.subtitle = _("Paused");
        pause_button.icon_name = "media-playback-start-symbolic";
        pause_button.tooltip_text = _("Resume Game");
        toolbar_view.content.add_css_class ("dim-label");
    }

    public void unpause () {
        pause_button.icon_name = "media-playback-pause-symbolic";
        pause_button.tooltip_text = _("Pause Game");
        toolbar_view.content.remove_css_class ("dim-label");

        if (visible_dialog != null)
            visible_dialog.force_close ();
    }
}
