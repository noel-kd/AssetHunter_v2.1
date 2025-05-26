AssetHunter v2.1
----------------

Remotely obtain last-user data from online/available systems via remote host event logs.

Author: Kyle Noel

PREREQUISITES:
- Application must be run as an admin.
- RSAT must be installed and sid user attribute must be configured for domain users (should be by default).


Modes:
------
Passive - 
 Pulls system names from a prefilled list. Ensure relevant system names are listed in .\clientlist.txt before launching.
 Enter system names into list file, each system on an individual line. Avoid spaces.
 Example:

ASUS-XXXXXX
DELL-AXXXXX
ASUS-AAAAAA
DESKT-ABABAB

 Select Launch_Passive.cmd to launch into Passive Mode.

Interactive - 
 Pulls system names from user input. You will be prompted to enter system name(s), separated by commas if there are more than one. 
 Spaces are okay in this mode.


NOTE: FQDNs are also acceptable and should function exactly the same as standard system names in either mode.

Known bugs
----------
Occasionally a logon event will be found without username information. Timestamp will be recorded but without a name.


Changelog
---------

20250505 - Added MAC address, WINRM status.

