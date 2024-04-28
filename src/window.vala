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

    public MahjonggWindow (Gtk.Application application, GameView game_view, List<Map> maps, List<string> themes)
    {
        Object(application: application);

        var menu_builder = new Gtk.Builder.from_resource ("/org/gnome/Mahjongg/ui/menu.ui");
        var menu_model = menu_builder.get_object ("menu") as MenuModel;
        var layout_menu = menu_builder.get_object ("layout_menu") as Menu;
        var theme_menu = menu_builder.get_object ("theme_menu") as Menu;

        foreach (var map in maps)
        {
            var menu_label = dpgettext2 (null, "mahjongg map name", map.name);
            var menu_item = new MenuItem (menu_label, null);
            menu_item.set_action_and_target_value ("app.layout", new Variant.string (map.name));
            layout_menu.append_item (menu_item);
        }

        foreach (var theme in themes)
        {
            var menu_label = theme.split (".", -1)[0].replace ("_", "__");
            var menu_item = new MenuItem (menu_label, null);
            menu_item.set_action_and_target_value ("app.theme", new Variant.string (theme));
            theme_menu.append_item (menu_item);
        }

        if (APP_ID.has_suffix (".Devel"))
            add_css_class("devel");

        menu_button.set_menu_model (menu_model);
        toolbar_view.set_content (game_view);
    }

    public void set_clock (string clock)
    {
        title_widget.set_title (clock);
    }

    public void set_moves_left (uint moves_left)
    {
        title_widget.set_subtitle (_("Moves Left: %2u").printf (moves_left));
    }

    public void pause ()
    {
        title_widget.set_subtitle (_("Paused"));
        pause_button.icon_name = "media-playback-start-symbolic";
        pause_button.set_tooltip_text (_("Resume Game"));
    }

    public void unpause ()
    {
        pause_button.icon_name = "media-playback-pause-symbolic";
        pause_button.set_tooltip_text (_("Pause Game"));
    }
}
