/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public struct Slot {
    public int x;
    public int y;
    public int layer;
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

    return 0;
}

public class Map {
    public string? name;
    public string? score_name;
    public List<Slot?> slots;

    public Map.test () {
        name = "Test";
        score_name = "test";
        slots.append (Slot () { x = 0, y = 0, layer = 0 });
        slots.append (Slot () { x = 2, y = 0, layer = 0 });
        slots.append (Slot () { x = 2, y = 0, layer = 1 });
        slots.append (Slot () { x = 4, y = 0, layer = 0 });
        slots.append (Slot () { x = 0, y = 2, layer = 0 });
        slots.append (Slot () { x = 2, y = 2, layer = 0 });
        slots.append (Slot () { x = 2, y = 2, layer = 1 });
        slots.append (Slot () { x = 4, y = 2, layer = 0 });
    }

    public Map.builtin () {
        name = "Turtle";
        score_name = "easy";
        slots.append (Slot () { x = 13, y = 7, layer = 4 });
        slots.append (Slot () { x = 12, y = 8, layer = 3 });
        slots.append (Slot () { x = 14, y = 8, layer = 3 });
        slots.append (Slot () { x = 12, y = 6, layer = 3 });
        slots.append (Slot () { x = 14, y = 6, layer = 3 });
        slots.append (Slot () { x = 10, y = 10, layer = 2 });
        slots.append (Slot () { x = 12, y = 10, layer = 2 });
        slots.append (Slot () { x = 14, y = 10, layer = 2 });
        slots.append (Slot () { x = 16, y = 10, layer = 2 });
        slots.append (Slot () { x = 10, y = 8, layer = 2 });
        slots.append (Slot () { x = 12, y = 8, layer = 2 });
        slots.append (Slot () { x = 14, y = 8, layer = 2 });
        slots.append (Slot () { x = 16, y = 8, layer = 2 });
        slots.append (Slot () { x = 10, y = 6, layer = 2 });
        slots.append (Slot () { x = 12, y = 6, layer = 2 });
        slots.append (Slot () { x = 14, y = 6, layer = 2 });
        slots.append (Slot () { x = 16, y = 6, layer = 2 });
        slots.append (Slot () { x = 10, y = 4, layer = 2 });
        slots.append (Slot () { x = 12, y = 4, layer = 2 });
        slots.append (Slot () { x = 14, y = 4, layer = 2 });
        slots.append (Slot () { x = 16, y = 4, layer = 2 });
        slots.append (Slot () { x = 8, y = 12, layer = 1 });
        slots.append (Slot () { x = 10, y = 12, layer = 1 });
        slots.append (Slot () { x = 12, y = 12, layer = 1 });
        slots.append (Slot () { x = 14, y = 12, layer = 1 });
        slots.append (Slot () { x = 16, y = 12, layer = 1 });
        slots.append (Slot () { x = 18, y = 12, layer = 1 });
        slots.append (Slot () { x = 8, y = 10, layer = 1 });
        slots.append (Slot () { x = 10, y = 10, layer = 1 });
        slots.append (Slot () { x = 12, y = 10, layer = 1 });
        slots.append (Slot () { x = 14, y = 10, layer = 1 });
        slots.append (Slot () { x = 16, y = 10, layer = 1 });
        slots.append (Slot () { x = 18, y = 10, layer = 1 });
        slots.append (Slot () { x = 8, y = 8, layer = 1 });
        slots.append (Slot () { x = 10, y = 8, layer = 1 });
        slots.append (Slot () { x = 12, y = 8, layer = 1 });
        slots.append (Slot () { x = 14, y = 8, layer = 1 });
        slots.append (Slot () { x = 16, y = 8, layer = 1 });
        slots.append (Slot () { x = 18, y = 8, layer = 1 });
        slots.append (Slot () { x = 8, y = 6, layer = 1 });
        slots.append (Slot () { x = 10, y = 6, layer = 1 });
        slots.append (Slot () { x = 12, y = 6, layer = 1 });
        slots.append (Slot () { x = 14, y = 6, layer = 1 });
        slots.append (Slot () { x = 16, y = 6, layer = 1 });
        slots.append (Slot () { x = 18, y = 6, layer = 1 });
        slots.append (Slot () { x = 8, y = 4, layer = 1 });
        slots.append (Slot () { x = 10, y = 4, layer = 1 });
        slots.append (Slot () { x = 12, y = 4, layer = 1 });
        slots.append (Slot () { x = 14, y = 4, layer = 1 });
        slots.append (Slot () { x = 16, y = 4, layer = 1 });
        slots.append (Slot () { x = 18, y = 4, layer = 1 });
        slots.append (Slot () { x = 8, y = 2, layer = 1 });
        slots.append (Slot () { x = 10, y = 2, layer = 1 });
        slots.append (Slot () { x = 12, y = 2, layer = 1 });
        slots.append (Slot () { x = 14, y = 2, layer = 1 });
        slots.append (Slot () { x = 16, y = 2, layer = 1 });
        slots.append (Slot () { x = 18, y = 2, layer = 1 });
        slots.append (Slot () { x = 2, y = 14, layer = 0 });
        slots.append (Slot () { x = 4, y = 14, layer = 0 });
        slots.append (Slot () { x = 6, y = 14, layer = 0 });
        slots.append (Slot () { x = 8, y = 14, layer = 0 });
        slots.append (Slot () { x = 10, y = 14, layer = 0 });
        slots.append (Slot () { x = 12, y = 14, layer = 0 });
        slots.append (Slot () { x = 14, y = 14, layer = 0 });
        slots.append (Slot () { x = 16, y = 14, layer = 0 });
        slots.append (Slot () { x = 18, y = 14, layer = 0 });
        slots.append (Slot () { x = 20, y = 14, layer = 0 });
        slots.append (Slot () { x = 22, y = 14, layer = 0 });
        slots.append (Slot () { x = 24, y = 14, layer = 0 });
        slots.append (Slot () { x = 6, y = 12, layer = 0 });
        slots.append (Slot () { x = 8, y = 12, layer = 0 });
        slots.append (Slot () { x = 10, y = 12, layer = 0 });
        slots.append (Slot () { x = 12, y = 12, layer = 0 });
        slots.append (Slot () { x = 14, y = 12, layer = 0 });
        slots.append (Slot () { x = 16, y = 12, layer = 0 });
        slots.append (Slot () { x = 18, y = 12, layer = 0 });
        slots.append (Slot () { x = 20, y = 12, layer = 0 });
        slots.append (Slot () { x = 4, y = 10, layer = 0 });
        slots.append (Slot () { x = 6, y = 10, layer = 0 });
        slots.append (Slot () { x = 8, y = 10, layer = 0 });
        slots.append (Slot () { x = 10, y = 10, layer = 0 });
        slots.append (Slot () { x = 12, y = 10, layer = 0 });
        slots.append (Slot () { x = 14, y = 10, layer = 0 });
        slots.append (Slot () { x = 16, y = 10, layer = 0 });
        slots.append (Slot () { x = 18, y = 10, layer = 0 });
        slots.append (Slot () { x = 20, y = 10, layer = 0 });
        slots.append (Slot () { x = 22, y = 10, layer = 0 });
        slots.append (Slot () { x = 0, y = 7, layer = 0 });
        slots.append (Slot () { x = 2, y = 8, layer = 0 });
        slots.append (Slot () { x = 4, y = 8, layer = 0 });
        slots.append (Slot () { x = 6, y = 8, layer = 0 });
        slots.append (Slot () { x = 8, y = 8, layer = 0 });
        slots.append (Slot () { x = 10, y = 8, layer = 0 });
        slots.append (Slot () { x = 12, y = 8, layer = 0 });
        slots.append (Slot () { x = 14, y = 8, layer = 0 });
        slots.append (Slot () { x = 16, y = 8, layer = 0 });
        slots.append (Slot () { x = 18, y = 8, layer = 0 });
        slots.append (Slot () { x = 20, y = 8, layer = 0 });
        slots.append (Slot () { x = 22, y = 8, layer = 0 });
        slots.append (Slot () { x = 24, y = 8, layer = 0 });
        slots.append (Slot () { x = 2, y = 6, layer = 0 });
        slots.append (Slot () { x = 4, y = 6, layer = 0 });
        slots.append (Slot () { x = 6, y = 6, layer = 0 });
        slots.append (Slot () { x = 8, y = 6, layer = 0 });
        slots.append (Slot () { x = 10, y = 6, layer = 0 });
        slots.append (Slot () { x = 12, y = 6, layer = 0 });
        slots.append (Slot () { x = 14, y = 6, layer = 0 });
        slots.append (Slot () { x = 16, y = 6, layer = 0 });
        slots.append (Slot () { x = 18, y = 6, layer = 0 });
        slots.append (Slot () { x = 20, y = 6, layer = 0 });
        slots.append (Slot () { x = 22, y = 6, layer = 0 });
        slots.append (Slot () { x = 24, y = 6, layer = 0 });
        slots.append (Slot () { x = 4, y = 4, layer = 0 });
        slots.append (Slot () { x = 6, y = 4, layer = 0 });
        slots.append (Slot () { x = 8, y = 4, layer = 0 });
        slots.append (Slot () { x = 10, y = 4, layer = 0 });
        slots.append (Slot () { x = 12, y = 4, layer = 0 });
        slots.append (Slot () { x = 14, y = 4, layer = 0 });
        slots.append (Slot () { x = 16, y = 4, layer = 0 });
        slots.append (Slot () { x = 18, y = 4, layer = 0 });
        slots.append (Slot () { x = 20, y = 4, layer = 0 });
        slots.append (Slot () { x = 22, y = 4, layer = 0 });
        slots.append (Slot () { x = 6, y = 2, layer = 0 });
        slots.append (Slot () { x = 8, y = 2, layer = 0 });
        slots.append (Slot () { x = 10, y = 2, layer = 0 });
        slots.append (Slot () { x = 12, y = 2, layer = 0 });
        slots.append (Slot () { x = 14, y = 2, layer = 0 });
        slots.append (Slot () { x = 16, y = 2, layer = 0 });
        slots.append (Slot () { x = 18, y = 2, layer = 0 });
        slots.append (Slot () { x = 20, y = 2, layer = 0 });
        slots.append (Slot () { x = 2, y = 0, layer = 0 });
        slots.append (Slot () { x = 4, y = 0, layer = 0 });
        slots.append (Slot () { x = 6, y = 0, layer = 0 });
        slots.append (Slot () { x = 8, y = 0, layer = 0 });
        slots.append (Slot () { x = 10, y = 0, layer = 0 });
        slots.append (Slot () { x = 12, y = 0, layer = 0 });
        slots.append (Slot () { x = 14, y = 0, layer = 0 });
        slots.append (Slot () { x = 16, y = 0, layer = 0 });
        slots.append (Slot () { x = 18, y = 0, layer = 0 });
        slots.append (Slot () { x = 20, y = 0, layer = 0 });
        slots.append (Slot () { x = 22, y = 0, layer = 0 });
        slots.append (Slot () { x = 24, y = 0, layer = 0 });
        slots.append (Slot () { x = 26, y = 7, layer = 0 });
        slots.append (Slot () { x = 28, y = 7, layer = 0 });
    }

    private int _width;
    public int width {
        get {
            if (_width > 0)
                return _width;

            var w = 0;
            foreach (unowned var slot in slots) {
                if (slot.x > w)
                    w = slot.x;
            }

            /* Width is x location of right most tile and the width of that tile (2 units) */
            _width = w + 2;
            return _width;
        }
    }

    private int _height;
    public int height {
        get {
            if (_height > 0)
                return _height;

            var h = 0;
            foreach (unowned var slot in slots) {
                if (slot.y > h)
                    h = slot.y;
            }

            /* Height is x location of bottom most tile and the height of that tile (2 units) */
            _height = h + 2;
            return _height;
        }
    }
}

public class MapLoader {
    public List<Map> maps;
    private Map? map;
    private int layer_z;

    public void load (string filename) throws Error {
        string data;
        size_t length;
        FileUtils.get_contents (filename, out data, out length);

        var parser = MarkupParser ();
        parser.start_element = start_element_cb;
        parser.end_element = end_element_cb;
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
        case "mahjongg":
            break;

        case "map":
            map = new Map ();
            map.name = get_attribute (attribute_names, attribute_values, "name", "");
            map.score_name = get_attribute (attribute_names, attribute_values, "scorename", "");
            break;

        case "layer":
            layer_z = (int) get_attribute_d (attribute_names, attribute_values, "z");
            break;

        case "row":
            var x1 = (int) (get_attribute_d (attribute_names, attribute_values, "left") * 2);
            var x2 = (int) (get_attribute_d (attribute_names, attribute_values, "right") * 2);
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; x1 <= x2; x1 += 2)
                map.slots.append (Slot () { x = x1, y = y, layer = z });
            break;

        case "column":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; y1 <= y2; y1 += 2)
                map.slots.append (Slot () { x = x, y = y1, layer = z });
            break;

        case "block":
            var x1 = (int) (get_attribute_d (attribute_names, attribute_values, "left") * 2);
            var x2 = (int) (get_attribute_d (attribute_names, attribute_values, "right") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; x1 <= x2; x1 += 2)
                for (var y = y1; y <= y2; y += 2)
                    map.slots.append (Slot () { x = x1, y = y, layer = z });
            break;

        case "tile":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            map.slots.append (Slot () { x = x, y = y, layer = z });
            break;
        }
    }

    private void end_element_cb (MarkupParseContext context, string element_name) throws MarkupError {
        switch (element_name.down ()) {
        case "map":
            var n_slots = map.slots.length ();
            if (map.name != null && map.score_name != null && n_slots <= 144 && n_slots % 2 == 0)
                maps.append (map);
            else
                warning ("Invalid map");
            map = null;
            break;

        case "layer":
            layer_z = 0;
            break;
        }
    }
}
