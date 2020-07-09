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

    # Update
    UpdateMovement* = "/update_movement.json"

##############################
##### APP SPECIFIC TYPES #####
##############################

type
    User* = object of RootObj
        name*: string
        email*: string
    
    ExistingUser* = object of User
        id*: int

    DataTable* = enum
        UserTable = "user"
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

    Movement* = object of RootObj
        name*: string
        plane*: MovementPlane
        area*: MovementArea
        concentric_type*: ConcentricType
        symmetry*: Symmetry
        description*: string

    ExistingMovement* = object of Movement
        id*: int

    MovementCombo* = object
        name*: string

    MovementComboAssignment* = object
        movement_id*, movement_combo_id*: int

    NewMovementComboRequest* = object
        movement_combo*: MovementCombo
        movement_ids*: seq[int]