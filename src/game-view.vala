// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class GameView : Gtk.Widget {
    private int x_offset;
    private int y_offset;
    private int tile_width;
    private int tile_height;
    private int tile_layer_offset_x;
    private int tile_layer_offset_y;
    private int tile_pattern_width;
    private int tile_pattern_height;

    public Rsvg.Handle? theme_handle;
    public Gdk.Texture? texture;
    public Cairo.Pattern? cairo_pattern;
    public int initial_theme_width;
    public int initial_theme_height;
    public int loaded_theme_width;
    public int loaded_theme_height;
    private bool using_cairo;
    private bool using_vector;
    private string theme;
    private double theme_aspect;
    private int rendered_theme_width;
    private int rendered_theme_height;
    private uint tick_id;

    private const int TILE_SHAKE_DURATION_MS = 250;
    private const int TILE_SHAKE_FREQUENCY = 6;
    private const int MIN_TILE_SHAKE_AMPLITUDE = 3;
    private const double TILE_SHAKE_SCALE_FACTOR = 0.04;

    private Game? _game;
    public Game? game {
        get { return _game; }
        set {
            if (tick_id != 0) {
                remove_tick_callback (tick_id);
                tick_id = 0;
            }

            _game = value;

            if (value == null)
                return;

            _game.redraw_tile.connect (redraw_tile_cb);
            _game.paused_changed.connect (paused_changed_cb);
            update_dimensions ();
            resize_theme ();
            queue_draw ();
        }
    }

    public GameView (bool using_cairo) {
        this.using_cairo = using_cairo;

        var click_controller = new Gtk.GestureClick ();
        this.add_controller (click_controller);
        click_controller.pressed.connect (click_cb);
    }

    public override void snapshot (Gtk.Snapshot snapshot) {
        if (game == null)
            return;

        update_dimensions ();
        resize_theme ();

        if (texture == null && cairo_pattern == null)
            return;

        Gsk.RenderNode? texture_node = null;

        /* Scale the tile texture */
        if (texture != null) {
            var texture_snapshot = new Gtk.Snapshot ();
            texture.snapshot (texture_snapshot, rendered_theme_width, rendered_theme_height);

            texture_node = texture_snapshot.free_to_node ();
        }

        foreach (unowned var tile in game) {
            if (!tile.visible)
                continue;

            /* Select image for this tile, or blank image if paused */
            var tile_number = game.paused ? -1 : tile.number;
            var texture_x = get_image_offset (tile_number) * tile_pattern_width;
            var texture_y = tile.highlighted ? tile_pattern_height : 0;

            /* Draw the tile */
            int tile_x, tile_y;
            get_tile_position (tile, out tile_x, out tile_y);

            if (tile.shaking)
                tile_x += tile.shake_offset;

            var tile_rect = Graphene.Rect ();
            tile_rect.init (tile_x, tile_y, tile_pattern_width, tile_pattern_height);

            snapshot.push_clip (tile_rect);

            if (texture_node != null) {
                snapshot.translate (Graphene.Point () {
                    x = tile_x - texture_x,
                    y = tile_y - texture_y
                });
                snapshot.append_node (texture_node);
            } else {
                /* Cairo fallback */
                var ctx = snapshot.append_cairo (tile_rect);
                var matrix = Cairo.Matrix.identity ();

                matrix.scale (
                    (double) loaded_theme_width / (double) rendered_theme_width,
                    (double) loaded_theme_height / (double) rendered_theme_height
                );
                matrix.translate (texture_x - tile_x, texture_y - tile_y);

                cairo_pattern.set_matrix (matrix);
                ctx.set_source (cairo_pattern);

                ctx.rectangle (tile_x, tile_y, tile_pattern_width, tile_pattern_height);
                ctx.fill ();
            }
            snapshot.pop ();
        }
    }

    public void set_theme (string? theme_path, GameView? game_view = null, string? fallback_theme_path = null) {
        this.texture = null;
        this.cairo_pattern = null;

        if (theme_path == null) {
            this.theme_handle = null;
            return;
        }

        if (game_view == null) {
            InputStream stream;
            theme_handle = new Rsvg.Handle ();
            theme_handle.set_base_uri ("resource://");

            try {
                stream = resources_open_stream (theme_path, ResourceLookupFlags.NONE);
                theme_handle.read_stream_sync (stream);
            } catch (Error e) {
                try {
                    stream = resources_open_stream (fallback_theme_path, ResourceLookupFlags.NONE);
                    theme_handle.read_stream_sync (stream);
                } catch (Error e) {
                    theme_handle = null;
                    warning ("Could not load theme %s: %s", theme_path, e.message);
                    return;
                }
            }

            double width, height;
            theme_handle.get_intrinsic_size_in_pixels (out width, out height);

            this.initial_theme_width = (int) width;
            this.initial_theme_height = (int) height;
            this.loaded_theme_width = 0;
            this.loaded_theme_height = 0;
        } else {
            this.theme_handle = game_view.theme_handle;
            this.texture = game_view.texture;
            this.cairo_pattern = game_view.cairo_pattern;
            this.initial_theme_width = game_view.initial_theme_width;
            this.initial_theme_height = game_view.initial_theme_height;
            this.loaded_theme_width = game_view.loaded_theme_width;
            this.loaded_theme_height = game_view.loaded_theme_height;
        }

        this.using_vector = theme_path.has_suffix ("postmodern");
        this.theme_aspect = ((double) this.initial_theme_height / 2) / ((double) this.initial_theme_width / 43);
        this.theme = theme_path;

        resize_theme ();
    }

    private void get_theme_size (out double width, out double height) {
        int[] scale_factors = {8, 4, 2};
        width = 0;
        height = 0;

        /* Try to scale down theme */
        foreach (var factor in scale_factors) {
            var scaled_width = initial_theme_width / factor;

            if (rendered_theme_width < scaled_width) {
                width = scaled_width;
                height = initial_theme_height / factor;
                break;
            }
        }

        /* No need to scale down, try to scale up instead */
        if (width == 0) {
            while (width < rendered_theme_width) {
                if (!using_vector && width > initial_theme_width) {
                    width = initial_theme_width;
                    height = initial_theme_height;
                    break;
                }
                width += initial_theme_width;
                height += initial_theme_height;
            }
        }

        /* Finally. apply system scale factor for HiDPI support */
        var scale = get_native ().get_surface ().get_scale ();
        width *= scale;
        height *= scale;
    }

    private void resize_theme () {
        if (game == null || theme == null)
            return;

        if (rendered_theme_width == 0)
            return;

        /* Get size to load the next tile texture at */
        double new_exact_theme_width, new_exact_theme_height;
        get_theme_size (out new_exact_theme_width, out new_exact_theme_height);

        var new_theme_width = (int) new_exact_theme_width;
        var new_theme_height = (int) new_exact_theme_height;

        /* If texture size didn't change, avoid unnecessary work */
        if (new_theme_width == loaded_theme_width)
            return;

        /* Load texture at new size */
        this.loaded_theme_width = new_theme_width;
        this.loaded_theme_height = new_theme_height;

        try {
            var theme_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, new_theme_width, new_theme_height);
            var context = new Cairo.Context (theme_surface);
            var rect = Rsvg.Rectangle () {
                x = 0,
                y = 0,
                width = new_exact_theme_width,
                height = new_exact_theme_height
            };
            theme_handle.render_document (context, rect);

            if (using_cairo) {
                this.cairo_pattern = new Cairo.Pattern.for_surface (theme_surface);
                this.cairo_pattern.set_filter (Cairo.Filter.BILINEAR);  // Faster scaling than default
            } else {
                unowned var data = theme_surface.get_data ();
                var rowstride = new_theme_width * 4;
                var format = (BYTE_ORDER == ByteOrder.LITTLE_ENDIAN)
                    ? Gdk.MemoryFormat.B8G8R8A8_PREMULTIPLIED
                    : Gdk.MemoryFormat.A8R8G8B8_PREMULTIPLIED;

                data.length = new_theme_height * rowstride;
                var new_texture = new Gdk.MemoryTexture (
                    new_theme_width,
                    new_theme_height,
                    format,
                    new Bytes.take (data),
                    rowstride
                );
                this.texture = new_texture;
            }
            queue_draw ();
        } catch (Error e) {
            warning ("Could not load theme %s: %s", theme, e.message);
        }
    }

    private void update_dimensions () {
        if (theme == null)
            return;

        var width = get_width ();
        var height = get_height ();

        /* Shrink border width at smaller window size (mobile screens) */
        var h_border = (float) width / 220;
        var v_border = (float) height / 560;
        var map_width = game.map.width + (game.map.h_overhang / 4) + h_border;
        var map_height = (game.map.height + (game.map.v_overhang / 4) + v_border) * theme_aspect;

        /* Scale the map to fit */
        var unit_width = (int) double.min (width / map_width, height / map_height);
        var unit_height = (int) (unit_width * theme_aspect);

        /* The size of one tile is two units wide, and the correct aspect ratio */
        tile_width = unit_width * 2;
        tile_height = unit_height * 2;

        /* Offset the tiles when on a higher layer (themes must use these hard-coded ratios) */
        tile_layer_offset_x = tile_width / 7;
        tile_layer_offset_y = tile_height / 10;

        /* Center the map */
        x_offset = (int) (width - ((game.map.width + (game.map.h_overhang / 4)) * unit_width)) / 2;
        y_offset = (int) (height - ((game.map.height * unit_height) - ((game.map.v_overhang * unit_height) / 8))) / 2;

        /* The images are bigger than the tile as they contain the isometric extension in the z-axis */
        tile_pattern_width = tile_width + tile_layer_offset_x;
        tile_pattern_height = tile_height + tile_layer_offset_y;

        /* Store the exact width the theme should be rendered at */
        rendered_theme_width = tile_pattern_width * 43;
        rendered_theme_height = tile_pattern_height * 2;
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
        if (!tile.shaking) {
            queue_draw ();
            return;
        }

        if (tick_id != 0)
            return;

        tick_id = add_tick_callback ((widget, frame_clock) => {
            bool animating = false;

            foreach (var t in game) {
                if (!t.shaking)
                    continue;

                var elapsed_ms = (frame_clock.get_frame_time () - t.shake_start_time) / 1000;
                var elapsed_s = elapsed_ms / 1000;

                if (elapsed_ms > TILE_SHAKE_DURATION_MS) {
                    t.shaking = false;
                    t.shake_offset = 0;
                    t.shake_start_time = 0.0;
                    continue;
                }

                var amplitude = Math.fmax (MIN_TILE_SHAKE_AMPLITUDE, tile_width * TILE_SHAKE_SCALE_FACTOR);
                t.shake_offset = (int) (amplitude * Math.sin (2 * Math.PI * TILE_SHAKE_FREQUENCY * elapsed_s));
                animating = true;
            }

            if (!animating)
                tick_id = 0;

            queue_draw ();
            return animating;
        });
    }

    private void paused_changed_cb () {
        queue_draw ();
    }

    private void click_cb (Gtk.GestureClick _controller, int n_press, double event_x, double event_y) {
        if (game == null)
            return;

        var click_blocked = game.inspecting || !game.attempt_move () || game.paused;

        if (click_blocked)
            return;

        /* Get the tile under the square */
        var tile = find_tile ((int) event_x, (int) event_y);

        if (n_press == 2 && tile == null && game.all_tiles_unblocked) {
            game.autoplay_end_game ();
        }

        /* If not a valid tile then ignore the event */
        if (tile == null)
            return;

        /* Shake unselectable tile */
        if (!tile.selectable) {
            var start_time = get_frame_clock ().get_frame_time ();
            game.shake_tile (tile, start_time);
            return;
        }

        /* Select first tile */
        if (game.selected_tile == null) {
            game.selected_tile = tile;
        }
        /* Unselect tile by clicking on it again */
        else if (tile == game.selected_tile) {
            game.selected_tile = null;
        }
        /* Attempt to match second tile to the selected one */
        else if (tile.matches (game.selected_tile)) {
            game.remove_pair (game.selected_tile, tile);
        }
        else {
            game.selected_tile = tile;
        }

        queue_draw ();
    }

    private Tile? find_tile (int x, int y) {
        unowned Tile? topmost_tile = null;
        var previous_layer = -1;

        foreach (unowned var tile in game) {
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
