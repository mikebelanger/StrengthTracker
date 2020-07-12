import times

type
    NewUser* = object of RootObj
        name*: string
        email*: string
    
    ExistingUser* = object of NewUser
        id*: int

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

    NewMovement* = object of RootObj
        name*: string
        plane*: MovementPlane
        area*: MovementArea
        concentric_type*: ConcentricType
        symmetry*: Symmetry
        description*: string

    ExistingMovement* = object of NewMovement
        id*: int

    NewMovementCombo* = object of RootObj
        name*: string
    
    ExistingMovementCombo* = object of NewMovementCombo
        id*: int

    NewMovementComboAssignment* = object of RootObj
        movement*: ExistingMovement
        movement_combo*: ExistingMovementCombo

    ExistingMovementComboAssignment* = object of NewMovementComboAssignment
        id*: int

    IntensityUnits* = enum
        UnspecifiedIntensityUnit
        Pounds
        Kilograms
        PercentageOfOneRepMax

    Intensity* = object
        quantity*: float32
        intensity*: IntensityUnits

    Routine* = object
        name*: string
        user*: NewUser

    Session* = object
        date*: DateTime
        routine*: Routine
 
    Set* = object
        movement*: ExistingMovement
        movement_combo*: ExistingMovementCombo
        reps*: int
        tempo*: string
        intensity*: Intensity
        session*: Session
        duration*: Duration
        order*: int