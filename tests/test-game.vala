// SPDX-FileCopyrightText: 2025 Mahjongg Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

private Game generate_game (owned Map? map = null, int32 seed = 123456789) {
    if (map == null)
        map = new Map.builtin ();
    var game = new Game (map);
    game.generate (seed);

    return game;
}

private void test_tile_highlighted () {
    var game = generate_game ();
    var match = game.next_hint ();

    assert_true (match != null);
    var tile = match.tile0;

    game.selected_tile = tile;
    assert_true (tile.highlighted);

    game.selected_tile = null;
    assert_false (tile.highlighted);
}

private void test_remove_invalid_pair () {
    var game = generate_game ();
    var tile_a = game.tiles.nth_data (0);
    var tile_b = game.tiles.nth_data (1);
    game.selected_tile = tile_a;

    // Verify invalid pair
    assert_false (tile_a.matches (tile_b));
    assert_true (tile_a.visible);
    assert_true (tile_a.highlighted);
    assert_true (tile_b.visible);
    assert_false (tile_b.highlighted);

    // Same tile
    assert_false (game.remove_pair (tile_a, tile_a));
    assert_true (tile_a.visible);
    assert_true (tile_a.highlighted);

    // Non-matching tiles
    assert_false (game.remove_pair (tile_a, tile_b));
    assert_true (tile_a.visible);
    assert_true (tile_a.highlighted);
    assert_true (tile_b.visible);
    assert_false (tile_b.highlighted);
}

private void test_remove_valid_pair () {
    var game = generate_game ();
    var match = game.next_hint ();
    game.selected_tile = match.tile0;

    // Verify valid pair
    assert_true (match != null);
    assert_true (match.tile0.matches (match.tile1));
    assert_true (match.tile0.visible);
    assert_true (match.tile0.highlighted);
    assert_true (match.tile1.visible);
    assert_false (match.tile1.highlighted);

    // Verify pair removal
    assert_true (game.remove_pair (match.tile0, match.tile1));
    assert_false (match.tile0.visible);
    assert_false (match.tile0.highlighted);
    assert_false (match.tile1.visible);
    assert_false (match.tile1.highlighted);

    // Verify double removal is not possible
    assert_false (game.remove_pair (match.tile0, match.tile1));
    assert_false (match.tile0.visible);
    assert_false (match.tile0.highlighted);
    assert_false (match.tile1.visible);
    assert_false (match.tile1.highlighted);
}

private void test_next_hint () {
    var game = generate_game ();

    int[,] expected_hint_pairs = {
        // First cycle
        {90, 89},
        {88, 89},
        {64, 65},
        {42, 43},
        {84, 87},
        {86, 87},
        {128, 129},
        {88, 90},
        {134, 133},
        {132, 133},
        {86, 84},
        {132, 134},
        {6, 7},
        {34, 35},
        {0, 1},
        {77, 79},
        {136, 137},

        // Second cycle
        {90, 89},
        {88, 89},
        {64, 65},
        {42, 43},
        {84, 87},
        {86, 87},
        {128, 129},
        {88, 90},
        {134, 133},
        {132, 133},
        {86, 84},
        {132, 134},
        {6, 7},
        {34, 35},
        {0, 1},
        {77, 79},
        {136, 137},
    };

    // Verify sequential hints
    for (int i = 0; i < expected_hint_pairs.length[0]; i++) {
        var match = game.next_hint ();
        assert_true (match != null);

        assert_true (match.tile0 != match.tile1);
        assert_true (match.tile0.visible);
        assert_true (match.tile1.visible);
        assert_true (match.tile0.selectable);
        assert_true (match.tile1.selectable);
        assert_true (match.tile0.matches (match.tile1));

        assert_true (
            match.tile0.number == expected_hint_pairs[i, 0]
            && match.tile1.number == expected_hint_pairs[i, 1]
        );
    }
}

private void test_shuffle_remaining () {
    var game = generate_game ();
    var tile_number = game.tiles.first ().data.number;

    game.shuffle_remaining ();
    assert_true (game.tiles.first ().data.number != tile_number);
}

private void test_undo_redo () {
    var game = generate_game ();

    assert_false (game.can_undo);
    assert_false (game.can_redo);

    var first_match = game.next_hint ();
    assert_true (first_match != null);
    game.remove_pair (first_match.tile0, first_match.tile1);

    var second_match = game.next_hint ();
    assert_true (second_match != null);
    game.remove_pair (second_match.tile0, second_match.tile1);

    // Verify undo/redo possibility and tile states
    assert_true (game.can_undo);
    assert_false (game.can_redo);
    assert_true (first_match.tile0.move_number == 1 && first_match.tile1.move_number == 1);
    assert_true (second_match.tile0.move_number == 2 && second_match.tile1.move_number == 2);

    game.undo ();
    assert_true (game.can_undo);
    assert_true (game.can_redo);

    game.redo ();
    assert_true (game.can_undo);
    assert_false (game.can_redo);

    game.undo ();
    assert_true (game.can_undo);
    assert_true (game.can_redo);

    game.undo ();
    assert_false (game.can_undo);
    assert_true (game.can_redo);
    assert_true (first_match.tile0.move_number == 1 && first_match.tile1.move_number == 1);
    assert_true (second_match.tile0.move_number == 2 && second_match.tile1.move_number == 2);

    // Verify tile state reset
    var third_match = game.next_hint ();
    assert_true (third_match != null);
    game.remove_pair (third_match.tile0, third_match.tile1);

    assert_true (game.can_undo);
    assert_false (game.can_redo);
    assert_true (first_match.tile0.move_number == 0 && first_match.tile1.move_number == 0);
    assert_true (second_match.tile0.move_number == 0 && second_match.tile1.move_number == 0);
    assert_true (third_match.tile0.move_number == 1 && third_match.tile1.move_number == 1);
}

private void test_undo_redo_no_moves () {
    var game = generate_game ();

    assert_false (game.can_undo);
    assert_false (game.can_redo);

    game.undo ();
    game.redo ();

    assert_false (game.can_undo);
    assert_false (game.can_redo);
}

private void test_seed_reproducibility () {
    var game1 = generate_game ();
    var game2 = generate_game ();

    assert_true (game1.tiles.length () == game2.tiles.length ());

    for (int i = 0; i < game1.tiles.length (); i++) {
        var tile1 = game1.tiles.nth_data (i);
        var tile2 = game2.tiles.nth_data (i);

        assert_true (tile1.number == tile2.number);
        assert_true (tile1.slot.x == tile2.slot.x);
        assert_true (tile1.slot.y == tile2.slot.y);
        assert_true (tile1.slot.layer == tile2.slot.layer);
    }
}

private void test_seed_difference () {
    var seed1 = 123456789;
    var seed2 = 987654321;
    var game1 = generate_game (null, seed1);
    var game2 = generate_game (null, seed2);

    bool found_difference = false;

    for (int i = 0; i < game1.tiles.length (); i++) {
        var tile1 = game1.tiles.nth_data (i);
        var tile2 = game2.tiles.nth_data (i);

        if (tile1.number != tile2.number ||
            tile1.slot.x != tile2.slot.x ||
            tile1.slot.y != tile2.slot.y ||
            tile1.slot.layer != tile2.slot.layer) {
            found_difference = true;
            break;
        }
    }
    assert_true (found_difference);
}

private void verify_tiles (List<Tile> tiles, int[,] expected_layout) {
    for (int i = 0; i < expected_layout.length[0]; i++) {
        var tile = tiles.nth_data (i);

        assert_true (tile.visible);
        assert_false (tile.highlighted);
        assert_true (tile.move_number == 0);

        assert_true (tile.number == expected_layout[i, 0]);
        assert_true (tile.selectable == (bool)expected_layout[i, 1]);
        assert_true (tile.slot.x == expected_layout[i, 2]);
        assert_true (tile.slot.y == expected_layout[i, 3]);
        assert_true (tile.slot.layer == expected_layout[i, 4]);
    }
}

private void test_seed_snapshot_turtle () {
    var game = generate_game ();

    verify_tiles (
        game.tiles,
        {
            {39, 1, 24, 0, 0},
            {53, 0, 22, 0, 0},
            {51, 1, 28, 7, 0},
            {109, 0, 20, 0, 0},
            {17, 0, 26, 7, 0},
            {85, 0, 24, 6, 0},
            {35, 1, 22, 4, 0},
            {1, 1, 20, 2, 0},
            {45, 0, 18, 0, 0},
            {63, 0, 24, 8, 0},
            {113, 0, 22, 6, 0},
            {81, 0, 20, 4, 0},
            {95, 0, 18, 2, 0},
            {25, 0, 16, 0, 0},
            {59, 0, 22, 8, 0},
            {3, 0, 20, 6, 0},
            {83, 0, 18, 4, 0},
            {121, 0, 16, 2, 0},
            {58, 0, 14, 0, 0},
            {79, 1, 22, 10, 0},
            {67, 0, 20, 8, 0},
            {24, 0, 18, 6, 0},
            {97, 0, 16, 4, 0},
            {69, 0, 14, 2, 0},
            {111, 0, 12, 0, 0},
            {137, 1, 24, 14, 0},
            {11, 0, 20, 10, 0},
            {23, 0, 18, 8, 0},
            {5, 0, 16, 6, 0},
            {119, 0, 14, 4, 0},
            {66, 0, 12, 2, 0},
            {57, 0, 10, 0, 0},
            {105, 0, 22, 14, 0},
            {89, 1, 20, 12, 0},
            {75, 0, 18, 10, 0},
            {47, 0, 16, 8, 0},
            {141, 0, 14, 6, 0},
            {71, 0, 12, 4, 0},
            {10, 0, 10, 2, 0},
            {44, 0, 8, 0, 0},
            {19, 0, 20, 14, 0},
            {15, 0, 18, 12, 0},
            {131, 0, 16, 10, 0},
            {46, 0, 14, 8, 0},
            {22, 0, 12, 6, 0},
            {103, 0, 10, 4, 0},
            {41, 0, 8, 2, 0},
            {40, 0, 6, 0, 0},
            {61, 0, 18, 14, 0},
            {125, 0, 16, 12, 0},
            {140, 0, 14, 10, 0},
            {130, 0, 12, 8, 0},
            {110, 0, 10, 6, 0},
            {120, 0, 8, 4, 0},
            {31, 1, 6, 2, 0},
            {30, 0, 4, 0, 0},
            {115, 0, 16, 14, 0},
            {38, 0, 14, 12, 0},
            {21, 0, 12, 10, 0},
            {33, 0, 10, 8, 0},
            {114, 0, 8, 6, 0},
            {135, 0, 6, 4, 0},
            {136, 1, 2, 0, 0},
            {32, 0, 14, 14, 0},
            {73, 0, 12, 12, 0},
            {49, 0, 10, 10, 0},
            {139, 0, 8, 8, 0},
            {138, 0, 6, 6, 0},
            {65, 1, 4, 4, 0},
            {70, 0, 12, 14, 0},
            {127, 0, 10, 12, 0},
            {55, 0, 8, 10, 0},
            {117, 0, 6, 8, 0},
            {123, 0, 4, 6, 0},
            {74, 0, 10, 14, 0},
            {60, 0, 8, 12, 0},
            {50, 0, 6, 10, 0},
            {94, 0, 4, 8, 0},
            {101, 0, 2, 6, 0},
            {29, 0, 8, 14, 0},
            {126, 1, 6, 12, 0},
            {43, 1, 4, 10, 0},
            {54, 0, 2, 8, 0},
            {87, 1, 0, 7, 0},
            {27, 0, 6, 14, 0},
            {112, 0, 4, 14, 0},
            {129, 1, 2, 14, 0},
            {42, 1, 18, 2, 1},
            {93, 1, 18, 4, 1},
            {104, 0, 16, 2, 1},
            {100, 1, 18, 6, 1},
            {91, 0, 16, 4, 1},
            {26, 0, 14, 2, 1},
            {90, 1, 18, 8, 1},
            {37, 0, 16, 6, 1},
            {2, 0, 14, 4, 1},
            {28, 0, 12, 2, 1},
            {88, 1, 18, 10, 1},
            {80, 0, 16, 8, 1},
            {18, 0, 14, 6, 1},
            {52, 0, 12, 4, 1},
            {99, 0, 10, 2, 1},
            {9, 1, 18, 12, 1},
            {102, 0, 16, 10, 1},
            {107, 0, 14, 8, 1},
            {108, 0, 12, 6, 1},
            {13, 0, 10, 4, 1},
            {133, 1, 8, 2, 1},
            {92, 0, 16, 12, 1},
            {4, 0, 14, 10, 1},
            {116, 0, 12, 8, 1},
            {106, 0, 10, 6, 1},
            {77, 1, 8, 4, 1},
            {124, 0, 14, 12, 1},
            {56, 0, 12, 10, 1},
            {68, 0, 10, 8, 1},
            {84, 1, 8, 6, 1},
            {48, 0, 12, 12, 1},
            {96, 0, 10, 10, 1},
            {64, 1, 8, 8, 1},
            {143, 0, 10, 12, 1},
            {134, 1, 8, 10, 1},
            {132, 1, 8, 12, 1},
            {7, 1, 16, 4, 2},
            {128, 1, 16, 6, 2},
            {62, 0, 14, 4, 2},
            {6, 1, 16, 8, 2},
            {118, 0, 14, 6, 2},
            {98, 0, 12, 4, 2},
            {12, 1, 16, 10, 2},
            {8, 0, 14, 8, 2},
            {36, 0, 12, 6, 2},
            {34, 1, 10, 4, 2},
            {20, 0, 14, 10, 2},
            {78, 0, 12, 8, 2},
            {0, 1, 10, 6, 2},
            {122, 0, 12, 10, 2},
            {72, 1, 10, 8, 2},
            {82, 1, 10, 10, 2},
            {14, 0, 14, 6, 3},
            {76, 0, 14, 8, 3},
            {142, 0, 12, 6, 3},
            {16, 0, 12, 8, 3},
            {86, 1, 13, 7, 4},
        }
    );
}

private void test_seed_snapshot_difficult () {
    var map_loader = new MapLoader ();
    map_loader.load_folder ("../data/maps/");
    assert_true (map_loader.length >= 1);

    var difficult_map = map_loader.get_map_at_position (map_loader.length - 1);
    var game = generate_game (difficult_map);

    verify_tiles (
        game.tiles,
        {
            {135, 0, 19, 1, 0},
            {85, 0, 17, 1, 0},
            {101, 0, 19, 3, 0},
            {65, 1, 20, 6, 0},
            {31, 0, 17, 3, 0},
            {79, 0, 14, 0, 0},
            {35, 0, 18, 5, 0},
            {95, 0, 15, 2, 0},
            {41, 0, 12, 0, 0},
            {69, 0, 16, 5, 0},
            {83, 0, 18, 7, 0},
            {45, 0, 13, 2, 0},
            {55, 0, 19, 9, 0},
            {23, 0, 14, 4, 0},
            {49, 0, 10, 0, 0},
            {68, 0, 16, 7, 0},
            {5, 0, 11, 2, 0},
            {15, 0, 17, 9, 0},
            {7, 0, 19, 11, 0},
            {47, 0, 12, 4, 0},
            {4, 0, 14, 6, 0},
            {117, 0, 8, 0, 0},
            {111, 0, 9, 2, 0},
            {137, 0, 17, 11, 0},
            {46, 0, 10, 4, 0},
            {22, 0, 12, 6, 0},
            {61, 0, 14, 8, 0},
            {17, 0, 6, 0, 0},
            {25, 0, 7, 2, 0},
            {29, 0, 15, 10, 0},
            {141, 0, 8, 4, 0},
            {131, 0, 10, 6, 0},
            {67, 0, 12, 8, 0},
            {63, 0, 5, 2, 0},
            {109, 0, 13, 10, 0},
            {93, 0, 3, 1, 0},
            {60, 0, 6, 4, 0},
            {140, 0, 8, 6, 0},
            {130, 0, 10, 8, 0},
            {89, 0, 14, 12, 0},
            {73, 0, 11, 10, 0},
            {87, 0, 1, 1, 0},
            {105, 0, 3, 3, 0},
            {59, 0, 6, 6, 0},
            {33, 0, 8, 8, 0},
            {27, 0, 12, 12, 0},
            {57, 0, 4, 5, 0},
            {127, 0, 9, 10, 0},
            {77, 0, 1, 3, 0},
            {115, 0, 6, 8, 0},
            {107, 0, 10, 12, 0},
            {13, 0, 2, 5, 0},
            {119, 0, 4, 7, 0},
            {118, 0, 7, 10, 0},
            {53, 0, 8, 12, 0},
            {81, 0, 2, 7, 0},
            {97, 0, 5, 10, 0},
            {129, 1, 0, 6, 0},
            {99, 0, 3, 9, 0},
            {125, 0, 6, 12, 0},
            {40, 0, 1, 9, 0},
            {62, 0, 3, 11, 0},
            {1, 0, 1, 11, 0},
            {76, 1, 18, 2, 1},
            {37, 0, 16, 2, 1},
            {133, 1, 13, 0, 1},
            {9, 1, 17, 4, 1},
            {88, 0, 14, 2, 1},
            {30, 0, 15, 4, 1},
            {54, 0, 17, 6, 1},
            {0, 0, 11, 1, 1},
            {72, 0, 15, 6, 1},
            {34, 1, 17, 8, 1},
            {126, 0, 12, 3, 1},
            {86, 1, 18, 10, 1},
            {28, 0, 9, 1, 1},
            {32, 0, 13, 5, 1},
            {8, 1, 7, 0, 1},
            {121, 0, 15, 8, 1},
            {114, 0, 10, 3, 1},
            {92, 0, 16, 10, 1},
            {110, 0, 11, 5, 1},
            {58, 0, 13, 7, 1},
            {19, 0, 8, 3, 1},
            {6, 0, 6, 2, 1},
            {78, 0, 14, 10, 1},
            {139, 0, 9, 5, 1},
            {138, 0, 11, 7, 1},
            {103, 0, 12, 9, 1},
            {64, 0, 4, 2, 1},
            {21, 0, 7, 5, 1},
            {66, 0, 9, 7, 1},
            {51, 1, 13, 12, 1},
            {36, 0, 5, 4, 1},
            {108, 0, 10, 9, 1},
            {128, 1, 2, 2, 1},
            {20, 0, 7, 7, 1},
            {143, 0, 11, 11, 1},
            {43, 1, 3, 4, 1},
            {12, 0, 5, 6, 1},
            {116, 0, 8, 9, 1},
            {91, 0, 9, 11, 1},
            {113, 0, 3, 6, 1},
            {82, 0, 5, 8, 1},
            {120, 0, 6, 10, 1},
            {134, 1, 7, 12, 1},
            {94, 1, 3, 8, 1},
            {100, 0, 4, 10, 1},
            {42, 1, 2, 10, 1},
            {16, 1, 15, 4, 2},
            {90, 0, 16, 6, 2},
            {3, 0, 13, 4, 2},
            {102, 0, 14, 6, 2},
            {71, 0, 11, 4, 2},
            {136, 1, 15, 8, 2},
            {24, 0, 12, 6, 2},
            {44, 0, 9, 4, 2},
            {39, 0, 13, 8, 2},
            {18, 0, 10, 6, 2},
            {70, 0, 7, 4, 2},
            {75, 0, 11, 8, 2},
            {56, 0, 8, 6, 2},
            {142, 1, 5, 4, 2},
            {48, 0, 9, 8, 2},
            {52, 0, 6, 6, 2},
            {26, 0, 7, 8, 2},
            {14, 0, 4, 6, 2},
            {11, 1, 5, 8, 2},
            {132, 1, 15, 6, 3},
            {106, 0, 13, 5, 3},
            {38, 0, 11, 5, 3},
            {96, 0, 13, 7, 3},
            {74, 0, 9, 5, 3},
            {123, 0, 11, 7, 3},
            {2, 0, 7, 5, 3},
            {122, 0, 9, 7, 3},
            {10, 0, 7, 7, 3},
            {50, 1, 5, 6, 3},
            {124, 0, 12, 6, 4},
            {80, 0, 10, 6, 4},
            {112, 0, 8, 6, 4},
            {104, 0, 11, 6, 5},
            {98, 0, 9, 6, 5},
            {84, 1, 10, 6, 6},
        }
    );
}

private void test_game_init () {
    var game = generate_game ();

    // Verify initial game state
    assert_true (game.map != null);
    assert_true (game.tiles.length () == 144);
    assert_false (game.started);
    assert_true (game.elapsed == 0.0);
    assert_false (game.paused);
    assert_true (game.selected_tile == null);
    assert_true (game.moves_left > 0);
    assert_false (game.complete);
    assert_true (game.can_move);
    assert_true (game.can_shuffle);
    assert_false (game.can_undo);
    assert_false (game.can_redo);
    assert_false (game.all_tiles_unblocked);

    // Verify tile states
    foreach (unowned var tile in game.tiles) {
        assert_true (tile.visible);
        assert_false (tile.highlighted);
        assert_true (tile.move_number == 0);
    }
}

private void test_game_restart () {
    var game = generate_game ();
    assert_true (game.moves_left == 17);

    // Remove tile pair
    var match = game.next_hint ();
    assert_true (match != null);
    game.remove_pair (match.tile0, match.tile1);
    assert_false (match.tile0.visible);
    assert_false (match.tile1.visible);
    assert_true (game.moves_left == 14);

    // Select a tile
    var second_match = game.next_hint ();
    game.selected_tile = second_match.tile0;

    // Verify game state reset after restart
    game.restart ();
    assert_true (match.tile0.visible);
    assert_true (match.tile1.visible);
    foreach (var tile in game.tiles)
        assert_true (tile.visible);
    assert_true (game.selected_tile == null);
    assert_true (game.moves_left == 17);
}

private void test_game_playthrough () {
    var game = generate_game ();

    assert_false (game.started);
    assert_true (game.elapsed == 0.0);

    int expected_move_number = 0;
    int num_moves = 0;
    int num_reshuffles = 0;
    int[,] tile_numbers = {
        {90, 89},
        {84, 87},
        {100, 101},
        {42, 43},
        {6, 7},
        {132, 134},
        {0, 1},
        {77, 79},
        {34, 35},
        {106, 104},
        {64, 65},
        {82, 80},
        {93, 95},
        {88, 91},
        {12, 13},
        {122, 121},
        {50, 51},
        {98, 96},
        {128, 129},
        {9, 11},
        {133, 135},
        {136, 137},
        {52, 55},
        {72, 75},
        {37, 39},
        {54, 53},
        {92, 94},
        {124, 126},
        {30, 31},
        {123, 120},
        {62, 60},
        {40, 41},
        {102, 103},
        {68, 71},
        {48, 49},
        {0, 1},
        {64, 65},
        {32, 33},
        {112, 113},
        {72, 73},
        {23, 21},
        {46, 47},
        {68, 69},
        {26, 25},
        {76, 77},
        {20, 22},
        {116, 117},
        {60, 61},
        {110, 111},
        {80, 81},
        {12, 13},
        {124, 125},
        {128, 129},
        {58, 59},
        {114, 115},
        {108, 109},
        {118, 119},
        {84, 85},
        {36, 37},
        {136, 137},
        {16, 17},
        {140, 141},
        {24, 27},
        {4, 5},
        {28, 29},
        {104, 105},
        {44, 45},
        {96, 97},
        {56, 57},
        {142, 143},
        {8, 9},
        {18, 19},
    };

    while (!game.complete) {
        assert_false (game.complete);
        assert_true (num_moves < tile_numbers.length[0]);

        if (!game.can_move) {
            game.shuffle_remaining ();
            expected_move_number = 0;
            num_reshuffles++;
        }

        var match = game.next_hint ();
        assert_true (match != null);

        assert_true (match.tile0.selectable && match.tile1.selectable);
        assert_true (match.tile0.visible && match.tile1.visible);
        assert_true (match.tile0 != match.tile1);
        assert_false (game.inspecting);

        game.remove_pair (match.tile0, match.tile1);
        assert_true (match.tile0.number == tile_numbers[num_moves, 0]);
        assert_true (match.tile1.number == tile_numbers[num_moves, 1]);
        assert_true (game.started);

        expected_move_number++;
        num_moves++;

        assert_false (match.tile0.selectable || match.tile1.selectable);
        assert_false (match.tile0.visible || match.tile1.visible);

        assert_true (match.tile0.move_number == expected_move_number);
        assert_true (match.tile1.move_number == expected_move_number);

        assert_true (game.can_undo);
        assert_false (game.can_redo);
    }

    // Verify final game state
    assert_true (game.complete);
    assert_true (game.elapsed > 0.0);
    assert_true (game.moves_left == 0);
    assert_true (game.next_hint () == null);
    assert_true (game.inspecting);
    assert_false (game.can_move);
    assert_false (game.can_shuffle);
    assert_true (game.can_undo);
    assert_false (game.can_redo);
    assert_true (game.all_tiles_unblocked);

    // Verify performed moves
    assert_true (expected_move_number == 37);
    assert_true (num_moves == 72);
    assert_true (num_reshuffles == 1);
}

public int main (string[] args) {
    Test.init (ref args);
    Test.add_func ("/game/tile_highlighted", test_tile_highlighted);
    Test.add_func ("/game/remove_invalid_pair", test_remove_invalid_pair);
    Test.add_func ("/game/remove_valid_pair", test_remove_valid_pair);
    Test.add_func ("/game/next_hint", test_next_hint);
    Test.add_func ("/game/shuffle_remaining", test_shuffle_remaining);
    Test.add_func ("/game/undo_redo", test_undo_redo);
    Test.add_func ("/game/undo_redo_no_moves", test_undo_redo_no_moves);
    Test.add_func ("/game/seed_reproducibility", test_seed_reproducibility);
    Test.add_func ("/game/seed_difference", test_seed_difference);
    Test.add_func ("/game/seed_snapshot_turtle", test_seed_snapshot_turtle);
    Test.add_func ("/game/seed_snapshot_difficult", test_seed_snapshot_difficult);
    Test.add_func ("/game/game_init", test_game_init);
    Test.add_func ("/game/game_restart", test_game_restart);
    Test.add_func ("/game/game_playthrough", test_game_playthrough);

    return Test.run ();
}
