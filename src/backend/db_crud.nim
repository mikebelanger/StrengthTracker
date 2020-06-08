import ../app_types, db_sqlite, json

type
    DbCRUDResult* = object
        success*: bool
        rows*: seq[Row]
        movements*: seq[Movement]
        combo_assignments*: seq[MovementComboAssignment]
        error*: string

template safely_exec_db(db_interface_commands: untyped) =
    
    # safely execute SQL statements
    try:
        db_interface_commands
    
    except DbError:
        return DbCRUDResult(success: false, rows: @[@[""]], error: getCurrentExceptionMsg())
    

proc not_blank(x: string): bool =
    return x != ""

# CREATE
proc create_movement*(d: DbConn, movement: Movement): DbCRUDResult =

    var 
        movement_plane_id = d.getValue(query = sql"SELECT id FROM movement_plane WHERE name = ?;", movement.movement_plane)
        movement_category_id = d.getValue(query = sql"SELECT id FROM movement_category WHERE name = ?;", movement.movement_category)
        movement_type_id = d.getValue(query = sql"SELECT id FROM movement_type WHERE name = ?;", movement.movement_type)
        body_area_id = d.getValue(query = sql"SELECT id FROM body_area WHERE name = ?;", movement.body_area)

    # Enter into SQL safely, and return result from function
    safely_exec_db:
        d.exec(sql"""INSERT INTO movement (name, movement_plane_id, movement_type_id, body_area_id, movement_category_id) 
                    VALUES(?, ?, ?, ?, ?);""", movement.name, movement_plane_id, movement_type_id, body_area_id, movement_category_id)
        return DbCRUDResult(success: true, 
                            error: "")

proc create_movement_combo*(d: DbConn, combo_name: string, session_order: int, movements: varargs[Movement]): DbCRUDResult =

    safely_exec_db:
        var new_combo_id = d.insertID(sql"INSERT INTO movement_combo (name, session_order) VALUES (?, ?)", combo_name, session_order)

        if not_blank($new_combo_id):

            for movement in movements:
                    # create an assignment between Movement and MovementCombo
                    # so Movement <-> MovementCombo_Assignment <-> MovementCombo
                
                d.exec(sql"""INSERT INTO movement_combo_assignment (movement_id, movement_combo_id)
                            SELECT movement.id, ?
                            FROM movement WHERE movement.name = ?""", new_combo_id, movement.name)

                result.combo_assignments.add(
                    MovementComboAssignment(name: combo_name, movement: movement)
                )


# READ
proc read_movement_combo_by_movement*(d: DbConn, movement_name: string): seq[Row] =

    return d.getAllRows(query = sql"""SELECT * FROM movement_combo WHERE id IN (
                                    SELECT movement_combo_id FROM movement_combo_assignment WHERE movement_id IN (
                                    SELECT id FROM movement WHERE name = ?));""", movement_name)

proc read_movement_by_category*(d: DbConn, movement_category: MovementCategory) =

    var rows = d.getAllRows(sql"""SELECT movement.name, movement_category.name, movement_type.name, movement_plane.name, body_area.name
                                  FROM movement, movement_category, movement_type, movement_plane, body_area WHERE
                                  Movement.movement_category_id = movement_category.id AND
                                  movement_category.name = ? AND
                                  movement_type.id = movement.movement_type_id AND
                                  movement_plane.id = movement.movement_plane_id AND
                                  body_area.id = movement.body_area_id;""", 
                                  $movement_category)
    echo rows

proc read_movement_by_movement_plane*(d: DbConn, movement_plane: MovementPlane) =

    var rows = d.getAllRows(sql"""SELECT movement.name, movement_category.name, movement_type.name, movement_plane.name, body_area.name
                                  FROM movement, movement_category, movement_type, movement_plane, body_area WHERE
                                  movement.movement_category_id = movement_category.id AND
                                  movement_type.id = movement.movement_type_id AND
                                  movement_plane.name = ? AND
                                  movement_plane.id = movement.movement_plane_id AND
                                  body_area.id = movement.body_area_id;""", 
                                  $movement_plane)
    echo rows

if isMainModule:
    let
        db = open("./src/backend/v27.db", "", "", "")
        b_split_squat = Movement(name: "Bulgarian Split Squat", 
                                movement_plane: Frontal,
                                movement_type: Unilateral,
                                movement_category: Pull, 
                                body_area: Upper)

        pullup = Movement(name: "Pull-Up", 
                        movement_plane: Vertical, 
                        movement_type: Bilateral, 
                        movement_category: Pull, 
                        body_area: Upper)

        movements = @[b_split_squat, pullup]

    var x = db.create_movement_combo(combo_name = "third_combo", 
                                    session_order = 2, 
                                    movements)

    echo x
    echo %*x