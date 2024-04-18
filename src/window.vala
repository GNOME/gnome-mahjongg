[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/window.ui")]
public class MahjonggWindow : Adw.ApplicationWindow {

    [GtkChild]
    private unowned Adw.ToolbarView toolbar_view;

    [GtkChild]
    private unowned Adw.WindowTitle titlewidget;

    [GtkChild]
    private unowned Gtk.Button pause_btn;

    public MahjonggWindow (Gtk.Application application, GameView game_view)
    {
        Object(application: application);
        toolbar_view.set_content (game_view);
    }

    public void set_map_title (GameView game_view)
    {
        var display_name = dpgettext2 (null, "mahjongg map name", game_view.game.map.name);
        titlewidget.set_title (display_name);
    }

    public void set_subtitle (GameView game_view, string clock)
    {
        string moves_left = _("Moves Left:");
        titlewidget.set_subtitle (("%s %2u   %s").printf (moves_left, game_view.game.moves_left, clock));
    }

    public void pause ()
    {
        pause_btn.icon_name = "media-playback-start-symbolic";
        pause_btn.set_tooltip_text (_("Resume Game"));
    }

    public void unpause ()
    {
        pause_btn.icon_name = "media-playback-pause-symbolic";
        pause_btn.set_tooltip_text (_("Pause Game"));
    }
}
