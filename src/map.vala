/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class Slot
{
    public int x;
    public int y;
    public int layer;
    
    public Slot (int x, int y, int layer)
    {
        this.x = x;
        this.y = y;
        this.layer = layer;
    }
}

private static int compare_slots (Slot a, Slot b)
{
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

public class Map
{
    public string? name = null;
    public string? score_name = null;
    public List<Slot> slots = null;

    public Map.test ()
    {
        name = "Test";
        score_name = "test";
        slots.append (new Slot (0, 0, 0));
        slots.append (new Slot (2, 0, 0));
        slots.append (new Slot (2, 0, 1));
        slots.append (new Slot (4, 0, 0));
        slots.append (new Slot (0, 2, 0));
        slots.append (new Slot (2, 2, 0));
        slots.append (new Slot (2, 2, 1));
        slots.append (new Slot (4, 2, 0));
    }

    public Map.builtin ()
    {
        name = "Easy";
        score_name = "easy";
        slots.append (new Slot (13, 7, 4));
        slots.append (new Slot (12, 8, 3));
        slots.append (new Slot (14, 8, 3));
        slots.append (new Slot (12, 6, 3));
        slots.append (new Slot (14, 6, 3));
        slots.append (new Slot (10, 10, 2));
        slots.append (new Slot (12, 10, 2));
        slots.append (new Slot (14, 10, 2));
        slots.append (new Slot (16, 10, 2));
        slots.append (new Slot (10, 8, 2));
        slots.append (new Slot (12, 8, 2));
        slots.append (new Slot (14, 8, 2));
        slots.append (new Slot (16, 8, 2));
        slots.append (new Slot (10, 6, 2));
        slots.append (new Slot (12, 6, 2));
        slots.append (new Slot (14, 6, 2));
        slots.append (new Slot (16, 6, 2));
        slots.append (new Slot (10, 4, 2));
        slots.append (new Slot (12, 4, 2));
        slots.append (new Slot (14, 4, 2));
        slots.append (new Slot (16, 4, 2));
        slots.append (new Slot (8, 12, 1));
        slots.append (new Slot (10, 12, 1));
        slots.append (new Slot (12, 12, 1));
        slots.append (new Slot (14, 12, 1));
        slots.append (new Slot (16, 12, 1));
        slots.append (new Slot (18, 12, 1));
        slots.append (new Slot (8, 10, 1));
        slots.append (new Slot (10, 10, 1));
        slots.append (new Slot (12, 10, 1));
        slots.append (new Slot (14, 10, 1));
        slots.append (new Slot (16, 10, 1));
        slots.append (new Slot (18, 10, 1));
        slots.append (new Slot (8, 8, 1));
        slots.append (new Slot (10, 8, 1));
        slots.append (new Slot (12, 8, 1));
        slots.append (new Slot (14, 8, 1));
        slots.append (new Slot (16, 8, 1));
        slots.append (new Slot (18, 8, 1));
        slots.append (new Slot (8, 6, 1));
        slots.append (new Slot (10, 6, 1));
        slots.append (new Slot (12, 6, 1));
        slots.append (new Slot (14, 6, 1));
        slots.append (new Slot (16, 6, 1));
        slots.append (new Slot (18, 6, 1));
        slots.append (new Slot (8, 4, 1));
        slots.append (new Slot (10, 4, 1));
        slots.append (new Slot (12, 4, 1));
        slots.append (new Slot (14, 4, 1));
        slots.append (new Slot (16, 4, 1));
        slots.append (new Slot (18, 4, 1));
        slots.append (new Slot (8, 2, 1));
        slots.append (new Slot (10, 2, 1));
        slots.append (new Slot (12, 2, 1));
        slots.append (new Slot (14, 2, 1));
        slots.append (new Slot (16, 2, 1));
        slots.append (new Slot (18, 2, 1));
        slots.append (new Slot (2, 14, 0));
        slots.append (new Slot (4, 14, 0));
        slots.append (new Slot (6, 14, 0));
        slots.append (new Slot (8, 14, 0));
        slots.append (new Slot (10, 14, 0));
        slots.append (new Slot (12, 14, 0));
        slots.append (new Slot (14, 14, 0));
        slots.append (new Slot (16, 14, 0));
        slots.append (new Slot (18, 14, 0));
        slots.append (new Slot (20, 14, 0));
        slots.append (new Slot (22, 14, 0));
        slots.append (new Slot (24, 14, 0));
        slots.append (new Slot (6, 12, 0));
        slots.append (new Slot (8, 12, 0));
        slots.append (new Slot (10, 12, 0));
        slots.append (new Slot (12, 12, 0));
        slots.append (new Slot (14, 12, 0));
        slots.append (new Slot (16, 12, 0));
        slots.append (new Slot (18, 12, 0));
        slots.append (new Slot (20, 12, 0));
        slots.append (new Slot (4, 10, 0));
        slots.append (new Slot (6, 10, 0));
        slots.append (new Slot (8, 10, 0));
        slots.append (new Slot (10, 10, 0));
        slots.append (new Slot (12, 10, 0));
        slots.append (new Slot (14, 10, 0));
        slots.append (new Slot (16, 10, 0));
        slots.append (new Slot (18, 10, 0));
        slots.append (new Slot (20, 10, 0));
        slots.append (new Slot (22, 10, 0));
        slots.append (new Slot (0, 7, 0));
        slots.append (new Slot (2, 8, 0));
        slots.append (new Slot (4, 8, 0));
        slots.append (new Slot (6, 8, 0));
        slots.append (new Slot (8, 8, 0));
        slots.append (new Slot (10, 8, 0));
        slots.append (new Slot (12, 8, 0));
        slots.append (new Slot (14, 8, 0));
        slots.append (new Slot (16, 8, 0));
        slots.append (new Slot (18, 8, 0));
        slots.append (new Slot (20, 8, 0));
        slots.append (new Slot (22, 8, 0));
        slots.append (new Slot (24, 8, 0));
        slots.append (new Slot (2, 6, 0));
        slots.append (new Slot (4, 6, 0));
        slots.append (new Slot (6, 6, 0));
        slots.append (new Slot (8, 6, 0));
        slots.append (new Slot (10, 6, 0));
        slots.append (new Slot (12, 6, 0));
        slots.append (new Slot (14, 6, 0));
        slots.append (new Slot (16, 6, 0));
        slots.append (new Slot (18, 6, 0));
        slots.append (new Slot (20, 6, 0));
        slots.append (new Slot (22, 6, 0));
        slots.append (new Slot (24, 6, 0));
        slots.append (new Slot (4, 4, 0));
        slots.append (new Slot (6, 4, 0));
        slots.append (new Slot (8, 4, 0));
        slots.append (new Slot (10, 4, 0));
        slots.append (new Slot (12, 4, 0));
        slots.append (new Slot (14, 4, 0));
        slots.append (new Slot (16, 4, 0));
        slots.append (new Slot (18, 4, 0));
        slots.append (new Slot (20, 4, 0));
        slots.append (new Slot (22, 4, 0));
        slots.append (new Slot (6, 2, 0));
        slots.append (new Slot (8, 2, 0));
        slots.append (new Slot (10, 2, 0));
        slots.append (new Slot (12, 2, 0));
        slots.append (new Slot (14, 2, 0));
        slots.append (new Slot (16, 2, 0));
        slots.append (new Slot (18, 2, 0));
        slots.append (new Slot (20, 2, 0));
        slots.append (new Slot (2, 0, 0));
        slots.append (new Slot (4, 0, 0));
        slots.append (new Slot (6, 0, 0));
        slots.append (new Slot (8, 0, 0));
        slots.append (new Slot (10, 0, 0));
        slots.append (new Slot (12, 0, 0));
        slots.append (new Slot (14, 0, 0));
        slots.append (new Slot (16, 0, 0));
        slots.append (new Slot (18, 0, 0));
        slots.append (new Slot (20, 0, 0));
        slots.append (new Slot (22, 0, 0));
        slots.append (new Slot (24, 0, 0));
        slots.append (new Slot (26, 7, 0));
        slots.append (new Slot (28, 7, 0));
    }
    
    public uint width
    {
        get
        {
            var w = 0;
            foreach (var slot in slots)
            {
                if (slot.x > w)
                    w = slot.x;
            }
            
            /* Width is x location of right most tile and the width of that tile (2 units) */
            return w + 2;
        }
    }

    public uint height
    {
        get
        {
            var h = 0;
            foreach (var slot in slots)
            {
                if (slot.y > h)
                    h = slot.y;
            }

            /* Height is x location of bottom most tile and the height of that tile (2 units) */
            return h + 2;
        }
    }
}

public class MapLoader
{
    public List<Map> maps = null;
    private Map map;
    private int layer_z = 0;

    public void load (string filename) throws Error
    {
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
        try
        {
            parse_context.parse (data, (ssize_t) length);
        }
        catch (MarkupError e)
        {
        }
    }

    private string? get_attribute (string[] attribute_names, string[] attribute_values, string name, string? default = null)
    {
        for (var i = 0; attribute_names[i] != null; i++)
        {
            if (attribute_names[i].down() == name)
                return attribute_values[i];
        }

        return default;
    }

    private double get_attribute_d (string[] attribute_names, string[] attribute_values, string name, double default = 0.0)
    {
        var a = get_attribute (attribute_names, attribute_values, name);
        if (a == null)
            return default;
        else
            return double.parse (a);
    }

    private void start_element_cb (MarkupParseContext context, string element_name, string[] attribute_names, string[] attribute_values) throws MarkupError
    {
        /* Identify the tag. */
        switch (element_name.down ())
        {
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
                map.slots.append (new Slot (x1, y, z));
            break;

        case "column":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; y1 <= y2; y1 += 2)
                map.slots.append (new Slot (x, y1, z));
            break;

        case "block":
            var x1 = (int) (get_attribute_d (attribute_names, attribute_values, "left") * 2);
            var x2 = (int) (get_attribute_d (attribute_names, attribute_values, "right") * 2);
            var y1 = (int) (get_attribute_d (attribute_names, attribute_values, "top") * 2);
            var y2 = (int) (get_attribute_d (attribute_names, attribute_values, "bottom") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            for (; x1 <= x2; x1 += 2)
                for (var y = y1; y <= y2; y += 2)
                    map.slots.append (new Slot (x1, y, z));
            break;

        case "tile":
            var x = (int) (get_attribute_d (attribute_names, attribute_values, "x") * 2);
            var y = (int) (get_attribute_d (attribute_names, attribute_values, "y") * 2);
            var z = (int) get_attribute_d (attribute_names, attribute_values, "z", layer_z);
            map.slots.append (new Slot (x, y, z));
            break;
        }
    }

    private void end_element_cb (MarkupParseContext context, string element_name) throws MarkupError
    {
        switch (element_name.down ())
        {
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
