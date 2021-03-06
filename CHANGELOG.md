# Hermaues Changelog

## v1

### v1.1

Move the index page out of a magic string and into the configuration file.

Update the configuration handler to account for the new information, and provide
some more helpful error messages on validation failure.

Update the Changelog structure slightly.

### v1.0

#### v1.0.2

Fix a File.open call; it was accidentally being given a string permission set
instead of numeric.

#### v1.0.1

Deployment to a separate machine brought some hidden bugs to light. Fixed a
syntax error in the initialization routines and added documentation about fresh
installations to the README.

#### v1.0.0

Added a storage backend (`Apocryphon` and `Archivist` classes) capable of
formatting the retrieved text and storing it on disk.

`mora` is confirmed to work in the wild, and so Hermaeus is ready for a 1.0
release.

### v0

Development versions used only for experimentation.

#### v0.2.0

Completed the ability to retrieve texts from reddit and process them enough for
demonstration purposes.

#### v0.1.0

Initial version -- Gained the ability to connect to reddit and retrieve basic
information.
