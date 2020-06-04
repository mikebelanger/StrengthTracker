import ../app_types, db_sqlite, sequtils


# CREATE
template enum_types_to_rows*(d: DbConn, input_enum: untyped) =    
    # loop through each enumeration as a separate row entry to table_name
    for enumerated_state in input_enum.low .. input_enum.high:
        discard d.insertID(sql"INSERT INTO ? (name) VALUES(?)", movement.input_enum, movement.enumerated_state)


proc is_not_blank(x: string): bool =
    return x != ""

proc create_movement*(d: DbConn, movement: Movement): int64 =

    var 
        movement_plane_id = d.getValue(query = sql"SELECT id FROM MovementPlane WHERE name = ?;", movement.movement_plane)
        movement_category_id = d.getValue(query = sql"SELECT id FROM MovementCategory WHERE name = ?;", movement.movement_category)
        movement_type_id = d.getValue(query = sql"SELECT id FROM MovementType WHERE name = ?;", movement.movement_type)
        body_area_id = d.getValue(query = sql"SELECT id FROM BodyArea WHERE name = ?;", movement.body_area)
        necessary_ids = @[movement_plane_id, movement_category_id, movement_type_id, body_area_id]
    
    # if there's entries for each of the movement's tables, then insert
    if all(necessary_ids, is_not_blank):

        var new_movement_id = d.insertID(sql"""INSERT INTO movement (name, movement_plane_id, movement_type_id, body_area_id, movement_category_id)
                                                VALUES(?, ?, ?, ?, ?);""", movement.name, movement_plane_id, movement_type_id, body_area_id, movement_category_id)

        return new_movement_id

    else:
        echo "movement input is not valid"
        return 0

proc create_movement_combo*(d: DbConn, combo_name: string, session_order: int, movement_ids: varargs[int64]) =

    var new_combo_id = d.insertID(sql"INSERT INTO MovementCombo (name, session_order) VALUES (?, ?)", combo_name, session_order)

    if is_not_blank($new_combo_id):

        for m_id in movement_ids:
                # create an assignment between Movement and MovementCombo
                # so Movement <-> MovementCombo_Assignment <-> MovementCombo
            
            discard d.insertID(sql"""INSERT INTO MovementCombo_Assignment (movement_id, movement_combo_id) 
                                    VALUES (?, ?)""", m_id, new_combo_id)


# READ
proc read_movement_combo_by_movement*(d: DbConn, movement_name: string): seq[Row] =
    
    return d.getAllRows(query = sql"""SELECT * FROM MovementCombo WHERE id IN (
                                    SELECT movement_combo_id FROM MovementCombo_Assignment WHERE movement_id IN (
                                    SELECT id FROM Movement WHERE name = ?));""", movement_name)

proc read_movement_by_category*(d: DbConn, movement_category: MovementCategory) =

    var rows = d.getAllRows(sql"""SELECT Movement.name, MovementCategory.name, MovementType.name, MovementPlane.name, BodyArea.name
                                  FROM Movement, MovementCategory, MovementType, MovementPlane, BodyArea WHERE
                                  Movement.movement_category_id = MovementCategory.id AND
                                  MovementCategory.name = ? AND
                                  MovementType.id = Movement.movement_type_id AND
                                  MovementPlane.id = Movement.movement_plane_id AND
                                  BodyArea.id = Movement.body_area_id;""", 
                                  $movement_category)
    echo rows

proc read_movement_by_movement_plane*(d: DbConn, movement_plane: MovementPlane) =

    var rows = d.getAllRows(sql"""SELECT Movement.name, MovementCategory.name, MovementType.name, MovementPlane.name, BodyArea.name
                                  FROM Movement, MovementCategory, MovementType, MovementPlane, BodyArea WHERE
                                  Movement.movement_category_id = MovementCategory.id AND
                                  MovementType.id = Movement.movement_type_id AND
                                  MovementPlane.name = ? AND
                                  MovementPlane.id = Movement.movement_plane_id AND
                                  BodyArea.id = Movement.body_area_id;""", 
                                  $movement_plane)
    echo rows