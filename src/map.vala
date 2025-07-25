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
        if (dx < dy)
            return 1;
        return dx;
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

public class Maps {
    private Map[] maps;
    private Map? map;
    private int layer_z;

    public int n_maps {
        get { return maps.length; }
    }

    public bool load () {
        var path = "/org/gnome/Mahjongg/maps/mahjongg.map";
        string data;
        try {
            data = (string) resources_lookup_data (path, ResourceLookupFlags.NONE).get_data ();
        }
        catch (Error e) {
            warning ("Could not load map %s: %s\n", path, e.message);
            return false;
        }

        var parser = MarkupParser () {
            start_element = start_element_cb,
            end_element = end_element_cb
        };
        var parse_context = new MarkupParseContext (parser, 0, this, null);
        try {
            parse_context.parse (data, data.length);
        }
        catch (MarkupError e) {
            warning ("Could not parse map %s: %s\n", path, e.message);
            return false;
        }
        return true;
    }

    public unowned Map? get_map_by_name (string? name) {
        foreach (unowned var map in maps) {
            if (map.name == name) {
                return map;
            }
        }
        return null;
    }

    public unowned Map? get_map_at_position (int position) {
        if (position < 0 || position >= n_maps)
            return null;
        return maps[position];
    }

    public unowned Map get_next_map (Map map) {
        var map_index = 0;
        foreach (unowned var m in maps) {
            if (m == map)
                break;
            map_index++;
        }
        var next_map_index = (map_index + 1) % (int) n_maps;
        return get_map_at_position (next_map_index);
    }

    public unowned Map get_random_map () {
        var map_index = Random.int_range (0, (int) n_maps);
        return get_map_at_position (map_index);
    }

    public string get_map_display_name (string score_name) {
        var display_name = score_name;

        foreach (var map in maps) {
            if (map.score_name == score_name) {
                display_name = dpgettext2 (null, "mahjongg map name", map.name);
                break;
            }
        }
        return display_name;
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
        private Maps maps;

        public Iterator (Maps maps) {
            this.maps = maps;
        }

        public bool next () {
            return index < maps.maps.length;
        }

        public unowned Map get () {
            return maps.maps[index++];
        }
    }
}
