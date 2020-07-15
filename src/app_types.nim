type
    # cannot convert json datetimes -> nim's DAteTime's data structures (from times module)
    # for more info, see here:
    # https://forum.nim-lang.org/t/4106
    # workaround - use our own custom date object

    Date* = object
        Year*, Month*, Day*, Hour*, Minute*, Second*: int
        day_name: string # ie) "Tuesday"

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

    MovementCombo* = object of Entry
        name*: string

    MovementComboAssignment* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo

    IntensityUnits* = enum
        UnspecifiedIntensityUnit
        Pounds
        Kilograms
        PercentageOfOneRepMax

    Intensity* = object of Entry
        quantity*: float32
        intensity*: IntensityUnits

    Routine* = object of Entry
        name*: string
        user*: User

    Session* = object of Entry
        date*: Date
        routine*: Routine
    
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