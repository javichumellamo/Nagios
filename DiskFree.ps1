# Install NsClient++ and configure it properly for tyour environment in the Veeam Backup Server
# Add the following lines to the nsclient.ini file removing the hash character at the beggining
# /settings/external scripts/scripts]
# check_disk_free = cmd /c echo scripts\DiskFree.ps1 ; exit($lastexitcode) | powershell.exe -command -
# Copy this script to the %programfiles%\nsclient++\scripts folder and restart nsclient service
# By default this script checks all the local hard drives warns when the usage of une of them is over 80%
# You can change this behaviour adding a string formed by 
# if you want to check one specific backup job, use -j switch followed by the Job Name 
# This is a sample of how to add those parameters to the nsclient.ini file:
# check_veeam_jobs = cmd /c echo scripts\Check_Veeam_Jobs.ps1  "-d" "$ARG1$" "-f" ; exit($lastexitcode) | powershell.exe -command -
# Good luck 
# @javichumellamo
$devs= @()
$perc=@()
$exitValue=0
$outMessage=""
[float[]] $frees=@()
[float[]] $pSize
$multi=1024*1024*1024
if( $args.Length -ge 1)
 {
    foreach($value in $args)
     {
       $devs+=$value.substring(0,1)
       if($value.substring(1,1) -eq '%')
        {
            $perc+=$value.substring(2)
            $frees+=0
        }

        elseif($value.substring(1,1) -eq 'G')
         {
            $perc+=0
            $frees+=$value.substring(2)
           }
       }
   
  }
else
 {
    foreach($disp in GET-WMIOBJECT –query “SELECT * from win32_logicaldisk where DriveType = 3”) {
       $devs+=$disp.name.substring(0,1)
       $perc+=20
       $frees+=1
     
      }
   }

   
for ($i=0; $i -lt $devs.count; $i++) {
    if($i -ne 0){$outmessage+="<br>"}
    $unid=get-psdrive -name $devs[$i]
    $size=($unid.free+$unid.used)
    $freeP=100*$unid.free/$size
    $outMessage+=$("Device " +$devs[$i]+ ": size "+ ("{0:N2}" -f ($size/$multi))+ "GB  unused space " +("{0:N2}" -f ($unid.Free/$multi))+ "GB " +("{0:N2}" -f $freeP)+"%")
     if(($freeP -le $perc[$i]) -or ($unid.Free -le ($frees[$i]*$multi))) {
	      $outMessage+= " *** FAIL ***"
             $exitvalue=1;
            }
            else {
	     $outMessage+=" OK"
            }
    
}
write-host $outMessage
exit $exitValue