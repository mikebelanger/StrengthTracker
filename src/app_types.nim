# exercise types
import options, json

type

    MovementPlane* = enum
        Horizontal, Vertical, Lateral, Frontal
    
    BodyArea* = enum
        Upper, Lower
    
    MovementType* = enum
        Unilateral, Bilateral

    MovementCategory* = enum
        Push, Pull, Squat, Hinge

    Movement* = object
        name*: string
        movement_plane*: MovementPlane
        body_area*: BodyArea
        movement_type*: MovementType
        movement_category*: MovementCategory


proc to_movement*(input_json: JsonNode): Option[Movement] =
    if input_json.contains("name") and input_json["name"].getStr.len > 0:

        try:
            var movement = input_json.to(Movement)
            return some(movement)

        except KeyError as ke:
            echo ke.msg

        except ValueError as ve:
            echo ve.msg

        except:
            let e = getCurrentException()
            echo e.msg

        return none(Movement)

    else:
        echo "input json either doesn't have a name, or its blank."
        return none(Movement)


if isMainModule:

    let 
        sample_json = parseJson("""
            {
                "name": "Push-up",
                "movement_plane" : "Horizontal",
                "movement_type" : "Unilateral",
                "body_area": "Upergper",
                "movement_category" : "Push"
            }
        """)

        another_sample_json = parseJson("""
            {
                "name": "Push-up",
                "movement_plane" : "Horizontal",
                "movement_type" : "Unilateral",
                "body_area": "Lower",
                "movement_category" : "Push"
            }
        """)

        sample = sample_json.to_movement
        another_sample = another_sample_json.to_movement

    echo sample.isNone
    echo another_sample.isSome