# Active Directory Audit Script

See the full [AD-Audit ](README-AD-Audit.md) document for full details and instructions.

An example of a [Change Control Request][examplei-CCR.pdf] (_CCR_) is included for implementation approval.

This PowerShell automation gathers the Active directory information for the required domain including:

- **Computer: Objects**
  - Computer Name
  - OU information
  - When created
  - When last modified
  - Last Login Date
  - Operating System
- **User Objects**
  - Account Name
  - OU information
  - When created
  - When last modified
  - Last bad Password attempt
  - Last Login Date
  - When password was last set
- **Group Objects**
  - Name of Group
  - When group was created
  - OU Information
  - When last modified
  - Members of the group
- **All Organisational Units and their Hierarchy (Directory Structure)**

This script outputs the above information in a spreadsheet (CSV) format.
