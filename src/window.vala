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
            if (_theme != null)
                remove_css_class (_theme);
            if (value != null)
                add_css_class (value);
            _theme = value;
        }
    }

    public MahjonggWindow (Gtk.Application application, GameView game_view, List<Map> maps) {
        Object (application: application);

        var menu_builder = new Gtk.Builder.from_resource ("/org/gnome/Mahjongg/ui/menu.ui");
        var menu_model = menu_builder.get_object ("menu") as MenuModel;
        var layout_menu = menu_builder.get_object ("layout_menu") as Menu;

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
        toolbar_view.content = game_view;
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
