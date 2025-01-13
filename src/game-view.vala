/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class GameView : Gtk.DrawingArea {
    private int x_offset;
    private int y_offset;
    private int tile_width;
    private int tile_height;
    private int tile_layer_offset_x;
    private int tile_layer_offset_y;
    private int tile_pattern_width;
    private int tile_pattern_height;

    private Cairo.Pattern? tile_pattern = null;
    private double theme_aspect;
    private int initial_theme_width;
    private int initial_theme_height;
    private int loaded_theme_width;
    private int loaded_theme_height;

    private Game? _game;
    public Game? game {
        get { return _game; }
        set {
            _game = value;
            _game.redraw_tile.connect (redraw_tile_cb);
            _game.paused_changed.connect (paused_changed_cb);
            update_dimensions ();
            resize_theme ();
            queue_draw ();
        }
    }

    private string? _theme = null;
    public string? theme {
        get { return _theme; }
        set {
            Gdk.Pixbuf? pixbuf = null;
            try {
                pixbuf = new Gdk.Pixbuf.from_resource (value);
            } catch (Error e) {
                warning ("Could not load theme %s: %s", value, e.message);
                return;
            }

            initial_theme_width = pixbuf.width;
            initial_theme_height = pixbuf.height;
            loaded_theme_width = 0;
            loaded_theme_height = 0;
            theme_aspect = ((double) initial_theme_height / 2) / ((double) initial_theme_width / 43);
            _theme = value;

            resize_theme ();
            queue_draw ();
        }
    }

    construct {
        set_draw_func (draw_func);

        var click_controller = new Gtk.GestureClick ();
        this.add_controller (click_controller);
        click_controller.pressed.connect (click_cb);
    }

    public override void size_allocate (int width, int height, int baseline) {
        update_dimensions ();
        resize_theme ();
    }

    private void resize_theme () {
        var rendered_theme_width = (tile_width + tile_layer_offset_x) * 43;
        var new_theme_width = 0;
        var new_theme_height = 0;

        if (rendered_theme_width > 0) {
            while (new_theme_width < rendered_theme_width) {
                new_theme_width += initial_theme_width;
                new_theme_height += initial_theme_height;
            }
        }

        if (new_theme_width == loaded_theme_width)
            return;

        loaded_theme_width = new_theme_width;
        loaded_theme_height = new_theme_height;

        try {
            var pixbuf = new Gdk.Pixbuf.from_resource_at_scale (theme, new_theme_width, new_theme_height, false);
            var bytes = new Bytes.take (pixbuf.get_pixels_with_length ());
            var theme_texture = new Gdk.MemoryTexture (
                new_theme_width,
                new_theme_height,
                Gdk.MemoryFormat.R8G8B8A8,
                bytes,
                pixbuf.rowstride
            );

            var theme_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, new_theme_width, new_theme_height);
            theme_texture.download (theme_surface.get_data (), theme_surface.get_stride ());
            theme_surface.mark_dirty ();

            tile_pattern = new Cairo.Pattern.for_surface (theme_surface);
            queue_draw ();
        } catch (Error e) {
            warning ("Could not load theme %s: %s", theme, e.message);
        }
    }

    private void draw_game (Cairo.Context cr) {
        if (theme == null)
            return;

        var width_scale = (double)loaded_theme_width / ((double)tile_pattern_width * 43);
        var height_scale = (double)loaded_theme_height / ((double)tile_pattern_height * 2);

        foreach (var tile in game.tiles) {
            if (!tile.visible)
                continue;

            /* Select image for this tile, or blank image if paused */
            var tile_number = game.paused ? -1 : tile.number;
            int texture_x = get_image_offset (tile_number) * tile_pattern_width;
            int texture_y = 0;

            if (!game.paused) {
                if ((tile == game.selected_tile) ||
                    (game.hint_blink_counter % 2 == 1 && (tile == game.hint_tiles[0] || tile == game.hint_tiles[1])))
                    texture_y = tile_pattern_height;
            }

            /* Draw the tile */
            int tile_x, tile_y;
            get_tile_position (tile, out tile_x, out tile_y);
            var matrix = Cairo.Matrix.identity ();

            matrix.scale (width_scale, height_scale);
            matrix.translate (texture_x - tile_x, texture_y - tile_y);

            tile_pattern.set_matrix (matrix);
            cr.set_source (tile_pattern);

            cr.rectangle (tile_x, tile_y, tile_pattern_width, tile_pattern_height);
            cr.fill ();
        }
    }

    private void update_dimensions () {
        if (theme == null)
            return;

        var width = get_width ();
        var height = get_height ();

        /* Need enough space for the whole map and one unit border */
        var map_width = game.map.width + 2;
        var map_height = (int) ((game.map.height + 2) * theme_aspect);

        /* Scale the map to fit */
        var unit_width = int.min (width / map_width, height / map_height);
        var unit_height = (int) (unit_width * theme_aspect);

        /* The size of one tile is two units wide, and the correct aspect ratio */
        tile_width = unit_width * 2;
        tile_height = unit_height * 2;

        /* Offset the tiles when on a higher layer (themes must use these hard-coded ratios) */
        tile_layer_offset_x = tile_width / 7;
        tile_layer_offset_y = tile_height / 10;

        /* Center the map */
        x_offset = (width - game.map.width * unit_width) / 2;
        y_offset = (height - game.map.height * unit_height) / 2;

        /* The images are bigger than the tile as they contain the isometric extension in the z-axis */
        tile_pattern_width = tile_width + tile_layer_offset_x;
        tile_pattern_height = tile_height + tile_layer_offset_y;
    }

    private void get_tile_position (Tile tile, out int x, out int y) {
        x = x_offset + tile.slot.x * tile_width / 2 + tile.slot.layer * tile_layer_offset_x;
        y = y_offset + tile.slot.y * tile_height / 2 - tile.slot.layer * tile_layer_offset_y;
    }

    private int get_image_offset (int number) {
        var set = number / 4;

        /* Invalid numbers use the blank tile */
        if (number < 0 || set >= 36)
            return 42;

        /* The bonus tiles have different images for each */
        if (set == 33)
            return 33 + number % 4;
        if (set == 35)
            return 38 + number % 4;

        /* The white dragons are in-between the bonus tiles just to be confusing */
        if (set == 34)
            return 37;

        /* Everything else is in set order */
        return set;
    }

    private void redraw_tile_cb (Tile tile) {
        update_dimensions ();
        queue_draw ();
    }

    private void paused_changed_cb () {
        queue_draw ();
    }

    public void draw_func (Gtk.DrawingArea area, Cairo.Context cr, int width, int height) {
        if (game == null)
            return;

        draw_game (cr);
    }

    private void click_cb (Gtk.GestureClick _controller, int n_press, double event_x, double event_y) {
        if (game == null || game.paused)
            return;

        /* Get the tile under the square */
        var tile = find_tile ((int) event_x, (int) event_y);

        /* If not a valid tile then ignore the event */
        if (tile == null || !game.tile_can_move (tile))
            return;

        /* Select first tile */
        if (game.selected_tile == null) {
            game.selected_tile = tile;
        }
        /* Unselect tile by clicking on it again */
        else if (tile == game.selected_tile) {
            game.selected_tile = null;
        }
        /* Attempt to match second tile to the selected one */
        else if (game.selected_tile.matches (tile)) {
            game.remove_pair (game.selected_tile, tile);
        }
        else {
            game.selected_tile = tile;
        }

        queue_draw ();
    }

    private Tile? find_tile (int x, int y) {
        Tile topmost_tile = null;
        var previous_layer = -1;

        foreach (var tile in game.tiles) {
            if (!tile.visible)
                continue;

            int tile_x, tile_y;
            get_tile_position (tile, out tile_x, out tile_y);

            if (tile.slot.layer > previous_layer
                    && tile_x <= x <= (tile_x + tile_pattern_width)
                    && tile_y <= y <= (tile_y + tile_pattern_height))
                topmost_tile = tile;
        }
        return topmost_tile;
    }
}
