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

    public void set_clock (string clock)
    {
        titlewidget.set_title (clock);
    }

    public void set_moves_left (uint moves_left)
    {
        titlewidget.set_subtitle (_("Moves Left: %2u").printf (moves_left));
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
