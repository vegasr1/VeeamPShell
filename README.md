# VeeamPShell
Powershell script to backup Veeam VMs
This is a Simple powershell script that I have set to run using a scheduled task on our Veeam backup server.
The script runs 2 times a week to store the .vbk files on site for weekly tape backups for better retention.
This is on a development system so its not 100% required to have retention on our backups however we still 
want to be able to have things in a state that can be restored for practice as needed for production systems.

<img src="veeam-pshell.jpg">

Original Credit Goes to https://thesysadminchannel.com/automate-backups-start-vbrzip-powershell-veeam-backup-free-edition
I have modified this work to include warning and errors as well as to send a report when all backups are completed.
