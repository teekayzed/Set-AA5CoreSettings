#requires -version 2
<#
.SYNOPSIS
  Changes settings on AppAssure5 Core

.DESCRIPTION
  Modifies settings on an AppAssure 5 Core for Client Timeout Settings, number of streams,
  timeouts and caching policies. 

.PARAMETERS
  No parameters required.

.INPUTS
  None

.OUTPUTS
  None

.NOTES
  Version:        1.0
  Author:         teekayzed
  Creation Date:  February 11, 2015
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp"
$sLogName = "<script_name>.log"
$sLogFile = $sLogPath + "\" + $sLogName

#Global Variables
$global:CoreRepositories = @()

#Client Timeout Settings
$ConnectionTimeout = 00:15:00 #hh:mm:ss
$ReadWriteTimeout = 00:15:00 #hh:mm:ss
$ConnectionUITimeout = 00:15:00 #hh:mm:ss
$ReadWriteUITimeout = 00:15:00 #hh:mm:ss

#Replication Service Settings
$MaxParallelStreams = 4
$RemoteReplicationSyncJobTimeout = 00:30:00 #hh:mm:ss
$VolumeImageSessionTimeout = 01:00:00 #hh:mm:ss

#AppAssure Vdisk Parameters - All times in milliseconds
$VdiskAsyncNetworkTimeout = 1200000
$VdiskNetworkTimeout = 600000

#AppAssure VStor Parameters - Times in milliseconds
$VStorNetworkTimeout = 600000


#-----------------------------------------------------------[Functions]------------------------------------------------------------

#Gracefully Shutdown Core  -  https://support.software.dell.com/kb/119400
Function Stop-AA5CoreService{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "Stopping AppAssure core services..."
  }
  
  Process{
    Try{
      #Dismount all mounted recovery points
      Remove-Mounts
      #Suspend all snapshots
      Suspend-Snapshot -All
      #Suspend replication to the Replay 5 Core offsite
      Suspend-Replication -Outgoing mail.domain.com -All
      #Suspend continual VM exports
      Suspend-VMexport -All
      #Set AA5 Service to disabled so it doesn't restart by itself
      Set-Service AppAssureCore -StartupType Disabled
      #Stop the AA5 service
      Stop-Service AppAssureCore
      #Test to see if Core.Service is still running. If so, force kill it.
      Get-Process Core.Service
      if($?) {Stop-Process -Processname Core.Service -Force}
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Start Core Services after gracefully having shut them down.
Function Start-AA5CoreService{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      #Enables the core service
      Sc.exe Config AppAssureCore Start= Delayed-Auto
      #Starts the core service
      Start-Service AppAssureCore
      #Resumes snapshots
      Resume-Snapshot -All
      #Resumes replication
      Resume-Replication -Outgoing mail.domain.com -All
      #Resume VM standby
      Resume-Vmexport -All
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Sets the AA5 Core's Client Timeout Settings for the following: Connection, ReadWrite,
#ConnectionUI, and ReadWriteUI as specified in the declarations.
Function Set-ClientTimeoutSettings($ConnectionTimeout,$ReadWriteTimeout,$ConnectionUITimeout,$ReadWriteUITimeout){
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      $RootKey = "HKLM:\SOFTWARE\AppRecovery\Core\CoreSettings\ClientTimeoutSettings"
      Set-ItemProperty -Path $RootKey -Name ConnectionTimeout -Value $ConnectionTimeout
      Set-ItemProperty -Path $RootKey -Name ReadWriteTimeout -Value $ReadWriteTimeout
      Set-ItemProperty -Path $RootKey -Name ConnectionUITimeout -Value $ConnectionUITimeout
      Set-ItemProperty -Path $RootKey -Name ReadWriteUITimeout -Value $ReadWriteUITimeout
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Sets the AA5 Core's Maximum number of Parallel Streams, Remote Sync timeout, and
#volume image session timeouts as specified in the declarations.
Function Set-ReplicationService($MaxParallelStreams,$RemoteReplicationSyncJobTimeout,$VolumeImageSessionTimeout){
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      $RootKey = "HKLM:\SOFTWARE\AppRecovery\Core\Replication\ReplicationService"
      Set-ItemProperty -Path $RootKey -Name MaxParallelStreams -Value $MaxParallelStreams
      Set-ItemProperty -Path $RootKey -Name RemoteReplicationSyncJobTimeout -Value $RemoteReplicationSyncJobTimeout
      Set-ItemProperty -Path $RootKey -Name VolumeImageSessionTimeout -Value $VolumeImageSessionTimeout
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Sets the AA5 Core's Vdisk Parameters as specified in the declarations
Function Set-VdiskParameters($VdiskAsyncNetworkTimeout,$VdiskNetworkTimeout){
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      $RootKey = "HKLM:\System\CurrentControlSet\Services\AAVdisk\Parameters"
      Set-ItemProperty -Path $RootKey -Name AsyncNetworkTimeout -Value $VdiskAsyncNetworkTimeout
      Set-ItemProperty -Path $RootKey -Name NetworkTimeout -Value $VdiskNetworkTimeout
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Sets the AA5 Core's VStor Parameters as specified in the declarations
Function Set-VStorParameters($VStorNetworkTimeout){
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      $RootKey = "HKLM:\System\CurrentControlSet\Services\AAVStor\Parameters"
      Set-ItemProperty -Path $RootKey -Name NetworkTimeout -Value $VStorNetworkTimeout
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Retrieves OS Version
Function Get-OSVersion{
  Param()

  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      <#
        5.0.x = Server 2000
        5.1.x = XP
        5.2.x = Server 2003/R2, XP Pro x64
        6.0.x = Server 2008, Vista
        6.1.x = Server 2008 R2, Windows 7
        6.2.x = Server 2012, Windows 8
        6.3.x = Server 2012 R2, Windows 8.1
      #>  
      $OSversion = Get-WmiObject Win32_OperatingSystem | Select Version
      $OSversion = $OSversion.Version
      return $OSversion
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Retrieves the UID for each repository on the AA5 Core
Function Get-CoreRepositories{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "Retrieving repositories..."
  }
  
  Process{
    Try{
      #Registry Key where AA5 Repositories are supposed to be located
	  $RepositoryKey= "HKLM:\Software\AppRecovery\Core\Repositories"
	  #Get an array of the subkeys... should be one for each repository
	  $Keys = Get-ChildItem $RepositoryKey
      #Create an empty array to house the list of repositories
	  Foreach ($Key in $Keys) {
	      #$Key.name is a value like: HKEY_LOCAL_MACHINE\AppRecovery\Core\Repositories\c70c8fcf-7eeb-4cf5-9cd7-5766332c8f50
   	      # so let's split it to get just the server name 
	      $tmparray=$Key.Name.Split("\")
	      #Repository UID should be last element of the array
	      $RepositoryUID = $tmpArray[-1]
          $global:CoreRepositories +=  $RepositoryUID
      }
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#Sets the AA5 Core's WriteCachingPolicy to each repository and extent
Function Set-WriteCachingPolicy{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      <code goes here>
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}




<#

Function <FunctionName>{
  Param()
  
  Begin{
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process{
    Try{
      <code goes here>
    }
    
    Catch{
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End{
    If($?){
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}

#>

#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
Get-CoreRepositories
Write-Host $global:CoreRepositories
#Log-Finish -LogPath $sLogFile
