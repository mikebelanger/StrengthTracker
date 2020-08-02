#### ***Caution: Not Functional Yet.  Only basic operations work.  I'm only sharing for those wanting more examples of Nim Web Development*** ####
#### StrengthTracker (** Very WIP **)

A web-app that tracks your strength exercises.

#### Project Goals

* Support a wide variety of exercise routines, such as [r/bodyweightfitness's recommended routine](https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine#wiki_welcome_to_the_recommended_routine) or [Max Shank's Forever Template](https://maxshank.com/strength-conditioning/forever/) or 
[Various programs outlined by Steven Low](http://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/).
* Easy to modify/customize.
* Easy to migrate data out at any time. 
* An excuse to try Nim :)

While I don't want to discourage anyone from customizing this further, I should mention there are some ideas/features that are outside of the current scope:

#### Current Non-Goals/Limitations

* Step-tracking.
* Nutrition tracking.
* Random exercises ( aka CrossFit WODS ).
* Anything where the intensity varies within a single session (like drop-sets).

That said, if you can see a way to add any of the above (or more) - please send me a PR!  I'd be interested.

#### Intended Usage

A user will log into the web app on a browser.  This browser could be running on a phone, tablet or computer.  The user would select their routine, and start a new "session" of that routine.  The app would show whatever exercise comes first, the user would perform the exercise, then enter how many reps they achieved.  The app would then show the next exercise to do, and the user would do the same thing.  The user could finish the routine at any point, or if there's a time limit, run out of time.

#### Tech Details

Code for both front, and back-end is mostly written in [Nim](http://www.nim-lang.org).  The backend compiles to C, the frontend to JS.  This breaks down to:

* Frontend: [Karax](https://github.com/pragmagic/karax) for DOM-manipulating and some [Tachyons](https://tachyons.io/) for style.
* Backend: [Allographer](https://github.com/itsumura-h/nim-allographer) as an ORM (with a Sqlite db), and [Jester](https://github.com/dom96/jester) for routing.

#### Developing

You'll need the [latest Nim](https://nim-lang.org/install.html) (at this time, that's with compiler v 1.3.5).  You'll also need [sqlite v.3.19.3](https://www.sqlite.org/index.html).  You'll also need to decide which terminal emulator to use.  For OS X users, Terminal.app or iTerm2.  For Windows users, I believe just Powershell.  Linux users have an overwhelming amount of emulators to choose from, and I can't possibly list them all.  If you use VSCode, you could also just use its built-in terminal emulator to enter the commands.


1. Download/Clone this repo
2.  Cd into this repo with your favorite terminal emulator.
3.  Enter `nimble install` to ensure you have all the dependencies.
4.  Enter `nim c -r src/backend/database_schema.nim` to setup the database's tables.
5.  [Optional] Enter `nim c -r src/backend/database_seed.nim` to get some 'fake' data to work with.
6. Enter `nimble frontend` to compile the front-end code into js, and make it servable by jester.
7. Finally, start the server by entering `nim c -r src/backend/server.nim`

From there, follow the prompt.  You should be asked to open http://localhost:5000 in a browser.

Please let me know of any issues.