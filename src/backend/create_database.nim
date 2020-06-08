import times, db_sqlite
import ../app_types
import db_crud

# Templates/Helper functions

# quick way of populating database with enum types
template enum_types_to_rows*(d: DbConn, input_enum: untyped, input_enum_name: string) =    
    # loop through each enumeration as a separate row entry to table_name
    for enumerated_state in input_enum.low .. input_enum.high:
        discard d.insertID(sql"INSERT INTO ? (name) VALUES(?)", $input_enum_name, $enumerated_state)


let db = open("./src/backend/v29.db", "", "", "")

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, "movement_plane"
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, "body_area"
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, "movement_type"
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, "movement_category"
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS movement (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    body_area_id INTEGER,
    movement_plane_id INTEGER,
    movement_type_id INTEGER,
    movement_category_id INTEGER,
    movement_combo_id INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS movement_combo  (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    session_order INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS movement_set (
    id INTEGER PRIMARY KEY,
    movement_id INTEGER,
    reps INTEGER,
    movement_order INTEGER,
    intensity TEXT,
    movement_combo_id INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS movement_combo_assignment (
    id INTEGER PRIMARY KEY,
    movement_id INTEGER,
    movement_combo_id INTEGER
    );
    """
    )


# add all enumerated types
db.enum_types_to_rows(MovementPlane, "movement_plane")
db.enum_types_to_rows(BodyArea, "body_area")
db.enum_types_to_rows(MovementType, "movement_type")
db.enum_types_to_rows(MovementCategory, "movement_category")


var
    # populate datatbase with movement metadata
    # Strength A

    split_squat = db.create_movement(Movement(
                                            name: "Bulgarian Split Squat", 
                                            movement_plane: Frontal, 
                                            movement_type: Unilateral,
                                            movement_category: Pull, 
                                            body_area: Upper)
    )

    pullup = db.create_movement(Movement(
                                    name: "Pull-Up", 
                                    movement_plane: Vertical, 
                                    movement_type: Bilateral, 
                                    movement_category: Pull, 
                                    body_area: Upper)
    )


    # Strength B
    ring_dip = db.create_movement(Movement(
                                    name: "Ring Dips", 
                                    movement_plane: Vertical, 
                                    movement_type: Bilateral,
                                    body_area: Upper,
                                    movement_category: Push)
    )

    slrdl = db.create_movement(Movement(
                                name: "Single Leg Romainian Deadlift",
                                movement_category: Hinge,
                                movement_plane: Frontal,
                                movement_type: Unilateral,
                                body_area: Lower
                                )
    )

    scap_pull = db.create_movement(Movement(
                                    name: "Scapular Pull",
                                    movement_plane: Frontal,
                                    movement_type: Unilateral,
                                    body_area: Lower,
                                    movement_category: Pull
                                    )
    )


# db.create_movement_combo(combo_name = "A: Pull-Up + B.Split Squat",
#                     session_order = 1,
#                     movement_ids = pullup_id, b_split_squat_id)

# db.create_movement_combo(combo_name = "B: Ring Dip + SLRDL", 
#                     session_order = 2,
#                     movement_ids = ring_dip_id, slrdl_id)

# db.create_movement_combo(combo_name = "A: Scap-pull + B.Split Squat",
#                     session_order = 1,
#                     movement_ids = scap_pull_id, b_split_squat_id)

# db.read_movement_combo_by_movement(movement_name = "Bulgarian Split Squat")

db.read_movement_by_category(movement_category = Pull)
db.read_movement_by_movement_plane(movement_plane = Vertical)

db.close()