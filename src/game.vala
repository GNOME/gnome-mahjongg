/*
 * Copyright (C) 2010-2013 Robert Ancell
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 2 of the License, or (at your option) any later
 * version. See http://www.gnu.org/copyleft/gpl.html the full text of the
 * license.
 */

public class Tile : Object
{
    public int number;
    public Slot slot;
    public bool visible = true;
    public int move_number;

    public int set
    {
        get { return number / 4; }
    }

    public Tile (Slot slot)
    {
        this.slot = slot;
    }

    public bool matches (Tile tile)
    {
        return tile.set == set;
    }
}

private static int compare_tiles (Tile a, Tile b)
{
    return compare_slots (a.slot, b.slot);
}

private static bool switch_tiles (Tile a, Tile b)
{
    if (a.visible && b.visible)
    {
        Slot h = a.slot;
        a.slot = b.slot;
        b.slot = h;
        return true;
    }
    return false;
}

public class Match : Object
{
    public Tile tile0;
    public Tile tile1;

    public Match (Tile tile0, Tile tile1)
    {
        this.tile0 = tile0;
        this.tile1 = tile1;
    }
}

public class Game : Object
{
    public Map map;
    public List<Tile> tiles = null;
    public Tile? hint_tiles[2];

    public int move_number;

    /* Hint animation */
    private uint hint_timout = 0;
    public uint hint_blink_counter = 0;

    /* Game timer */
    private double clock_elapsed;
    private Timer? clock;
    private uint clock_timeout;

    public signal void redraw_tile (Tile tile);
    public signal void moved ();
    public signal void paused_changed ();
    public signal void tick ();

    public bool started
    {
        get { return clock != null; }
    }

    public double elapsed
    {
        get
        {
            if (clock == null)
                return 0.0;
            return clock_elapsed + clock.elapsed ();
        }
    }

    private bool _paused = false;
    public bool paused
    {
        set
        {
            _paused = value;
            if (clock != null)
            {
                if (value)
                    stop_clock ();
                else
                    continue_clock ();
            }
            paused_changed ();
        }
        get { return _paused; }
    }

    private Tile? _selected_tile = null;
    public Tile? selected_tile
    {
        get { return _selected_tile; }
        set
        {
            if (_selected_tile != null)
                redraw_tile (_selected_tile);
            _selected_tile = value;
            if (value != null)
                redraw_tile (value);
        }
    }

    public int visible_tiles
    {
        get
        {
            var n = 0;
            foreach (var tile in tiles)
                if (tile.visible)
                    n++;
            return n;
        }
    }

    public uint moves_left
    {
        get { return find_matches ().length (); }
    }

    public bool complete
    {
        get { return visible_tiles == 0; }
    }

    public bool can_move
    {
        get { return moves_left != 0; }
    }

    public Game (Map map)
    {
        this.map = map;
        move_number = 1;

        /* Create the tiles in the locations required in the map */
        foreach (var slot in map.slots)
        {
            var tile = new Tile (slot);
            tile.number = 0;
            tiles.insert_sorted (tile, compare_tiles);
        }

        /* Come up with a random solution by picking random pairs and assigning them
         * with a random value.  If end up with an invalid solution, then choose the
         * next avaiable pair */
        var n_pairs = (int) tiles.length () / 2;
        var numbers = new int[n_pairs];
        for (var i = 0; i < n_pairs; i++)
            numbers[i] = i*2;
        for (var i = 0; i < n_pairs; i++)
        {
            var n = Random.int_range (i, n_pairs);
            var t = numbers[i];
            numbers[i] = numbers[n];
            numbers[n] = t;
        }
        shuffle (numbers);

        /* Make everything visible again */
        reset ();
    }

    public void shuffle_remaining (bool redraw = true) {
        // Fisher Yates Shuffle
        var n = tiles.length();
        for (var i = n-1; i > 0; i--) {
            int j = Random.int_range(0,(int)i+1);
            // switch internal positions
            switch_tiles (tiles.nth_data(j), tiles.nth_data(i));
        }
        // resort for drawing order
        tiles.sort(compare_tiles);
        // reset moves and move numbers
        move_number = 1;
        foreach (var tile in tiles)
            tile.move_number = 0;
        find_matches ();
        moved ();
        if (redraw)
            redraw_all_tiles ();
    }

    public void redraw_all_tiles () {
        foreach (var tile in tiles)
            if (tile.visible)
                redraw_tile (tile);
    }

    private bool shuffle (int[] numbers, int depth = 0)
    {
        /* All shuffled */
        if (depth == tiles.length () / 2)
            return true;

        var matches = find_matches ();
        var n_matches = matches.length ();

        /* No matches on this branch, rewind */
        if (n_matches == 0)
            return false;

        var n = Random.int_range (0, (int) n_matches);
        for (var i = 0; i < n_matches; i++)
        {
            var match = matches.nth_data ((n + i) % n_matches);
            match.tile0.number = numbers[depth];
            match.tile0.visible = false;
            match.tile1.number = numbers[depth] + 1;
            match.tile1.visible = false;

            if (shuffle (numbers, depth + 1))
                return true;

            /* Undo this move */
            match.tile0.number = 0;
            match.tile0.visible = true;
            match.tile1.number = 0;
            match.tile1.visible = true;
        }

        return false;
    }

    public void reset ()
    {
        reset_clock ();
        move_number = 1;
        selected_tile = null;
        set_hint (null, null);
        foreach (var tile in tiles)
        {
            tile.visible = true;
            tile.move_number = 0;
        }
    }

    public void set_hint (Tile? tile0, Tile? tile1)
    {
        if (hint_tiles[0] != null)
            redraw_tile (hint_tiles[0]);
        if (hint_tiles[1] != null)
            redraw_tile (hint_tiles[1]);

        /* Stop hints */
        if (tile0 == null && tile1 == null)
        {
            hint_blink_counter = 0;
            hint_timeout_cb ();
            return;
        }

        hint_tiles[0] = tile0;
        hint_tiles[1] = tile1;
        hint_blink_counter = 6;
        if (hint_timout != 0)
            Source.remove (hint_timout);
        hint_timout = Timeout.add (250, hint_timeout_cb);
        hint_timeout_cb ();

        /* 30s penalty */
        start_clock ();
        clock_elapsed += 30.0;
        tick ();
    }

    private bool hint_timeout_cb ()
    {
        if (hint_blink_counter == 0)
        {
            if (hint_timout != 0)
                Source.remove (hint_timout);
            hint_timout = 0;
            return false;
        }
        hint_blink_counter--;

        if (hint_tiles[0] != null)
            redraw_tile (hint_tiles[0]);
        if (hint_tiles[1] != null)
            redraw_tile (hint_tiles[1]);

        return true;
    }

    public bool tile_can_move (Tile tile)
    {
        if (!tile.visible)
            return false;

        var blocked_left = false;
        var blocked_right = false;
        var slot = tile.slot;
        foreach (var t in tiles)
        {
            if (t == tile || !t.visible)
                continue;

            var s = t.slot;

            /* Can't move if blocked by a tile above */
            if (s.layer == slot.layer + 1 &&
                (s.x >= slot.x - 1 && s.x <= slot.x + 1) &&
                (s.y >= slot.y - 1 && s.y <= slot.y + 1))
                return false;

            /* Can't move if blocked both on the left and the right */
            if (s.layer == slot.layer && (s.y >= slot.y - 1 && s.y <= slot.y + 1))
            {
                if (s.x == slot.x - 2)
                    blocked_left = true;
                if (s.x == slot.x + 2)
                    blocked_right = true;
                if (blocked_left && blocked_right)
                    return false;
            }
        }

        return true;
    }

    public int number_of_movable_tiles () {
        int count = 0;
        foreach (var tile in tiles)
            if (tile_can_move(tile))
                count++;
        return count;
    }

    public List<Match> find_matches (Tile? tile = null)
    {
        List<Match> matches = null;

        if (tile != null && !tile_can_move (tile))
            return matches;

        if (tile == null)
        {
            foreach (var t in tiles)
            {
                foreach (var match in find_matches (t))
                {
                    bool already_matched = false;
                    foreach (var existing_match in matches)
                    {
                        if (existing_match.tile0 == match.tile1 && existing_match.tile1 == match.tile0)
                        {
                            already_matched = true;
                            break;
                        }
                    }

                    if (!already_matched)
                        matches.append (match);
                }
            }
        }
        else
        {
            foreach (var t in tiles)
            {
                if (t == tile || !tile_can_move (t))
                    continue;

                if (t.matches (tile))
                    matches.append (new Match (t, tile));
            }
        }

        return matches;
    }

    public bool remove_pair (Tile tile0, Tile tile1)
    {
        if (!tile0.visible || !tile1.visible)
            return false;

        if (tile0.set != tile1.set)
            return false;

        selected_tile = null;
        set_hint (null, null);

        /* You lose your re-do queue when you make a move */
        foreach (var tile in tiles)
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

    private void start_clock ()
    {
        if (clock == null)
            clock = new Timer ();
        timeout_cb ();
    }

    private void stop_clock ()
    {
        if (clock == null)
            return;
        if (clock_timeout != 0)
            Source.remove (clock_timeout);
        clock_timeout = 0;
        clock.stop ();
        tick ();
    }

    private void continue_clock ()
    {
        if (clock == null)
            clock = new Timer ();
        else
            clock.continue ();
        timeout_cb ();
    }

    private void reset_clock ()
    {
        stop_clock ();
        clock = null;
        clock_elapsed = 0.0;
        /* Ensure the clock label is updated */
        tick ();
    }

    private bool timeout_cb ()
    {
        if (clock != null)
        {
            /* Notify on the next tick */
            var elapsed = clock.elapsed ();
            var next = (int) (elapsed + 1.0);
            var wait = next - elapsed;
            clock_timeout = Timeout.add ((int) (wait * 1000), timeout_cb);

            tick ();
        }

        return false;
    }

    public bool can_undo
    {
        get { return move_number > 1; }
    }

    public void undo ()
    {
        if (!can_undo)
            return;

        selected_tile = null;
        set_hint (null, null);

        /* Re-show tiles that were removed */
        move_number--;
        foreach (var tile in tiles)
        {
            if (tile.move_number == move_number)
            {
                tile.visible = true;
                redraw_tile (tile);
            }
        }
    }

    public bool can_redo
    {
        get
        {
            foreach (var tile in tiles)
                if (tile.move_number >= move_number)
                    return true;
            return false;
        }
    }

    public void redo ()
    {
        if (!can_redo)
            return;

        selected_tile = null;
        set_hint (null, null);

        foreach (var tile in tiles)
        {
            if (tile.move_number == move_number)
            {
                tile.visible = false;
                redraw_tile (tile);
            }
        }
        move_number++;
    }
}
