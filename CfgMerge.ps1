# This function displays usage instructions and descriptions for the arguments
function WriteUsage() {
    "Usage: `n"
    Write-Host "CfgMerge.ps1 <filetype(optional)> <old> <new> <target(optional)>`n"
    Write-Host "Arguments: "
    Write-Host "- fileType: The type of the files that will be merged. In case it is not inserted, as long old and new files has the same extension at the end of the filename, this extension will be considered as fileType. Valid inputs: ini, config, conf, json."
    Write-Host "- old: Path to the .ini file of the outdated package."
    Write-Host "- new: Path to the default product .ini file. In case no target is inserted, it will also be considered the target path."
    Write-Host "- target: Path to the .ini file on the target installation. It may be omited in case the filename of 'old' and 'new' file are the same. It may only contain the path to the directory and the target filename will be the same as 'old' and 'new'."
}

# Get the amount of arguments passed to the script
$argsCount = $args.Count

# Check if the correct number of arguments were passed
if (-not ($argsCount -ge 2 -and $argsCount -le 4)) {
    Write-Host "Invalid number of arguments."
    WriteUsage
    exit 1
}

# Set n = 1 if args[0] is not fileType
$n = 0
$fileTypeList = @("ini", "config", "conf", "json")
$typeBool = $False
foreach ($fileType in $fileTypeList) {
    if ($fileType -eq $args[0]) {
        $typeBool = $True
    }
}
$fileType = $null
if (-not $typeBool -and ((Test-Path -Path $args[0] -PathType Leaf) -eq (Test-Path -Path $args[1] -PathType Leaf)) -and ([System.IO.Path]::GetExtension($args[0]) -eq [System.IO.Path]::GetExtension($args[1]))) {
    $fileType = [System.IO.Path]::GetExtension($args[0])
    $fileType = $fileType -replace "\."
    $n = 1
}
elseif ($typeBool) {
    $fileType = $args[0] 
}

# Validate that "new" and "old" are valid file paths
for ($i = 1; $i -lt 2; $i++) {
    $arg = $args[$i - $n]
    if (-not (Test-Path -Path $arg -PathType Leaf)) {
        Write-Host "Invalid argument: '$arg'. Must be a valid file path."
        WriteUsage
        exit 1
    }
}

# Initialize the parameters that will be passed to the MergeIniFiles functio
$oldCfgPath = $args[1 - $n]
$newCfgPath = $args[2 - $n]
$targetCfgPath = $null

#Write-Host "$args, $n"
if (($argsCount -eq 2 -and $n -eq 1) -or ($argsCount -eq 3 -and $n -eq 0)) {
    # Case where only the path of the "old" file and the default file are passed in the input. The target file path will be considered the same as the default file
    $targetCfgPath = $newCfgPath
}
elseif (Test-Path -Path $args[3 - $n] -PathType Leaf) {
    # Case where the target file path is passed explicitly
    $targetCfgPath = $args[3 - $n]
}
elseif (((Split-Path $oldCfgPath -Leaf) -eq (Split-Path $newCfgPath -Leaf)) -and (Test-Path -Path $args[3 - $n] -PathType Container)) {
    # Case where the target filename is not explicit and the "old" and "new" filenames are the same. In this case the name of the target file will be the same as the others
    $targetCfgPath = Join-Path -Path $args[3 - $n] -ChildPath (Split-Path $oldCfgPath -Leaf)
}
elseif (-not (Test-Path -Path $args[3 - $n] -PathType Container) -and -not (Test-Path -Path $args[3 - $n] -PathType Leaf) -and (Test-Path -Path (Split-Path -Path $args[3 - $n] -Parent) -PathType Container)) {
    # Case where the target file path is the path to a previously non-existent new file
    $targetCfgPath = $args[3 - $n]
}
else {
    # Default case for invalid arguments
    Write-Host "Invalid arguments."
    WriteUsage
}

# Call the function that performs the merge operation on the files
switch ($fileType) {
    "ini" {
        Import-Module "./IniMerge/IniMerge.psm1"
        MergeIniFiles $oldCfgPath $newCfgPath $targetCfgPath
    }
    "config" {
        Import-Module "./ConfigMerge/ConfigMerge.psm1"
        MergeConfigFiles $oldCfgPath $newCfgPath $targetCfgPath
    }
    "conf" {
        Import-Module "./ConfigMerge/ConfigMerge.psm1"
        MergeConfigFiles $oldCfgPath $newCfgPath $targetCfgPath
    }
    "json" {
        Import-Module "./JsonMerge/JsonMerge.psm1"
	MergeJsonFiles $oldCfgPath $newCfgPath $targetCfgPath
    }
    default {
        WriteUsage
    }
}
