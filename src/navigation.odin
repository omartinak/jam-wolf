package game

Vec2i :: [2]i32

Nav_Data :: struct {
    start: Vec2i,
    end: Vec2i,
//    edges: [3654][2]Vec2i,
    edges: [dynamic][2]Vec2i,
    path: [dynamic]Vec2i,
}

adj :: proc(tile: Vec2i, visited: []Vec2i) -> [dynamic]Vec2i {
    ret := make([dynamic]Vec2i, 0, 8, context.temp_allocator)
//    atiles: [8]Vec2i = {
//        {tile.x - 1, tile.y - 1},
//        {tile.x - 1, tile.y    },
//        {tile.x - 1, tile.y + 1},
//        {tile.x    , tile.y - 1},
//        {tile.x    , tile.y + 1},
//        {tile.x + 1, tile.y - 1},
//        {tile.x + 1, tile.y    },
//        {tile.x + 1, tile.y + 1},
//    }
    atiles: [8]Vec2i = {
        {tile.x - 1, tile.y    },
        {tile.x    , tile.y - 1},
        {tile.x    , tile.y + 1},
        {tile.x + 1, tile.y    },
        {tile.x - 1, tile.y - 1},
        {tile.x - 1, tile.y + 1},
        {tile.x + 1, tile.y - 1},
        {tile.x + 1, tile.y + 1},
    }

    for at, _ in atiles {
        wall := is_wall(gs.level, at)
        // TODO: it sometimes finds path across corners
        // Avoid corners
//        switch i {
//        case 4: if is_wall(at.x - 1, at.y) || is_wall(at.x, at.y - 1) do wall = true
//        case 5: if is_wall(at.x - 1, at.y) || is_wall(at.x, at.y + 1) do wall = true
//        case 6: if is_wall(at.x + 1, at.y) || is_wall(at.x, at.y - 1) do wall = true
//        case 7: if is_wall(at.x + 1, at.y) || is_wall(at.x, at.y + 1) do wall = true
//        }

        vis: bool
        for vt in visited {
            if at == vt {
                vis = true
                break
            }
        }

        if !wall && !vis do append(&ret, at)
    }

    return ret
}

bfs :: proc(start, end: Vec3, nav_data: ^Nav_Data) {
    // TODO: helper procs for converting Vec3 <=> Tile
    nav_data.start = [2]i32{i32(start.x), i32(start.z)}
    nav_data.end = [2]i32{i32(end.x), i32(end.z)}

    if nav_data.start == nav_data.end {
        clear(&nav_data.edges)
        clear(&nav_data.path)
        return
    }

    nav_data.edges = make([dynamic][2]Vec2i, context.temp_allocator)

    // TODO: default allocator temp?
    // TODO: don't reallocate, store in nav_data and share
    visited := make([dynamic]Vec2i, context.temp_allocator)
    queue := make([dynamic]Vec2i, context.temp_allocator)

    append(&visited, nav_data.start)
    append(&queue, nav_data.start)

    outer: for len(queue) > 0 {
        tile := pop_front(&queue)
        atiles := adj(tile, visited[:])
        for at in atiles {
            edge := [2]Vec2i{tile, at}
            append(&nav_data.edges, edge)
            append(&visited, at)
            append(&queue, at)
            if at == nav_data.end do break outer
        }
    }

    // TODO: store indices
    nav_data.path = make([dynamic]Vec2i, context.temp_allocator) // TODO: init with len
    inject_at(&nav_data.path, 0, nav_data.end)
    cur := nav_data.end
    found: bool = true
    for found {
        found = false
        for edge in nav_data.edges {
            if edge[1] == cur {
                found = true
                inject_at(&nav_data.path, 0, edge[0])
                cur = edge[0]
            }
        }
    }
}
