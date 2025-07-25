// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class GameSave {
    public Map? map;
    public double clock;
    public int move;
    public int32 seed;

    private string map_name;
    private string filename;
    private Tile[] tiles;

    public GameSave (string filename) {
        this.filename = filename;
    }

    public bool load (Maps maps) {
        string data;
        size_t length;

        if (!FileUtils.test (filename, FileTest.EXISTS))
            return false;

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
            reset ();
            return false;
        }

        map = maps.get_map_by_name (map_name);
        if (!is_valid (map)) {
            warning ("Saved layout '%s' is not valid.\n", map_name);
            reset ();
            return false;
        }
        return true;
    }

    public void write (Game game) {
        if (!game.can_save)
            return;

        var builder = new StringBuilder ();

        builder.append_printf ("<game map=\"%s\" seed=\"%d\" clock=\"%s\" move=\"%d\">\n",
            game.map.name,
            game.seed,
            game.elapsed.to_string (),
            game.current_move
        );

        builder.append ("\t<tiles>\n");

        foreach (unowned var tile in game) {
            builder.append_printf (
                "\t\t<tile number=\"%d\" visible=\"%s\" move=\"%d\" z=\"%d\" x=\"%d\" y=\"%d\"/>\n",
                tile.number,
                tile.visible ? "true" : "false",
                tile.move,
                tile.slot.layer,
                tile.slot.x,
                tile.slot.y
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

    public void delete () {
        if (!FileUtils.test (filename, FileTest.EXISTS))
            return;

        var result = FileUtils.remove (filename);
        if (result == -1)
            warning ("Could not remove save file %s.", filename);

        reset ();
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
            map_name = get_attribute (attribute_names, attribute_values, "map", "");
            seed = (int) get_attribute_d (attribute_names, attribute_values, "seed");
            clock = get_attribute_d (attribute_names, attribute_values, "clock");
            move = (int) get_attribute_d (attribute_names, attribute_values, "move");
            break;

        case "tile":
            var number = (int) (get_attribute_d (attribute_names, attribute_values, "number"));
            var visible = get_attribute (attribute_names, attribute_values, "visible") == "true";
            var move = (int) (get_attribute_d (attribute_names, attribute_values, "move"));
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x"));
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y"));
            var layer = (int) (get_attribute_d (attribute_names, attribute_values, "z"));

            var slot = new Slot (x, y, layer);
            var tile = new Tile (slot) {
                number = number,
                visible = visible,
                move = move
            };
            tiles += tile;
            break;
        }
    }

    private bool is_valid (Map? map) {
        if (map == null)
            return false;

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

    private void reset () {
        map = null;
        map_name = "";
        clock = 0.0;
        move = 0;
        seed = 0;
        tiles = null;
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
