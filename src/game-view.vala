/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class GameView : Gtk.DrawingArea
{
    public Gdk.RGBA background_color;

    private int tile_pattern_width = 0;
    private int tile_pattern_height = 0;


    private int    x_offset;
    private int    y_offset;
    private int    tile_width;
    private int    tile_height;
    private int    tile_layer_offset_x;
    private int    tile_layer_offset_y;

    private int    theme_width;
    private int    theme_height;
    private double theme_aspect;
    private Rsvg.Handle? theme_handle = null;
    private Cairo.Pattern? tile_pattern = null;

    private Game? _game;
    public Game? game
    {
        get { return _game; }
        set
        {
            _game = value;
            _game.redraw_tile.connect (redraw_tile_cb);
            _game.paused_changed.connect (paused_changed_cb);
            queue_draw ();
        }
    }

    private string? _theme = null;
    public string? theme
    {
        get { return _theme; }
        set {
            _theme = value;
            try {
                theme_handle = new Rsvg.Handle.from_file (value);
                theme_width  = theme_handle.width;
                theme_height  = theme_handle.height;
            } catch (Error e) {
                theme_handle = null;
                Gdk.Pixbuf.get_file_info (theme, out theme_width, out theme_height);
            }
            theme_aspect = ((double) theme_height / 2) / ((double) theme_width / 43);
            update_dimensions ();
            tile_pattern = null;
            queue_draw ();
        }
    }

    public void build_pattern () {
        if (theme_handle == null)
            return;  // Only rebuild if SVG

        /* We want to check if the existing pattern is large enough
         * for the current widget size */
        var a_width = get_allocated_width();

        if (tile_pattern != null && theme_handle != null) {
            Cairo.Surface? surface;
            tile_pattern.get_surface(out surface);

            if (surface != null) {
                var w = ((Cairo.ImageSurface)surface).get_width();
            }
        }
    }

    public GameView ()
    {
        can_focus = true;
        add_events (Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK);
        size_allocate.connect(() => {
            update_dimensions ();
        });
    }

    public void set_background (string? colour)
    {
        background_color = Gdk.RGBA ();
        if (colour == null || !background_color.parse (colour))
            background_color.red = background_color.green = background_color.blue = 0;
        queue_draw ();
    }

    private void draw_game (Cairo.Context cr, bool render_indexes = false)
    {
        if (theme == null)
            return;

        /* The images are bigger than the tile as they contain the isometric extension in the z-axis */
        var image_width = tile_width + tile_layer_offset_x;
        var image_height = tile_height + tile_layer_offset_y;

        /* Render the tiles */
        if (!render_indexes && (tile_pattern == null || tile_pattern_width != image_width || tile_pattern_height != image_height))
        {
            tile_pattern_width = image_width;
            tile_pattern_height = image_height;

            var width = image_width * 43;
            var height = image_height * 2;

            var surface = new Cairo.Surface.similar (cr.get_target (), Cairo.Content.COLOR_ALPHA, width, height);
            var c = new Cairo.Context (surface);
            load_theme (c, width, height);
            tile_pattern = new Cairo.Pattern.for_surface (surface);
        }

        /* This works because of the way the tiles are sorted. We could
         * reverse them to make this look a little nicer, but when searching
         * for a tile we want it the other way around. */

        foreach (var tile in game.tiles)
        {
            if (!tile.visible)
                continue;

            int x, y;
            get_tile_position (tile, out x, out y);

            /* Select image for this tile, or blank image if paused */
            var texture_x = get_image_offset (tile.number) * image_width;
            var texture_y = 0;
            if (game.paused)
            {
                texture_x = get_image_offset (-1) * image_width;
                texture_y = 0;
            }
            else if (tile == game.selected_tile)
                texture_y = image_height;
            else if (game.hint_blink_counter % 2 == 1 && (tile == game.hint_tiles[0] || tile == game.hint_tiles[1]))
                texture_y = image_height;

            if (render_indexes)
                cr.set_source_rgb (tile.number / 255.0, tile.number / 255.0, tile.number / 255.0);
            else
            {
                var matrix = Cairo.Matrix.identity ();
                matrix.translate (texture_x - x, texture_y - y);
                tile_pattern.set_matrix (matrix);
                cr.set_source (tile_pattern);
            }
            cr.rectangle (x, y, image_width, image_height);
            cr.fill ();
        }

        /* Draw pause overlay */
        if (game.paused)
        {
            cr.set_source_rgba (0, 0, 0, 0.75);
            cr.paint ();

            cr.select_font_face ("Sans", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
            cr.set_font_size (get_allocated_width () * 0.125);

            var text = _("Paused");
            Cairo.TextExtents extents;
            cr.text_extents (text, out extents);
            cr.move_to ((get_allocated_width () - extents.width) / 2.0, (get_allocated_height () + extents.height) / 2.0);
            cr.set_source_rgb (1, 1, 1);
            cr.show_text (text);
        }
    }

    private void load_theme (Cairo.Context c, int width, int height)
    {
        if (theme_handle != null) {
            var m = Cairo.Matrix.identity ();
            m.scale ((double) width / theme_handle.width, (double) height / theme_handle.height);
            c.set_matrix (m);
            theme_handle.render_cairo (c);
            return;
        } else {
            var p = new Gdk.Pixbuf.from_file_at_scale (theme, width, height, false);
            Gdk.cairo_set_source_pixbuf (c, p, 0, 0);
            c.paint ();
            return;
        }
        warning ("Failed to load theme %s", theme);
    }

    private void update_dimensions ()
    {
        if (theme == null)
            return;

        var width = get_allocated_width ();
        var height = get_allocated_height ();

        /* Need enough space for the whole map and one unit border */
        var map_width = game.map.width + 2.0;
        var map_height = (game.map.height + 2.0) * theme_aspect;

        /* Scale the map to fit */
        var unit_width = double.min (width / map_width, height / map_height);
        var unit_height = unit_width * theme_aspect;

        /* The size of one tile is two units wide, and the correct aspect ratio */
        tile_width = (int) (unit_width * 2);
        tile_height = (int) (unit_height * 2);

        /* Offset the tiles when on a higher layer (themes must use these hard-coded ratios) */
        tile_layer_offset_x = tile_width / 7;
        tile_layer_offset_y = tile_height / 10;

        /* Center the map */
        x_offset = (int) (width - game.map.width * unit_width) / 2;
        y_offset = (int) (height - game.map.height * unit_height) / 2;
    }

    private void get_tile_position (Tile tile, out int x, out int y)
    {
        x = x_offset + tile.slot.x * tile_width / 2 + tile.slot.layer * tile_layer_offset_x;
        y = y_offset + tile.slot.y * tile_height / 2 - tile.slot.layer * tile_layer_offset_y;
    }

    private int get_image_offset (int number)
    {
        var set = number / 4;

        /* Invalid numbers use the blank tile */
        if (number < 0 || set >= 36)
            return 42;

        /* The bonus tiles have different images for each */
        if (set == 33)
            return 33 + number % 4;
        if (set == 35)
            return 38 + number % 4;
        /* The white dragons are inbetween the bonus tiles just to be confusing */
        if (set == 34)
            return 37;

        /* Everything else is in set order */
        return set;
    }

    private void redraw_tile_cb (Tile tile)
    {
        update_dimensions ();
        int x, y;
        get_tile_position (tile, out x, out y);
        queue_draw_area (x, y, tile_pattern_width, tile_pattern_height);
    }

    private void paused_changed_cb ()
    {
        queue_draw ();
    }

    public override bool draw (Cairo.Context cr)
    {
        if (game == null)
            return false;

        Gdk.cairo_set_source_rgba (cr, background_color);
        cr.paint ();
        draw_game (cr);

        return true;
    }

    public override bool button_press_event (Gdk.EventButton event)
    {
        if (game == null || game.paused)
            return false;

        /* Ignore the 2BUTTON and 3BUTTON events. */
        if (event.type != Gdk.EventType.BUTTON_PRESS)
            return false;

        /* Get the tile under the square */
        var tile = find_tile ((uint) event.x, (uint) event.y);

        /* If not a valid tile then ignore the event */
        if (tile == null || !game.tile_can_move (tile))
            return true;

        if (event.button == 1)
        {
            /* Select first tile */
            if (game.selected_tile == null)
            {
                game.selected_tile = tile;
                return true;
            }

            /* Unselect tile by clicking on it again */
            if (tile == game.selected_tile)
            {
                game.selected_tile = null;
                return true;
            }

            /* Attempt to match second tile to the selected one */
            if (game.selected_tile.matches (tile))
            {
                game.remove_pair (game.selected_tile, tile);
                return true;
            }
            else
            {
                game.selected_tile = tile;
                return true;
            }
        }

        return false;
    }

    private Tile? find_tile (uint x, uint y)
    {
        /* Render a 1x1 image where the cursor is using a different color for each tile */
        var surface = new Cairo.ImageSurface (Cairo.Format.RGB24, 1, 1);
        var cr = new Cairo.Context (surface);
        cr.set_source_rgba (255, 255, 255, 255);
        cr.paint ();
        cr.translate (-x, -y);
        draw_game (cr, true);

        /* The color value is the tile under the cursor */
        unowned uchar[] data = surface.get_data ();
        var number = data[0];
        foreach (var tile in game.tiles)
            if (tile.number == number)
                return tile;

        return null;
    }
}
