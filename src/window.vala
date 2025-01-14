[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/window.ui")]
public class MahjonggWindow : Adw.ApplicationWindow {
    private string theme;

    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Adw.WindowTitle title_widget;

    [GtkChild]
    private unowned Gtk.MenuButton menu_button;

    [GtkChild]
    private unowned Gtk.Button pause_button;

    public MahjonggWindow (Gtk.Application application, GameView game_view, List<Map> maps) {
        Object (application: application);

        var menu_builder = new Gtk.Builder.from_resource ("/org/gnome/Mahjongg/ui/menu.ui");
        var menu_model = menu_builder.get_object ("menu") as MenuModel;
        var layout_menu = menu_builder.get_object ("layout_menu") as Menu;

        layout_menu.remove_all ();

        foreach (var map in maps) {
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

    public void update_clock (string clock) {
        title_widget.title = clock;
    }

    public void update_moves_left (uint moves_left) {
        title_widget.subtitle = _("Moves Left: %2u").printf (moves_left);
    }

    public void update_theme (string theme) {
        if (this.theme != null)
            remove_css_class (this.theme);

        add_css_class (theme);
        this.theme = theme;
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
    }
}
