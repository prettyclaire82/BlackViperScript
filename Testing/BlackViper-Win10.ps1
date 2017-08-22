##########
# Win 10 Black Viper Service Configuration Script
#
# Black Viper's Service Configurations
#  Author: Charles "Black Viper" Sparks
# Website: http://www.blackviper.com/
#
# Script + Menu(GUI) By
#  Author: Madbomb122
# Website: https://github.com/madbomb122/BlackViperScript/
#
$Script_Version = "3.6"
$Minor_Version = "1"
$Script_Date = "Aug-19-2017"
#$Release_Type = "Stable"
$Release_Type = "Testing"
##########

## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!                                            !!
## !!             SAFE TO EDIT ITEM              !!
## !!            AT BOTTOM OF SCRIPT             !!
## !!                                            !!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
## !!                                            !!
## !!                  CAUTION                   !!
## !!        DO NOT EDIT PAST THIS POINT         !!
## !!                                            !!
## !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

<#------------------------------------------------------------------------------
Copyright (c) 1999-2017 Charles "Black Viper" Sparks - Services Configuration

The MIT License (MIT)

Copyright (c) 2017 Madbomb122 - Black Viper Service Script

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

--------------------------------------------------------------------------------

.Prerequisite to run script
    System: Windows 10 x64
    Edition: Home or Pro     (Can run on other Edition AT YOUR OWN RISK)
    Build: Creator's Update  (Can run on other Build AT YOUR OWN RISK)
    Files: This script and 'BlackViper.csv' (Service Configurations)

.DESCRIPTION
 Script that can set services based on Black Viper's Service Configurations. 

 AT YOUR OWN RISK YOU CAN 
  1. Run the script on x32 w/o changing settings (But shows a warning) 
  2. Skip the check for 
      A. Home/Pro ($Script:EditionCheck variable bottom of script or use -sec switch) 
      B. Creator's Update ($Script:BuildCheck variable bottom of script or use -sbc switch) 

.BASIC USAGE
  Run script with powershell.exe -NoProfile -ExecutionPolicy Bypass -File BlackViper-Win10.ps1
  or Use bat file provided

  Then Use the Gui and Select the desired Choices

.ADVANCED USAGE
 One of the following Methods...
  1. Edit values at bottom of the script then run script
  2. Edit bat file and run
  3. Run the script with one of these arguments/switches (space between multiple)

--Basic Switches--
 Switches       Description of Switch
  -atos          (Accepts ToS)
  -auto          (Implies -atos...Runs the script to be Automated.. Closes on - User Input, Errors, or End of Script)

--Service Configuration Switches--
  -default       (Runs the script with Services to Default Configuration)
  -safe          (Runs the script with Services to Black Viper's Safe Configuration)
  -tweaked       (Runs the script with Services to Black Viper's Tweaked Configuration)
  -lcsc File.csv (Loads Custom Service Configuration, File.csv = Name of your backup/custom file)

--Service Choice Switches--
  -all           (Every windows services will change)
  -min           (Just the services different from the default to safe/tweaked list)

--Update Switches--
  -usc           (Checks for Update to Script file before running)
  -use           (Checks for Update to Service file before running)
  -sic           (Skips Internet Check, if you cant ping github.com for some reason)

--Log Switches--
  -log           (Makes a log file Script.log)
  -baf           (Log File of Services Configuration Before and After the script)
  
--AT YOUR OWN RISK Switches--
  -sec           (Skips Edition Check by Setting Edition as Pro)
  -secp           ^Same as Above
  -sech          (Skips Edition Check by Setting Edition as Home)
  -sbc           (Skips Build Check)

--Misc Switches--
  -bcsc          (Backup Current Service Configuration)
  -dry           (Runs the script and shows what services will be changed)
  -diag          (Shows diagnostic information, Stops -auto)
  -snis          (Show not installed Services)
------------------------------------------------------------------------------#>
##########
# Pre-Script -Start
##########

$Script:WindowVersion = [Environment]::OSVersion.Version.Major
If($WindowVersion -ne 10) {
    Clear-Host
	Write-Host "Sorry, this Script supports Windows 10 ONLY." -ForegroundColor "cyan" -BackgroundColor "black"
	If($Automated -ne 1){ Read-Host -Prompt "`nPress Any key to Close..." }
	Exit
}

If($Release_Type -eq "Stable"){ $ErrorActionPreference = 'silentlycontinue' }

$Global:PassedArg = $args
$Global:filebase = $PSScriptRoot + "\"

If(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PassedArg" -Verb RunAs ;Exit
}

$URL_Base = "https://raw.githubusercontent.com/madbomb122/BlackViperScript/master/"
$Version_Url = $URL_Base + "Version/Version.csv"
$Service_Url = $URL_Base + "BlackViper.csv"

If([System.Environment]::Is64BitProcess){ $OSType = 64 }
$Script:ServiceEnd = (Get-Service "*_*" | Select Name | Select-Object -first 1).Name.split('_')[1]

$colors = @(
"black",        #0
"blue",         #1
"cyan",         #2
"darkblue",     #3
"darkcyan",     #4
"darkgray",     #5
"darkgreen",    #6
"darkmagenta",  #7
"darkred",      #8
"darkyellow",   #9
"gray",         #10
"green",        #11
"magenta",      #12
"red",          #13
"white",        #14
"yellow")       #15

$ServicesTypeList = @(
'',          #0 -None (Skip/Not Installed)
'Disabled',  #1 -Disable
'Manual',    #2 -Manual
'Automatic', #3 -Automatic
'Automatic') #4 -Automatic (Delayed Start)

$Script:Black_Viper = 0
$Script:All_or_Min = "-min"
$Script:RunScript = 2
$Script:ErrorDi = ""

##########
# Pre-Script -End
##########
# Multi Use Functions -Start
##########

Function MenuBlankLineLog { DisplayOutMenu "|                                                   |" 14 0 1 1 }
Function MenuLineLog { DisplayOutMenu "|---------------------------------------------------|" 14 0 1 1 }
Function LeftLineLog { DisplayOutMenu "| " 14 0 0 1 }
Function RightLineLog { DisplayOutMenu " |" 14 0 1 1 }

Function MenuBlankLine { DisplayOutMenu "|                                                   |" 14 0 1 0 }
Function MenuLine { DisplayOutMenu "|---------------------------------------------------|" 14 0 1 0 }
Function LeftLine { DisplayOutMenu "| " 14 0 0 0 }
Function RightLine { DisplayOutMenu " |" 14 0 1 0 }

Function OpenWebsite([String]$Url) { [System.Diagnostics.Process]::Start($Url) }
Function DownloadFile([String]$Url, [String]$FilePath) { (New-Object System.Net.WebClient).DownloadFile($Url, $FilePath) }
Function ShowInvalid([Int]$InvalidA) { If($InvalidA -eq 1) { Write-Host "`nInvalid Input" -ForegroundColor Red -BackgroundColor Black -NoNewline } Return 0 }
Function LaptopCheck { $Script:PCType = (Get-WmiObject -Class Win32_ComputerSystem).PCSystemType ;If($PCType -ne 2) { Return "-Desk" } Return "-Lap" }

Function DisplayOutMenu([String]$TxtToDisplay, [int]$TxtColor, [int]$BGColor, [int]$NewLine, [int]$LogOut) {
    If($NewLine -eq 0) {
        If($ScriptLog -eq 1 -and $LogOut -eq 1){ Write-Output $TxtToDisplay 4>&1 | Out-File -filepath $LogFile -NoNewline -Append }
        Write-Host -NoNewline $TxtToDisplay -ForegroundColor $colors[$TxtColor] -BackgroundColor $colors[$BGColor]
    } Else {
        If($ScriptLog -eq 1 -and $LogOut -eq 1){ Write-Output $TxtToDisplay 4>&1 | Out-File -filepath $LogFile -Append }
        Write-Host $TxtToDisplay -ForegroundColor $colors[$TxtColor] -BackgroundColor $colors[$BGColor]
    }
}

Function DisplayOut([String]$TxtToDisplay, [int]$TxtColor, [int]$BGColor) {
    If($ScriptLog -eq 1){ Write-Output $TxtToDisplay 4>&1 | Out-File -filepath $LogFile -Append }
    If($TxtColor -le 15){ Write-Host $TxtToDisplay -ForegroundColor $colors[$TxtColor] -BackgroundColor $colors[$BGColor] } Else { Write-Host $TxtToDisplay }
}

Function  AutomatedExitCheck([int]$ExitBit) {
    If($Automated -ne 1){ Read-Host -Prompt "`nPress Any key to Close..." }
    If($ExitBit -eq 1){ Exit }
}

Function Error_Top_Display {
    Clear-Host
    DiagnosticCheck 0
    MenuLineLog
    LeftLineLog ;DisplayOutMenu "                      Error                      " 13 0 0 1 ;RightLineLog
    MenuLineLog
    MenuBlankLineLog
}

Function Error_Bottom {
    MenuBlankLineLog
    MenuLineLog
    If($Diagnostic -eq 1) {
        DiagnosticCheck 0
        Read-Host -Prompt "`nPress Any key to Close..."
        Exit
    } Else {
        AutomatedExitCheck 1
    }
}

Function DiagnosticCheck([int]$Bypass) {
    If($Release_Type -ne "Stable" -or $Bypass -eq 1 -or $Diagnostic -eq 1) {
        DisplayOutMenu " Diagnostic Output" 15 0 1 1
        DisplayOutMenu " Some items may be blank" 15 0 1 1
        DisplayOutMenu " --------Start--------" 15 0 1 1
        DisplayOutMenu " Script Version = $Script_Version" 15 0 1 1
        DisplayOutMenu " Script Minor Version = $Minor_Version" 15 0 1 1
        DisplayOutMenu " Release Type = $Release_Type" 15 0 1 1
        DisplayOutMenu " Services Version = $ServiceVersion" 15 0 1 1
        DisplayOutMenu " Error = $ErrorDi" 13 0 1 1
        DisplayOutMenu " Window = $WindowVersion" 15 0 1 1
        DisplayOutMenu " Edition = $FullWinEdition" 15 0 1 1
        DisplayOutMenu " Edition SKU# = $WinSku" 15 0 1 1
        DisplayOutMenu " Build = $BuildVer" 15 0 1 1
        DisplayOutMenu " Version = $Win10Ver" 15 0 1 1
        DisplayOutMenu " PC Type = $PCType" 15 0 1 1
        DisplayOutMenu " Desktop/Laptop = $IsLaptop" 15 0 1 1
        DisplayOutMenu " ServiceConfig = $Black_Viper" 15 0 1 1
        DisplayOutMenu " All/Min = $All_or_Min" 15 0 1 1        
        DisplayOutMenu " ToS = $AcceptToS" 15 0 1 1
        DisplayOutMenu " Automated = $Automated" 15 0 1 1
        DisplayOutMenu " ScriptVerCheck = $ScriptVerCheck" 15 0 1 1
        DisplayOutMenu " ServiceVerCheck = $ServiceVerCheck" 15 0 1 1
        DisplayOutMenu " InternetCheck = $InternetCheck" 15 0 1 1
        DisplayOutMenu " ShowChanged = $ShowChanged" 15 0 1 1
        DisplayOutMenu " ShowAlreadySet = $ShowAlreadySet" 15 0 1 1
        DisplayOutMenu " ShowNonInstalled = $ShowNonInstalled" 15 0 1 1
        DisplayOutMenu " ShowSkipped = $ShowSkipped" 15 0 1 1
        DisplayOutMenu " EditionCheck = $EditionCheck" 15 0 1 1
        DisplayOutMenu " BuildCheck = $BuildCheck" 15 0 1 1
        DisplayOutMenu " Args = $PassedArg" 15 0 1 1
        DisplayOutMenu " ---------End---------`n" 15 0 1 1
    }
}

##########
# Multi Use Functions -End
##########
# TOS -Start
##########

Function TOSDisplay {
    Clear-Host
    $BorderColor = 14
    If($Release_Type -ne "Stable") {
        $BorderColor = 15
        DisplayOutMenu "|---------------------------------------------------|" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "                  Caution!!!                     " 13 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu " This script is still being tested.              " 14 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "              USE AT YOUR OWN RISK.              " 14 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
    }
    If($OSType -ne 64) {
        $BorderColor = 15
        DisplayOutMenu "|---------------------------------------------------|" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "                    WARNING!!                    " 13 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "      These settings are ment for x64 Bit.       " 14 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "              USE AT YOUR OWN RISK.              " 14 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
        DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
    }
    DisplayOutMenu "|---------------------------------------------------|" $BorderColor 0 1 0
    DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "                  Terms of Use                   " 11 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
    DisplayOutMenu "|---------------------------------------------------|" $BorderColor 0 1 0
    DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
    DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "This program comes with ABSOLUTELY NO WARRANTY.  " 2 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
    DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "This is free software, and you are welcome to    " 2 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
    DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "redistribute it under certain conditions.        " 2 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
    DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
    DisplayOutMenu "| " $BorderColor 0 0 ;DisplayOutMenu "Read License file for full Terms.                " 2 0 0 ;DisplayOutMenu " |" $BorderColor 0 1 0
    DisplayOutMenu "|                                                   |" $BorderColor 0 1 0
    DisplayOutMenu "|---------------------------------------------------|" $BorderColor 0 1 0
}

Function TOS {
    while($TOS -ne "Out") {
        TOSDisplay
        $Invalid = ShowInvalid $Invalid
        $TOS = Read-Host "`nDo you Accept? (Y)es/(N)o"
        Switch($TOS.ToLower()) {
            { $_ -eq "n" -or $_ -eq "no" } { Exit ;Break }
            { $_ -eq "y" -or $_ -eq "yes" } { $TOS = "Out" ;TOSyes ;Break }
            default { $Invalid = 1 ;Break }
        }
    } Return
}

Function TOSyes {
    $Script:AcceptToS = "Accepted-Script"
    $Script:RunScript = 1
    If($LoadServiceConfig -eq 1) {
        ServiceSet "StartType"
    } ElseIf($Black_Viper -eq 0) {
        Gui-Start
    } Else {
        Black_Viper_Set $Black_Viper $All_or_Min
    }
}

##########
# TOS -End
##########
# GUI -Start
##########

Function Update-Window {
    [cmdletBinding()]
    Param($Control, $Property, $Value, [switch]$AppendContent)
    If($Property -eq "Close"){ $syncHash.Window.Dispatcher.invoke([action]{$syncHash.Window.Close()},"Normal") ;Return }
    $form.Dispatcher.Invoke([action]{ If($PSBoundParameters['AppendContent']){ $Control.AppendText($Value) } Else{ $Control.$Property = $Value } }, "Normal")
}

Function OpenSaveDiaglog([Int]$SorO){
    If($SorO -eq 0){ $SOFileDialog = New-Object System.Windows.Forms.OpenFileDialog } Else{ $SOFileDialog = New-Object System.Windows.Forms.SaveFileDialog }
    $SOFileDialog.initialDirectory = $filebase
    $SOFileDialog.filter = "CSV (*.csv)| *.csv"
    $SOFileDialog.ShowDialog() | Out-Null
    If($SorO -eq 0){ $Script:ServiceConfigFile = $SOFileDialog.filename ;$WPF_LoadFileTxtBox.Text = $ServiceConfigFile ;RunDisableCheck } Else{ Save_Service $SOFileDialog.filename }
}

Function HideCustomSrvStuff {
    $WPF_LoadServicesButton.IsEnabled = $True
    $WPF_RadioAll.IsEnabled = $True
    $WPF_RadioMin.IsEnabled = $True
    ForEach($Var in $CNoteList) { $Var.Value.Visibility = 'Hidden' }
    $WPF_LoadFileTxtBox.Visibility = 'Hidden'
    $WPF_btnOpenFile.Visibility = 'Hidden'
}

Function Gui-Start {
    Clear-Host
    DisplayOutMenu "Preparing GUI, Please wait..." 15 0 1 0
    $TPath = $filebase + "BlackViper.csv"
    If(Test-Path $TPath -PathType Leaf) {
        $TMP = Import-Csv $TPath
        $ServiceVersion = ($TMP[0]."Def-Home-Full")
        $ServiceDate = ($TMP[0]."Def-Home-Min")
    } Else {
        $ServiceVersion = "Missing File"
        $ServiceDate = ""
    }

[xml]$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
  Title="Black Viper Service Configuration Script By: MadBomb122" Height="343" Width="490" ResizeMode="NoResize" BorderBrush="Black" Background="White" WindowStyle="ThreeDBorderWindow">
<Window.Effect> <DropShadowEffect/></Window.Effect><Grid>
 <Label Content="Service Version:" HorizontalAlignment="Left" Margin="256,276,0,0" VerticalAlignment="Top" Height="25"/>
 <Label Content="Script Version:" HorizontalAlignment="Left" Margin="1,276,0,0" VerticalAlignment="Top" Height="25"/>
 <Button Name="RunScriptButton" Content="Run Script" HorizontalAlignment="Left" Margin="0,238,0,0" VerticalAlignment="Top" Width="474" Height="20" FontWeight="Bold"/>
 <Button Name="CopyrightButton" Content="Copyright" HorizontalAlignment="Left" Margin="114,259,0,0" VerticalAlignment="Top" Width="114" FontStyle="Italic"/>
 <Button Name="BlackViperWSButton" Content="BlackViper's Website" HorizontalAlignment="Left" Margin="228,259,0,0" VerticalAlignment="Top" Width="117" FontStyle="Italic"/>
 <Button Name="Madbomb122WSButton" Content="Madbomb122's Website" HorizontalAlignment="Left" Margin="345,259,0,0" VerticalAlignment="Top" Width="129" FontStyle="Italic"/>
 <Button Name="DonateButton" Content="Donate to me" HorizontalAlignment="Left" Margin="0,259,0,0" VerticalAlignment="Top" Width="114" FontStyle="Italic"/> <TextBox Name="Script_Ver_Txt" HorizontalAlignment="Left" Height="24" Margin="82,280,0,0" TextWrapping="Wrap" Text="2.8.0 (6-21-2017)" VerticalAlignment="Top" Width="125" IsEnabled="False"/>
 <TextBox Name="Service_Ver_Txt" HorizontalAlignment="Left" Height="24" Margin="345,280,0,0" TextWrapping="Wrap" Text="2.0 (5-21-2017)" VerticalAlignment="Top" Width="129" IsEnabled="False"/>
 <TextBox Name="Release_Type_Txt" HorizontalAlignment="Left" Height="24" Margin="207,280,0,0" TextWrapping="Wrap" Text="Testing" VerticalAlignment="Top" Width="48" IsEnabled="False"/>
 <TabControl Name="TabControl" Height="235" VerticalAlignment="Top">
  <TabItem Name="Services_Tab" Header="Services Options" Margin="-2,0,2,0"><Grid Background="#FFE5E5E5">
   <Label Content="Service Configurations:" HorizontalAlignment="Left" Margin="2,63,0,0" VerticalAlignment="Top" Height="27" Width="146" FontWeight="Bold"/>
   <ComboBox Name="ServiceConfig" HorizontalAlignment="Left" Margin="139,66,0,0" VerticalAlignment="Top" Width="118" Height="23">
    <ComboBoxItem Content="Default" HorizontalAlignment="Left" Width="116" IsSelected="True"/>
    <ComboBoxItem Content="Safe" HorizontalAlignment="Left" Width="116"/>
    <ComboBoxItem Content="Tweaked" HorizontalAlignment="Left" Width="116"/>
    <ComboBoxItem Content="Custom Setting *" HorizontalAlignment="Left" Width="116"/>
   </ComboBox>
   <RadioButton Name="RadioAll" Content="All -Change All Services" HorizontalAlignment="Left" Margin="5,26,0,0" VerticalAlignment="Top" IsChecked="True"/>
   <RadioButton Name="RadioMin" Content="Min -Change Services that are Different from Default to Safe/Tweaked" HorizontalAlignment="Left" Margin="5,41,0,0" VerticalAlignment="Top"/>
   <Label Content="Black Viper Configuration Options (BV Services Only)" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="2,3,0,0" FontWeight="Bold"/>
   <Label Name="CustomNote1" Content="*Note: Configure Bellow" HorizontalAlignment="Left" Margin="262,63,0,0" VerticalAlignment="Top" Width="148" Height="27" FontWeight="Bold"/>
   <Rectangle Fill="#FFFFFFFF" Height="1" Margin="0,97,-6,0" Stroke="Black" VerticalAlignment="Top"/>
   <Button Name="btnOpenFile" Content="Browse File" HorizontalAlignment="Left" Margin="5,120,0,0" VerticalAlignment="Top" Width="66" Height="22"/>
   <TextBox Name="LoadFileTxtBox" HorizontalAlignment="Left" Height="50" Margin="5,150,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="461" IsReadOnly="True" Background="#FFECECEC"/>
   <Label Name="CustomNote3" Content="Config File: Browse for file" HorizontalAlignment="Left" Margin="76,118,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <Label Name="CustomNote2" Content="Custom Configuration" HorizontalAlignment="Left" Margin="164,95,0,0" VerticalAlignment="Top" Width="135" Height="26" FontWeight="Bold"/></Grid>
  </TabItem>
  <TabItem Name="Options_tab" Header="Script Options" Margin="-2,0,2,0"><Grid Background="#FFE5E5E5">
   <Label Content="Display Options" HorizontalAlignment="Left" Margin="4,5,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <Label Content="Log Options" HorizontalAlignment="Left" Margin="4,128,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <Label Content="Misc Options" HorizontalAlignment="Left" Margin="4,67,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <CheckBox Name="Dryrun_CB" Content="Dryrun -Shows what will be changed" HorizontalAlignment="Left" Margin="9,90,0,0" VerticalAlignment="Top" Height="15" Width="213"/>
   <CheckBox Name="LogBeforeAfter_CB" Content="Services Before and After" HorizontalAlignment="Left" Margin="9,150,0,0" VerticalAlignment="Top" Height="16" Width="158"/>
   <CheckBox Name="ShowAlreadySet_CB" Content="Show Already Set Services" HorizontalAlignment="Left" Margin="9,28,0,0" VerticalAlignment="Top" Height="15" Width="158" IsChecked="True"/>
   <CheckBox Name="ShowNonInstalled_CB" Content="Show Not Installed Services" HorizontalAlignment="Left" Margin="9,43,0,0" VerticalAlignment="Top" Height="15" Width="166"/>
   <CheckBox Name="ScriptLog_CB" Content="Script Log:" HorizontalAlignment="Left" Margin="9,166,0,0" VerticalAlignment="Top" Height="14" Width="76"/>
   <CheckBox Name="BackupServiceConfig_CB" Content="Backup Current Service Configuration" HorizontalAlignment="Left" Margin="9,105,0,-11" VerticalAlignment="Top" Height="15" Width="218"/>
   <TextBox Name="LogNameInput" HorizontalAlignment="Left" Height="20" Margin="87,164,0,0" TextWrapping="Wrap" Text="Script.log" VerticalAlignment="Top" Width="140" IsEnabled="False"/>
   <CheckBox Name="ScriptVerCheck_CB" Content="Script Update*" HorizontalAlignment="Left" Margin="244,105,0,0" VerticalAlignment="Top" Height="15" Width="99"/>
   <CheckBox Name="ServiceUpdateCB" Content="Service Update" HorizontalAlignment="Left" Margin="244,90,0,0" VerticalAlignment="Top" Height="15" Width="99"/>
   <CheckBox Name="InternetCheck_CB" Content="Skip Internet Check" HorizontalAlignment="Left" Margin="244,120,0,0" VerticalAlignment="Top" Height="15" Width="124"/>
   <Label Content="*Will run and use current settings" HorizontalAlignment="Left" Margin="238,129,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <Label Content="Update Items" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="239,67,0,0" FontWeight="Bold"/>
   <CheckBox Name="BuildCheck_CB" Content="Skip Build Check" HorizontalAlignment="Left" Margin="244,28,0,0" VerticalAlignment="Top" Height="15" Width="110"/>
   <CheckBox Name="EditionCheck_CB" Content="Skip Edition Check Set as :" HorizontalAlignment="Left" Margin="244,43,0,0" VerticalAlignment="Top" Height="15" Width="160"/>
   <ComboBox Name="EditionConfig" HorizontalAlignment="Left" Margin="404,40,0,0" VerticalAlignment="Top" Width="60" Height="23">
    <ComboBoxItem Content="Home" HorizontalAlignment="Left" Width="58"/>
    <ComboBoxItem Content="Pro" HorizontalAlignment="Left" Width="58" IsSelected="True"/>
   </ComboBox>
   <Label Content="SKIP CHECK AT YOUR OWN RISK!" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="238,5,0,0" FontWeight="Bold"/>
   <Rectangle Fill="#FFFFFFFF" HorizontalAlignment="Left" Height="210" Margin="236,-2,0,-3" Stroke="Black" VerticalAlignment="Top" Width="1"/></Grid>
  </TabItem>
  <TabItem Name="ServicesCB_Tab" Header="Services List" Margin="-2,0,2,0"><Grid Background="#FFE5E5E5">
   <ScrollViewer VerticalScrollBarVisibility="Visible" Margin="0,38,1,0"> <StackPanel Name="StackCBHere" Width="458" ScrollViewer.VerticalScrollBarVisibility="Auto" CanVerticallyScroll="True"/></ScrollViewer>
   <Rectangle Fill="#FFFFFFFF" Height="1" Margin="-2,37,2,0" Stroke="Black" VerticalAlignment="Top"/>
   <Button Name="SaveCustomSrvButton" Content="Save Current" HorizontalAlignment="Left" Margin="153,1,0,0" VerticalAlignment="Top" Width="80" Visibility="Hidden"/>
   <Button Name="LoadServicesButton" Content="Load Services" HorizontalAlignment="Left" Margin="3,1,0,0" VerticalAlignment="Top" Width="76"/>
   <Label Name="ServiceNote" Content="Uncheck what you &quot;Don't want to be changed&quot;" HorizontalAlignment="Left" Margin="196,15,0,0" VerticalAlignment="Top" Visibility="Hidden"/>
   <Label Name="ServiceLegendLabel" Content="Service -&gt; Current -&gt; Changed To" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-2,15,0,0" Visibility="Hidden"/>
   <Label Name="ServiceClickLabel" Content="&lt;-- Click to load Service List" HorizontalAlignment="Left" Margin="75,-3,0,0" VerticalAlignment="Top"/>
   <CheckBox Name="CustomBVCB" Content="Use Checked Services" HorizontalAlignment="Left" Margin="288,3,0,0" VerticalAlignment="Top" Width="158" RenderTransformOrigin="0.696,0.4" Visibility="Hidden"/></Grid>
  </TabItem>
  <TabItem Name="Dev_Option_Tab" Header="Dev Option/Contact/About" Margin="-2,0,2,0"><Grid Background="#FFE5E5E5">
   <CheckBox Name="Diagnostic_CB" Content="Diagnostic Output (On Error)" HorizontalAlignment="Left" Margin="9,18,0,0" VerticalAlignment="Top" Height="15" Width="174"/>
   <CheckBox Name="DevLog_CB" Content="Dev Log" HorizontalAlignment="Left" Margin="9,33,0,0" VerticalAlignment="Top" Height="15" Width="174"/>
   <Button Name="EMail" Content="e-mail Madbomb122" HorizontalAlignment="Left" Margin="12,66,0,0" VerticalAlignment="Top" Width="123"/>
   <Label Content="If your having problems email me&#xD;&#xA;&#xD;&#xA;e-mail: Madbomb122@gmail.com" HorizontalAlignment="Left" Margin="200,10,0,0" VerticalAlignment="Top" Width="190"/>
   <Label Content="&lt;-- with a 'Dev Log' if asked to." HorizontalAlignment="Left" Margin="178,26,0,0" VerticalAlignment="Top"/>
   <Label Content="Please check FAQ on my Github before contacting me." HorizontalAlignment="Left" Margin="135,63,0,0" VerticalAlignment="Top" FontWeight="Bold"/>
   <Rectangle Fill="#FFFFFFFF" Height="1" Margin="0,90,0,0" Stroke="Black" VerticalAlignment="Top"/>
   <Label Content="This script lets you set Windows 10's services based on Black Viper's Service &#xD;&#xA;Configurations, your own Service Configuration (If in a proper format), or a backup &#xD;&#xA;of your Service Configurations made by this script.&#xD;&#xA;&#xD;&#xA;This script was created by MadBomb122." HorizontalAlignment="Left" Margin="11,101,0,0" VerticalAlignment="Top" Width="450" Height="91"/></Grid>
  </TabItem>
 </TabControl>
 <Rectangle Fill="#FFFFFFFF" Height="1" Margin="0,237,0,0" Stroke="Black" VerticalAlignment="Top"/>
 <Rectangle Fill="#FFFFFFFF" Height="1" Margin="0,258,0,0" Stroke="Black" VerticalAlignment="Top"/>
 <Rectangle Fill="#FFFFFFFF" Height="1" Margin="0,279,0,0" Stroke="Black" VerticalAlignment="Top"/>
 <Rectangle Fill="#FFFFFFFF" HorizontalAlignment="Left" Margin="255,280,0,0" Stroke="Black" Width="1" Height="25" VerticalAlignment="Top"/>
 <Rectangle Fill="#FFB6B6B6" Stroke="Black" Margin="0,304,0,0" Height="10" VerticalAlignment="Top"/>
 <Rectangle Fill="#FFB6B6B6" Stroke="Black" HorizontalAlignment="Left" Width="10" Margin="474,0,0,0"/> </Grid>
</Window>
"@

    [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $Form = [Windows.Markup.XamlReader]::Load( $reader )
    $xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF_$($_.Name)" -Value $Form.FindName($_.Name) -scope Script}

    $Runspace = [runspacefactory]::CreateRunspace()
    $PowerShell = [PowerShell]::Create()
    $PowerShell.runspace = $Runspace
    $Runspace.Open()
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
    [System.Collections.ArrayList]$VarList = Get-Variable "WPF_*_CB"
    [System.Collections.ArrayList]$CNoteList = Get-Variable "WPF_CustomNote*"
    [System.Collections.ArrayList]$Script:CBNameList = @()

    $WPF_ServiceConfig.add_SelectionChanged({
        If(($WPF_ServiceConfig.SelectedIndex+1) -eq $BVCount) {
            $WPF_RadioAll.IsEnabled = $False
            $WPF_RadioMin.IsEnabled = $False
            ForEach($Var in $CNoteList){ $Var.Value.Visibility = 'Visible' }
            $WPF_LoadFileTxtBox.Visibility = 'Visible'
            $WPF_btnOpenFile.Visibility = 'Visible'
        } Else {
            HideCustomSrvStuff
        }
        RunDisableCheck
    })

    $WPF_RunScriptButton.Add_Click({
        $Script:RunScript = 1
        $Black_Viper = $WPF_ServiceConfig.SelectedIndex + 1
        If($Black_Viper -eq $BVCount) {
            $Script:ServiceConfigFile = $WPF_LoadFileTxtBox.Text
            If(!(Test-Path $ServiceConfigFile -PathType Leaf) -and $ServiceConfigFile -ne $null) {
                [Windows.Forms.MessageBox]::Show("The File '$ServiceConfigFile' does not exist","Error", 'OK')
                $Script:RunScript = 0
            } Else {
                $Script:LoadServiceConfig = 1
                $Script:Black_Viper = 0
            }
        }
        If($RunScript -eq 1){ Gui-Done }
    })

    $WPF_ScriptLog_CB.Add_Checked({ $WPF_LogNameInput.IsEnabled = $True })
    $WPF_ScriptLog_CB.Add_UnChecked({ $WPF_LogNameInput.IsEnabled = $False })
    $WPF_CustomBVCB.Add_Checked({ $RunDisableCheck ;$WPF_SaveCustomSrvButton.content = "Save Selection" })
    $WPF_CustomBVCB.Add_UnChecked({ $RunDisableCheck ;$WPF_SaveCustomSrvButton.content = "Save Current" })
    $WPF_btnOpenFile.Add_Click({ OpenSaveDiaglog 0 })
    $WPF_SaveCustomSrvButton.Add_Click({ OpenSaveDiaglog 1 })
    $WPF_EMail.Add_Click({ OpenWebsite "mailto:madbomb122@gmail.com" })
    $WPF_BuildCheck_CB.Add_Click({ RunDisableCheck })
    $WPF_EditionCheck_CB.Add_Click({ RunDisableCheck })
    $WPF_BlackViperWSButton.Add_Click({ OpenWebsite "http://www.blackviper.com/" })
    $WPF_Madbomb122WSButton.Add_Click({ OpenWebsite "https://github.com/madbomb122/" })
    $WPF_DonateButton.Add_Click({ OpenWebsite "https://www.amazon.com/gp/registry/wishlist/YBAYWBJES5DE/" })
    $WPF_LoadServicesButton.Add_Click({ Generate-Services })
    $WPF_CopyrightButton.Add_Click({ [Windows.Forms.MessageBox]::Show($CopyrightItems,"Copyright", 'OK') })

    $CopyrightItems = 'Copyright (c) 1999-2017 Charles "Black Viper" Sparks - Services Configuration

The MIT License (MIT)

Copyright (c) 2017 Madbomb122 - Black Viper Service Configuration Script

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'

    $Skip_Services = @(
    "PimIndexMaintenanceSvc_",
    "DevicesFlowUserSvc_",
    "UserDataSvc_",
    "UnistoreSvc_",
    "WpnUserService_",
    "AppXSVC",
    "BrokerInfrastructure",
    "ClipSVC",
    "CoreMessagingRegistrar",
    "DcomLaunch",
    "EntAppSvc",
    "gpsvc",
    "LSM",
    "NgcSvc",
    "NgcCtnrSvc",
    "RpcSs",
    "RpcEptMapper",
    "sppsvc",
    "StateRepository",
    "SystemEventsBroker",
    "Schedule",
    "tiledatamodelsvc",
    "WdNisSvc",
    "SecurityHealthService",
    "msiserver",
    "Sense",
    "WdNisSvc",
    "WinDefend")
    For($i=0;$i -ne 5;$i++){ $Skip_Services[$i] = $Skip_Services[$i] + $ServiceEnd }

    $Script:CurrServices = Get-Service | Select DisplayName, Name, StartType
    $Script:RunScript = 0
    If($All_or_Min -eq "-full"){ $WPF_RadioAll.IsChecked = $True } Else{ $WPF_RadioMin.IsChecked = $True }
    If($ScriptLog -eq 1) { $WPF_ScriptLog_CB.IsChecked = $True ;$WPF_LogNameInput.IsEnabled = $True} Else{ $WPF_LogNameInput.IsEnabled = $False }
    If($IsLaptop -eq "-Lap"){ $WPF_ServiceConfig.Items.RemoveAt(2) }
    $Script:BVCount = $WPF_ServiceConfig.Items.Count

    ForEach($Var in $VarList){ If($(Get-Variable -Name ($Var.Name.split('_')[1]) -ValueOnly) -eq 1){ $Var.Value.IsChecked = $True } Else{ $Var.Value.IsChecked = $False } }

    $WPF_EditionCheck_CB.IsChecked = $True
    $WPF_EditionConfig.IsEnabled = $True
    $WPF_EditionConfig.SelectedIndex = 1
    If($EditionCheck -eq "Pro") {
    } ElseIf($EditionCheck -eq "Home") {
        $WPF_EditionConfig.SelectedIndex = 0
    } Else {
        $WPF_EditionCheck_CB.IsChecked = $False
        $WPF_EditionConfig.IsEnabled = $False
    }

    $WPF_LoadFileTxtBox.Text = $ServiceConfigFile
    $WPF_LogNameInput.Text = $LogName
    $WPF_Script_Ver_Txt.Text = "$Script_Version.$Minor_Version ($Script_Date)"
    $WPF_Service_Ver_Txt.Text = "$ServiceVersion ($ServiceDate)"
    $WPF_Release_Type_Txt.Text = $Release_Type
    $Script:ServicesGenerated = $False
    HideCustomSrvStuff
    RunDisableCheck
    Clear-Host
    DisplayOutMenu "Displaying GUI Now" 14 0 1 0
    $Form.ShowDialog() | out-null
}

Function RunDisableCheck {
    If($WPF_BuildCheck_CB.IsChecked){ $Script:BuildCheck = 1 } Else{ $Script:BuildCheck = 0 }
    If($WPF_EditionCheck_CB.IsChecked){ $Script:EditionCheck = $WPF_EditionConfig.Text ;$WPF_EditionConfig.IsEnabled = $True } Else { $Script:EditionCheck = 0 ;$WPF_EditionConfig.IsEnabled = $False }

    $tempfail = 0
    $temp1 = ""
    $temp2 = ""

    If($HomeEditions -contains $WinEdition -or $EditionCheck -eq "Home" -or $WinSku -IN 100..101) {
    } ElseIf($ProEditions -contains $WinEdition -or $EditionCheck -eq "Pro" -or $WinSku -eq 48) {
    } Else {
        $temp1 = "Edition"
        $tempfail++
    }

    If($BuildVer -lt $ForBuild -and $BuildCheck -ne 1) { $tempfail++ ; $temp2 = "Build" }
    If($tempfail -ne 0) {
        $Buttontxt = "Run Disabled Due to "
        If($tempfail -eq 2) {
            $Buttontxt += $temp1 + " & " + $temp2
        } Else {
            If($temp1 -ne ""){ $Buttontxt += $temp1 }
            If($temp2 -ne ""){ $Buttontxt += $temp2 }
        }
        $WPF_RunScriptButton.IsEnabled = $False
        $Buttontxt += " Check"
    } Else {
        If($WPF_CustomBVCB.IsChecked){ $Buttontxt = "Run Script with Checked Services" } Else{ $Buttontxt = "Run Script" }
        $WPF_RunScriptButton.IsEnabled = $True
        If($WPF_ServiceConfig.SelectedIndex + 1 -eq $BVCount) {
            $Script:ServiceConfigFile = $WPF_LoadFileTxtBox.Text
            If(!($ServiceConfigFile) -or !(Test-Path $ServiceConfigFile -PathType Leaf)) { 
                $WPF_RunScriptButton.IsEnabled = $False
                $Buttontxt = "Run Disabled, No Custom Service Selected or Doesn't exist."
                $WPF_LoadServicesButton.IsEnabled = $False
            } Else {
                $WPF_LoadServicesButton.IsEnabled = $True
            }
        }
    } $WPF_RunScriptButton.content = $Buttontxt
}

Function Gui-Done {
    ForEach($Var in $VarList){ If($Var.Value.IsChecked){ $SetValue = 1 } Else{ $SetValue = 0 } ;Set-Variable -Name ($Var.Name.split('_')[1]) -Value $SetValue -scope Script }
    If($WPF_RadioAll.IsChecked){ $Script:All_or_Min = "-full" } Else{ $Script:All_or_Min = "-min" }
    If($WPF_ScriptLog_CB.IsChecked){ $Script:LogName = $WPF_LogNameInput.Text }
    If($WPF_EditionCheck_CB.IsChecked){ $Script:EditionCheck = $WPF_EditionConfig.Text }
    If($WPF_CustomBVCB.IsChecked){ GetCustomBV }

    $Form.Close()
    Black_Viper_Set $Black_Viper $All_or_Min
}

Function Generate-Services {
    $removecb = $False
    If($ServicesGeneratedA){ $OldBVService = $BVService ;$removecb = $True}

    $Black_Viper = $WPF_ServiceConfig.SelectedIndex + 1
    If($Black_Viper -eq $BVCount) {
        $Script:LoadServiceConfig = 1
        $ServiceFilePath = $WPF_LoadFileTxtBox.Text
    } Else {
        If($WPF_RadioAll.IsChecked){ $FullMin = "-Full" } Else{ $FullMin = "-Min" }
        $Script:LoadServiceConfig = 0
        $ServiceFilePath = $filebase + "BlackViper.csv"
    }

    Switch($Black_Viper) {
        {$LoadServiceConfig -eq 1} { $Script:BVService = "StartType" ;Break }
        1 { ($Script:BVService="Def-"+$WinEdition+$FullMin) ;$BVSAlt = "Def-"+$WinEdition+"-Full" ;Break }
        2 { ($Script:BVService="Safe"+$IsLaptop+$FullMin) ;$BVSAlt = "Safe"+$IsLaptop+"-Full";Break }
        3 { ($Script:BVService="Tweaked"+$IsLaptop+$FullMin) ;$BVSAlt = "Tweaked"+$IsLaptop+"-Full" ;Break }
    }

    If($OldBVService -ne $BVService){ If($OldBVService -eq "StartType" -or $BVService -eq "StartType"){ $WPF_StackCBHere.Children.Clear() ;$Script:ServicesGenerated = $False } }
    If(!($ServicesGenerated)){ [System.Collections.ArrayList]$ServCB = Import-Csv $ServiceFilePath }

    [System.Collections.ArrayList]$Script:ServiceCBList = @()

    ForEach($item In $ServCB) {
        $ServiceTypeNum = $($item.$BVService)
        $ServiceName = $($item.ServiceName)
        If($ServiceName -like "*_*"){ $ServiceName = $ServiceName.split('_')[0] + "_$ServiceEnd" }
        If($CurrServices.Name -contains $ServiceName) {
            $ServiceCurrType = ($CurrServices.Where{$_.Name -eq $ServiceName}).StartType
            If($ServiceTypeNum -eq 0){ $ServiceType = $ServicesTypeList[$($item.$BVSAlt)] } Else{ $ServiceType = $ServicesTypeList[$ServiceTypeNum] }
            If($ServiceName -is [system.array]){ $ServiceName = $ServiceName[0] }
            $ServiceCommName = ($CurrServices.Where{$_.Name -eq $ServiceName}).DisplayName
            $DispTemp = "$ServiceCommName - $ServiceCurrType -> $ServiceType"
            If($ServiceTypeNum -eq 4){ $DispTemp += " (Delayed Start)" }
            $CBName = "WPF_"+$ServiceName + "_1CB"

            If(!($CBNameList -contains $CBName)) {
                New-Variable -name $CBName -value ([System.Windows.Controls.CheckBox]::new()) -scope Script
                $checkbox = Get-Variable -Name $CBName -valueOnly
                $checkbox.width = 450
                $checkbox.height = 20
                $CBNameList.Add($CBName)
            } Else {
                $checkbox = Get-Variable -Name $CBName -valueOnly
			}

            If(!($ServicesGenerated)){ $WPF_StackCBHere.AddChild($checkbox) }
            $checkbox.Content = "$DispTemp"
            If($ServiceTypeNum -eq 0){ $checkbox.IsChecked = $False } Else{ $checkbox.IsChecked = $True }

            $Object = New-Object PSObject -Property @{
                Value = $checkbox
                CBName = $CBName
                ServiceName = $ServiceName
                StartType = $ServiceTypeNum
            }
            $ServiceCBList += $Object
        }
    }

    If(!($ServicesGeneratedA)){
        $WPF_ServiceClickLabel.Visibility = 'Hidden'
        $WPF_ServiceLegendLabel.Visibility = 'Visible'
        $WPF_ServiceNote.Visibility = 'Visible'
        $WPF_CustomBVCB.Visibility = 'Visible'
        $WPF_SaveCustomSrvButton.Visibility = 'Visible'
        $WPF_LoadServicesButton.content = "Reload"
        $Script:ServicesGenerated = $True
        $Script:ServicesGeneratedA = $True
    }
}

Function GetCustomBV {
    $Script:LoadServiceConfig = 2
    [System.Collections.ArrayList]$Script:csvTemp = @()
    ForEach($item In $ServiceCBList) {
        If($item.Value.IsChecked) {
            $Object = New-Object PSObject -Property @{
                ServiceName = $item.ServiceName
                StartType = $item.StartType
            }
            $Script:csvTemp+= $Object
        }
    }
    [System.Collections.ArrayList]$Script:csv = $Script:csvTemp
}

##########
# GUI -End
##########

Function LoadWebCSV {
    while($LoadWebCSV -ne "Out") {
        $Script:ErrorDi = "Missing File BlackViper.csv -LoadCSV"
        Error_Top_Display
        LeftLine ;DisplayOutMenu " The File " 2 0 0 ;DisplayOutMenu "BlackViper.csv" 15 0 0 ;DisplayOutMenu " is missing.             " 2 0 0 ;RightLine
        MenuBlankLine
        LeftLine ;DisplayOutMenu " Do you want to download the missing file?       " 2 0 0 ;RightLine
        MenuBlankLine
        MenuLine
        $Invalid = ShowInvalid $Invalid
        $LoadWebCSV = Read-Host "`nDownload? (Y)es/(N)o"
        Switch($LoadWebCSV.ToLower()) {
            { $_ -eq "n" -or $_ -eq "no" } { Exit ;Break }
            { $_ -eq "y" -or $_ -eq "yes" } { DownloadFile $Service_Url $ServiceFilePath ;$LoadWebCSV = "Out" ;Break }
            default {$Invalid = 1 ;Break }
        }
    } Return
}

Function ServiceBAfun([String]$ServiceBA) {
    If($LogBeforeAfter -eq 1) {
        $ServiceBAFile = $filebase + $ServiceBA + ".log"
        If($ServiceBA -eq "Services-Before"){ $CurrServices | Out-File $ServiceBAFile } Else{ Get-Service | Select DisplayName, StartType | Out-File $ServiceBAFile }
        Get-Service | Select DisplayName, StartType | Out-File $ServiceBAFile
    } ElseIf($LogBeforeAfter -eq 2) {
        If($ServiceBA -eq "Services-Before"){ $TMPServices = $CurrServices } Else{ $TMPServices = Get-Service | Select DisplayName, Name, StartType }
        Write-Output "`n$ServiceBA -Start" 4>&1 | Out-File -filepath $LogFile -Append
        Write-Output "-------------------------------------" 4>&1 | Out-File -filepath $LogFile -Append
        Write-Output $TMPServices 4>&1 | Out-File -filepath $LogFile -Append
        Write-Output "-------------------------------------" 4>&1 | Out-File -filepath $LogFile -Append
        Write-Output "$ServiceBA -End" 4>&1 | Out-File -filepath $LogFile -Append
        Write-Output " " 4>&1 | Out-File -filepath $LogFile -Append
    }
}

Function Save_Service([String]$SavePath) {
    $ServiceSavePath = $filebase + $env:computername
    $SaveService = @()

    If($WPF_CustomBVCB.IsChecked) {
        $ServiceSavePath += "-Custom-Service.csv"
        ForEach($item In $ServiceCBList) {
            If($item.Value.IsChecked) {
                $ServiceName = $item.ServiceName
                If($ServiceName -like "*_*"){ $ServiceName = $ServiceName.split('_')[0] + "?????" }
                $Object = New-Object PSObject -Property @{
                   ServiceName = $ServiceName
                   StartType = $item.StartType
                }
                $SaveService += $Object
            }
        }
    } Else {
        If($AllService -eq $null) { 
            $ServiceSavePath += "-Service-Backup.csv"
            $AllService = Get-Service | Select Name, StartType
        } Else {
            $ServiceSavePath += "-Custom-Service.csv"
        }
        ForEach ($Service in $AllService) {
            $ServiceName = $Service.Name
            If(!($Skip_Services -contains $ServiceName)) {
                Switch("$($Service.StartType)") {
                    "Disabled" { $StartType = 1 ;Break }
                    "Manual" { $StartType = 2 ;Break }
                    "Automatic" { $exists = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$ServiceName\").DelayedAutostart ;If($exists -eq 1){ $StartType = 4 } Else{ $StartType = 3 } ;Break }
                    Default { $StartType = "$($Service.StartType)" ;Break }
                }
                If($ServiceName -like "*_*"){ $ServiceName = $ServiceName.split('_')[0] + "?????" }
                $Object = New-Object PSObject -Property @{
                   ServiceName = $ServiceName
                   StartType = $StartType
                }
                $SaveService += $Object
            }
        }
    }
    If($SavePath -ne $null){ $ServiceSavePath = $SavePath}
    $SaveService | Export-Csv -LiteralPath $ServiceSavePath -encoding "unicode" -force -Delimiter ","
    If($SavePath -ne $null){ [Windows.Forms.MessageBox]::Show("File saved as '$SavePath'","File Saved", 'OK') }
}

Function ServiceSet([String]$BVService) {
    Clear-Host
    $NetTCP = @("NetMsmqActivator","NetPipeActivator","NetTcpActivator")
    If($LogBeforeAfter -eq 2) { DiagnosticCheck 1 }
    ServiceBAfun "Services-Before"
    If($DryRun -ne 1){ DisplayOut "Changing Service Please wait..." 14 0 } Else{ DisplayOut "List of Service that would be changed on Non-Dryrun..." 14 0 }
    DisplayOut "Service_Name - Current -> Change_To" 14 0
    DisplayOut "-------------------------------------" 14 0
    ForEach($item In $csv) {
        $ServiceTypeNum = $($item.$BVService)
        $ServiceName = $($item.ServiceName)
        $ServiceCommName = ($CurrServices.Where{$_.Name -eq $ServiceName}).DisplayName
        If($ServiceTypeNum -eq 0 -and $ShowSkipped -eq 1) {
            If($ServiceCommName -ne $null){ $DispTemp = "Skipping $ServiceCommName ($ServiceName)" } Else{ $DispTemp = "Skipping $ServiceName" }
            DisplayOut $DispTemp  14 0
        } ElseIf($ServiceTypeNum -ne 0) {
            If($ServiceName -like "*_*"){ $ServiceName = $ServiceName.split('_')[0] + "_$ServiceEnd" }
            $ServiceType = $ServicesTypeList[$ServiceTypeNum]
            $ServiceCurrType = ServiceCheck $ServiceName $ServiceType
            If($ServiceName -is [system.array]){ $ServiceName = $ServiceName[0] }
            If($ServiceCurrType -ne $False -and $ServiceCurrType -ne "Already") {
                $DispTemp = "$ServiceCommName ($ServiceName) - $ServiceCurrType -> $ServiceType"
                If($ServiceTypeNum -In 1..4 -and $DryRun -ne 1){ Set-Service $ServiceName -StartupType $ServiceType }
                If($ServiceTypeNum -eq 4) {
                    $DispTemp += " (Delayed Start)"
                    If($DryRun -ne 1){ Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\$ServiceName\" -Name "DelayedAutostart" -Type DWord -Value 1 }
                }
                If($ShowChanged -eq 1){ DisplayOut $DispTemp  11 0 }
            } ElseIf($ServiceCurrType -eq "Already" -and $ShowAlreadySet -eq 1) {
                $DispTemp = "$ServiceCommName ($ServiceName) is already $ServiceType"
                If($ServiceTypeNum -eq 4){ $DispTemp += " (Delayed Start)" }
                DisplayOut $DispTemp  15 0
            } ElseIf($ServiceCurrType -eq $False -and $ShowNonInstalled -eq 1) {
                $DispTemp = "No service with name $ServiceName"
                DisplayOut $DispTemp  13 0
            }
        }
    }
    DisplayOut "-------------------------------------" 14 0
    If($DryRun -ne 1){ DisplayOut "Service Changed..." 14 0 } Else{ DisplayOut "List of Service Done..." 14 0 }
    ServiceBAfun "Services-After"
    AutomatedExitCheck 1
}

Function ServiceCheck([string]$S_Name, [string]$S_Type) {
    If($CurrServices.Name -contains $S_Name) {
        $C_Type = ($CurrServices.Where{$_.Name -eq $S_Name}).StartType
        If($S_Type -ne $C_Type) {
            If($S_Name -eq 'lfsvc' -and $C_Type -eq 'disabled') {
                If(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\TriggerInfo\3") { Remove-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\TriggerInfo\3" -recurse -Force }
            } ElseIf($S_Name -eq 'NetTcpPortSharing') {
                If($NetTCP -contains $CurrServices.Name){ Return "Manual" } Return $False
            } Return $C_Type
        } Return "Already"
    } Return $False
}

Function Black_Viper_Set([Int]$BVOpt, [String]$FullMin) {
    PreScriptCheck
    Switch($BVOpt) {
        {$LoadServiceConfig -eq 1 -or $LoadServiceConfig -eq 2} { ServiceSet "StartType" ;Break }
        1 { ServiceSet ("Def"+$WinEdition+$FullMin) ;Break }
        2 { ServiceSet ("Safe"+$IsLaptop+$FullMin) ;Break }
        3 { ServiceSet ("Tweaked"+$IsLaptop+$FullMin) ;Break }
    }
}

Function InternetCheck { If($InternetCheck -eq 1){ Return $True } ElseIf(!(Test-Connection -computer github.com -count 1 -quiet)){ Return $False } Return $True }

Function CreateLog {
    If($DevLog -eq 1) {
        $Script:ScriptLog = 1
        $Script:LogName = "Dev-Log.log"
        $Script:Diagnostic = 1
        $Script:Automated = 0
        $Script:LogBeforeAfter = 2
        $Script:DryRun = 1
        $Script:AcceptToS = "Accepted-Dev-Switch"
        $Script:ShowNonInstalled = 1
        $Script:ShowSkipped = 1
        $Script:ShowChanged = 1
        $Script:ShowAlreadySet = 1
    }

    If($ScriptLog -ne 0) {
        $Script:LogFile = $filebase + $LogName
        $Time = Get-Date -Format g
        If($ScriptLog -eq 2) {
            Write-Output "Updated Script File running" 4>&1 | Out-File -filepath $LogFile -NoNewline -Append
            Write-Output "--Start of Log ($Time)--" | Out-File -filepath $LogFile -NoNewline -Append
            $ScriptLog = 1
        } Else {
            Write-Output "--Start of Log ($Time)--" | Out-File -filepath $LogFile
        }
    }
}

Function ScriptUpdateFun {
    $FullVer = "$WebScriptVer.$WebScriptMinorVer"
    $DFilename = "BlackViper-Win10-Ver." + $FullVer
    If($Release_Type -ne "Stable"){ $DFilename += "-Testing" ;$Script_Url = $URL_Base + "Testing/" }
    $DFilename += ".ps1"
    $Script_Url = $URL_Base + "BlackViper-Win10.ps1"
    $WebScriptFilePath = $filebase + $DFilename
    Clear-Host
    MenuLineLog
    LeftLineLog ;DisplayOutMenu "                  Update Found!                  " 13 0 0 1 ;RightLineLog
    MenuLineLog
    MenuBlankLineLog
    LeftLineLog ;DisplayOutMenu "Downloading version " 15 0 0 1 ;DisplayOutMenu ("$FullVer" + (" "*(29-$FullVer.length))) 11 0 0 1 ;RightLineLog
    LeftLineLog ;DisplayOutMenu "Will run " 15 0 0 1 ;DisplayOutMenu ("$DFilename" +(" "*(40-$DFilename.length))) 11 0 0 1 ;RightLineLog
    LeftLineLog ;DisplayOutMenu "after download is complete.                      " 2 0 0 1 ;RightLineLog
    MenuBlankLine
    MenuLineLog
    DownloadFile $Script_Url $WebScriptFilePath
    $UpArg = ""
    If($Automated -eq 1){ $UpArg += "-auto " }
    If($AcceptToS -ne 0){ $UpArg += "-atosu " }
    If($ServiceVerCheck -eq 1){ $UpArg += "-use " }
    If($InternetCheck -eq 1){ $UpArg += "-sic " }
    If($EditionCheck -eq "Home"){ $UpArg += "-sech " }
    If($EditionCheck -eq "Pro"){ $UpArg += "-secp " }
    If($BuildCheck -eq 1){ $UpArg += "-sbc " }
    If($Black_Viper -eq 1){ $UpArg += "-default " }
    If($Black_Viper -eq 2){ $UpArg += "-safe " }
    If($Black_Viper -eq 3){ $UpArg += "-tweaked " }
    If($Diagnostic -eq 1){ $UpArg += "-diag " }
    If($LogBeforeAfter -eq 1){ $UpArg += "-baf " }
    If($DryRun -eq 1){ $UpArg += "-dry " }
    If($ShowNonInstalled -eq 1){ $UpArg += "-snis " }
    If($ShowSkipped -eq 1){ $UpArg += "-sss " }
    If($DevLog -eq 1){ $UpArg += "-devl " }
    If($ScriptLog -eq 1){ $UpArg += "-logc $LogName " }
    If($All_or_Min -eq "-full"){ $UpArg += "-all " } Else{ $UpArg += "-min " }
    If($LoadServiceConfig -eq 1){ $UpArg += "-lcsc $ServiceConfigFile " }
    If($LoadServiceConfig -eq 2){ $TempSrv = $env:Temp + "\TempSrv.csv" ;$Script:csv | Export-Csv -LiteralPath $TempSrv -encoding "unicode" -force -Delimiter "," ;$UpArg += "-lcsc $TempSrv " } 
    If($BackupServiceConfig -eq 1){ $UpArg += "-bcsc " }
    If($ShowNonInstalled -eq 1){ $UpArg += "-snis " }
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$WebScriptFilePath`" $UpArg" -Verb RunAs
    Exit
}

Function PreScriptCheck {
    If($RunScript -eq 0){ Exit }
    CreateLog
    $EBCount = 0

    If($HomeEditions -contains $WinEdition -or $EditionCheck -eq "Home" -or $WinSku -IN 100..101) {
        $Script:WinEdition = "-Home"
    } ElseIf($ProEditions -contains $WinEdition -or $EditionCheck -eq "Pro" -or $WinSku -eq 48) {
        $Script:WinEdition = "-Pro"
    } Else {
        $Script:ErrorDi = "Edition"
        $EditionCheck = "Fail"
        $EBCount++
    }

    If($BuildVer -lt $ForBuild -and $BuildCheck -ne 1) {
        If($EditionCheck -eq "Fail"){ $Script:ErrorDi += " & Build" } Else{ $Script:ErrorDi = "Build" }
        $Script:ErrorDi += " Check Failed"
        $BuildCheck = "Fail"
        $EBCount++
    }

    If($EBCount -ne 0) {
       $EBCount=0
        Error_Top_Display
        LeftLineLog ;DisplayOutMenu " Script won't run due to the following problem(s)" 2 0 0 1 ;RightLineLog
        MenuBlankLineLog
        MenuLineLog
        If($EditionCheck -eq "Fail") {
            $EBCount++
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " $EBCount. Not a valid Windows Edition for this Script. " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " Windows 10 Home and Pro Only                    " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " You are using " 2 0 0 1;DisplayOutMenu ("$FullWinEdition" +(" "*(34-$FullWinEdition.length))) 15 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " SKU # " 2 0 0 1;DisplayOutMenu ("$WinSku" +(" "*(42-$WinSku.length))) 15 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " If you are using Home or Pro, Please contact me " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " with what Edition you are using and what it says" 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " Windows 10 Home and Pro Only                    " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " To skip use one of the following methods        " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 1. Change " 2 0 0 1 ;DisplayOutMenu "EditionCheck" 15 0 0 1 ;DisplayOutMenu " in script file          " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 2. Change " 2 0 0 1 ;DisplayOutMenu "Skip_EditionCheck" 15 0 0 1 ;DisplayOutMenu " to " 2 0 0 1 ;DisplayOutMenu "=yes" 15 0 0 1 ;DisplayOutMenu " in bat file" 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 3. Run Script or Bat file with " 2 0 0 1 ;DisplayOutMenu "-secp" 15 0 0 1 ;DisplayOutMenu " argument   " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 4. Run Script or Bat file with " 2 0 0 1 ;DisplayOutMenu "-sech" 15 0 0 1 ;DisplayOutMenu " argument   " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            MenuLineLog
        }
        If($BuildCheck -eq "Fail") {
            $EBCount++
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " $EBCount. Not a valid Build for this Script.           " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " Lowest Build Recommended is Creator's Update    " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " You are using Build " 2 0 0 1 ;DisplayOutMenu ("$BuildVer" +(" "*(24-$BuildVer.length))) 15 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " You are using Version " 2 0 0 1 ;DisplayOutMenu ("$Win10Ver" +(" "*(23-$BuildVer.length))) 15 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " To skip use one of the following methods        " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 1. Change " 2 0 0 1 ;DisplayOutMenu "BuildCheck" 15 0 0 1 ;DisplayOutMenu " to " 2 0 0 1 ;DisplayOutMenu "=1" 15 0 0 1 ;DisplayOutMenu " in script file      " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 2. Change " 2 0 0 1 ;DisplayOutMenu "Skip_BuildCheck" 15 0 0 1 ;DisplayOutMenu " to " 2 0 0 1 ;DisplayOutMenu "=yes" 15 0 0 1 ;DisplayOutMenu " in bat file  " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 3. Run Script or Bat file with " 2 0 0 1 ;DisplayOutMenu "-sbc" 15 0 0 1 ;DisplayOutMenu " argument    " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            MenuLineLog
        }
        AutomatedExitCheck 1
    }

    If($BackupServiceConfig -eq 1){ Save_Service }
    If($LoadServiceConfig -eq 1){
        $ServiceFilePath = $filebase + $ServiceConfigFile
        If(!(Test-Path $ServiceFilePath -PathType Leaf)) {
            $Script:ErrorDi = "Missing File $ServiceConfigFile"
            Error_Top_Display
            LeftLineLog ;DisplayOutMenu "The File " 2 0 0 1 ;DisplayOutMenu ("$ServiceConfigFile" +(" "*(28-$DFilename.length))) 15 0 0 1 ;DisplayOutMenu " is missing." 2 0 0 1 ;RightLineLog
            Error_Bottom
        }
        $ServiceVerCheck = 0
    } ElseIf($LoadServiceConfig -eq 2) {
    } Else {
        $ServiceFilePath = $filebase + "BlackViper.csv"
        If(!(Test-Path $ServiceFilePath -PathType Leaf)) {
            If($ServiceVerCheck -eq 0) {
                If($ScriptLog -eq 1){ Write-Output "Missing File 'BlackViper.csv'" | Out-File -filepath $LogFile }
                LoadWebCSV
            } Else {
                If($ScriptLog -eq 1){ Write-Output "Downloading Missing File 'BlackViper.csv'" | Out-File -filepath $LogFile }
                DownloadFile $Service_Url $ServiceFilePath
            }
            $ServiceVerCheck = 0
        }
    }
    If($LoadServiceConfig -ne 2){ [System.Collections.ArrayList]$Script:csv = Import-Csv $ServiceFilePath }
    If($ScriptVerCheck -eq 1 -or $ServiceVerCheck -eq 1) {
        If(InternetCheck) {
            $VersionFile = $env:Temp + "\Temp.csv"
            DownloadFile $Version_Url $VersionFile
            $CSV_Ver = Import-Csv $VersionFile
            If($ServiceVerCheck -eq 1 -and $($CSV_Ver[1].Version) -gt $($csv[0]."Def-Home-Full")) {
                If($ScriptLog -eq 1) { Write-Output "Downloading update for 'BlackViper.csv'" | Out-File -filepath $LogFile }
                DownloadFile $Service_Url $ServiceFilePath
                If($LoadServiceConfig -ne 2){ [System.Collections.ArrayList]$Script:csv = Import-Csv $ServiceFilePath }
            }
            If($ScriptVerCheck -eq 1) {
                If($Release_Type -eq "Stable"){ $CSVLine = 0 } Else{ $CSVLine = 3 }
                $WebScriptVer = $($CSV_Ver[$CSVLine].Version)
                $WebScriptMinorVer =  $($CSV_Ver[$CSVLine].MinorVersion)
                If($WebScriptVer -gt $Script_Version) {
                    $Script_Update = "True"
                } ElseIf($WebScriptVer -eq $Script_Version -and $WebScriptMinorVer -gt $Minor_Version) {
                    $Script_Update = "True"
                } Else {
                    $Script_Update = "False"
                }
                If($Script_Update -eq "True"){ ScriptUpdateFun }
            }
        } Else {
            $Script:ErrorDi = "No Internet"
            Error_Top_Display
            LeftLineLog ;DisplayOutMenu " Update Failed Because no internet was detected. " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " Tested by pinging github.com                    " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            LeftLineLog ;DisplayOutMenu " To skip use one of the following methods        " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 1. Change " 2 0 0 1 ;DisplayOutMenu "InternetCheck" 15 0 0 1 ;DisplayOutMenu " to " 2 0 0 1 ;DisplayOutMenu "=1" 15 0 0 1 ;DisplayOutMenu " in script file   " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 2. Change " 2 0 0 1 ;DisplayOutMenu "InternetCheck" 15 0 0 1 ;DisplayOutMenu " to " 2 0 0 1 ;DisplayOutMenu "=no" 15 0 0 1 ;DisplayOutMenu " in bat file     " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu " 3. Run Script or Bat file with " 2 0 0 1 ;DisplayOutMenu "-sic" 15 0 0 1 ;DisplayOutMenu " argument    " 2 0 0 1 ;RightLineLog
            MenuBlankLineLog
            MenuLineLog
            If(!(Test-Path $ServiceFilePath -PathType Leaf)) {
                MenuBlankLineLog
                LeftLineLog ;DisplayOutMenu "The File " 2 0 0 1 ;DisplayOutMenu "BlackViper.csv" 15 0 0 1 ;DisplayOutMenu " is missing and the script" 2 0 0 1 ;RightLineLog
                LeftLineLog ;DisplayOutMenu "can't run w/o it.      " 2 0 0 1 ;RightLineLog
                MenuBlankLineLog
                MenuLineLog
                AutomatedExitCheck 1
            } Else {
                AutomatedExitCheck 0
            }
        }
    }

    If($LoadServiceConfig -ne 2) { 
        If(!(Test-Path $ServiceFilePath -PathType Leaf)) {
            $Script:ErrorDi = "Missing File BlackViper.csv"
            Error_Top_Display
            LeftLineLog ;DisplayOutMenu "The File " 2 0 0 1 ;DisplayOutMenu "BlackViper.csv" 15 0 0 1 ;DisplayOutMenu " is missing and couldn't  " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu "couldn't download for some reason.               " 2 0 0 1 ;RightLineLog
            Error_Bottom
        }
        $ServiceVersion = ($csv[0]."Def-Home-Full")
        $ServiceDate = ($csv[0]."Def-Home-Min")
        $csv.RemoveAt(0)
    }
}

Function GetArgs {
    For($i=0; $i -lt $PassedArg.length; $i++) {
        If($PassedArg[$i].StartsWith("-")) {
            Switch($PassedArg[$i]) {
              "-default" { $Script:Black_Viper = 1 ;$Script:BV_ArgUsed = 2 ;Break }
              "-safe" { $Script:Black_Viper = 2 ;$Script:BV_ArgUsed = 2;Break }
              "-tweaked" { If($IsLaptop -ne "-Lap"){ $Script:Black_Viper = 3 ;$Script:BV_ArgUsed = 2 } Else{ $Script:BV_ArgUsed = 3 } ;Break }
              "-all" { $Script:All_or_Min = "-full" ;Break }
              "-min" { $Script:All_or_Min = "-min" ;Break }
              "-log" { $Script:ScriptLog = 1 ;If(!($PassedArg[$i+1].StartsWith("-"))){ $Script:LogName = $PassedArg[$i+1] ; $i++ } ;Break }
              "-logc" { $Script:ScriptLog = 2 ;If(!($PassedArg[$i+1].StartsWith("-"))){ $Script:LogName = $PassedArg[$i+1] ; $i++ } ;Break }
              "-lcsc" { $Script:BV_ArgUsed = 3 ;$Script:LoadServiceConfig = 1 ;If(!($PassedArg[$i+1].StartsWith("-"))){ $Script:ServiceConfigFile = $PassedArg[$i+1] ; $i++ } ;Break }
              "-bcsc" { $Script:BackupServiceConfig = 1 ;Break }
              "-baf" { $Script:LogBeforeAfter = 1 ;Break }
              "-snis" { $Script:ShowNonInstalled = 1 ;Break }
              "-sss" { $Script:ShowSkipped = 1 ;Break }
              "-sic" { $Script:InternetCheck = 1 ;Break }
              "-usc" { $Script:ScriptVerCheck = 1 ;Break }
              "-use" { $Script:ServiceVerCheck = 1 ;Break }
              "-atos" { $Script:AcceptToS = "Accepted-Switch" ;Break }
              "-atosu" { $Script:AcceptToS = "Accepted-Update" ;Break }
              "-auto" { $Script:Automated = 1 ;$Script:AcceptToS = "Accepted-Automated-Switch" ;Break }
              "-dry" { $Script:DryRun = 1 ;$Script:ShowNonInstalled = 1 ;Break }
              "-diag" { $Script:Diagnostic = 1 ;$Script:Automated = 0 ;Break }
              "-diagt" { $Script:Diagnostic = 2 ;$Script:Automated = 0 ;Break }
              "-devl" { $Script:DevLog = 1 ;Break }
              "-sbc" { $Script:BuildCheck = 1 ;Break }
              "-sech" { $Script:EditionCheck = "Home" ;Break }
              {$_ -eq "-secp" -or $_ -eq "-sec" } { $Script:EditionCheck = "Pro" ;Break }
            }
        }
    }
}

Function ArgsAndVarSet {
    $ProEditions = @(
    "Pro",           #English
    "Professionnel") #French

    $HomeEditions = @(
    "Home",    #English
    "Famille") #French

    $Script:IsLaptop = LaptopCheck
    If($PassedArg.length -gt 0){ GetArgs }

    $Script:WinSku = (Get-WmiObject Win32_OperatingSystem).OperatingSystemSKU
    #  48 = Pro
    # 100 = Home (Single Language)
    # 101 = Home

    $Script:FullWinEdition = (Get-WmiObject Win32_OperatingSystem).Caption
    $Script:WinEdition = $FullWinEdition.Split(' ')[-1]
    #  Pro or Home

    $Script:ForBuild = 15063
    $Script:BuildVer = [Environment]::OSVersion.Version.build
    # 15063 = Creator's Update
    # 14393 = Anniversary Update
    # 10586 = First Major Update
    # 10240 = First Release

    $Script:ForVer = 1703
    $Script:Win10Ver = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name ReleaseID).releaseId
    # 1703 = Creator's Update
    # 1607 = Anniversary Update
    # 1511 = First Major Update
    # 1507 = First Release

    If($BV_ArgUsed -eq 1) {
        If($Automated -eq 1) {
            CreateLog
            $Script:ErrorDi = "Automated with Tweaked + Laptop (Not supported ATM)"
            Error_Top_Display
            LeftLineLog ;DisplayOutMenu "Script is set to Automated and...                " 2 0 0 1 ;RightLineLog
            LeftLineLog ;DisplayOutMenu "Laptops can't use Twaked option ATM.             " 2 0 0 1 ;RightLineLog
            Error_Bottom
        } Else {
            Gui-Start
        }
    } ElseIf($BV_ArgUsed -IN 2..3) {
        $Script:RunScript = 1
        If($AcceptToS -ne 0) {
            If($LoadServiceConfig -eq 1) {
                ServiceSet "StartType"
            } Else {
                Black_Viper_Set $Black_Viper $All_or_Min
            }
        } Else {
            TOS
        }
    } ElseIf($Automated -eq 1) {
        CreateLog
        $Script:ErrorDi = "Automated Selected, No Service Selected"
        Error_Top_Display
        LeftLineLog ;DisplayOutMenu "Script is set to Automated and no Service        " 2 0 0 1 ;RightLineLog
        LeftLineLog ;DisplayOutMenu "Configuration option was selected.               " 2 0 0 1 ;RightLineLog
        Error_Bottom
    } Else {
        If($AcceptToS -ne 0){ $Script:RunScript = 1
            Gui-Start
        } Else {
            TOS
        }
    }
}

#--------------------------------------------------------------------------
# Edit values (Option) to your preferance

# Function = Option             #Choices
$Script:AcceptToS = 0           #0 = See ToS
                                #Anything else = Accept ToS

$Script:Automated = 0           #0 = Pause on - User input, On Errors, or End of Script
                                #1 = Close on - User input, On Errors, or End of Script
# Automated = 1, Implies that you accept the "ToS"

$Script:BackupServiceConfig = 0 #0 = Dont backup Your Current Service Configuration before services are changes
                                #1 = Backup Your Current Service Configuration before services are changes
# Will be script's directory named "(ComputerName)-Service-Backup.csv"

$Script:DryRun = 0              #0 = Runs script normaly
                                #1 = Runs script but shows what will be changed

$Script:ScriptLog = 0           #0 = Dont make a log file
                                #1 = Make a log file
# Will be script's directory named `Script.log` (default)

$Script:LogName = "Script.log"  #Name of log file (you can change it)

$Script:LogBeforeAfter = 0      #0 = Dont make a file of all the services before and after the script
                                #1 = Make a file of all the services before and after the script
# Will be script's directory named `Services-Before.log` and `Services-After.log`

$Script:ScriptVerCheck = 0      #0 = Skip Check for update of Script File
                                #1 = Check for update of Script File
# Note: If found will Auto download and runs that, File name will be "BlackViper-Win10-Ver.(version#).ps1"

$Script:ServiceVerCheck = 0     #0 = Skip Check for update of Service File
                                #1 = Check for update of Service File
# Note: If found will Auto download will be used

$Script:ShowChanged = 1         #0 = Dont Show Changed Services
                                #1 = Show Changed Services

$Script:ShowAlreadySet = 1      #0 = Dont Show Already set Services
                                #1 = Show Already set Services

$Script:ShowNonInstalled = 0    #0 = Dont Show Services not present
                                #1 = Show Services not present

$Script:InternetCheck = 0       #0 = Checks if you have internet by doing a ping to github.com
                                #1 = Bypass check if your pings are blocked

$Script:EditionCheck = 0        #0 = Check if Home or Pro Edition
                                #"Pro" = Set Edition as Pro (Needs "s)
                                #"Home" = Set Edition as Home (Needs "s)

$Script:BuildCheck = 0          #0 = Check Build (Creator's Update Minimum)
                                #1 = Allows you to run on Non-Creator's Update
#--------------------------------
# Best not to use these unless asked to (these stop automated)
$Script:Diagnostic = 0          #0 = Doesn't show Shows diagnostic information
                                #1 = Shows diagnostic information

$Script:DevLog = 0              #0 = Doesn't make a Dev Log
                                #1 = Makes a log files.. with what services change, before and after for services, and diagnostic info 
#--------------------------------------------------------------------------
# Starts the script (Do not change)

ArgsAndVarSet
