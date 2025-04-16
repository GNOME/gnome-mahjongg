// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class GameSave {
    public string filename;
    public string map_name;
    public double elapsed_time;
    public int move_number;
    public int32 seed;
    public List<Tile> tiles;

    public GameSave (string filename) {
        this.filename = filename;
    }

    public void load () throws Error {
        string data;
        size_t length;
        FileUtils.get_contents (filename, out data, out length);

        var parser = MarkupParser ();

        parser.start_element = start_element_cb;
        parser.text = null;
        parser.passthrough = null;
        parser.error = null;

        var parse_context = new MarkupParseContext (parser, 0, this, null);
        try {
            parse_context.parse (data, (ssize_t) length);
        }
        catch (MarkupError e) {
        }
    }

    public void write (Game game) {
        StringBuilder builder = new StringBuilder ();

        builder.append_printf ("<game map_name=\"%s\" elapsed_time=\"%s\" move_number=\"%d\" seed=\"%d\">\n",
            game.map.name,
            game.elapsed.to_string (),
            game.current_move_number,
            game.seed
        );

        builder.append ("\t<tiles>\n");

        foreach (unowned var tile in game.tiles) {
            builder.append_printf (
                "\t\t<tile number=\"%d\" visible=\"%s\" move_number=\"%d\" x=\"%d\" y=\"%d\" layer=\"%d\"/>\n",
                tile.number,
                tile.visible ? "true" : "false",
                tile.move_number,
                tile.slot.x,
                tile.slot.y,
                tile.slot.layer
            );
        }

        builder.append ("\t</tiles>\n");
        builder.append ("</game>\n");

        try {
            DirUtils.create_with_parents (Path.get_dirname (filename), 0775);
            FileUtils.set_contents (filename, builder.str);
        }
        catch (FileError e) {
            warning ("Failed to save the game : %s", e.message);
        }
    }

    public bool exists () {
        return FileUtils.test (filename, FileTest.EXISTS);
    }

    public void delete () {
        if (!exists ())
            return;

        int result = FileUtils.remove (filename);

        if (result == -1)
            warning ("Failed to remove the save file.");

        map_name = "";
        elapsed_time = 0.0;
        move_number = 0;
        seed = 0;
        tiles = new List<Tile> ();
    }

    private string? get_attribute (string[] attribute_names, string[] attribute_values, string name,
                                   string? default = null) {
        for (var i = 0; attribute_names[i] != null; i++) {
            if (attribute_names[i].down () == name)
                return attribute_values[i];
        }

        return default;
    }

    private double get_attribute_d (string[] attribute_names, string[] attribute_values, string name,
                                    double default = 0.0) {
        var a = get_attribute (attribute_names, attribute_values, name);
        if (a == null)
            return default;
        else
            return double.parse (a);
    }

    private void start_element_cb (MarkupParseContext context, string element_name, string[] attribute_names,
                                   string[] attribute_values) throws MarkupError {
        /* Identify the tag. */
        switch (element_name.down ()) {
        case "game":
            map_name = get_attribute (attribute_names, attribute_values, "map_name", "");
            elapsed_time = get_attribute_d (attribute_names, attribute_values, "elapsed_time");
            move_number = (int) get_attribute_d (attribute_names, attribute_values, "move_number");
            seed = (int) get_attribute_d (attribute_names, attribute_values, "seed");
            break;

        case "tile":
            int tile_number = (int) (get_attribute_d (attribute_names, attribute_values, "number"));
            bool visible = get_attribute (attribute_names, attribute_values, "visible") == "true";
            int move_number = (int) (get_attribute_d (attribute_names, attribute_values, "move_number"));
            int x = (int) (get_attribute_d (attribute_names, attribute_values, "x"));
            int y = (int) (get_attribute_d (attribute_names, attribute_values, "y"));
            int layer = (int) (get_attribute_d (attribute_names, attribute_values, "layer"));

            Slot slot = new Slot (x, y, layer);

            Tile tile = new Tile (slot) {
                number = tile_number,
                visible = visible,
                move_number = move_number
            };

            tiles.append (tile);
            break;
        }
    }
}
