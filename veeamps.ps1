<#
.Synopsis
    Automate Backups with Start-VBRZip in Powershell (Veeam Backup Free Edition)
    For updated help and examples refer to -Online version.
 
.DESCRIPTION
    Automate Backups with Start-VBRZip in Powershell (Veeam Backup Free Edition)
    For updated help and examples refer to -Online version.
    
.NOTES   
    Veeam_BackupAllVMs (And send email report with details of warnings/errors)
    Author: iAmVegas
    Version: 2.0
    DateCreated: 2018-Apr-25
    DateUpdated: 2021-Feb-23

.LINK to Original Author
    https://thesysadminchannel.com/automate-backups-start-vbrzip-powershell-veeam-backup-free-edition -

.EXAMPLE
    either start directly in Powershell or the included .bat file that can be used to access via Scheduled Task
#>

# Add the Powershell Snapin for Veeam
if ((Get-PSSnapin -Name VeeamPSSNapin -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin VeeamPSSNapin 
}

# Remove the Old Report to prepare for Fresh results. You can change this to your chosen path for management.
Remove-Item "C:\Scripts\BackupReport.htm"

# Create the New Results File
New-Item -ItemType file -Path C:\Scripts -Name BackupReport.htm 

# From Email address if you want email report
$from = ""

# Email address for sending the report to.
$to = ""

# Connect to your mail server
$smtp = New-Object System.Net.Mail.SmtpClient("mail.yourserver.com");

# SMTP authentication
$smtp.Credentials = New-Object System.Net.NetworkCredential("Email Account", "Password");

# Give the variable the location of the report file (HTML Based)
$fileName = "C:\Scripts\BackupReport.htm" 

# Find all VMs in the server using server entries in Veeam Backup Manager
$VMs = Find-VBRViEntity -Name * | Where-Object {($_.Type -eq "VM")} | Sort-Object Name

# The location that you want your VM Backups to be stored
$BackupFolder = "D:\Veeam_Backup"

# Start time of each backup in the session
$StartTime = Get-Date

# Log file location for output of logs.
$LogFile = "D:\Veeam_Backup\_Logs\log.csv"

# How long the VM backups should be held
$Retention = "In3days" <# Valid Options:  Never Tonight TomorrowNight In3days In1Week In2Weeks In1Month In3Months In6Months In1Year #>

# Here we start to build the html structure of the report
Function writeHtmlHeader 
{ 
param($fileName) 
$Date = ( Get-Date ).ToString('MM/dd/yy') 
Add-Content $fileName "<html>" 
Add-Content $fileName "<head>" 
Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>" 
Add-Content $fileName '<title>DEVNET VM Backup Report</title>' 
Add-Content $fileName '<STYLE TYPE="text/css">' 
Add-Content $fileName  "<!--" 
Add-Content $fileName  "td {" 
Add-Content $fileName  "font-family: Tahoma;" 
Add-Content $fileName  "font-size: 11px;" 
Add-Content $fileName  "border-top: 1px solid #999999;" 
Add-Content $fileName  "border-right: 1px solid #999999;" 
Add-Content $fileName  "border-bottom: 1px solid #999999;" 
Add-Content $fileName  "border-left: 1px solid #999999;" 
Add-Content $fileName  "padding-top: 0px;" 
Add-Content $fileName  "padding-right: 0px;" 
Add-Content $fileName  "padding-bottom: 0px;" 
Add-Content $fileName  "padding-left: 0px;" 
Add-Content $fileName  "}" 
Add-Content $fileName  "body {" 
Add-Content $fileName  "margin-left: 5px;" 
Add-Content $fileName  "margin-top: 5px;" 
Add-Content $fileName  "margin-right: 0px;" 
Add-Content $fileName  "margin-bottom: 10px;" 
Add-Content $fileName  "" 
Add-Content $fileName  "table {" 
Add-Content $fileName  "border: thin solid #000000;" 
Add-Content $fileName  "}" 
Add-Content $fileName  "-->" 
Add-Content $fileName  "</style>" 
Add-Content $fileName "</head>" 
Add-Content $fileName "<body>" 
Add-Content $fileName  "<table width='100%'>" 
Add-Content $fileName  "<tr bgcolor='#CCCCCC'>" 
Add-Content $fileName  "<td colspan='7' height='25' align='center'>" 
Add-Content $fileName  "<font face='tahoma' color='#003399' size='4'><strong>VeeamZip Backup - $Date</strong></font>" 
Add-Content $fileName  "</td>" 
Add-Content $fileName  "</tr>" 
Add-Content $fileName  "</table>" 
} 

# Write the HTML Header to the file for reporting
Function writeTableHeader 
{ 
param($fileName) 
Add-Content $fileName "<table width='100%'><tbody>"  
Add-Content $fileName "<tr bgcolor=#CCCCCC>" 
Add-Content $fileName "<td width='10%' align='center'>VM Name</td>" 
Add-Content $fileName "<td width='10%' align='center'>Status</td>"
Add-Content $fileName "<td width='10%' align='center'>Time</td>" 
Add-Content $fileName "<td width='10%' align='center'>Size</td>"  
Add-Content $fileName "<td width='10%' align='center'></td>"
Add-Content $fileName "</tr>" 
} 

# Writing the footer of the report file. Nothing Special here.
Function writeHtmlFooter 
{ 
param($fileName) 
Add-Content $fileName "</table>" 
Add-Content $fileName "</body>" 
Add-Content $fileName "</html>" 
}

# Function to display the file size in friendly terms. (ie: 34.5GB)
function DisplayInBytes($num) 
{
    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($num -gt 1kb) 
    {
        $num = $num / 1kb
        $index++
    } 

    "{0:N1} {1}" -f $num, $suffix[$index]
}

# Start the process and write the initial header of the html report file.
writeHtmlHeader $fileName 

# Write the begining portion of the table for data display
writeTableHeader $fileName 

# Lets Loop for each VM found in the Veeam Backup Service.
foreach($VM in $VMs){

# Convert the name to simple terms and then make it all Upper Case.
    $VMName = $VM.Name
    $VMName = $VMName.ToUpper()
 
# Check to see if the folder exists for the current VM name if not create it.
    if (!$(Test-Path $BackupFolder\$VMName)) {
        mkdir $BackupFolder\$VMName
    }
    
# Start the backup for the current VM.
    Start-VBRZip -Folder "$BackupFolder\$VMName" -Entity $VM -Compression 3 -AutoDelete $Retention
 
# Provide results for the current VM backup.
    $Results =  Get-VBRBackupSession | Where-Object {$_.Name -match $VMName} | Sort-Object EndTime -Descending | select -First 1

# Set the file variable to the actual filename of the backup (.vbk)
    $File = Get-ChildItem -Path $BackupFolder\$VMName | Sort-Object LastWriteTime -Descending | select -ExpandProperty Name -First 1

# Get Session details so we can extract any Warnings or Errors in the process of backing up.
    $session = Get-VBRBackupSession | Where-Object {$_.Name -match $VMName} | Sort-Object EndTime -Descending | select -First 1

# Lets extract the actual Warnings/Errors
        $Info = [Veeam.Backup.Core.CBackupTaskSession]::GetByJobSession($session.id)

# For simplicity we will set a simple variable of said Warnings/Errors
        $warn = $Info[0].Reason

# Adding the variables for other results (Status (Success, Warning, Failed)
        $status = $Results.Result

# What time the current VM has started
        $start = $Results.CreationTime.ToString('MM/dd/yyyy  hh:mm')

# What time the Current VM Backup Ended
        $end = $Results.EndTime.ToString('MM/dd/yyyy  hh:mm')
    
 # Outputting results into logfile. Does not include warnings/errors
    " " | Select @{Name = "VMName"; Expression = {$VMName}}, @{Name = "Status"; Expression = {$Results.Result}}, @{Name = "StartTime"; Expression= {$Results.CreationTime.ToString('MM/dd/yyyy  hh:mmtt')}}, @{Name = "EndTime"; Expression= {$Results.EndTime.ToString('MM/dd/yyyy  hh:mmtt')}}, @{Name = "TotalTime"; Expression= {$VMTime = ($Results.EndTime - $Results.CreationTime); "Hours: " + $VMTime.ToString('hh') + "   " + "Minutes: " + $VMTime.ToString('mm')}}, @{Name = "Filename"; Expression = {$File}}, @{Name = "SizeGB"; Expression= {[math]::Round((Get-ChildItem -Path $BackupFolder\$VMName -Filter $File | select -ExpandProperty Length) / 1GB,2)}}, @{Name = "AutoDelete"; Expression = {$Retention}} | Export-Csv $LogFile -NoTypeInformation -Append
 
 #Create Variables from results of the file size
        $size = DisplayInBytes ((Get-Item $BackupFolder\$VMName\$File).length)

# Write to the screen the VM Name and the warnings/errors (Can be removed or commented out).
        Write-Host $VMName " - " $warn

# If status is Success then we write the table with green background for the status Column
If($status -eq "Success"){
    Function writeTableS 
        { 
            param($fileName) 
                Add-Content $fileName "<tr>"
                Add-Content $fileName "<td width='10%' align='center'>$VMName</td>" 
                Add-Content $fileName "<td width='10%' bgcolor='#4AA02C' align='center'>$status</td>"
                Add-Content $fileName "<td width='10%' align='center'>$start</td>" 
                Add-Content $fileName "<td width='10%' align='center'>$size</td>"  
                Add-Content $fileName "<td width='10%' align='center'>$warn</td>"   
                Add-Content $fileName "</tr>" 
        } 

# Write the actual table data
      writeTableS $fileName

# If status is Warning then we write the table with yellow background for the status Column
 }elseif($status -eq "Warning"){

     Function writeTableW 
        { 
            param($fileName)  
                Add-Content $fileName "<tr>"
                Add-Content $fileName "<td width='10%' align='center'>$VMName</td>" 
                Add-Content $fileName "<td width='10%' bgcolor='#FFFF00' align='center'>$status</td>"
                Add-Content $fileName "<td width='10%' align='center'>$start</td>" 
                Add-Content $fileName "<td width='10%' align='center'>$size</td>"  
                Add-Content $fileName "<td width='10%' align='center'>$warn</td>"  
        } 

# Write the actual table data
      writeTableW $fileName

 }else{

 # If status is Failed then we write the table with red background for the status Column
     Function writeTableF 
        { 
            param($fileName)  
                Add-Content $fileName "<tr>"
                Add-Content $fileName "<td width='10%' align='center'>$VMName</td>" 
                Add-Content $fileName "<td width='10%' bgcolor='#FF0000' align='center'>$status</td>"
                Add-Content $fileName "<td width='10%' align='center'>$start</td>" 
                Add-Content $fileName "<td width='10%' align='center'>$size</td>" 
                Add-Content $fileName "<td width='10%' align='center'>$warn</td>" 
                Add-Content $fileName "</tr>" 
        }

# Write the actual table data
      writeTableF $fileName
    }
  }
      writehtmlfooter $fileName

#######################################
###        Send the Report          ###
#######################################
        
    $msg = new-object System.Net.Mail.MailMessage
	$msg.From = $from
	$msg.To.Add($to)
	$msg.Subject = "Veeam Powershell Backup Report", $day
	$msg.Body = Get-Content C:\Scripts\BackupReport.htm
 	$msg.isBodyhtml = $true 	
    $smtp.Send($msg)
