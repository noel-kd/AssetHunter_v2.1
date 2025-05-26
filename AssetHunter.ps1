#Program: AssetHunter v2.1
#Author: Kyle Noel
#Last Updated: 20250505

Clear-Host


Write-Host @"
   _____                        __     ___ ___               __                
  /  _  \   ______ ______ _____/  |_  /   |   \ __ __  _____/  |_  ___________ 
 /  /_\  \ /  ___//  ___// __ \   __\/    -    \  |  \/    \   __\/ __ \_  __ \
/    |    \\___ \ \___ \\  ___/|  |  \    T    /  |  /   |  \  | \  ___/|  | \/
\____|__  /____  >____  >\___  >__|   \___|_  /|____/|___|  /__|  \___  >__|    v2.1
        \/     \/     \/     \/             \/            \/          \/       
"@


Write-Host "Please ensure you are running this application with admin privileges."


If ($args[0] -eq "-interactive"){

    Write-Host "Launching interactive mode..." -ForegroundColor DarkGray

    Write-Host "`nEnter one or multiple comma-separated system names."
    $computerList = Read-Host "System name(s)"
    $computerList = $computerList.Replace(" ","")

    $computers = $computerList.Split(",")

    Write-Host "Processing systems..."
}

Else{
    
    Write-Host "Launching passive mode..." -ForegroundColor DarkGray

    Write-Host "`nProcessing systems from " -NoNewline; Write-Host ".\clientlist.txt" -ForegroundColor Cyan

    #Pulling computer names from list file
    $clientFile = "$PSScriptRoot\clientlist.txt"
    $computers = Get-Content -Path $clientFile

}

#Setting system object list
$sysList = New-Object System.Collections.ArrayList
$foundList = New-Object System.Collections.ArrayList

#Setting up log file
$dateTime = (Get-Date).ToString('yyyMMdd_HHmm.ss.fff')
$logFile = "log_" + $dateTime + ".txt"
$logPath = "$PSScriptRoot\logs\$logFile"

if(!(Test-Path $logPath)){
    New-Item -Path $logPath | Out-Null}
else{Clear-Content $logPath}

$dateTime | Out-File $logPath

#Initializing progress
$progress = 1


Foreach ($computer in $computers){

    $currProgress=[math]::Round($progress/$computers.count*100)
    Write-Progress -Activity "Processing systems" -Status "Progress: $currProgress % | $($progress)/$($computers.count)   Checking: $computer" -Id 1 -PercentComplete $currProgress

    if(!(Test-Connection $computer -Count 1 -Quiet)){
        
        #Adding offline system object to list
        $sysList.add((New-Object PSObject -Property @{
            SYSTEM = $computer
            IP = "OFFLINE"
            MAC = " "
            WINRM = " "
            LAST_USER = " "
            LAST_LOGON = " "
        })) | Out-Null

        #Incrementing progress
        $progress++

        continue
    }

    $ip = $null

    $ip = Resolve-DnsName -Name $client -Type A -ErrorAction SilentlyContinue | Select-Object -ExpandProperty IPAddress

    $mac = $null
    
    $mac = Invoke-Command -ComputerName $computer -ScriptBlock {
    
        Get-WmiObject win32_networkadapterconfiguration | Where-Object -Property description -Like "*Ethernet*" | Select-Object -ExpandProperty macaddress

    } -ErrorAction SilentlyContinue


    $lastInfo = $null

    try{

        $lastInfo = Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-User Profile Service/Operational'; ID='1'} -MaxEvents 1 -ComputerName $computer -ErrorAction SilentlyContinue
    
    }

    catch [System.Diagnostics.Eventing.Reader.EventLogException],[Microsoft.Powershell.Commands.GetWinEventCommand]{
    
        $null
        
    }

    #Catch if lastInfo still null/invoke-command failed to process
    if($lastInfo -eq $null){
    
        #Adding error system object to list
        $sysList.add((New-Object PSObject -Property @{
            SYSTEM = $computer
            IP = $ip
            MAC = $mac
            WINRM = "ERROR"
            LAST_USER = " "
            LAST_LOGON = " "
        })) | Out-Null

        #Incrementing progress
        $progress++

        continue
    }

    $lastUserID = $lastInfo.UserID

    $lastTime = $lastInfo.TimeCreated

    $lastUserName = Get-ADUser -filter 'sid -like $lastUserID' -Properties Name | Select-Object -ExpandProperty Name



    If($lastUserName -eq $null){
        
        $lastUserName = Get-ADUser -filter 'sid -like $lastUserID' -Properties Name | Select-Object -ExpandProperty Name

    }

    #Adding found system object to list
    $sysObj = (New-Object PSObject -Property @{
        SYSTEM = $computer
        IP = $ip
        MAC = $mac
        WINRM = "ONLINE"
        LAST_USER = $lastUserName
        LAST_LOGON = $lastTime
    })

    $sysList.add($sysObj) | Out-Null
    $foundList.add($sysObj) | Out-Null

    #Clearing variables
    $lastTime = $null
    $lastUserName = $null
    $sysObj = $null

    #Incrementing progress
    $progress++
}

Write-Progress -Activity "Processing complete" -Id 1 -Complete

$sysList | Format-Table SYSTEM, IP, MAC, WINRM, LAST_USER, LAST_LOGON

$sysList | Format-Table SYSTEM, IP, MAC, WINRM, LAST_USER, LAST_LOGON | Out-File $logPath -Append



Write-Host "`nSee " -NoNewline; Write-Host ".\logs" -ForegroundColor Cyan -NoNewline; Write-Host " for a record of this session."

Write-Host "`nPress any key to exit"

$host.UI.RawUI.ReadKey() | Out-Null