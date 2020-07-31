#### StrengthTracker (** Very WIP **)

A web-app that tracks your strength exercises.

#### Project Goals

* Support a wide variety of non-random exercise routines.  Should be able to support anything from [r/bodyweightfitness's recommended routine](https://www.reddit.com/r/bodyweightfitness/wiki/kb/recommended_routine#wiki_welcome_to_the_recommended_routine) to something out of [Max Shank's Forever Template](https://maxshank.com/strength-conditioning/forever/) to 
[Various programs outlined by Steven Low](http://stevenlow.org/the-fundamentals-of-bodyweight-strength-training/).
* Be easy to modify/customize.  Main code is written in [Nim](https://nim-lang.org/).  An incredibly effective, and approachable language.

* Be easy to migrate data out at any time.  Absolutely no proprietary methods/encryption on this data.  The app stores data in a SQLITE database, which has all kinds of tools/methods of exporting data out.

* Be another example of web app programming with Nim.  While Nim is an awesome language - it needs more example repos of doing various things, so newcomers to the language have more to learn from.


While I don't want to discourage anyone from customizing this further, I should warn that I'm currently developing it with the following non-goals/limitations:

#### Current non-goals/Limitations

* Step-tracking.  Its assumed users will do strength based movements with a relatively low amount of repetitions, and enter them manually into the web app.
* Nutrition tracking.  While nutrition is an important component of health and therefore fitness, I don't have the time/resources to add this.
* Random exercises ( aka CrossFit WODS ).  I believe Crossfit already has plenty of examples of apps that support random exercises.
* Anything with variable intensity (like drop-sets).  I might make this a priority at some point, but don't have the time.

That said, if you can see a way to add any of the above (or more) - please send me a PR!  I'd be interested.

#### Intended Usage

User will log into the web app, either from a phone or their computer/tablet.  

#### Tech Details

Code for both front, and back-end is mostly written in [Nim](http://www.nim-lang.org).  This breaks down to:

* Frontend: [Karax](https://github.com/pragmagic/karax) for DOM-manipulating and some [Tachyons](https://tachyons.io/) for style.
* Backend: [Allographer](https://github.com/itsumura-h/nim-allographer) as an ORM, and [Jester](https://github.com/dom96/jester) for routing.
