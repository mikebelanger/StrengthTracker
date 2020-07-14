import times

type
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
        date*: DateTime
        routine*: Routine
 
    Set* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo
        reps*: int
        tempo*: string
        intensity*: Intensity
        session*: Session
        duration*: Duration
        order*: int