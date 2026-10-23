# Room Music Scan

Android-only MediaStore discovery and temporary audio export. Adapted from the
local `scan_music` implementation in `/Users/huili/nady/lib/widgets/scan_music/`.
The reference plugin contains no published license; this package remains private.

Unlike the reference, audio is opened through its content URI, not a DATA path.
Queries and stream copies run on a worker executor. Permission requests remain
user initiated. No all-files permission, network requests, or player is included.
The application owns hashing, sandbox persistence, temporary-file cleanup and UI.
