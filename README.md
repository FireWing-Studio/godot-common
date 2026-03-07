# godot-common
Common addons for godot projects

# FWLogger

FWLogger is the class used to log to file or console by the FW common plugin.

FWLogger DOES NOT CURRENTLY SUPPORT MULTIHTREADING (use it only in the main thread).

The first log entry to be run is the ```Initialized log``` log, which has in the data
information about the game and plugin versions, and information about the Log itself.

## Autoload

The autoload name is ```Log```.

The autoload must be done manually.

## Structure

In each log are present:
* TIME: Time in the system's UTC, in ISO 8601.

* FRAME: The current frame number of the game, bassed n ```Engine.get_frames_drawn()```.

* LEVEL: The name of the level of log.

* CALLER: The name of the caller of the log entry. The caller can choose what they want.\
The standard of the FW plugin is ```<class>:<name>.<method>```.

* MESSAGE: The message of the log entry. This should be a fixed emssage for each of the same instance.\
Variable data should lie in the DATA part.

* DATA: variable useful data for the log entry. The data is written in JSON.

The log entry is written in the following format (The part in curly brackets is present only if
DATA is not empty):

[TIME][FRAME][LEVEL][CALLER] MESSAGE{ | DATA}

## Levels

The levels are the following:

* DEBUG: Used for log entries which show no actual nor potential problems.

* INFO: Used for log entries which indicate a potential problem, but usually isn't.

* WARN: Used for log entries which indicate an issue, but isn't too severe and is recoverable

* ERROR: Used for log entries which indicate an issue which is severe and potentially game freezing.

* PANIC: Used for log entries which indicate an issue which is severe and game crashing.\
After the log entry, a crash dump is written.

## File

The logs are written into ```user://logs/app.log``` if ```log_to_file``` is set to true
(which is set automatically if the game is not in a debug build).

After each booton, the game log file is rewritten in place.
Thus, the logs between a booton and another are NOT preserved.

If ```skip_minor_levels``` is set to true (which is set automatically if
the game is not in a debug build) the logging (to file and to console) is skipped for
levels in ```MINOR_LEVELS [DEBUG, INFO]```.

The file is flushed after a cumulative amount of ```FLUSH_THRESHOLD [4096]``` characters
(the characters of a line plus the newline character).

The file is flushed immediately if the log level is in the ```URGENT_LEVELS [ERROR, PANIC]```.

The file is flushed after ```FLUSH_TIMEOUT [1000.0]``` milliseconds (using a ```Timer``` child
node).

## Crash Dump

If a ```PANIC``` level log is called, then the module, after logging the entry, will write a
crash dump. The crash dump has diverse information on the game status, the game version as well as
the recent logs stored (in amount of ```LOGS_STORED [50]```).

The crash dump file is flushed and closed immediately after writing the JSON of the data.

The crash file is ```crash_dump-<UNIX>.json```, where ```<UNIX>``` is the unix time at that moment.
The directory is ```user://logs/dumps/```.
