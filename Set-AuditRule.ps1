function Set-AuditRule
{
    <#
    .SYNOPSIS

    Sets an access control entry (ACE) on a system access control list (SACL) of the file, registry or ad object security descriptor.

    .PARAMETER RegistryPath

    Path of the registry securable object
    
    .PARAMETER FilePath

    Path of the file securable object

    .PARAMETER AdObjectPath

    Path of the Ad securable object

    .PARAMETER Rights
    
    Specifies the access control rights that can be applied to registry, file or ad objects

    .PARAMETER InheritanceFlag

    Inheritance flags specify the semantics of inheritance for access control entries (ACEs)

    .PARAMETER PropagationFlags

    Specifies how Access Control Entries (ACEs) are propagated to child objects. These flags are significant only if inheritance flags are present

    .PARAMETER AuditFlags

    Specifies the conditions for auditing attempts to access a securable object

    .NOTES
    
    Author: Roberto Rodriguez (@Cyb3rWard0g)
    License: GPL-3.0

    Reference: 
    - @adbertram - https://www.enowsoftware.com/solutions-engine/bid/185867/Powershell-Upping-your-Parameter-Validation-Game-with-Dynamic-Parameters-Part-II
    - https://social.technet.microsoft.com/Forums/ie/en-US/b012f66e-08d1-46d2-b659-6ee004e721c0/powershell-to-set-sacl-on-files?forum=ITCG
    - http://giuoco.org/security/configure-file-and-registry-auditing-with-powershell/
    - https://medium.com/@cryps1s/detecting-windows-endpoint-compromise-with-sacls-cd748e10950

    .EXAMPLE

    PS > Get-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\Sysmondrv\Parameters\ -Audit | fl

    Path   : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sysmondrv\Parameters\
    Owner  : BUILTIN\Administrators
    Group  : DESKTOP-WARDOG\None
    Access : BUILTIN\Administrators Allow  FullControl
             ..
             ...
    Audit  :
    Sddl   : O:BAG:...
    
    PS > Set-AuditRule -RegistryPath HKLM:\SYSTEM\CurrentControlSet\Services\Sysmondrv\Parameters\ -IdentityReference Everyone -Rights ReadKey,QueryValues -InheritanceFlags None -PropagationFlags None -AuditFlags Success
    
    PS > Get-Acl -Path HKLM:\SYSTEM\CurrentControlSet\Services\Sysmondrv\Parameters\ -Audit | fl

    Path   : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Sysmondrv\Parameters\
    Owner  : BUILTIN\Administrators
    Group  : DESKTOP-WARDOG\None
    Access : BUILTIN\Administrators Allow  FullControl
             ..
             ...
    Audit  : Everyone Success  ReadKey
    Sddl   : O:BAG:...S:AI(AU;SA;KR;;;WD)

    .EXAMPLE

    PS > Get-Acl -Path C:\tools\test.txt -Audit | fl

    Path   : Microsoft.PowerShell.Core\FileSystem::C:\tools\test.txt
    Owner  : RIVENDELL\cbrown
    Group  : 
    Access : BUILTIN\Administrators Allow  FullControl
             NT AUTHORITY\SYSTEM Allow  FullControl
             BUILTIN\Users Allow  ReadAndExecute, Synchronize
             NT AUTHORITY\Authenticated Users Allow  Modify, Synchronize
    Audit  : 
    Sddl   : O:S-1-5...

    PS > Set-AuditRule -FilePath C:\tools\test4.txt.txt -IdentityReference Everyone -Rights Read,Modify -InheritanceFlags None -PropagationFlags None -AuditFlags Success

    PS > Get-Acl -Path C:\tools\test.txt -Audit | fl

    Path   : Microsoft.PowerShell.Core\FileSystem::C:\tools\test.txt
    Owner  : RIVENDELL\cbrown
    Group  : 
    Access : BUILTIN\Administrators Allow  FullControl
             NT AUTHORITY\SYSTEM Allow  FullControl
             BUILTIN\Users Allow  ReadAndExecute, Synchronize
             NT AUTHORITY\Authenticated Users Allow  Modify, Synchronize
    Audit  : Everyone Success  Modify
    Sddl   : O:S-1-5... S:AI(AU;SA;CCDCLCSWRPWPLOCRSDRC;;;WD)

    .EXAMPLE

    PS > Get-Acl -Path 'AD:\CN=Domain Admins,CN=Users,DC=RIVENDELL,DC=local' -Audit | fl
    PS > Set-AuditRule -AdObjectPath 'AD:\CN=Domain Admins,CN=Users,DC=RIVENDELL,DC=local' -IdentityReference Everyone -Rights GenericRead -InheritanceFlags None -AuditFlags Success
    PS > Get-Acl -Path 'AD:\CN=Domain Admins,CN=Users,DC=RIVENDELL,DC=local' -Audit | fl

    #>

    [CmdletBinding(DefaultParameterSetName='NoParam')]
    param
    (
        [Parameter(Position=0,Mandatory=$true,ParameterSetname='RegistryAudit')]
        [string]$RegistryPath,

        [Parameter(Position=0,Mandatory=$true,ParameterSetname='FileAudit')]
        [string]$FilePath,
        
        [Parameter(Position=0,Mandatory=$true,ParameterSetname='AdObjectAudit')]
        [string]$AdObjectPath,

        [Parameter(Position=1, Mandatory=$true)]
        [Security.Principal.NTAccount]$IdentityReference
    )
    DynamicParam {
        if ($PSCmdlet.ParameterSetName -eq 'AdObjectAudit')
        {
            $ParamOptions = @(
                @{
                'Name' = 'Rights';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.DirectoryServices.ActiveDirectoryRights]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                },
                @{
                'Name' = 'InheritanceFlags';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.DirectoryServices.ActiveDirectorySecurityInheritance]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                },
                @{
                'Name' = 'AuditFlags';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.Security.AccessControl.AuditFlags]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                }
            )
        }
        else
        {
            If ($PSCmdlet.ParameterSetName -eq 'RegistryAudit'){$AccessRights = [System.Security.AccessControl.RegistryRights]}
            If ($PSCmdlet.ParameterSetName -eq 'FileAudit'){$AccessRights = [System.Security.AccessControl.FileSystemRights]}
            $ParamOptions = @(
                @{
                'Name' = 'Rights';
                'Mandatory' = $true;
                'ValidateSetOptions' = ($AccessRights).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                },
                @{
                'Name' = 'InheritanceFlags';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.Security.AccessControl.InheritanceFlags]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                },
                @{
                'Name' = 'PropagationFlags';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.Security.AccessControl.PropagationFlags]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                },
                @{
                'Name' = 'AuditFlags';
                'Mandatory' = $true;
                'ValidateSetOptions' = ([System.Security.AccessControl.AuditFlags]).DeclaredMembers | where { $_.IsStatic } | select -ExpandProperty name
                }
            )
        }

        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        foreach ($Param in $ParamOptions) {
            $RuntimeParam = New-DynamicParam @Param
            $RuntimeParamDic.Add($Param.Name, $RuntimeParam)
        }
        return $RuntimeParamDic
    }

    begin {
        $PsBoundParameters.GetEnumerator() | foreach { New-Variable -Name $_.Key -Value $_.Value -ea 'SilentlyContinue'}
    }

    process
    {
        try 
        {
            if ($PSCmdlet.ParameterSetName -eq 'AdObjectAudit')
            {
                $AuditRuleObject = New-Object System.DirectoryServices.ActiveDirectoryAuditRule($IdentityReference,$Rights,$AuditFlags,[guid]'00000000-0000-0000-0000-000000000000', $InheritanceFlags,[guid]'00000000-0000-0000-0000-000000000000')
                $path = $AdObjectPath
            }
            else
            {
                If($PSCmdlet.ParameterSetName -eq 'RegistryAudit')
                {
                    $AuditRule = "System.Security.AccessControl.RegistryAuditRule"
                    $Path = $RegistryPath
                }
                If($PSCmdlet.ParameterSetName -eq 'FileAudit')
                {
                    $AuditRule = "System.Security.AccessControl.FileSystemAuditRule"
                    $Path = $FilePath
                }
                $AuditRuleObject = New-Object $AuditRule($IdentityReference,$Rights,$InheritanceFlags,$PropagationFlags,$AuditFlags)
            }
            $Acl = Get-Acl $Path -Audit
            $Acl.SetAuditRule($AuditRuleObject)
            Set-Acl $Path $Acl
        } 
        catch 
        {
            Write-Error $_.Exception.Message
        }
    }
}

function New-DynamicParam {
    [CmdletBinding()]
    [OutputType('System.Management.Automation.RuntimeDefinedParameter')]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [array]$ValidateSetOptions,
        [Parameter()]
        [switch]$Mandatory = $false,
        [Parameter()]
        [switch]$ValueFromPipeline = $false,
        [Parameter()]
        [switch]$ValueFromPipelineByPropertyName = $false
    )

    $Attrib = New-Object System.Management.Automation.ParameterAttribute
    $Attrib.Mandatory = $Mandatory.IsPresent
    $Attrib.ValueFromPipeline = $ValueFromPipeline.IsPresent
    $Attrib.ValueFromPipelineByPropertyName = $ValueFromPipelineByPropertyName.IsPresent

    # Create AttributeCollection object for the attribute
    $Collection = new-object System.Collections.ObjectModel.Collection[System.Attribute]
    # Add our custom attribute
    $Collection.Add($Attrib)
    # Add Validate Set 
    $ValidateSet= new-object System.Management.Automation.ValidateSetAttribute($Param.ValidateSetOptions)
    $Collection.Add($ValidateSet)
    # Create Runtime Parameter
    if ($Param.Name -eq 'Rights')
    {
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter($Param.Name, [array], $Collection)
    }
    else
    {
        $DynParam = New-Object System.Management.Automation.RuntimeDefinedParameter($Param.Name, [string], $Collection)
    }
    $DynParam
}