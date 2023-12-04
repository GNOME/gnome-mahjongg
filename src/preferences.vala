[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/preferences.ui")]
public class PreferencesWindow : Adw.PreferencesWindow {

    [GtkChild]
    private unowned Adw.ComboRow themes_row;

    [GtkChild]
    private unowned Adw.ComboRow layout_row;

    [GtkChild]
    private unowned Gtk.ColorButton background_btn;

    private Settings settings;

    public PreferencesWindow (Settings settings) {
        this.settings = settings;
        themes_row.set_expression (new Gtk.PropertyExpression (typeof (ThemeItem), null, "display_name"));
        layout_row.set_expression (new Gtk.PropertyExpression (typeof (LayoutItem), null, "display_name"));
    }

    public void populate_themes (List<string> themes)
    {
        var model = new ListStore (typeof (ThemeItem));
        foreach (var theme in themes)
        {
            model.append (new ThemeItem (theme));
        }

        themes_row.set_model (model);
        for (int i = 0; i < model.get_n_items(); i++)
        {
            if (settings.get_string ("tileset") == ((ThemeItem)model.get_item (i)).filename)
            {
                themes_row.set_selected (i);
                break;
            }
        }

        themes_row.notify["selected"].connect ( (s, p) => {
            var thememodel = themes_row.model as ListModel;
            var theme = ((ThemeItem)thememodel.get_item (themes_row.selected)).filename;
            settings.set_string ("tileset", theme);
        });
    }

    public void populate_layouts (List<Map> layouts)
    {
        var model = new ListStore (typeof (LayoutItem));
        foreach (var map in layouts)
        {
            model.append (new LayoutItem (map.name));
        }
        layout_row.set_model (model);

        for (int i = 0; i < model.get_n_items(); i++)
        {
            if (settings.get_string ("mapset") == ((LayoutItem)model.get_item (i)).name)
            {
                layout_row.set_selected (i);
                break;
            }
        }

        layout_row.notify["selected"].connect ( (s, p) => {
            var layoutmodel = layout_row.model as ListModel;
            var layout = ((LayoutItem)layoutmodel.get_item (layout_row.selected)).name;
            settings.set_string ("mapset", layout);
        });
    }

    public void populate_background (Gdk.RGBA background_color)
    {
        background_btn.set_rgba (background_color);
        background_btn.color_set.connect ( () => {
            var colour = background_btn.get_rgba ();
            settings.set_string ("bgcolour", colour.to_string ());
        });
    }
}

public class ThemeItem : Object {
    public string filename {get; set;}
    public string display_name {get; set;}

    public ThemeItem (string filename)
    {
        var tokens = filename.split (".", -1);
        this.filename = filename;
        this.display_name = tokens[0];
    }
}

public class LayoutItem : Object {
    public string name {get; set;}
    public string display_name {get; set;}

    public LayoutItem (string name)
    {
        this.name = name;
        this.display_name = dpgettext2 (null, "mahjongg map name", name);
    }
}
