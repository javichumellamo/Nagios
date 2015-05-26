Add-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue
function CheckOneJob {
    $JobCheck=get-vbrjob -Name $args[0]
    if($JobCheck.IsBackupJob -eq $true) # Only Backup Jobs are checked
     {
        if($global:OutMessage -ne ""){$global:OutMessage+="<br>"}
        $global:OutMessage+="Job name:"+$JobCheck.Name+" "
        if($JobCheck.isScheduleEnabled -eq $false){ # Disabled job -> WARNING
            if($DisabledJobs -eq $true){
                $global:OutMessage+=" WARNING: Disabled job"
                if($global:ExitCode -lt 2){$global:ExitCode=1} # if no previous Critical status then switch to WARNING
                }
            }
        else  # The job is enabled
         {
            $lastStatus=$JobCheck.GetLastResult()
            if($($JobCheck.findlastsession()).State -eq "Working"){
                $global:OutMessage+="OK: Job in progress"
               }
            else {
                if($lastStatus -ne "Success"){ # Failed or None->never run before (probaly a newly created job)
                    if($lastStatus -eq "none"){
                        $global:OutMessage+="WARNING: Job never run"
                        if($global:ExitCode -ne 2) {$global:ExitCode=1}
                    }
                    elseif($lastStatus -eq "Warning"){
                        $global:OutMessage+="WARNING: Check job messages"
                        if($global:ExitCode -ne 2) {$global:ExitCode=1}
                    }
                    else {
                        $global:OutMessage+="CRITICAL: Job failed"
                        $global:ExitCode=2
                       }
                  }
                else{  # Check last run date
                    $LastRun=$JobCheck.ScheduleOptions.LatestRun
                    $global:OutMessage+="OK Last run "+$LastRun.year+"/"+("{0:D2}" -f $LastRun.Month)+"/"+("{0:D2}" -f $LastRun.Day)+" "+("{0:D2}" -f $LastRun.hour)+":"+("{0:D2}" -f $LastRun.Minute)+" "
                    if($JobCheck.IsContinuous -eq $true) {   # Continuous job
                        $EstRun=get-date
                        $DiffTime=new-timespan $LastRun $EstRun
                        if($Difftime.TotalMinutes -gt 15){
                            $global:ExitCode=2  # Continuous job not run in the last 15 minutes -> CRITICAL
                            $global:OutMessage+="<br>   CRITICAL: Continuous job not run for more than 15 minutes"
                         }
                     }
 
                }
            }
        }
     }
 }

##########################################################################
#                               Main loop                                #
##########################################################################

$nextIsJob=$false
$oneJob=$false
$jobToCheck=""
$WrongParam=$false
$DisabledJobs=$true
$global:OutMessage=""
$global:Exitcode=""
if( $args.Length -ge 1)
 {
     {
       if($nextIsJob -eq $true) { # parameter coming after -j switch
            if(($value.Length -eq 2) -and ($value.substring(0,1) -eq '-')){
                $WrongParam=$true
                }
            $nextIsJob=$false
            $jobToCheck=$value
            $onejob=$true
            }
       elseif($value -eq '-j') { # -j -> check only one job and its name goes in the following parameter (default is to check all backup jobs)
            $nextIsJob=$true
            }
       elseif($value -eq '-d') { # -d -> Do not warn for disabled jobs (default is to warn)
            $DisabledJobs=$false
            }
       else {$WrongParam=$true}
       }
  }

if($WrongParam -eq $true){
    write-host "Wrong parameters"
    write-host "Syntax: Check_Veeam_Jobs [-j JobNameToCheck] [-d]"
    write-host "       -j switch to check only one job (default is to check all backup jobs)"
    Write-Host "       -d switch to not inform when there is any disabled job"
    exit 1
    }

$VJobList=get-vbrjob
$ExitCode=0

IF($oneJob -eq $true){
    CheckOneJob($jobToCheck)}
else {
    foreach($Vjob in $VJobList){
        CheckOneJob($Vjob.Name)
    }
}
write-host $global:OutMessage
exit $global:Exitcode