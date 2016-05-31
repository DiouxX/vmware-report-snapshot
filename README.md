# VMWare Snapshot Report

## Description
Ce script de réaliser un rapport avec la liste des snpashots

## Utilisation

* PathToReport : Chemin du fichier de rapport 

* CredentialFile : Chemin ou nom du fichier crédential
    
* To : Destinataire mail du rapport
 
* From : Expéditeur du rapport mail

* SMTPServer : Serveur mail

### Création du fichier crédential XML
<code></code><code>PowerShell
New-VICredentialStoreItem -Host ESXorvCenterHostname -User root -Password "Super$ecretPassword" -File credential-vsphere.xml<code></code><code>

## Exemple
### 1er Méthode : Passer en argument
```sh
.\vmware-report-snapshot.ps1 -CredentialFile C:\credential-vsphere.xml -SMTPServer mail.domain.com -From report-vmware@domain.com -To user@domain.com
```

### 2ème Méthode : Modification des variables (deconseillé)

* [string]$CredentialFile="credential-vsphere.xml",
    
* [string]$To = "user@domain.com",
* [string]$From = "report-vmware@domain.com",
* [string]$SMTPServer = "mail.domain.com"

```sh
.\vmware-report-snapshot.ps1
```