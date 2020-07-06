import json

##################
#### ROUTES ######
##################

const
    # GET
    Home* = "/"
    Index* = "/index.html"        
    ReadAllMovement* = "/read_all_movements.json"
    ReadAllMovementAttrs* = "/read_distinct_movement_attributes.json"

    # POST

    # Create
    CreateMovement* = "/create_movement.json"
    CreateMovementCombo* = "/create_movement_combo.json"

##############################
##### APP SPECIFIC TYPES #####
##############################

type

    DataTable* = enum
        MovementTable = "movement"
        MovementComboTable = "movement_combo"
        MovementComboAssignmentTable = "movement_combo_assignment"

    ForeignKey* = enum
        MovementId = "movement_id"
        MovementComboId = "movement_combo_id"

    MovementPlane* = enum
        UnspecifiedPlane
        Horizontal
        Vertical
        Frontal
        Lateral
        MultiPlane
    
    MovementArea* = enum
        UnspecifiedArea
        Upper
        Lower
        Full
    
    ConcentricType* = enum
        UnspecifiedConcentricType
        Push
        Pull
        Squat
        Hinge

    Symmetry* = enum
        UnspecifiedSymmetry
        Unilateral
        Bilateral

    Movement* = object
        name*: string
        plane*: MovementPlane
        area*: MovementArea
        concentric_type*: ConcentricType
        symmetry*: Symmetry

    # Request types
    NewMovementComboRequest* = object
        name*: string
        movement_ids*: seq[int]

when isMainModule:

    var sample = parseJson("""
    [
    "movement_ids" : ["a", 2, 4],
    "name" : "some_name",
    "*" : "%",
    "hostile" : "parameters"
    }
    """)

    var new_movement = sample.to(NewMovementComboRequest)
    echo new_movement
    for new_id in new_movement.movement_ids:
        echo new_id