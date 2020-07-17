# exercise types
import options

type

    MovementPlane* = enum
        Horizontal, Vertical, Lateral, Frontal
    
    BodyArea* = enum
        Upper, Lower
    
    MovementType* = enum
        Unilateral, Bilateral

    MovementCategory* = enum
        Push, Pull, Squat, Hinge


template loop_through_enum(input_enum: untyped, input_str) =

    for e in input_enum.low .. input_enum.high:
        if $e == input_str: 
            return some(e) 
    
    return none(input_enum)

proc get_movement_plane*(input_str: string): seq[MovementPlane] =
    loop_through_enum(MovementPlane, input_str)

proc get_body_area*(input_str: string): seq[BodyArea] =
    loop_through_enum(BodyArea, input_str)

proc get_movement_type*(input_str: string): seq[MovementType] =
    loop_through_enum(MovementType, input_str)
    
proc get_movement_category*(input_str: string): seq[MovementCategory] =
    loop_through_enum(MovementCategory, input_str)


if isMainModule:

    # for m in MovementPlane.low .. MovementPlane.high:
    #     echo $m
    #     echo ord(m)

    let x = get_movement_plane("Vertical")
    echo $x
    
    let y = get_movement_plane("Blahblah")
    echo $y

    echo x.isSome, y.isSome