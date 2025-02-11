// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class Tile {
    public int number = -1;
    public int pair = -1;
    public bool visible = true;
    public int move_number;
    public Slot slot;
    public List<Tile> left;
    public List<Tile> right;
    public List<Tile> above;

    public Tile (Slot slot) {
        this.slot = slot;
    }
}

public static bool tiles_match (Tile a, Tile b) {
    return a.pair == b.pair;
}

private static int compare_tiles (Tile a, Tile b) {
    return compare_slots (a.slot, b.slot);
}

private static bool switch_tiles (Tile a, Tile b) {
    if (!a.visible || !b.visible)
        return false;

    var number = a.number;
    var pair = a.pair;
    a.number = b.number;
    b.number = number;
    a.pair = b.pair;
    b.pair = pair;
    return true;
}

public class Match {
    public Tile tile0;
    public Tile tile1;

    public Match (Tile tile0, Tile tile1) {
        this.tile0 = tile0;
        this.tile1 = tile1;
    }
}

public class Game {
    public Map map;
    public List<Tile> tiles;

    private int move_number;

    private Tile? hint_tiles[2];
    private uint hint_timeout;
    private uint hint_blink_counter;

    private double clock_elapsed;
    private Timer? clock;
    private uint clock_timeout;

    public signal bool attempt_move ();
    public signal void redraw_tile (Tile tile);
    public signal void moved ();
    public signal void paused_changed ();
    public signal void tick ();

    public bool started {
        get { return clock != null; }
    }

    public double elapsed {
        get {
            if (clock == null)
                return 0.0;
            return clock_elapsed + clock.elapsed ();
        }
    }

    private bool _paused;
    public bool paused {
        set {
            _paused = value;
            if (clock != null) {
                if (value)
                    stop_clock ();
                else
                    continue_clock ();
            }
            selected_tile = null;
            reset_hint ();
            paused_changed ();
        }
        get { return _paused; }
    }

    private Tile? _selected_tile;
    public Tile? selected_tile {
        get { return _selected_tile; }
        set {
            if (_selected_tile != null)
                redraw_tile (_selected_tile);
            _selected_tile = value;
            if (value != null)
                redraw_tile (value);
        }
    }

    public uint moves_left {
        get { return find_matches ().length; }
    }

    public bool complete {
        get {
            foreach (unowned var tile in tiles)
                if (tile.visible)
                    return false;
            return true;
        }
    }

    public bool can_move {
        get { return moves_left != 0; }
    }

    public bool can_shuffle {
        get {
            var num_selectable_tiles = 0;
            foreach (unowned var tile in tiles) {
                if (tile_is_selectable (tile)) {
                    num_selectable_tiles++;
                    if (num_selectable_tiles == 2)
                        return true;
                }
            }
            return false;
        }
    }

    public bool can_undo {
        get { return move_number > 1; }
    }

    public bool can_redo {
        get {
            foreach (unowned var tile in tiles)
                if (tile.move_number >= move_number)
                    return true;
            return false;
        }
    }

    public Game (Map map) {
        this.map = map;

        /* Create blank tiles in the locations required in the map */
        create_tiles ();

        /* Start with a board consisting of visible blank tiles. Walk through all
         * tiles, choosing and removing tile pairs until we have a solvable board.
         *
         * Check all possible tile matches for visible/remaining tiles. Choose a
         * random match, hide/remove both tiles, and repeat the process. If we
         * reach an unsolvable state, undo the previous move and try the next match.
         *
         * Once we have a path to victory, assign random tile faces to all pairs.
         */
        generate_game ();

        /* The algorithm has "finished" the game. Make all tiles visible again for
         * the player. */
        reset ();
    }

    public void destroy_timers () {
        remove_hint_timeout ();
        stop_clock ();
    }

    public bool tile_is_highlighted (Tile tile) {
        if (tile == selected_tile)
            return true;

        if (hint_blink_counter % 2 == 0)
            return false;

        return tile == hint_tiles[0] || tile == hint_tiles[1];
    }

    public bool tile_is_selectable (Tile tile) {
        if (!tile.visible)
            return false;

        var left_blocked = false;
        var right_blocked = false;

        foreach (unowned var t in tile.left)
            if (t.visible) {
                left_blocked = true;
                break;
            }

        foreach (unowned var t in tile.right)
            if (t.visible) {
                right_blocked = true;
                break;
            }

        if (left_blocked && right_blocked)
            return false;

        foreach (unowned var t in tile.above)
            if (t.visible)
                return false;

        return true;
    }

    public bool remove_pair (Tile tile0, Tile tile1) {
        if (!tile0.visible || !tile1.visible)
            return false;

        if (!tiles_match (tile0, tile1))
            return false;

        selected_tile = null;
        reset_hint ();

        /* You lose your re-do queue when you make a move */
        foreach (unowned var tile in tiles)
            if (tile.move_number >= move_number)
                tile.move_number = 0;

        tile0.visible = false;
        tile0.move_number = move_number;
        tile1.visible = false;
        tile1.move_number = move_number;

        move_number++;

        redraw_tile (tile0);
        redraw_tile (tile1);

        if (complete)
            stop_clock ();
        else
            start_clock ();

        moved ();
        return true;
    }

    public void shuffle_remaining () {
        if (!can_shuffle)
            return;

        /* Reset moves and move numbers */
        move_number = 1;
        foreach (unowned var tile in tiles)
            tile.move_number = 0;

        /* Fisher Yates Shuffle */
        var n = tiles.length ();
        do {
            for (var i = n - 1; i > 0; i--) {
                var j = Random.int_range (0, (int) i + 1);
                switch_tiles (tiles.nth_data (j), tiles.nth_data (i));
            }
        } while (!can_move);

        moved ();
        redraw_all_tiles ();

        /* 60s penalty */
        start_clock ();
        clock_elapsed += 60.0;
        tick ();
    }

    public void undo () {
        if (!can_undo)
            return;

        selected_tile = null;
        reset_hint ();

        /* Re-show tiles that were removed */
        move_number--;
        foreach (unowned var tile in tiles) {
            if (tile.move_number == move_number) {
                tile.visible = true;
                redraw_tile (tile);
            }
        }
    }

    public void redo () {
        if (!can_redo)
            return;

        selected_tile = null;
        reset_hint ();

        foreach (unowned var tile in tiles) {
            if (tile.move_number == move_number) {
                tile.visible = false;
                redraw_tile (tile);
            }
        }
        move_number++;
        moved ();
    }

    public void show_hint () {
        var matches = find_matches_for_tile (selected_tile);

        /* No match, find any random match as if nothing was selected */
        if (matches.length == 0)
            matches = find_matches ();

        var n = Random.int_range (0, (int) matches.length);
        unowned var match = matches[n];
        set_hint (match.tile0, match.tile1);
    }

    public void reset () {
        reset_clock ();
        move_number = 1;
        selected_tile = null;
        reset_hint ();
        foreach (unowned var tile in tiles) {
            tile.visible = true;
            tile.move_number = 0;
        }
        redraw_all_tiles ();
    }

    private void generate_game () {
        var n_pairs = (int) tiles.length () / 2;
        var tile_numbers = new int[n_pairs];

        /* Create tile numbers */
        for (var i = 0; i < n_pairs; i++)
            tile_numbers[i] = i * 2;

        /* Shuffle tile numbers */
        for (var i = 0; i < n_pairs; i++) {
            var n = Random.int_range (i, n_pairs);
            var tile_number = tile_numbers[i];
            tile_numbers[i] = tile_numbers[n];
            tile_numbers[n] = tile_number;
        }

        /* Choose tile pairs until we have a solvable board */
        choose_tile_pairs (tile_numbers);
        move_number = 1;
    }

    private void create_tiles (Map map) {
        foreach (unowned var slot in map.slots)
            tiles.insert_sorted (new Tile (slot), compare_tiles);

        foreach (unowned var tile in tiles) {
            unowned var slot = tile.slot;
            var x = slot.x;
            var y_above = slot.y - 1;
            var y_bottom_half = slot.y + 1;
            var layer = slot.layer;

            foreach (unowned var t in tiles) {
                if (t == tile)
                    continue;

                unowned var s = t.slot;
                var s_y = s.y;

                if (s_y < y_above || s_y > y_bottom_half)
                    continue;

                var s_layer = s.layer;

                /* Can't move if blocked both on the left and the right */
                if (s_layer == layer) {
                    var s_x = s.x;

                    if (s_x == x - 2)
                        tile.left.prepend (t);
                    if (s_x == x + 2)
                        tile.right.prepend (t);

                /* Can't move if blocked by a tile above */
                } else if (s_layer > layer) {
                    var s_x = s.x;

                    if (s_x >= x - 1 && s_x <= x + 1)
                        tile.above.prepend (t);
                }
            }
        }
    }

    private bool choose_tile_pairs (int[] tile_numbers, int depth = 0) {
        /* All tile pairs chosen */
        if (depth == tiles.length () / 2)
            return true;

        var matches = find_matches ();
        var n_matches = matches.length;

        /* No matches on this branch, rewind */
        if (n_matches == 0)
            return false;

        var n = Random.int_range (0, (int) n_matches);
        for (var i = 0; i < n_matches; i++) {
            var number = tile_numbers[depth];
            unowned var match = matches[(n + i) % n_matches];
            unowned var tile0 = match.tile0;
            unowned var tile1 = match.tile1;

            tile0.visible = false;
            tile1.visible = false;

            if (choose_tile_pairs (tile_numbers, depth + 1)) {
                /* Assign tile face for pair */
                tile0.number = number;
                tile1.number = number + 1;
                tile0.pair = tile1.pair = number / 4;
                return true;
            }

            /* Unsolvable state, undo move and try the next match */
            tile0.visible = true;
            tile1.visible = true;
        }
        return false;
    }

    private Match[] find_matches () {
        Match[] matches = null;
        Tile[] processed_tiles = null;

        foreach (unowned var t in tiles) {
            var submatches = find_matches_for_tile (t, processed_tiles);

            foreach (unowned var match in submatches)
                matches += match;

            /* Remember processed tiles, to later avoid creating duplicate matches
             * with swapped tile positions */
            if (submatches.length > 0)
                processed_tiles += t;
        }
        return matches;
    }

    private Match[] find_matches_for_tile (Tile? tile, Tile[]? ignored_tiles = null) {
        Match[] matches = null;

        if (tile == null || !tile_is_selectable (tile))
            return matches;

        foreach (unowned var t in tiles) {
            if (t == tile)
                continue;
            if (tiles_match (t, tile) && tile_is_selectable (t) && !(t in ignored_tiles))
                matches += new Match (t, tile);
        }
        return matches;
    }

    private void redraw_all_tiles () {
        foreach (unowned var tile in tiles)
            if (tile.visible)
                redraw_tile (tile);
    }

    private void reset_hint () {
        set_hint (null, null);
    }

    private void set_hint (Tile? tile0, Tile? tile1) {
        if (hint_tiles[0] != null)
            redraw_tile (hint_tiles[0]);
        if (hint_tiles[1] != null)
            redraw_tile (hint_tiles[1]);

        /* Stop hints */
        remove_hint_timeout ();

        if (tile0 == null && tile1 == null)
            return;

        hint_tiles[0] = tile0;
        hint_tiles[1] = tile1;
        hint_blink_counter = 6;
        hint_timeout = Timeout.add (250, hint_timeout_cb);
        hint_timeout_cb ();

        /* 30s penalty */
        start_clock ();
        clock_elapsed += 30.0;
        tick ();
    }

    private void remove_hint_timeout () {
        if (hint_timeout != 0)
            Source.remove (hint_timeout);
        hint_timeout = 0;
        hint_blink_counter = 0;
    }

    private bool hint_timeout_cb () {
        if (hint_blink_counter == 0) {
            remove_hint_timeout ();
            return false;
        }
        hint_blink_counter--;

        if (hint_tiles[0] != null)
            redraw_tile (hint_tiles[0]);
        if (hint_tiles[1] != null)
            redraw_tile (hint_tiles[1]);

        return true;
    }

    private void start_clock () {
        if (clock != null)
            return;
        clock = new Timer ();
        clock_timeout_cb ();
    }

    private void stop_clock () {
        if (clock == null)
            return;
        if (clock_timeout != 0)
            Source.remove (clock_timeout);
        clock_timeout = 0;
        clock.stop ();
    }

    private void continue_clock () {
        if (clock == null)
            clock = new Timer ();
        else
            clock.continue ();
        clock_timeout_cb ();
    }

    private void reset_clock () {
        stop_clock ();
        clock = null;
        clock_elapsed = 0.0;
        /* Ensure the clock label is updated */
        tick ();
    }

    private void clock_timeout_cb () {
        if (clock == null)
            return;

        var wait = 0;
        while (wait <= 0) {
            var elapsed = clock.elapsed ();
            var next = (int) (elapsed + 1);
            wait = (int) ((next - elapsed) * 1000);
        }

        clock_timeout = Timeout.add_once (wait, clock_timeout_cb);
        tick ();
    }
}
