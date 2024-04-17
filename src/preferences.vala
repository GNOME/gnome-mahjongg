[GtkTemplate (ui = "/org/gnome/Mahjongg/ui/preferences.ui")]
public class PreferencesWindow : Adw.PreferencesWindow {

    [GtkChild]
    private unowned Adw.ComboRow themes_row;

    [GtkChild]
    private unowned Adw.ComboRow layout_row;

    [GtkChild]
    private unowned Adw.ComboRow background_row;

    private Settings settings;

    public PreferencesWindow (Settings settings) {
        this.settings = settings;
        themes_row.set_expression (new Gtk.PropertyExpression (typeof (ThemeItem), null, "display_name"));
        layout_row.set_expression (new Gtk.PropertyExpression (typeof (LayoutItem), null, "display_name"));
        background_row.set_expression (new Gtk.PropertyExpression (typeof (BackgroundItem), null, "display_name"));
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

    public void populate_backgrounds ()
    {
        var model = new ListStore (typeof (BackgroundItem));
        model.append (new BackgroundItem ("system", _("Follow system")));
        model.append (new BackgroundItem ("light", _("Light")));
        model.append (new BackgroundItem ("dark", _("Dark")));

        background_row.set_model (model);

        for (int i = 0; i < model.get_n_items(); i++)
        {
            if (settings.get_string ("background-color") == ((BackgroundItem)model.get_item (i)).name)
            {
                background_row.set_selected (i);
                break;
            }
        }

        background_row.notify["selected"].connect ( (s, p) => {
            var background_item = background_row.model.get_item (background_row.selected);
            settings.set_string ("background-color", ((BackgroundItem)background_item).name);
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

public class BackgroundItem : Object {
    public string name {get; set;}
    public string display_name {get; set;}

    public BackgroundItem (string name, string display_name)
    {
        this.name = name;
        this.display_name = display_name;
    }
}
