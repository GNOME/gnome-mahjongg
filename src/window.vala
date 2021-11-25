[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/window.ui")]
public class MahjonggWindow : Gtk.ApplicationWindow {

    [GtkChild]
    private unowned Adw.WindowTitle titlewidget;

    [GtkChild]
    private unowned Gtk.Button pause_btn;

    public MahjonggWindow (Gtk.Application application, GameView game_view)
    {
        Object(application: application);
        this.set_child (game_view);
    }

    public void set_map_title (GameView game_view)
    {
        var display_name = dpgettext2 (null, "mahjongg map name", game_view.game.map.name);
        titlewidget.set_title (display_name);
    }

    public void set_subtitle (GameView game_view, string clock)
    {
        if (game_view.game.move_number != 1)
            titlewidget.set_subtitle ("Moves Left: %2u   %s".printf (game_view.game.moves_left, clock));
        else
            titlewidget.set_subtitle ("Moves Left: 0   %s".printf (clock));
    }

    public void pause ()
    {
        pause_btn.icon_name = "media-playback-start-symbolic";
        pause_btn.set_tooltip_text (_("Unpause the game"));
    }

    public void unpause ()
    {
        pause_btn.icon_name = "media-playback-pause-symbolic";
        pause_btn.set_tooltip_text (_("Pause the game"));
    }
}
