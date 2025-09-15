// SPDX-FileCopyrightText: 2010-2025 Mahjongg Contributors
// SPDX-FileCopyrightText: 2010-2013 Robert Ancell
// SPDX-License-Identifier: GPL-2.0-or-later

public class Tile {
    public int number = -1;
    public bool visible = true;
    public bool highlighted;
    public int move;
    public Slot slot;

    public bool shaking;
    public int shake_offset;
    public double shake_start_time;

    private Tile[] left;
    private Tile[] right;
    private Tile[] above;

    public bool selectable {
        get {
            if (!visible)
                return false;

            var left_blocked = false;
            foreach (unowned var tile in left)
                if (tile.visible) {
                    left_blocked = true;
                    break;
                }

            var right_blocked = false;
            foreach (unowned var tile in right)
                if (tile.visible) {
                    right_blocked = true;
                    break;
                }

            if (left_blocked && right_blocked)
                return false;

            foreach (unowned var tile in above)
                if (tile.visible)
                    return false;

            return true;
        }
    }

    public Tile (Slot slot) {
        this.slot = slot;
    }

    public void add_tile_left (Tile tile) {
        left += tile;
    }

    public void add_tile_right (Tile tile) {
        right += tile;
    }

    public void add_tile_above (Tile tile) {
        above += tile;
    }

    public bool matches (Tile tile) {
        var tile_face_a = number / 4;
        var tile_face_b = tile.number / 4;
        return tile_face_a == tile_face_b;
    }
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

    private Tile[] tiles;
    private Rand random;

    private Match? hint_match;
    private Match[] hint_matches;
    private int hint_match_index;
    private uint hint_timeout;
    private uint hint_blink_counter;

    private uint autoplay_end_game_timeout;

    private double clock_elapsed;
    private Timer? clock;
    private uint clock_timeout;

    public signal bool attempt_move ();
    public signal void redraw_tile (Tile tile);
    public signal void moved ();
    public signal void paused_changed ();
    public signal void tick ();

    private int32 _seed = -1;
    public int32 seed {
        get { return _seed; }
    }

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

    private bool _inspecting;
    public bool inspecting {
        get { return _inspecting; }
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
            set_hint (null);
            paused_changed ();
        }
        get { return _paused; }
    }

    private Tile? _selected_tile;
    public Tile? selected_tile {
        get { return _selected_tile; }
        set {
            if (_selected_tile != null) {
                _selected_tile.highlighted = false;
                redraw_tile (_selected_tile);
            }

            _selected_tile = value;
            if (_selected_tile != null) {
                _selected_tile.highlighted = true;
                redraw_tile (_selected_tile);
            }

            /* Hint matches can change depending on the selected tile. Reset them. */
            hint_matches = null;
        }
    }

    private int _current_move;
    public int current_move {
        get { return _current_move; }
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
                if (tile.selectable) {
                    num_selectable_tiles++;
                    if (num_selectable_tiles == 2)
                        return true;
                }
            }
            return false;
        }
    }

    public bool can_undo {
        get { return _current_move > 1; }
    }

    public bool can_redo {
        get {
            foreach (unowned var tile in tiles)
                if (tile.move >= _current_move)
                    return true;
            return false;
        }
    }

    public bool can_save {
        get { return started && can_move && !inspecting; }
    }

    public bool all_tiles_unblocked {
        get {
            foreach (unowned var tile in tiles)
                if (tile.visible && !tile.selectable)
                    return false;
            return true;
        }
    }

    public int n_tiles {
        get { return tiles.length; }
    }

    public Game (Map map) {
        this.map = map;

        /* Create blank tiles in the locations required in the map */
        create_tiles ();
    }

    /* Start with a board consisting of visible blank tiles. Walk through all
     * tiles, choosing and removing tile pairs until we have a solvable board.
     *
     * Check all possible tile matches for visible/remaining tiles. Choose a
     * random match, hide/remove both tiles, and repeat the process. If we
     * reach an unsolvable state, undo the previous move and try the next match.
     *
     * Once we have a path to victory, assign random tile faces to all pairs.
     */
    public void generate (int32 seed = -1) {
        this._seed = seed != -1 ? seed : Random.int_range (0, int32.MAX);
        var n_pairs = (int) tiles.length / 2;
        var pair_numbers = new int[n_pairs];

        /* Reset game */
        reset_clock ();
        paused = false;
        _current_move = 1;
        _inspecting = false;

        /* Create tile pair numbers */
        for (var i = 0; i < n_pairs; i++)
            pair_numbers[i] = i * 2;

        /* Choose tile pairs until we have a solvable board */
        random = new Rand.with_seed (this._seed);
        pair_numbers = shuffle_pair_numbers (pair_numbers);
        choose_tile_pairs (pair_numbers);

        /* The algorithm has "finished" the game. Make all tiles visible again for
         * the player. */
        foreach (unowned var tile in tiles) {
            tile.visible = true;
            tile.move = 0;
        }
        redraw_all_tiles ();
        moved ();
    }

    public void restore (GameSave save) {
        _seed = save.seed;
        _current_move = save.move;
        random = new Rand.with_seed (_seed);

        foreach (unowned var tile in tiles) {
            foreach (unowned var t in save) {
                if (tile.slot.equals (t.slot)) {
                    tile.number = t.number;
                    tile.move = t.move;
                    tile.visible = t.visible;
                }
            }
        }

        clock = new Timer ();
        clock.stop ();
        clock_elapsed = save.clock;
        tick ();

        redraw_all_tiles ();
        moved ();
        paused = true;
    }

    public void restart () {
        foreach (unowned var tile in tiles) {
            tile.number = -1;
            tile.visible = true;
        }
        generate (_seed);
    }

    public void destroy_timers () {
        remove_hint_timeout ();
        remove_autoplay_end_game_timeout ();
        stop_clock ();
    }

    public Tile? get_tile (int position) {
        if (position < 0 || position >= n_tiles)
            return null;
        return tiles[position];
    }

    public void shake_tile (Tile tile, int64 start_time) {
        tile.shaking = true;
        tile.shake_offset = 0;
        tile.shake_start_time = start_time;
        redraw_tile (tile);
    }

    public bool remove_pair (Tile tile0, Tile tile1) {
        if (!tile0.visible || !tile1.visible)
            return false;

        if (tile0 == tile1 || !tile0.matches (tile1))
            return false;

        selected_tile = null;
        set_hint (null);

        /* You lose your re-do queue when you make a move */
        foreach (unowned var tile in tiles)
            if (tile.move >= _current_move)
                tile.move = 0;

        tile0.visible = false;
        tile0.move = current_move;
        tile1.visible = false;
        tile1.move = current_move;

        _current_move++;

        redraw_tile (tile0);
        redraw_tile (tile1);

        if (complete)
            stop_clock ();
        else
            start_clock ();

        moved ();

        if (complete)
            _inspecting = true;

        return true;
    }

    public void shuffle_remaining () {
        if (!can_shuffle)
            return;

        int[] removed_tile_faces = null;
        int[] pair_numbers = null;
        Tile[] tiles_to_shuffle = null;

        /* Retrieve tile pair numbers of remaining tiles, and blank the tiles */
        _current_move = 1;

        foreach (unowned var tile in tiles) {
            tile.move = 0;

            if (tile.visible) {
                tiles_to_shuffle += tile;
                continue;
            }

            var tile_face = tile.number / 4;
            if (!(tile_face in removed_tile_faces))
                removed_tile_faces += tile_face;
        }

        foreach (unowned var tile in tiles_to_shuffle) {
            var tile_face = tile.number / 4;
            var pair_number = tile.number - (tile.number % 2);
            tile.number = -1;

            /* A tile pair with the current face was previously removed. Since two
             * tile pairs share the same face, there is a possibility that a tile
             * from each pair were matched, leaving two "incomplete" pairs behind.
             * Ensure that the two remaining tiles use a single pair number.
             */
            if (tile_face in removed_tile_faces)
                pair_number = tile_face * 4;

            if (!(pair_number in pair_numbers))
                pair_numbers += pair_number;
        }

        /* Choose tile pairs from remaining tiles until we have a solvable board */
        pair_numbers = shuffle_pair_numbers (pair_numbers);
        choose_tile_pairs (pair_numbers);

        /* Make remaining tiles visible again */
        foreach (unowned var tile in tiles_to_shuffle)
            tile.visible = true;

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
        set_hint (null);

        /* Re-show tiles that were removed */
        _current_move--;
        foreach (unowned var tile in tiles) {
            if (tile.move == _current_move) {
                tile.visible = true;
                redraw_tile (tile);
            }
        }
        moved ();
    }

    public void redo () {
        if (!can_redo)
            return;

        selected_tile = null;
        set_hint (null);

        foreach (unowned var tile in tiles) {
            if (tile.move == _current_move) {
                tile.visible = false;
                redraw_tile (tile);
            }
        }
        _current_move++;
        moved ();
    }

    public Match? next_hint () {
        if (hint_matches.length == 0) {
            hint_matches = find_matches_for_tile (selected_tile);

            /* No match, find any random match as if nothing was selected */
            if (hint_matches.length == 0)
                hint_matches = find_matches ();

            /* No remaining tiles, no hint to show */
            if (hint_matches.length == 0)
                return null;

            hint_match_index = random.int_range (0, (int) hint_matches.length);
        }

        /* Cycle through hint matches */
        hint_match_index++;

        if (hint_match_index >= hint_matches.length)
            hint_match_index = 0;

        var match = hint_matches[hint_match_index];
        return match;
    }

    public void show_hint () {
        set_hint (next_hint ());
    }

    public void autoplay_end_game () {
        if (!all_tiles_unblocked)
            return;

        autoplay_end_game_timeout = Timeout.add (500, autoplay_end_game_timeout_cb);
        autoplay_end_game_timeout_cb ();
    }

    public Iterator iterator () {
        return new Iterator (this);
    }

    private void create_tiles () {
        foreach (unowned var slot in map)
            tiles += new Tile (slot);

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
                        tile.add_tile_left (t);
                    if (s_x == x + 2)
                        tile.add_tile_right (t);

                /* Can't move if blocked by a tile above */
                } else if (s_layer > layer) {
                    var s_x = s.x;

                    if (s_x >= x - 1 && s_x <= x + 1)
                        tile.add_tile_above (t);
                }
            }
        }
    }

    private unowned int[] shuffle_pair_numbers (int[] pair_numbers) {
        /* Fisher-Yates Shuffle */
        for (var i = 0; i < pair_numbers.length; i++) {
            var n = random.int_range (i, pair_numbers.length);
            var tile_number = pair_numbers[i];
            pair_numbers[i] = pair_numbers[n];
            pair_numbers[n] = tile_number;
        }
        return pair_numbers;
    }

    private bool choose_tile_pairs (int[] pair_numbers, int depth = 0, bool check_selectable = true) {
        /* All tile pairs chosen */
        if (depth == pair_numbers.length)
            return true;

        var matches = find_matches (check_selectable);
        var n_matches = matches.length;

        /* No matches on this branch, rewind */
        if (n_matches == 0)
            return false;

        var n = random.int_range (0, (int) n_matches);
        for (var i = 0; i < n_matches; i++) {
            var number = pair_numbers[depth];
            unowned var match = matches[(n + i) % n_matches];
            unowned var tile0 = match.tile0;
            unowned var tile1 = match.tile1;

            tile0.visible = false;
            tile1.visible = false;

            if (choose_tile_pairs (pair_numbers, depth + 1, check_selectable)) {
                /* Assign tile face for pair */
                tile0.number = number;
                tile1.number = number + 1;
                return true;
            }

            if (check_selectable && depth == 0 && i == n_matches - 1) {
                /* Unsolvable tile arrangement, possibly a handful of tiles in a
                 * tall stack remaining. Ensure we still assign faces to all tiles. */
                check_selectable = false;
                i--;
            }

            /* Unsolvable state, undo move and try the next match */
            tile0.visible = true;
            tile1.visible = true;
        }
        return false;
    }

    private Match[] find_matches (bool check_selectable = true) {
        Match[] matches = null;
        Tile[] processed_tiles = null;

        foreach (unowned var t in tiles) {
            var submatches = find_matches_for_tile (t, processed_tiles, check_selectable);

            foreach (unowned var match in submatches)
                matches += match;

            /* Remember processed tiles, to later avoid creating duplicate matches
             * with swapped tile positions */
            if (submatches.length > 0)
                processed_tiles += t;
        }
        return matches;
    }

    private Match[] find_matches_for_tile (Tile? tile, Tile[]? ignored_tiles = null,
                                           bool check_selectable = true) {
        Match[] matches = null;

        if (tile == null || !tile.visible)
            return matches;

        if (check_selectable && !tile.selectable)
            return matches;

        foreach (unowned var t in tiles) {
            if (t == tile || !t.visible)
                continue;
            if (t.matches (tile) && (!check_selectable || t.selectable) && !(t in ignored_tiles))
                matches += new Match (t, tile);
        }
        return matches;
    }

    private void redraw_all_tiles () {
        foreach (unowned var tile in tiles)
            if (tile.visible)
                redraw_tile (tile);
    }

    private void set_hint (Match? match) {
        /* Stop hints */
        remove_hint_timeout ();

        if (match == null) {
            hint_match = null;
            hint_matches = null;
            return;
        }

        hint_match = match;
        hint_blink_counter = 6;
        hint_timeout = Timeout.add (250, hint_timeout_cb);
        hint_timeout_cb ();

        if (_inspecting)
            return;

        var had_started = started;

        /* 30s penalty */
        start_clock ();
        clock_elapsed += 30.0;
        tick ();

        if (!had_started)
            moved ();
    }

    private void redraw_hint_match (Match? match) {
        if (match == null)
            return;

        match.tile0.highlighted = hint_blink_counter % 2 != 0 || match.tile0 == selected_tile;
        redraw_tile (match.tile0);

        match.tile1.highlighted = hint_blink_counter % 2 != 0 || match.tile1 == selected_tile;
        redraw_tile (match.tile1);
    }

    private void remove_hint_timeout () {
        if (hint_timeout != 0)
            Source.remove (hint_timeout);
        hint_timeout = 0;
        hint_blink_counter = 0;

        redraw_hint_match (hint_match);
    }

    private bool hint_timeout_cb () {
        if (hint_blink_counter == 0) {
            remove_hint_timeout ();
            return false;
        }
        hint_blink_counter--;
        redraw_hint_match (hint_match);
        return true;
    }

    private void remove_autoplay_end_game_timeout () {
        if (autoplay_end_game_timeout != 0)
            Source.remove (autoplay_end_game_timeout);
        autoplay_end_game_timeout = 0;
    }

    private bool autoplay_end_game_timeout_cb () {
        var match = next_hint ();
        if (match == null) {
            remove_autoplay_end_game_timeout ();
            return false;
        }

        remove_pair (match.tile0, match.tile1);
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
        if (clock_timeout != 0) {
            Source.remove (clock_timeout);
            clock_timeout = 0;
        }
        if (clock.is_active ())
            clock.stop ();
    }

    private void continue_clock () {
        if (clock == null)
            clock = new Timer ();
        else if (!clock.is_active ())
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

    public class Iterator {
        private int index;
        private Game game;

        public Iterator (Game game) {
            this.game = game;
        }

        public bool next () {
            return index < game.tiles.length;
        }

        public unowned Tile get () {
            return game.tiles[index++];
        }
    }
}
