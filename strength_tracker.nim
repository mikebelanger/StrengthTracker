# This is just an example to get you started. A typical hybrid package
# uses this file as the main entry point of the application.

import strength_tracker/submodule
import jester
import json

when isMainModule:
  echo(getWelcomeMessage())


routes:

  get "/welcome.json":
    resp %*{"content": "Hello world!"}