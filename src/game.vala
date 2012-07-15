public class Tile
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

public class Match
{
    public Tile tile0;
    public Tile tile1;
    
    public Match (Tile tile0, Tile tile1)
    {
        this.tile0 = tile0;
        this.tile1 = tile1;
    }
}

public class Game
{
    public Map map;
    public List<Tile> tiles = null;
    public Tile? hint_tiles[2];

    public int move_number;

    /* Hint animation */
    private uint hint_timer = 0;
    public uint hint_blink_counter = 0;

    public signal void redraw_tile (Tile tile);
    public signal void moved ();

    public bool started
    {
        get { return move_number > 1; }
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
        if (hint_timer != 0)
            Source.remove (hint_timer);
        hint_timer = Timeout.add (250, hint_timeout_cb);
        hint_timeout_cb ();
    }

    private bool hint_timeout_cb ()
    {
        if (hint_blink_counter == 0)
        {
            if (hint_timer != 0)
                Source.remove (hint_timer);
            hint_timer = 0;
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
                    matches.append (match);
            }
        }
        else
        {
            foreach (var t in tiles)
            {
                if (t == tile || !tile_can_move (t))
                    continue;

                if (!t.matches (tile))
                    continue;

                var already_matched = false;
                foreach (var match in matches)
                {
                    if (match.tile0 == tile && match.tile1 == t)
                    {
                        already_matched = true;
                        break;
                    }
                }

                if (!already_matched)
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

        tile0.visible = false;
        tile0.move_number = move_number;
        tile1.visible = false;
        tile1.move_number = move_number;

        move_number++;

        redraw_tile (tile0);
        redraw_tile (tile1);

        /* You lose your re-do queue when you make a move */
        foreach (var tile in tiles)
            if (tile.move_number >= move_number)
                tile.move_number = 0;

        moved ();

        return true;
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
