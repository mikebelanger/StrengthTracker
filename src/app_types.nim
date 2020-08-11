type

    ### Types that don't have a corresponding table in the db

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

    IntensityUnits* = enum
        UnspecifiedIntensityUnit
        Pounds
        Kilograms
        PercentageOfOneRepMax

    EntryKind* = enum
        New
        Existing

    Entry* = object of RootObj
        case kind*: EntryKind
            of New: nil
            of Existing: id*: Positive

    #### Types that have a corresponding type in the db
    User* = object of Entry
        name*, email*: string

    Movement* = object of Entry
        name*, description*: string
        plane*: MovementPlane
        area*: MovementArea
        concentric_type*: ConcentricType
        symmetry*: Symmetry

    MovementCombo* = object of Entry
        name*: string
        routine_order*: int

    Routine* = object of Entry
        name*: string
        active*: bool
        user*: User

    MovementComboAssignment* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo
        routine*: Routine
            
    WorkoutSet* = object of Entry
        movement*: Movement
        movement_combo*: MovementCombo
        routine*: Routine
        intensity*: float
        intensity_units*: IntensityUnits
        set_date*: string
        start_duration*, eccentric_duration*, concentric_duration*, end_duration*, set_duration*, routine_order*, reps, duration_in_minutes: int

    # Request-specific stuff - nothing in db
    MovementComboGroup* = ref object of RootObj
        movement_combo*: MovementCombo
        movements*: seq[Movement]