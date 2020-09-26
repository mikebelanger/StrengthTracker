import allographer/schema_builder
import sequtils

type
    TableNames* = enum
        User = "user"
        Session = "session"
        WorkoutSet = "workout_set"
    
    Basic* = enum
        id = "id"

    UserSchema* = enum
        name = "name"
        email = "email"

    SessionSchema* = enum
        session_date = "session_date"

    WorkoutSchema* = enum
        reps = "reps"
        

converter table_to_string*(t: TableNames): string =
    $t

converter basic_to_string*(b: Basic): string = 
    $b

converter user_schema_to_string*(u: UserSchema): string =
    $u

converter session_schema_to_string*(ss: SessionSchema): string =
    $ss

converter workout_schema_to_string*(ws: WorkoutSchema): string =
    $ws

let
    user* = table(User, [
        Column().increments(id),
        Column().string(name).unique(),
        Column().string(email).unique()
    ])

    session* = table(Session, [
        Column().increments(id),
        Column().timestamp(session_date),
        Column().foreign(id).reference(id).on(User).onDelete(SET_NULL)
    ])

    workout_set* = table(WorkoutSet, [
        Column().increments(id),
        Column().foreign(id).reference(id).on(User).onDelete(SET_NULL),
        Column().integer(reps)
    ])

    app_schema* = [
        user, session, workout_set
    ]