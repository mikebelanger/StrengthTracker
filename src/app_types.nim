type
    # cannot convert json datetimes -> nim's DAteTime's data structures (from times module)
    # for more info, see here:
    # https://forum.nim-lang.org/t/4106
    # workaround - use our own custom date object

    YYYYMMDD* = object
        Year*, Month*, Day*: int

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

    EntryKind* = enum
        New
        Existing

    Entry* = object of RootObj
        case kind*: EntryKind
            of New: nil
            of Existing: id*: Positive

    User* = object of Entry
        name*: string
        email*: string

    Movement* = object of Entry
        name*: string
        plane*: MovementPlane
        area*: MovementArea
        concentric_type*: ConcentricType
        symmetry*: Symmetry
        description*: string

    Session* = object of Entry
        session_date*: YYYYMMDD
        routine*: Routine

    MovementCombo* = object of Entry
        name*: string

    Routine* = object of Entry
        name*: string
        active*: bool
        user*: User

    MovementComboAssignment* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo

    RoutineAssignment* = object of Entry
        movement_combo*: MovementCombo
        routine*: Routine
        routine_order*: int

    IntensityUnits* = enum
        UnspecifiedIntensityUnit
        Pounds
        Kilograms
        PercentageOfOneRepMax

    Intensity* = object of Entry
        quantity*: float32
        intensity*: IntensityUnits
            
    Minutes* = distinct int

    Set* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo
        reps*: int
        tempo*: string
        intensity*: Intensity
        session*: Session
        duration*: Minutes
        order*: int