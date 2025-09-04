<#
NAME:
    Active Directory Audit script

Description : 
    A script that gathers information about Active Directory domain Computer Objects, User Objects, 
    Group Objects and Organisational Units and their Hierarchy (Directory Structure) and saves them to file.  
    See README-AD-Audit.txt file for use instructions

FILENAME: 
    AD-Audit.ps1

USER SUPPORT:
    README-AD-Audit.txt

AUTHOR:
     Michael Webb

Version History:

v.0.9. 23/11/24, Michael Webb.  Refactor variables to conform to coding standard change output to meaningful filenames
v.1.0. 25/11/24, Michael Webb.  Added Checks for user writable directory.
v.1.1. 26/11/24, Michael Webb.  Added logging function and user friendly messages to Console.
v.1.2. 27/11/24, Michael Webb.  Fix tyops and speeling errors.
#>

<#
        .SYNOPSIS
        Gathers Active Directory User, Computer and Group information

        .DESCRIPTION
        Gathers Active Directory User, Computer and Group objects and saves
        it to individual .CSV files.
        Takes any strings for the file path to save the .CSV files to.

        .PARAMETER Name
        Specifies the file save path. Or blank for home directory as default save path

        .PARAMETER Extension
        NONE

        .INPUTS
        NONE

        .OUTPUTS
        Errors and progress utput to console and log file. Script output saves to .csv files

        .EXAMPLE
        PS> AD-Audit.ps1 -filepath "file path name"
        File.txt

        .EXAMPLE
        PS> ADAudit.ps1 -filepath "C:\temp"
        C:\temp\AD Computer Objects.csv

        .EXAMPLE
        PS>AD-Audit.ps1
        C:\Users\"UserNAME"\AD Computer Objects.csv

        .LINK
        NONE

#>

param(
    [string]$filePath = $HOME
)

# Set  date and time for the CSV file (20241126132811)
$scanTime = (Get-Date).toString("yyyyMMddHHmmss")

# Check to see if user defined path exists. Exit with error if  not
if (!(Test-Path $filePath -pathType container)) { 
	throw "  [-] ERROR: Given path Does not exist: "+$fileaPath
}
else {
    Write-Host -ForegroundColor Green "[+] SUCCESS: $filePath Is Real"
}
# Check to see if user defined path is writable by writing a temp file.
# Exit with error msg if not
# Create random test file name
$logFile = "$filePath\AD-Audit - $scanTime.log"

try { 
	# Try to create log file
	[io.file]::OpenWrite($LogFile).close()
	Write-Host -ForegroundColor Green "  [+] SUCCESS: Writable: $filePath"
}
catch {
	# Report error writing to file path
	Write-Host -ForegroundColor Red "  [-] ERROR: Not writable: $filePath"
    throw "Critical Error:  Exiting"
}

# Function to write to a log file
function WriteLog {

    Param([string]$eventString)
    $eventTime = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
    $logMessage = "$eventTime $eventString"
    If($logfile) {
        Add-content $logFile -value $logMessage
    }
    Else {
        Write-Output $line
    }
}

# Define throw message for file creation error
$fileCreate_Error = [string]"Critical error encounted creating file. Exiting"
WriteLog "Active Directory Audit script started"

# check for and load the Active Directory module. Exit with messege on fail 
<# if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Import-Module ActiveDirectory
	Write-Host -ForegroundColor Green "[+] Success: ActiveDirectory module imported"
} 
else {
    Write-Host -ForegroundColor Red "[-] Error: Code 400: ActiveDirectory module not imported.  See README-AD-Audit.txt for details"
    throw "fatal ERROR! Exiting"
}
#>
try {
    Import-Module ActiveDirectory -ErrorAction Stop
	Write-Host -ForegroundColor Green "  [+] Success: ActiveDirectory module imported"
    WriteLog "Success: ActiveDirectory module imported"
}
catch {
    Write-Host -ForegroundColor Red "[-] Error: Code 400: ActiveDirectory module not imported.  See README-AD-Audit.txt for details"
    WriteLog "Error: Code 400: ActiveDirectory module not imported.  See README-AD-Audit.txt for details"
    throw "fatal ERROR! Exiting"
}

<#

---- GATHER AD COMPUTER OBJECT DATA ----

#>

Write-Host -ForegroundColor Green "`nCreating AD Computer Object data and saving to file"

# Set the CSV file path and name
$csvFile = "$filePath\AD Computer Objects - $scanTime.csv"

# Get all computer objects from Active Directory
$adComputerProperties = Get-ADComputer -Filter * -Properties Name, whenChanged, whenCreated, LastLogonDate, OperatingSystem, CanonicalName, DistinguishedName

# Initialize an empty array to hold the user objects
$computerPropertyArray = @()

# Iterate through each user object and collect the required properties
foreach ($object in $adComputerProperties) {

    # Populate the user objects to the array
    # Use PSCustomObject (or use New-Object PSObject -Property) convert array strings back to objects, 
    # without this, Export-CSV will only output the lenght of the string and not the value expected 
    # for the object property

    $computerPropertyArray += [PSCustomObject]@{

        Name = $object.Name
        whenChanged = $object.whenChanged
        whenCreated = $object.whenCreated
        LastLogonDate = $object.LastLogonDate
        OperatingSystem = $object.OperatingSystem
        CanonicalName = $object.CanonicalName
        DistinguishedName = $object.DistinguishedName
    }
}

# Write Array of Active Directory user objects to CSV file
$computerPropertyArray | Export-Csv -Path $csvFile -NoTypeInformation -force

if (!(Test-Path -Path $csvFile)) {
    Write-Host -ForegroundColor Red "  [-] ERROR: Failed to write AD Computer data to $csvFile"
    WriteLog "Error Writing AD Computer data to $csvFile"
    Throw "$fileCreate_Error $csvFile. Stopping exicution of script"
}
else {
    # Display success message 
   Write-Host -ForegroundColor Green "  [+] SUCCESS: Exported AD Computer data to $csvFile"
   WriteLog "Exported AD Computer data to $csvFile"
}

<#

---- GATHER AD USER OBJECT DATA ----

#>

Write-Host -ForegroundColor Green "`nCreating AD User Object data and saving to file"

# Set the CSV file path and name
$csvFile = "$filePath\AD User Objects - $scanTime.csv"

# Get defined properties for all AD user objects 
$adUserProperties = Get-ADUser -Filter * -Properties DisplayName, CanonicalName, DistinguishedName, Created, Modified, LastBadPasswordAttempt, LastLogonDate, PasswordLastSet

# Initialize an empty array to hold the user objects
$userPropertyArray = @()

# Iterate through each user object and collect the required properties
foreach ($object in $adUserProperties) {
    # Populate the user objects to the array
    # Use PSCustomObject (or use New-Object PSObject -Property) convert array strings back to objects, without this, Export-CSV 
    # will only output the lenght of the string and not the value expected for the object property

    $userPropertyArray += [PSCustomObject]@{

        DisplayName = $object.DisplayName
        CanonicalName = $object.CanonicalName
        DistinguishedName = $object.DistinguishedName
        Create = $object.Created
        Modified = $object.Modified
        LastBadPasswordAttempt = $object.LastBadPasswordAttempt
        LastLogonDate = $object.LastLogonDate
        PasswordLastSet = $object.PasswordLastSet
    }
}

# Write Array of Active Directory user objects to CSV file
$userPropertyArray | Export-Csv -Path $csvFile -NoTypeInformation -force

if (!(Test-Path -Path $csvFile)) {
   Write-Host -ForegroundColor Red "  [-] ERROR: Failed to write AD User data to $csvFile"
   WriteLog "Error writing AD User data to $csvFile"
   Throw "$fileCreate_Error $csvFile. Stopping exicution of script"
}
else {
   # Display success message
   Write-Host -ForegroundColor Green "  [+] SUCCESS: Exported AD User data to $csvFile"
   WriteLog "Exported AD User data to $csvFile"
}

<#

---- GATHER AD GROUP MEMEBER OBJECT DATA ----

#>

Write-Host -ForegroundColor Green "`nCreating AD Group Memember data and saving to file"

# Set the CSV file path and name
$csvFile = "$filePath\AD Group Member Objects - $scanTime.csv"

# Get all defined properties for all group objects
$adGroups = Get-ADGroup -Filter * -Properties SamAccountName, Name, whenCreated, whenChanged, DistinguishedName, CanonicalName

# # Initialize an empty array to hold the group and memeber objects
$groupMemberArray = @()

Write-Host -ForegroundColor green "`nSearching through Group and Member Objects. This may take some time"

# Iterate through each group object and collect the required properties
foreach ($groupObject in $adGroups) {

    Write-Host -ForegroundColor yellow "  [*]Gathering data for $groupObject"
    # Get the members of the group
    $adGroupmembers = Get-ADGroupMember -Identity $groupObject.SamAccountName

    # Iterate through each group and get member properties and create and populate an array
    # Populate the user objects to the array
    # Use PSCustomObject (or use New-Object PSObject -Property) to convert array strings back to objects, without this, Export-CSV 
    # will only output the lenght of the string and not the value expected for the object property

    foreach ($memberObject in $adGroupmembers) {
    
        $groupMemberArray += [PSCustomObject]@{
            GroupName = $groupObject.Name
            GroupCreated = $groupObject.whenCreated
            GroupChanged = $groupObject.whenChanged
            GroupDistinguishedName = $groupObject.DistinguishedName
            GroupCanonicalName = $groupObject.CanonicalName
            MemberName = $memberObject.Name
            MemberClassType = $memberObject.objectClass
        }
    }
}

# Write the Array of group and member objects to a CSV file
$groupMemberArray | Export-Csv -Path $csvFile -NoTypeInformation -Force

if (!(Test-Path -Path $csvFile)) {
    Write-Host -ForegroundColor Red "  [-] ERROR: Failed Writing AD Group data to $csvFile"
    WriteLog "Error Writing AD Group data to $csvFile"
    Throw "$fileCreate_Error $csvFile. Stopping exicution of script"
}
else {
    # Display success message
    Write-Host -ForegroundColor Green "  [+] SUCCESS: Exported AD Group data to $csvFile"
    WriteLog "Exported AD Group data to $csvFile"
}

<#

---- GATHER AD HIERARACHY STRUCTURE DATA ----

#>

Write-Host -ForegroundColor Green "`nCreating AD Hierarchy structure data and saving to file"
# Set the CSV file path and name 
$csvFile = "$filePath\OU Hierarchy - $scanTime.csv"

# Get all defined properties for all group objects
$adOUs = Get-ADOrganizationalUnit -Filter * -Properties * | Select-Object CanonicalName, DistinguishedName

# Write the Array of group and member objects to a CSV file
$adOUs | Export-Csv -Path $csvFile -NoTypeInformation -Force

if (!(Test-Path -Path $csvFile)) {
    Write-Host -ForegroundColor Red "  [-] Error writing  OU Hierarchy to $csvFile"
    WriteLog "Error writing OU Hierarchy to $csvFile"
    Throw "$fileCreate_Error $csvFile. Stopping exicution of script"
} 
else {
    # Display success message
    Write-Host -ForegroundColor Green "`n  [+] Exported AD OU Hierarchy structure data to $csvFile`n"
    WriteLog "Exported AD OU Hierarchy structure data to $csvFile"
}

Write-Host -ForegroundColor Green "`n`n[++]Script Completed successfully. Files saved to $FilePath"

WriteLog "Active Directory Audit script completed."
