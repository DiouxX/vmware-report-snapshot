Param (
    [Alias("Host")]
    [string]$PathToReport,
    [string]$CredentialFile="credential-vsphere.xml",
    
    [string]$To = "",
    [string]$From = "",
    [string]$SMTPServer = ""
)


$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TR:Hover TD {Background-Color: #C1D5F8;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
.odd  { background-color:#ffffff; }
.even { background-color:#dddddd; }
</style>
<title>
Snapshot Report - $VIServer
</title>
"@
 
Function Set-AlternatingRows {
    [CmdletBinding()]
         Param(
             [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
             [object[]]$HTMLDocument,
 
             [Parameter(Mandatory=$True)]
             [string]$CSSEvenClass,
 
             [Parameter(Mandatory=$True)]
             [string]$CSSOddClass
         )
     Begin {
         $ClassName = $CSSEvenClass
     }
     Process {
         [string]$Line = $HTMLDocument
         $Line = $Line.Replace("<tr>","<tr class=""$ClassName"">")
         If ($ClassName -eq $CSSEvenClass)
         {    $ClassName = $CSSOddClass
         }
         Else
         {    $ClassName = $CSSEvenClass
         }
         $Line = $Line.Replace("<table>","<table width=""50%"">")
         Return $Line
     }
}

#Chargement du module Vmware
If (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Throw "Problem loading VMware.VimAutomation.Core snapin because ""$($Error[1])""" }
}

#Récupération du fichier avec les identifiants
Write-Host "Fichier Credential : " $CredentialFile

#Si la variable contient un \ => un chemine passé en paramètre
If(-Not ($CredentialFile.Contains("\")))
{
    Write-Host "Fichier direct"
    $PathCredentialFile = Split-Path $Script:MyInvocation.MyCommand.Path -Parent
    $PathCredentialFile += "\" + $CredentialFile
}

Write-Host "Chemin du fichier : " $PathCredentialFile 

$credential = Get-VICredentialStoreItem -File $PathCredentialFile

#Affectation de la variable VIServer
$VIServer = $credential.Host
#$VIServer

#Connexion au vsphere
$connection = Connect-VIServer -Server $credential.Host -User $credential.User -Password $credential.Password -WarningAction SilentlyContinue

$Report = Get-VM | Get-Snapshot | Select VM,Name,Description,@{Label="Size";Expression={"{0:N2} GB" -f ($_.SizeGB)}},Created,@{Label="Created by";Expression={''}}

foreach($snap in $Report) 
{
#Si le message est en français
$snap.'Created by'= Get-VIEvent -entity (get-vm $snap.vm) -type info -MaxSamples 1000 | Where { $_.FullFormattedMessage.contains("Créer un snapshot de machine virtuelle")}| Select-Object -First 1 -ExpandProperty username
#if the message is on English
#$snap.'Created by'= Get-VIEvent -entity (get-vm $snap.vm) -type info -MaxSamples 1000 | Where { $_.FullFormattedMessage.contains("Create virtual machine snapshot")}| Select-Object -First 1 -ExpandProperty username 
} 

If (-not $Report)
{  $Report = New-Object PSObject -Property @{
      VM = "No snapshots found on any VM's controlled by $VIServer"
      Name = ""
      Description = ""
      Size = ""
      Created = ""
   }
}



$Report = $Report | Select VM,Name,Description,Size,Created,"Created by" | ConvertTo-Html -Head $Header -PreContent "<p><h2>Snapshot Report - $VIServer</h2></p><br>" | Set-AlternatingRows -CSSEvenClass even -CSSOddClass odd
	
#Si on veut enregistrer le rapport à un endroit
#$Report | Out-File $PathToReport\SnapShotReport.html

#Fonction d'envoi de mail
$MailSplat = @{
    To         = $To
    From       = $From
    Subject    = "$VIServer Snapshot Report"
    Body       = ($Report | Out-String)
    BodyAsHTML = $true
    SMTPServer = $SMTPServer
}

Send-MailMessage @MailSplat

#Deconnexion du VIServer sans prompt
Disconnect-VIServer -Server $connection -Force -Confirm:$false