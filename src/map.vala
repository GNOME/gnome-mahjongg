// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class Slot {
    public int x;
    public int y;
    public int layer;

    public Slot (int x, int y, int layer) {
        this.x = x;
        this.y = y;
        this.layer = layer;
    }

    public bool equals (Slot b) {
        return this.x == b.x && this.y == b.y && this.layer == b.layer;
    }
}

public class Map {
    public string? name;
    public string? score_name;
    private List<Slot> slots;

    public int n_slots {
        get { return (int) slots.length (); }
    }

    public Map.builtin () {
        name = "Turtle";
        score_name = "easy";
        add_slot (new Slot (13, 7, 4));
        add_slot (new Slot (12, 8, 3));
        add_slot (new Slot (14, 8, 3));
        add_slot (new Slot (12, 6, 3));
        add_slot (new Slot (14, 6, 3));
        add_slot (new Slot (10, 10, 2));
        add_slot (new Slot (12, 10, 2));
        add_slot (new Slot (14, 10, 2));
        add_slot (new Slot (16, 10, 2));
        add_slot (new Slot (10, 8, 2));
        add_slot (new Slot (12, 8, 2));
        add_slot (new Slot (14, 8, 2));
        add_slot (new Slot (16, 8, 2));
        add_slot (new Slot (10, 6, 2));
        add_slot (new Slot (12, 6, 2));
        add_slot (new Slot (14, 6, 2));
        add_slot (new Slot (16, 6, 2));
        add_slot (new Slot (10, 4, 2));
        add_slot (new Slot (12, 4, 2));
        add_slot (new Slot (14, 4, 2));
        add_slot (new Slot (16, 4, 2));
        add_slot (new Slot (8, 12, 1));
        add_slot (new Slot (10, 12, 1));
        add_slot (new Slot (12, 12, 1));
        add_slot (new Slot (14, 12, 1));
        add_slot (new Slot (16, 12, 1));
        add_slot (new Slot (18, 12, 1));
        add_slot (new Slot (8, 10, 1));
        add_slot (new Slot (10, 10, 1));
        add_slot (new Slot (12, 10, 1));
        add_slot (new Slot (14, 10, 1));
        add_slot (new Slot (16, 10, 1));
        add_slot (new Slot (18, 10, 1));
        add_slot (new Slot (8, 8, 1));
        add_slot (new Slot (10, 8, 1));
        add_slot (new Slot (12, 8, 1));
        add_slot (new Slot (14, 8, 1));
        add_slot (new Slot (16, 8, 1));
        add_slot (new Slot (18, 8, 1));
        add_slot (new Slot (8, 6, 1));
        add_slot (new Slot (10, 6, 1));
        add_slot (new Slot (12, 6, 1));
        add_slot (new Slot (14, 6, 1));
        add_slot (new Slot (16, 6, 1));
        add_slot (new Slot (18, 6, 1));
        add_slot (new Slot (8, 4, 1));
        add_slot (new Slot (10, 4, 1));
        add_slot (new Slot (12, 4, 1));
        add_slot (new Slot (14, 4, 1));
        add_slot (new Slot (16, 4, 1));
        add_slot (new Slot (18, 4, 1));
        add_slot (new Slot (8, 2, 1));
        add_slot (new Slot (10, 2, 1));
        add_slot (new Slot (12, 2, 1));
        add_slot (new Slot (14, 2, 1));
        add_slot (new Slot (16, 2, 1));
        add_slot (new Slot (18, 2, 1));
        add_slot (new Slot (2, 14, 0));
        add_slot (new Slot (4, 14, 0));
        add_slot (new Slot (6, 14, 0));
        add_slot (new Slot (8, 14, 0));
        add_slot (new Slot (10, 14, 0));
        add_slot (new Slot (12, 14, 0));
        add_slot (new Slot (14, 14, 0));
        add_slot (new Slot (16, 14, 0));
        add_slot (new Slot (18, 14, 0));
        add_slot (new Slot (20, 14, 0));
        add_slot (new Slot (22, 14, 0));
        add_slot (new Slot (24, 14, 0));
        add_slot (new Slot (6, 12, 0));
        add_slot (new Slot (8, 12, 0));
        add_slot (new Slot (10, 12, 0));
        add_slot (new Slot (12, 12, 0));
        add_slot (new Slot (14, 12, 0));
        add_slot (new Slot (16, 12, 0));
        add_slot (new Slot (18, 12, 0));
        add_slot (new Slot (20, 12, 0));
        add_slot (new Slot (4, 10, 0));
        add_slot (new Slot (6, 10, 0));
        add_slot (new Slot (8, 10, 0));
        add_slot (new Slot (10, 10, 0));
        add_slot (new Slot (12, 10, 0));
        add_slot (new Slot (14, 10, 0));
        add_slot (new Slot (16, 10, 0));
        add_slot (new Slot (18, 10, 0));
        add_slot (new Slot (20, 10, 0));
        add_slot (new Slot (22, 10, 0));
        add_slot (new Slot (0, 7, 0));
        add_slot (new Slot (2, 8, 0));
        add_slot (new Slot (4, 8, 0));
        add_slot (new Slot (6, 8, 0));
        add_slot (new Slot (8, 8, 0));
        add_slot (new Slot (10, 8, 0));
        add_slot (new Slot (12, 8, 0));
        add_slot (new Slot (14, 8, 0));
        add_slot (new Slot (16, 8, 0));
        add_slot (new Slot (18, 8, 0));
        add_slot (new Slot (20, 8, 0));
        add_slot (new Slot (22, 8, 0));
        add_slot (new Slot (24, 8, 0));
        add_slot (new Slot (2, 6, 0));
        add_slot (new Slot (4, 6, 0));
        add_slot (new Slot (6, 6, 0));
        add_slot (new Slot (8, 6, 0));
        add_slot (new Slot (10, 6, 0));
        add_slot (new Slot (12, 6, 0));
        add_slot (new Slot (14, 6, 0));
        add_slot (new Slot (16, 6, 0));
        add_slot (new Slot (18, 6, 0));
        add_slot (new Slot (20, 6, 0));
        add_slot (new Slot (22, 6, 0));
        add_slot (new Slot (24, 6, 0));
        add_slot (new Slot (4, 4, 0));
        add_slot (new Slot (6, 4, 0));
        add_slot (new Slot (8, 4, 0));
        add_slot (new Slot (10, 4, 0));
        add_slot (new Slot (12, 4, 0));
        add_slot (new Slot (14, 4, 0));
        add_slot (new Slot (16, 4, 0));
        add_slot (new Slot (18, 4, 0));
        add_slot (new Slot (20, 4, 0));
        add_slot (new Slot (22, 4, 0));
        add_slot (new Slot (6, 2, 0));
        add_slot (new Slot (8, 2, 0));
        add_slot (new Slot (10, 2, 0));
        add_slot (new Slot (12, 2, 0));
        add_slot (new Slot (14, 2, 0));
        add_slot (new Slot (16, 2, 0));
        add_slot (new Slot (18, 2, 0));
        add_slot (new Slot (20, 2, 0));
        add_slot (new Slot (2, 0, 0));
        add_slot (new Slot (4, 0, 0));
        add_slot (new Slot (6, 0, 0));
        add_slot (new Slot (8, 0, 0));
        add_slot (new Slot (10, 0, 0));
        add_slot (new Slot (12, 0, 0));
        add_slot (new Slot (14, 0, 0));
        add_slot (new Slot (16, 0, 0));
        add_slot (new Slot (18, 0, 0));
        add_slot (new Slot (20, 0, 0));
        add_slot (new Slot (22, 0, 0));
        add_slot (new Slot (24, 0, 0));
        add_slot (new Slot (26, 7, 0));
        add_slot (new Slot (28, 7, 0));
    }

    private int _width;
    public int h_overhang;
    public int width {
        get {
            if (_width > 0)
                return _width;

            var x = 0;
            var layer = 0;
            foreach (unowned var slot in slots) {
                if (slot.x >= x && slot.layer >= layer) {
                    x = slot.x;
                    layer = slot.layer;
                }
            }

            /* Width is x location of right most tile and the width of that tile (2 units) */
            h_overhang = layer;
            _width = x + 2;
            return _width;
        }
    }

    private int _height;
    public int v_overhang;
    public int height {
        get {
            if (_height > 0)
                return _height;

            var y = 0;
            var layer = 0;
            foreach (unowned var slot in slots) {
                if (slot.y > y)
                    y = slot.y;

                else if (slot.y == 0 && slot.layer > layer)
                    layer = slot.layer;
            }

            /* Height is x location of bottom most tile and the height of that tile (2 units) */
            v_overhang = layer;
            _height = y + 2;
            return _height;
        }
    }

    public void add_slot (Slot slot) {
        slots.insert_sorted (slot, compare_slots);
    }

    public unowned Slot? get_slot (int position) {
        return slots.nth_data (position);
    }

    public Iterator iterator () {
        return new Iterator (this);
    }

    private static int compare_slots (Slot a, Slot b) {
        /* Sort lowest to highest */
        var dl = a.layer - b.layer;
        if (dl != 0)
            return dl;

        /* Sort diagonally, top left to bottom right */
        var dx = a.x - b.x;
        var dy = a.y - b.y;
        if (dx > dy)
            return -1;
        return 1;
    }

    public class Iterator {
        private int index;
        private Map map;

        public Iterator (Map map) {
            this.map = map;
        }

        public bool next () {
            return index < map.slots.length ();
        }

        public unowned Slot get () {
            return map.slots.nth_data (index++);
        }
    }
}

public class MapLoader {
    private Map[] maps;
    private Map? map;
    private int layer_z;

    public int n_maps {
        get { return maps.length; }
    }

    public void load_builtin () {
        maps += new Map.builtin ();
    }

    public void load_folder (string folder_path) {
        Dir dir;
        try {
            dir = Dir.open (folder_path);
        }
        catch (FileError e) {
            return;
        }

        while (true) {
            var filename = dir.read_name ();
            if (filename == null)
                break;

            if (!filename.has_suffix (".map"))
                continue;

            var path = Path.build_filename (folder_path, filename);
            load_file (path);
        }
    }

    public unowned Map? get_map_by_name (string name) {
        foreach (unowned var map in maps) {
            if (map.name == name) {
                return map;
            }
        }
        return null;
    }

    public unowned Map? get_map_at_position (int position) {
        if (position >= 0 && position < n_maps)
            return maps[position];
        return null;
    }

    public unowned Map get_next_map (Map map) {
        int map_index = -1;
        for (int i = 0; i < n_maps; i++) {
            if (maps[i] == map) {
                map_index = i;
                break;
            }
        }
        var next_map_index = (map_index + 1) % (int) n_maps;
        return get_map_at_position (next_map_index);
    }

    public unowned Map get_random_map () {
        var map_index = Random.int_range (0, (int) n_maps);
        return get_map_at_position (map_index);
    }

    public string get_map_display_name (string name) {
        var display_name = name;

        foreach (var map in maps) {
            if (map.score_name == name) {
                display_name = dpgettext2 (null, "mahjongg map name", map.name);
                break;
            }
        }
        return display_name;
    }

    public Iterator iterator () {
        return new Iterator (this);
    }

    private bool load_file (string filename) {
        string data;
        size_t length;

        try {
            FileUtils.get_contents (filename, out data, out length);
        }
        catch (FileError e) {
            warning ("Could not load map %s: %s\n", filename, e.message);
            return false;
        }

        var parser = MarkupParser () {
            start_element = start_element_cb,
            end_element = end_element_cb
        };
        var parse_context = new MarkupParseContext (parser, 0, this, null);
        try {
            parse_context.parse (data, (ssize_t) length);
        }
        catch (MarkupError e) {
            warning ("Could not parse map %s: %s\n", filename, e.message);
            return false;
        }
        return true;
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
        if (element_name.down () == "map") {
            map = new Map ();
            map.name = get_attribute (attribute_names, attribute_values, "name", "");
            map.score_name = get_attribute (attribute_names, attribute_values, "scorename", "");
            return;
        }

        if (map == null)
            return;

        switch (element_name.down ()) {
        case "layer":
            layer_z = (int) get_attribute_d (attribute_names, attribute_values, "z");
            break;

        case "row":
            var x1 = (int) (get_attribute_d (attribute_names, attribute_values, "left") * 2);
            var x2 = (int) (get_attribute_d (attribute_names, attribute_values, "right") * 2);
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; x1 <= x2; x1 += 2)
                map.add_slot (new Slot (x1, y, z));
            break;

        case "column":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; y1 <= y2; y1 += 2)
                map.add_slot (new Slot (x, y1, z));
            break;

        case "block":
            var x1 = (int) (get_attribute_d (attribute_names, attribute_values, "left") * 2);
            var x2 = (int) (get_attribute_d (attribute_names, attribute_values, "right") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; x1 <= x2; x1 += 2)
                for (var y = y1; y <= y2; y += 2)
                    map.add_slot (new Slot (x1, y, z));
            break;

        case "tile":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            map.add_slot (new Slot (x, y, z));
            break;
        }
    }

    private void end_element_cb (MarkupParseContext context, string element_name) throws MarkupError {
        switch (element_name.down ()) {
        case "map":
            if (map.n_slots > 0 && map.n_slots <= 144 && map.n_slots % 2 == 0)
                maps += map;
            else
                warning ("Invalid map %s with %d slots", map.name, map.n_slots);
            map = null;
            break;

        case "layer":
            layer_z = 0;
            break;
        }
    }

    public class Iterator {
        private int index;
        private MapLoader map_loader;

        public Iterator (MapLoader map_loader) {
            this.map_loader = map_loader;
        }

        public bool next () {
            return index < map_loader.maps.length;
        }

        public unowned Map get () {
            return map_loader.maps[index++];
        }
    }
}
