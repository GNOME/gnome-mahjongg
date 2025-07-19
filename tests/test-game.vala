// SPDX-FileCopyrightText: 2025 Mahjongg Contributors
// SPDX-License-Identifier: GPL-2.0-or-later

private Game generate_game (owned Map? map = null, int32 seed = 123456) {
    if (map == null) {
        var maps = new Maps ();
        maps.load ();
        map = maps.get_map_at_position (0);
    }

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
    var tile_a = game.get_tile (0);
    var tile_b = game.get_tile (1);
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
        {104, 107},
        {106, 107},
        {52, 53},
        {62, 63},
        {106, 104},
        {83, 80},
        {82, 80},
        {82, 83},
        {118, 119},
        {132, 133},
        {136, 137},
        {50, 51},
        {15, 13},
        {94, 95},
        {107, 105},
        {104, 105},
        {106, 105},

        // Second cycle
        {104, 107},
        {106, 107},
        {52, 53},
        {62, 63},
        {106, 104},
        {83, 80},
        {82, 80},
        {82, 83},
        {118, 119},
        {132, 133},
        {136, 137},
        {50, 51},
        {15, 13},
        {94, 95},
        {107, 105},
        {104, 105},
        {106, 105},
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
    var tile_number = game.get_tile (0).number;

    game.shuffle_remaining ();
    assert_true (game.get_tile (0).number != tile_number);
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
    assert_true (first_match.tile0.move == 1 && first_match.tile1.move == 1);
    assert_true (second_match.tile0.move == 2 && second_match.tile1.move == 2);

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
    assert_true (first_match.tile0.move == 1 && first_match.tile1.move == 1);
    assert_true (second_match.tile0.move == 2 && second_match.tile1.move == 2);

    // Verify tile state reset
    var third_match = game.next_hint ();
    assert_true (third_match != null);
    game.remove_pair (third_match.tile0, third_match.tile1);

    assert_true (game.can_undo);
    assert_false (game.can_redo);
    assert_true (first_match.tile0.move == 0 && first_match.tile1.move == 0);
    assert_true (second_match.tile0.move == 0 && second_match.tile1.move == 0);
    assert_true (third_match.tile0.move == 1 && third_match.tile1.move == 1);
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

    assert_true (game1.n_tiles == game2.n_tiles);

    for (int i = 0; i < game1.n_tiles; i++) {
        var tile1 = game1.get_tile (i);
        var tile2 = game2.get_tile (i);

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

    for (int i = 0; i < game1.n_tiles; i++) {
        var tile1 = game1.get_tile (i);
        var tile2 = game2.get_tile (i);

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

private void verify_tiles (Game game, int[,] expected_layout) {
    for (int i = 0; i < expected_layout.length[0]; i++) {
        var tile = game.get_tile (i);

        assert_true (tile.visible);
        assert_false (tile.highlighted);
        assert_true (tile.move == 0);

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
        game,
        {
            {35, 1, 24, 0, 0},
            {29, 0, 22, 0, 0},
            {51, 1, 28, 7, 0},
            {61, 0, 20, 0, 0},
            {57, 0, 26, 7, 0},
            {23, 0, 18, 0, 0},
            {89, 1, 20, 2, 0},
            {13, 1, 22, 4, 0},
            {25, 0, 24, 6, 0},
            {33, 0, 16, 0, 0},
            {39, 0, 18, 2, 0},
            {55, 0, 20, 4, 0},
            {141, 0, 22, 6, 0},
            {28, 0, 24, 8, 0},
            {9, 0, 14, 0, 0},
            {43, 0, 16, 2, 0},
            {37, 0, 18, 4, 0},
            {79, 0, 20, 6, 0},
            {60, 0, 22, 8, 0},
            {73, 0, 12, 0, 0},
            {125, 0, 14, 2, 0},
            {97, 0, 16, 4, 0},
            {3, 0, 18, 6, 0},
            {127, 0, 20, 8, 0},
            {15, 1, 22, 10, 0},
            {129, 0, 10, 0, 0},
            {59, 0, 12, 2, 0},
            {17, 0, 14, 4, 0},
            {11, 0, 16, 6, 0},
            {113, 0, 18, 8, 0},
            {67, 0, 20, 10, 0},
            {95, 1, 24, 14, 0},
            {117, 0, 8, 0, 0},
            {31, 0, 10, 2, 0},
            {75, 0, 12, 4, 0},
            {16, 0, 14, 6, 0},
            {5, 0, 16, 8, 0},
            {112, 0, 18, 10, 0},
            {105, 1, 20, 12, 0},
            {124, 0, 22, 14, 0},
            {56, 0, 6, 0, 0},
            {123, 0, 8, 2, 0},
            {8, 0, 10, 4, 0},
            {49, 0, 12, 6, 0},
            {93, 0, 14, 8, 0},
            {48, 0, 16, 10, 0},
            {115, 0, 18, 12, 0},
            {47, 0, 20, 14, 0},
            {81, 0, 4, 0, 0},
            {94, 1, 6, 2, 0},
            {122, 0, 8, 4, 0},
            {41, 0, 10, 6, 0},
            {10, 0, 12, 8, 0},
            {4, 0, 14, 10, 0},
            {72, 0, 16, 12, 0},
            {135, 0, 18, 14, 0},
            {107, 1, 2, 0, 0},
            {101, 0, 6, 4, 0},
            {42, 0, 8, 6, 0},
            {126, 0, 10, 8, 0},
            {96, 0, 12, 10, 0},
            {7, 0, 14, 12, 0},
            {139, 0, 16, 14, 0},
            {85, 1, 4, 4, 0},
            {1, 0, 6, 6, 0},
            {27, 0, 8, 8, 0},
            {138, 0, 10, 10, 0},
            {40, 0, 12, 12, 0},
            {134, 0, 14, 14, 0},
            {69, 0, 4, 6, 0},
            {116, 0, 6, 8, 0},
            {46, 0, 8, 10, 0},
            {143, 0, 10, 12, 0},
            {99, 0, 12, 14, 0},
            {88, 0, 2, 6, 0},
            {131, 0, 4, 8, 0},
            {2, 0, 6, 10, 0},
            {14, 0, 8, 12, 0},
            {58, 0, 10, 14, 0},
            {71, 0, 2, 8, 0},
            {53, 1, 4, 10, 0},
            {68, 1, 6, 12, 0},
            {74, 0, 8, 14, 0},
            {114, 1, 0, 7, 0},
            {91, 0, 6, 14, 0},
            {66, 0, 4, 14, 0},
            {52, 1, 2, 14, 0},
            {24, 1, 18, 2, 1},
            {87, 0, 16, 2, 1},
            {109, 1, 18, 4, 1},
            {90, 0, 14, 2, 1},
            {92, 0, 16, 4, 1},
            {45, 1, 18, 6, 1},
            {32, 0, 12, 2, 1},
            {6, 0, 14, 4, 1},
            {103, 0, 16, 6, 1},
            {50, 1, 18, 8, 1},
            {19, 0, 10, 2, 1},
            {22, 0, 12, 4, 1},
            {30, 0, 14, 6, 1},
            {78, 0, 16, 8, 1},
            {121, 1, 18, 10, 1},
            {63, 1, 8, 2, 1},
            {18, 0, 10, 4, 1},
            {21, 0, 12, 6, 1},
            {0, 0, 14, 8, 1},
            {12, 0, 16, 10, 1},
            {104, 1, 18, 12, 1},
            {80, 1, 8, 4, 1},
            {77, 0, 10, 6, 1},
            {26, 0, 12, 8, 1},
            {36, 0, 14, 10, 1},
            {128, 0, 16, 12, 1},
            {38, 1, 8, 6, 1},
            {108, 0, 10, 8, 1},
            {142, 0, 12, 10, 1},
            {65, 0, 14, 12, 1},
            {83, 1, 8, 8, 1},
            {84, 0, 10, 10, 1},
            {102, 0, 12, 12, 1},
            {119, 1, 8, 10, 1},
            {20, 0, 10, 12, 1},
            {82, 1, 8, 12, 1},
            {98, 1, 16, 4, 2},
            {54, 0, 14, 4, 2},
            {62, 1, 16, 6, 2},
            {120, 0, 12, 4, 2},
            {64, 0, 14, 6, 2},
            {76, 1, 16, 8, 2},
            {133, 1, 10, 4, 2},
            {34, 0, 12, 6, 2},
            {44, 0, 14, 8, 2},
            {137, 1, 16, 10, 2},
            {136, 1, 10, 6, 2},
            {111, 0, 12, 8, 2},
            {100, 0, 14, 10, 2},
            {106, 1, 10, 8, 2},
            {86, 0, 12, 10, 2},
            {132, 1, 10, 10, 2},
            {130, 0, 14, 6, 3},
            {140, 0, 12, 6, 3},
            {110, 0, 14, 8, 3},
            {70, 0, 12, 8, 3},
            {118, 1, 13, 7, 4},
        }
    );
}

private void test_seed_snapshot_taipei () {
    var maps = new Maps ();
    maps.load ();
    assert_true (maps.n_maps >= 1);

    var taipei_map = maps.get_map_at_position (maps.n_maps - 1);
    var game = generate_game (taipei_map);

    verify_tiles (
        game,
        {
            {71, 0, 19, 1, 0},
            {77, 0, 17, 1, 0},
            {141, 0, 19, 3, 0},
            {129, 0, 14, 0, 0},
            {117, 0, 17, 3, 0},
            {83, 1, 20, 6, 0},
            {85, 0, 15, 2, 0},
            {53, 0, 18, 5, 0},
            {79, 0, 12, 0, 0},
            {113, 0, 13, 2, 0},
            {5, 0, 16, 5, 0},
            {21, 0, 18, 7, 0},
            {87, 0, 10, 0, 0},
            {135, 0, 14, 4, 0},
            {29, 0, 19, 9, 0},
            {17, 0, 11, 2, 0},
            {47, 0, 16, 7, 0},
            {109, 0, 8, 0, 0},
            {97, 0, 12, 4, 0},
            {16, 0, 14, 6, 0},
            {27, 0, 17, 9, 0},
            {15, 0, 19, 11, 0},
            {127, 0, 9, 2, 0},
            {105, 0, 6, 0, 0},
            {134, 0, 10, 4, 0},
            {4, 0, 12, 6, 0},
            {139, 0, 14, 8, 0},
            {19, 0, 17, 11, 0},
            {33, 0, 7, 2, 0},
            {37, 0, 15, 10, 0},
            {49, 0, 8, 4, 0},
            {93, 0, 10, 6, 0},
            {96, 0, 12, 8, 0},
            {123, 0, 5, 2, 0},
            {43, 0, 13, 10, 0},
            {101, 0, 3, 1, 0},
            {92, 0, 6, 4, 0},
            {126, 0, 8, 6, 0},
            {138, 0, 10, 8, 0},
            {115, 0, 14, 12, 0},
            {59, 0, 11, 10, 0},
            {25, 0, 1, 1, 0},
            {111, 0, 3, 3, 0},
            {58, 0, 6, 6, 0},
            {46, 0, 8, 8, 0},
            {131, 0, 12, 12, 0},
            {143, 0, 4, 5, 0},
            {99, 0, 9, 10, 0},
            {133, 0, 1, 3, 0},
            {11, 0, 6, 8, 0},
            {110, 0, 10, 12, 0},
            {14, 0, 2, 5, 0},
            {142, 0, 4, 7, 0},
            {32, 0, 7, 10, 0},
            {35, 0, 8, 12, 0},
            {1, 0, 2, 7, 0},
            {73, 0, 5, 10, 0},
            {70, 1, 0, 6, 0},
            {0, 0, 3, 9, 0},
            {52, 0, 6, 12, 0},
            {57, 0, 1, 9, 0},
            {18, 0, 3, 11, 0},
            {122, 0, 1, 11, 0},
            {107, 1, 18, 2, 1},
            {137, 0, 16, 2, 1},
            {34, 1, 13, 0, 1},
            {114, 1, 17, 4, 1},
            {81, 0, 14, 2, 1},
            {140, 0, 15, 4, 1},
            {121, 0, 17, 6, 1},
            {132, 0, 11, 1, 1},
            {41, 0, 12, 3, 1},
            {48, 0, 15, 6, 1},
            {89, 1, 17, 8, 1},
            {95, 0, 9, 1, 1},
            {112, 0, 13, 5, 1},
            {86, 1, 18, 10, 1},
            {51, 1, 7, 0, 1},
            {55, 0, 10, 3, 1},
            {82, 0, 15, 8, 1},
            {125, 0, 11, 5, 1},
            {10, 0, 13, 7, 1},
            {28, 0, 16, 10, 1},
            {26, 0, 8, 3, 1},
            {39, 0, 6, 2, 1},
            {98, 0, 9, 5, 1},
            {40, 0, 11, 7, 1},
            {13, 0, 14, 10, 1},
            {23, 0, 12, 9, 1},
            {24, 0, 4, 2, 1},
            {75, 0, 7, 5, 1},
            {22, 0, 9, 7, 1},
            {63, 0, 5, 4, 1},
            {74, 0, 10, 9, 1},
            {50, 1, 13, 12, 1},
            {130, 1, 2, 2, 1},
            {3, 0, 7, 7, 1},
            {104, 0, 11, 11, 1},
            {119, 1, 3, 4, 1},
            {91, 0, 5, 6, 1},
            {2, 0, 8, 9, 1},
            {88, 0, 9, 11, 1},
            {100, 0, 3, 6, 1},
            {45, 0, 5, 8, 1},
            {120, 0, 6, 10, 1},
            {76, 1, 3, 8, 1},
            {44, 1, 7, 12, 1},
            {84, 0, 4, 10, 1},
            {62, 1, 2, 10, 1},
            {118, 1, 15, 4, 2},
            {38, 0, 16, 6, 2},
            {124, 0, 13, 4, 2},
            {7, 0, 14, 6, 2},
            {31, 0, 11, 4, 2},
            {94, 1, 15, 8, 2},
            {6, 0, 12, 6, 2},
            {67, 0, 9, 4, 2},
            {36, 0, 13, 8, 2},
            {9, 0, 10, 6, 2},
            {103, 0, 7, 4, 2},
            {8, 0, 11, 8, 2},
            {72, 0, 8, 6, 2},
            {80, 1, 5, 4, 2},
            {54, 0, 9, 8, 2},
            {65, 0, 6, 6, 2},
            {61, 0, 7, 8, 2},
            {69, 0, 4, 6, 2},
            {56, 1, 5, 8, 2},
            {136, 1, 15, 6, 3},
            {42, 0, 13, 5, 3},
            {12, 0, 11, 5, 3},
            {90, 0, 13, 7, 3},
            {128, 0, 9, 5, 3},
            {60, 0, 11, 7, 3},
            {78, 0, 7, 5, 3},
            {30, 0, 9, 7, 3},
            {66, 0, 7, 7, 3},
            {106, 1, 5, 6, 3},
            {64, 0, 12, 6, 4},
            {102, 0, 10, 6, 4},
            {20, 0, 8, 6, 4},
            {116, 0, 11, 6, 5},
            {68, 0, 9, 6, 5},
            {108, 1, 10, 6, 6},
        }
    );
}

private void test_game_init () {
    var game = generate_game ();

    // Verify initial game state
    assert_true (game.map != null);
    assert_true (game.n_tiles == 144);
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
    foreach (unowned var tile in game) {
        assert_true (tile.visible);
        assert_false (tile.highlighted);
        assert_true (tile.move == 0);
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
    assert_true (game.moves_left == 15);

    // Select a tile
    var second_match = game.next_hint ();
    game.selected_tile = second_match.tile0;

    // Verify game state reset after restart
    game.restart ();
    assert_true (match.tile0.visible);
    assert_true (match.tile1.visible);
    foreach (var tile in game)
        assert_true (tile.visible);
    assert_true (game.selected_tile == null);
    assert_true (game.moves_left == 17);
}

private void test_game_playthrough () {
    var game = generate_game ();

    assert_false (game.started);
    assert_true (game.elapsed == 0.0);

    int expected_move = 0;
    int num_moves = 0;
    int num_reshuffles = 0;
    int[,] tile_numbers = {
        {104, 107},
        {94, 95},
        {82, 83},
        {118, 119},
        {62, 63},
        {132, 133},
        {80, 81},
        {84, 85},
        {18, 19},
        {120, 123},
        {50, 51},
        {70, 68},
        {54, 52},
        {110, 109},
        {14, 13},
        {32, 35},
        {53, 55},
        {106, 105},
        {56, 57},
        {136, 137},
        {100, 101},
        {111, 108},
        {38, 37},
        {90, 89},
        {114, 115},
        {44, 45},
        {130, 128},
        {26, 25},
        {31, 29},
        {121, 122},
        {12, 15},
        {65, 67},
        {86, 87},
        {140, 142},
        {20, 22},
        {76, 77},
        {102, 103},
        {0, 2},
        {64, 66},
        {91, 88},
        {143, 141},
        {74, 72},
        {78, 79},
        {58, 59},
        {71, 69},
        {30, 28},
        {60, 61},
        {127, 125},
        {112, 113},
        {98, 99},
        {6, 5},
        {1, 3},
        {8, 11},
        {92, 93},
        {42, 43},
        {40, 41},
        {44, 45},
        {8, 9},
        {36, 37},
        {128, 129},
        {136, 137},
        {124, 125},
        {24, 25},
        {72, 73},
        {96, 97},
        {4, 5},
        {16, 17},
        {48, 49},
        {132, 133},
        {20, 21},
        {32, 33},
        {116, 117},
    };

    while (!game.complete) {
        assert_false (game.complete);
        assert_true (num_moves < tile_numbers.length[0]);

        if (!game.can_move) {
            game.shuffle_remaining ();
            expected_move = 0;
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

        expected_move++;
        num_moves++;

        assert_false (match.tile0.selectable || match.tile1.selectable);
        assert_false (match.tile0.visible || match.tile1.visible);

        assert_true (match.tile0.move == expected_move);
        assert_true (match.tile1.move == expected_move);

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
    assert_true (expected_move == 16);
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
    Test.add_func ("/game/seed_snapshot_taipei", test_seed_snapshot_taipei);
    Test.add_func ("/game/game_init", test_game_init);
    Test.add_func ("/game/game_restart", test_game_restart);
    Test.add_func ("/game/game_playthrough", test_game_playthrough);

    return Test.run ();
}
