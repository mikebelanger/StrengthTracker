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
        movement_plane_id = d.getValue(query = sql"SELECT id FROM MovementPlane WHERE name = ?;", movement.movement_plane)
        movement_category_id = d.getValue(query = sql"SELECT id FROM MovementCategory WHERE name = ?;", movement.movement_category)
        movement_type_id = d.getValue(query = sql"SELECT id FROM MovementType WHERE name = ?;", movement.movement_type)
        body_area_id = d.getValue(query = sql"SELECT id FROM BodyArea WHERE name = ?;", movement.body_area)

    # Enter into SQL safely, and return result from function
    safely_exec_db:
        d.exec(sql"""INSERT INTO movement (name, movement_plane_id, movement_type_id, body_area_id, movement_category_id) 
                                            VALUES(?, ?, ?, ?, ?);""", movement.name, movement_plane_id, movement_type_id, body_area_id, movement_category_id)
        return DbCRUDResult(success: true, 
                            error: "")

proc create_movement_combo*(d: DbConn, combo_name: string, session_order: int, movements: varargs[Movement]): DbCRUDResult =

    safely_exec_db:
        var new_combo_id = d.insertID(sql"INSERT INTO MovementCombo (name, session_order) VALUES (?, ?)", combo_name, session_order)

        if not_blank($new_combo_id):

            for movement in movements:
                    # create an assignment between Movement and MovementCombo
                    # so Movement <-> MovementCombo_Assignment <-> MovementCombo
                
                d.exec(sql"""INSERT INTO MovementCombo_Assignment (movement_id, movement_combo_id)
                            SELECT Movement.id, ?
                            FROM Movement WHERE Movement.name = ?""", new_combo_id, movement.name)

                result.combo_assignments.add(
                    MovementComboAssignment(name: combo_name, movement: movement)
                )


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