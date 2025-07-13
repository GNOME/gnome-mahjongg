// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class GameSave {
    public string map_name;
    public double elapsed_time;
    public int move_number;
    public int32 seed;
    private Tile[] tiles;

    private string filename;

    public GameSave (string filename) {
        this.filename = filename;
    }

    public bool load () {
        string data;
        size_t length;

        try {
            FileUtils.get_contents (filename, out data, out length);
        }
        catch (FileError e) {
            warning ("Could not load game save %s: %s\n", filename, e.message);
            return false;
        }

        var parser = MarkupParser () {
            start_element = start_element_cb
        };
        var parse_context = new MarkupParseContext (parser, 0, this, null);
        try {
            parse_context.parse (data, (ssize_t) length);
        }
        catch (MarkupError e) {
            warning ("Could not parse game save %s: %s\n", filename, e.message);
            return false;
        }
        return true;
    }

    public void write (Game game) {
        var builder = new StringBuilder ();

        builder.append_printf ("<game map_name=\"%s\" elapsed_time=\"%s\" move_number=\"%d\" seed=\"%d\">\n",
            game.map.name,
            game.elapsed.to_string (),
            game.current_move_number,
            game.seed
        );

        builder.append ("\t<tiles>\n");

        foreach (unowned var tile in game) {
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
            warning ("Could not save game to %s: %s", filename, e.message);
        }
    }

    public bool exists () {
        return FileUtils.test (filename, FileTest.EXISTS);
    }

    public bool is_valid (Map map) {
        var n_matched_tiles = 0;
        foreach (unowned var slot in map) {
            foreach (unowned var tile in tiles) {
                if (slot.equals (tile.slot)) {
                    n_matched_tiles++;
                    break;
                }
            }
        }
        return map.n_slots == n_matched_tiles;
    }

    public void delete () {
        if (!exists ())
            return;

        var result = FileUtils.remove (filename);
        if (result == -1)
            warning ("Could not remove save file %s.", filename);

        map_name = "";
        elapsed_time = 0.0;
        move_number = 0;
        seed = 0;
        tiles = null;
    }

    public Iterator iterator () {
        return new Iterator (this);
    }

    private string? get_attribute (string[] attribute_names, string[] attribute_values, string name,
                                   string? default = null) {
        for (var i = 0; attribute_names[i] != null; i++)
            if (attribute_names[i].down () == name)
                return attribute_values[i];

        return default;
    }

    private double get_attribute_d (string[] attribute_names, string[] attribute_values, string name,
                                    double default = 0.0) {
        var a = get_attribute (attribute_names, attribute_values, name);
        if (a != null)
            return double.parse (a);
        return default;
    }

    private void start_element_cb (MarkupParseContext context, string element_name, string[] attribute_names,
                                   string[] attribute_values) throws MarkupError {
        switch (element_name.down ()) {
        case "game":
            map_name = get_attribute (attribute_names, attribute_values, "map_name", "");
            elapsed_time = get_attribute_d (attribute_names, attribute_values, "elapsed_time");
            move_number = (int) get_attribute_d (attribute_names, attribute_values, "move_number");
            seed = (int) get_attribute_d (attribute_names, attribute_values, "seed");
            break;

        case "tile":
            var tile_number = (int) (get_attribute_d (attribute_names, attribute_values, "number"));
            var visible = get_attribute (attribute_names, attribute_values, "visible") == "true";
            var move_number = (int) (get_attribute_d (attribute_names, attribute_values, "move_number"));
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x"));
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y"));
            var layer = (int) (get_attribute_d (attribute_names, attribute_values, "layer"));

            var slot = new Slot (x, y, layer);
            var tile = new Tile (slot) {
                number = tile_number,
                visible = visible,
                move_number = move_number
            };
            tiles += tile;
            break;
        }
    }

    public class Iterator {
        private int index;
        private GameSave game_save;

        public Iterator (GameSave game_save) {
            this.game_save = game_save;
        }

        public bool next () {
            return index < game_save.tiles.length;
        }

        public unowned Tile get () {
            return game_save.tiles[index++];
        }
    }
}
