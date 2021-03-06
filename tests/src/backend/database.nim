import times, db_sqlite
import ../app_types
import db_crud

let db = open("./src/backend/v27.db", "", "", "")

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, $MovementPlane
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, $BodyArea
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, $MovementType
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS ? (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE
    );
    """, $MovementCategory
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS Movement (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    body_area_id INTEGER,
    movement_plane_id INTEGER,
    movement_type_id INTEGER,
    movement_category_id INTEGER,
    movement_combo_id INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS MovementCombo  (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    session_order INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS MovementSet (
    id INTEGER PRIMARY KEY,
    movement_id INTEGER,
    reps INTEGER,
    movement_order INTEGER,
    intensity TEXT,
    movement_combo_id INTEGER
    );"""
    )

db.exec(sql"""CREATE TABLE IF NOT EXISTS MovementCombo_Assignment (
    id INTEGER PRIMARY KEY,
    movement_id INTEGER,
    movement_combo_id INTEGER
    );
    """
    )


# add all enumerated types
db.enum_types_to_rows(MovementPlane)
db.enum_types_to_rows(BodyArea)
db.enum_types_to_rows(MovementType)
db.enum_types_to_rows(MovementCategory)


var
    # populate datatbase with movement metadata
    # Strength A

    b_split_squat_id = db.create_movement(name = "Bulgarian Split Squat", 
                                            movement_plane = Frontal, 
                                            movement_type = Unilateral,
                                            movement_category = Pull, 
                                            body_area = Upper)

    pullup_id = db.create_movement(name = "Pull-Up", 
                                    movement_plane = Vertical, 
                                    movement_type = Bilateral, 
                                    movement_category = Pull, 
                                    body_area = Upper)


    # Strength B
    ring_dip_id = db.create_movement(name ="Ring Dips", 
                                    movement_plane = Vertical, 
                                    movement_type = Bilateral,
                                    body_area = Upper,
                                    movement_category = Push
                                    )

    slrdl_id = db.create_movement(name = "Single Leg Romainian Deadlift",
                                movement_category = Hinge,
                                movement_plane = Frontal,
                                movement_type = Unilateral,
                                body_area = Lower
                                )

    scap_pull_id = db.create_movement(name = "Scapular Pull",
                                    movement_plane = Frontal,
                                    movement_type = Unilateral,
                                    body_area = Lower,
                                    movement_category = Pull)


db.create_movement_combo(combo_name = "A: Pull-Up + B.Split Squat",
                    session_order = 1,
                    movement_ids = pullup_id, b_split_squat_id)

db.create_movement_combo(combo_name = "B: Ring Dip + SLRDL", 
                    session_order = 2,
                    movement_ids = ring_dip_id, slrdl_id)

db.create_movement_combo(combo_name = "A: Scap-pull + B.Split Squat",
                    session_order = 1,
                    movement_ids = scap_pull_id, b_split_squat_id)

db.read_movement_combo_by_movement(movement_name = "Bulgarian Split Squat")

db.read_movement_by_category(movement_category = Pull)
db.read_movement_by_movement_plane(movement_plane = Vertical)

db.close()