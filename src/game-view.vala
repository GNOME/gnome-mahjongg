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

    private uint   theme_resize_timer;
    private uint   theme_timer_id;

    private Gtk.GestureClick click_controller;     // for keeping in memory

    private Game? _game;
    public Game? game
    {
        get { return _game; }
        set
        {
            _game = value;
            _game.redraw_tile.connect (redraw_tile_cb);
            _game.paused_changed.connect (paused_changed_cb);
            update_dimensions ();
            resize_theme ();
            queue_draw ();
        }
    }

    private string? _theme = null;
    public string? theme
    {
        get { return _theme; }
        set {
            Gdk.Texture texture = null;
            theme_handle = null;
            tile_pattern = null;

            try {
                theme_handle = new Rsvg.Handle.from_file (value);

                double width, height;
                theme_handle.get_intrinsic_size_in_pixels (out width, out height);

                theme_width = (int)width;
                theme_height = (int)height;
            } catch (Error e) {
                try {
                    texture = Gdk.Texture.from_filename (value);
                    theme_width = texture.width;
                    theme_height = texture.height;
                } catch (Error e) {
                    warning ("Could not load theme %s: %s", value, e.message);
                    return;
                }
            }

            theme_aspect = ((double) theme_height / 2) / ((double) theme_width / 43);
            update_dimensions ();

            if (texture != null) {
                var theme_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, theme_width, theme_height);
                texture.download (theme_surface.get_data (),
                                  theme_surface.get_stride ());
                theme_surface.mark_dirty ();
                tile_pattern = new Cairo.Pattern.for_surface (theme_surface);
            }

            resize_theme ();
            queue_draw ();
            _theme = value;
        }
    }

    construct
    {
        can_focus = true;
        theme_timer_id = 0;
        init_mouse ();
        set_draw_func (draw_func);
    }

    public override void size_allocate (int width, int height, int baseline)
    {
        update_dimensions ();

        /* Resize the rsvg theme lazily after 300ms of the last resize event */
        if (theme_timer_id != 0) {
            Source.remove (theme_timer_id);
            theme_timer_id = 0;
        }

        if (theme_handle != null) {
            theme_resize_timer = 2;
            theme_timer_id = Timeout.add (100, () => {
                if (theme_resize_timer == 0) {
                    resize_theme ();
                    theme_timer_id = 0;
                    return false;
                }

                theme_resize_timer--;
                return true;
            });
        }
    }

    private void resize_theme ()
    {
        if (theme_handle == null)
            return;

        var rendered_theme_width = (tile_width + tile_layer_offset_x) * 43;

        if (theme_width >= rendered_theme_width) {
            double width, height;
            theme_handle.get_intrinsic_size_in_pixels (out width, out height);
            theme_width = (int) width;
            theme_height = (int) height;
        }


        while (theme_width < rendered_theme_width) {
            theme_width += theme_width;
            theme_height += theme_height;
        }

        var theme_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, theme_width, theme_height);
        var ctx = new Cairo.Context (theme_surface);

        try {
            theme_handle.render_document(ctx, {0,0,theme_width,theme_height});
            tile_pattern = new Cairo.Pattern.for_surface (theme_surface);
            queue_draw();
        } catch (Error e) {
            warning ("Could not upscale theme");
        }
    }

    private void draw_game (Cairo.Context cr, bool render_indexes = false)
    {
        if (theme == null)
            return;

        /* The images are bigger than the tile as they contain the isometric extension in the z-axis */
        tile_pattern_width = tile_width + tile_layer_offset_x;
        tile_pattern_height = tile_height + tile_layer_offset_y;

        foreach (var tile in game.tiles)
        {
            if (!tile.visible)
                continue;

            int x, y;
            get_tile_position (tile, out x, out y);

            if (render_indexes)
                cr.set_source_rgb (tile.number / 255.0, tile.number / 255.0, tile.number / 255.0);
            else
            {
                double width_scale = (double)theme_width / ((double)tile_pattern_width * 43.0);
                double height_scale = (double)theme_height / ((double)tile_pattern_height * 2);

                var tile_number = game.paused ? -1 : tile.number;

                /* Select image for this tile, or blank image if paused */
                double texture_x = (double)get_image_offset (tile_number) * tile_pattern_width;
                double texture_y = 0;

                if (!game.paused) {
                    if ((tile == game.selected_tile) ||
                        (game.hint_blink_counter % 2 == 1 && (tile == game.hint_tiles[0] || tile == game.hint_tiles[1])))
                        texture_y = tile_pattern_height;
                }

                var matrix = Cairo.Matrix.identity ();

                matrix.scale(width_scale, height_scale);
                matrix.translate (texture_x - x, texture_y - y);

                tile_pattern.set_matrix (matrix);
                cr.set_source (tile_pattern);
            }
            cr.rectangle (x, y, tile_pattern_width, tile_pattern_height);
            cr.fill ();
        }
    }

    private void update_dimensions ()
    {
        if (theme == null)
            return;

        var width = get_width ();
        var height = get_height ();

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
        queue_draw ();
    }

    private void paused_changed_cb ()
    {
        queue_draw ();
    }

    public void draw_func (Gtk.DrawingArea area, Cairo.Context cr, int width, int height)
    {
        if (game == null)
            return;

        draw_game (cr);
    }

    private inline void init_mouse ()
    {
        click_controller = new Gtk.GestureClick ();    // only reacts to Gdk.BUTTON_PRIMARY
        this.add_controller (click_controller);
        click_controller.pressed.connect (on_click);
    }

    private inline void on_click (Gtk.GestureClick _click_controller, int n_press, double event_x, double event_y)
    {
        if (game == null || game.paused)
            return;

        /* Get the tile under the square */
        var tile = find_tile (event_x, event_y);

        /* If not a valid tile then ignore the event */
        if (tile == null || !game.tile_can_move (tile))
            return;

        /* Select first tile */
        if (game.selected_tile == null)
        {
            game.selected_tile = tile;
        }

        /* Unselect tile by clicking on it again */
        else if (tile == game.selected_tile)
        {
            game.selected_tile = null;
        }

        /* Attempt to match second tile to the selected one */
        else if (game.selected_tile.matches (tile))
        {
            game.remove_pair (game.selected_tile, tile);
        }
        else
        {
            game.selected_tile = tile;
        }

        queue_draw();
    }

    private Tile? find_tile (double x, double y)
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
