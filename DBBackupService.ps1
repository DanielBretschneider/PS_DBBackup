# Script 
<# .SYNOPSIS
     This file compresses all backup files in /xr50/bup directory according to following 
     rules:
     - only last months files will be compressed which implies the need to daily check if a new month has begun
     - if rule above is true, then compress all files with ".bup" or ".log.bup" filetyp using 7zip
.DESCRIPTION
     - date format is yyyyMM (y=year, M=Month)
     - premiss: currentMonth.txt must exist for correct function 
.NOTES
     ManageMED 
#>


# ------------- GLOBALS ------------- 

# location, relevant for file naming
$location = "XYZ"

# .txt-File stores current month from last execution in following format "yyyyMM"
$currentMonthFile = Get-ChildItem -Name "currentMonth.txt"

# Get content of currentMonth.txt file
$currentMonthFileContent = Get-Content "currentMonth.txt"

# get current month and year
$currentMonthFormatted = Get-Date -Format "yyyyMM"

# get current date and datetime
$CurrentDate = Get-Date -format s

# backup filetypes that should be compressed
$filetype = "*.bup"

# Log info
$logActivityInfo = "[info][$CurrentDate]: "
$logActivityError = "[error][$CurrentDate]: "

# log file location
$LogFile = ".\DBBackup.log" 



# ------------- Functions -------------

#
# initLogFile() - see if log file exists. If not, create one.
#
function initLogFile
{
    if (!(Test-Path $LogFile))
    {
        New-Item -itemType File -Path "." -Name ("DBBackup" + ".log")
        log 0 "initLogFile" "No log file found. New one was created with path: '$LogFile'"
    }
    else
    {
        Write-Host "File already exists."
    }
}

#
# log - print out and log informatuion
#
# 1st param: log level (0 = info, 1 = error)
# 2nd param: name of function sending information
# 3rd param: message itself
#
function log
{
    # paramter
    param 
    (
        $loglevel,
        $functionname,
        $message
    )
    
    # print information
    # depending on log level
    # 0 = info
    if ($loglevel -eq 0) 
    {
        Write-Host "$logActivityInfo[$functionname] - $message"
        Add-Content $LogFile "$logActivityInfo[$functionname] - $message"
    } 
    elseif ($loglevel -eq 1)
    {
        Write-Host "$logActivityError[$functionname] - $message"
        Add-Content $activityfile "$logActivityError[$functionname] - $message"
    }
    
}



#
# Compare current month with content of currentMonth.txt
# if equal: do nothing, if not equal (new moht) then start
# compressing
#
function compareMonth 
{
    log 0 "compareMonth" "Comparing current month with content of currentMonth.txt"
    
    # comparison
    if ("$currentMonthFileContent" -eq "$currentMonthFormatted") 
    {
        log 0 "compareMonth" "Content of currentMonth.txt and current month are equal. No action required."
        log 0 "compareMonth" "Exit DB backup service."
        exit
    } 
    else 
    {
        log 0 "compareMonth" "Content of currentMonth.txt and current month is not equal. "
        log 0 "compareMonth" "Starting to compress .bup and .log.bup files in db backup directory."
        compressBackupFiles
    } 
}

#
# compress all .bup and .log.bup files in directory
#
function compressBackupFiles
{
    log 0 "compressBackupFiles" "Retreive all backup files in directory"

    # retreive all files with backup file extension
    $backupFiles = Get-ChildItem -Filter "*.bup"

    # list all items
    foreach($file in $backupFiles) 
    {
        log 0 "compressBackupFiles" "Found file: $file"
    }

    # start compressing files
    log 0 "compressBackupFiles" "Start compressing Files with 7zip"
    & "C:\Program Files\7-Zip\7z.exe" a -sdel -t7z -stm6 -bd "\\XYZ$currentMonthFileContent_11part1.7z" $backupFiles
	
    if($LASTEXITCODE -ne 0) 
    {
        throw "Error while compressing data."
        exit
    }
	
    # finished
    log 0 "compressBackupFiles" "Successfully finished compressing files. INFO: Files have been deleted automatically"

    # update current month file
    updateCurrentMonthFile
}   


#
# write new month in currentMonth.txt file
#
function updateCurrentMonthFile
{
    # write new month in currentMonth file
    $currentMonthFormatted | Set-Content $currentMonthFile

    log 0 "updateCurrentMonthFile" "Wrote new month into currentMonth.txt :: new content $currentMonthFormatted"
}



# ------------- Main -------------
log 0 "main" "Started DBBackup Service"

# check if log file exists
initLogFile

# compare current month with currentMonth.txt
compareMonth

# finished
log 0 "main" "Finished Backup Service!"

# EXIT
exit

# ------------- EOF -------------