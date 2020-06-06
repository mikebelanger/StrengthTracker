import ../app_types, db_sqlite, sequtils

type
    DbCRUDResultKind* = enum
        createSuccess,
        createAlreadyExists,
        createInsufficientInput,
        dbUndefinedError

    DbCRUDResult* = tuple
        feedback_type: DbCRUDResultKind
        feedback_details: string
        db_id: int

template enter_into_db(db_interface_commands: untyped) =
    
    # safely execute SQL statements
    try:
        return (
                feedback_type: createSuccess, 
                feedback_details: "success", 
                db_id: db_interface_commands
        )
    
    except DbError as de:
        return (feedback_type: createAlreadyExists, feedback_details: de.msg, db_id: 0)

    except:
        return (feedback_type: dbUndefinedError, feedback_details: getCurrentExceptionMsg(), db_id: 0)


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
    enter_into_db:
        d.insertID(sql"INSERT INTO movement (name, movement_plane_id, movement_type_id, body_area_id, movement_category_id) VALUES(?, ?, ?, ?, ?);", movement.name, movement_plane_id, movement_type_id, body_area_id, movement_category_id).int


proc create_movement_combo*(d: DbConn, combo_name: string, session_order: int, movement_ids: varargs[int64]) =

    var new_combo_id = d.insertID(sql"INSERT INTO MovementCombo (name, session_order) VALUES (?, ?)", combo_name, session_order)

    if not_blank($new_combo_id):

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