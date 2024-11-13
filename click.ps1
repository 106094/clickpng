function installjava([int32]$ver,[switch]$testing){
    # Request Admin Privilieges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (!$isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    Exit
}
$jdk_folder="$PSScriptRoot\java\"
if (!($env:JAVA_HOME -eq $jdk_folder)){
    Write-Output "need install java"
    $ver=23
    $downloadlink=((Invoke-WebRequest https://jdk.java.net/$($ver)/).links|Where-Object {$_.href -match "windows" -and $_.innerHTML -eq "zip"}).href
    $jdk_zip_file="$PSScriptRoot\java.zip"
    if(!$testing){
    Invoke-WebRequest $downloadlink -OutFile $jdk_zip_file
    Expand-Archive -Path $jdk_zip_file -DestinationPath "$PSScriptRoot\java"
    Remove-Item -Path $jdk_zip_file
    }
    $javabin=(get-childitem $PSScriptRoot\java\ -Directory -r |Where-Object{$_.name -match "bin"}).FullName
    # Set Environment Variables
    $path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    [System.Environment]::SetEnvironmentVariable('Path', $path + ';' + $javabin, 'Machine')

    [Environment]::SetEnvironmentVariable('JAVA_HOME', $jdk_folder, 'Machine')
    [Environment]::SetEnvironmentVariable('JDK_HOME', $jdk_folder, 'Machine')
    [Environment]::SetEnvironmentVariable('JRE_HOME', $jdk_folder, 'Machine')
    # Reload system environment variables
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::Machine) + ";" + 
    [System.Environment]::GetEnvironmentVariable("Path", [System.EnvironmentVariableTarget]::User)

    $checkJavaInstall = & java -version 2>&1
    Write-Output $checkJavaInstall
}
else{
    java -version
    Write-Output "already installed Java"
}
}
function downloadsikuli{
    $sikulipath="$PSScriptRoot\sikulixide-2.0.5.jar"
    if(!(test-path  $sikulipath)){
        Invoke-WebRequest  "https://launchpad.net/sikuli/sikulix/2.0.5/+download/sikulixide-2.0.5.jar" -OutFile $sikulipath
        if(test-path  $sikulipath){
            Write-Output "sikuli downloaded ok"
           }
        }

       else{
        Write-Output "sikuli already downloaded"
       }
}

function click([string]$imagef){
    $success=$false
    $pngs=Get-ChildItem ($PSScriptRoot+"\click.sikuli\png\$($imagef)\*.png")
    $logspath="$PSScriptRoot\SikuliLogs.txt"
    $clickpng="$PSScriptRoot\click.sikuli\click.png"
    if(!(test-path  $logspath)){
        New-Item -Path $logspath -ItemType File|out-null
    }
    foreach($png in $pngs){
        $pngpath=$png.FullName
        $pngname=$png.Name
        Copy-Item -path $pngpath -Destination $clickpng -force
        java -jar "$PSScriptRoot\sikulixide-2.0.5.jar" -r $PSScriptRoot\click.sikuli\ -v -f $PSScriptRoot\SikuliLog.txt
        $resultclick=get-content $PSScriptRoot\SikuliLog.txt
        if( $resultclick -like "*CLICK on*"){
            $success=$true
            break  
        }           
       remove-item $clickpng -Force            
    }
    if($success){
        add-content $logspath -Value "$(get-date -Format "yy/MM/dd HH:mm:ss"): click on $($imagef)/$($pngname) ok"
    }else{
        add-content $logspath -Value "$(get-date -Format "yy/MM/dd HH:mm:ss"): click on $($imagef) fail"
    }

}

installjava 23
downloadsikuli
$clicknames=(get-childitem $PSScriptRoot\click.sikuli\png\ -Directory).name
$clickfiles=(get-childitem $PSScriptRoot\click.sikuli\png\ -r |Where-Object{$_.name -match "png"} )
if(!$clickfiles){
    Write-Output "no png files is found"
    exit
}
foreach($clickname in $clicknames){
click $clickname
}