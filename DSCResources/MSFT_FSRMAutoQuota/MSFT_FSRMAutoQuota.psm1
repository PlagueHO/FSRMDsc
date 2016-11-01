Import-Module -Name (Join-Path `
    -Path (Split-Path -Path $PSScriptRoot -Parent) `
    -ChildPath 'CommonResourceHelper.psm1')
$LocalizedData = Get-LocalizedData -ResourceName 'MSFT_FSRMAutoQuota'

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingAutoQuotaMessage) `
            -f $Path
        ) -join '' )

    # Lookup the existing auto quota
    $AutoQuota = Get-AutoQuota -Path $Path

    $returnValue = @{
        Path = $Path
    }
    if ($AutoQuota)
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.AutoQuotaExistsMessage) `
                -f $Path
            ) -join '' )

        $returnValue += @{
            Ensure = 'Present'
            Disabled = $AutoQuota.Disabled
            Template = $AutoQuota.Template
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.AutoQuotaDoesNotExistMessage) `
                -f $Path
            ) -join '' )

        $returnValue += @{
            Ensure = 'Absent'
        }
    }

    $returnValue
} # Get-TargetResource

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $Disabled,

        [System.String]
        $Template
    )

    # Remove any parameters that can't be splatted.
    $null = $PSBoundParameters.Remove('Ensure')

    # Lookup the existing Auto Quota
    $AutoQuota = Get-AutoQuota -Path $Path

    if ($Ensure -eq 'Present')
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureAutoQuotaExistsMessage) `
                -f $Path
            ) -join '' )

        if ($AutoQuota)
        {
            # The Auto Quota exists
            Set-FSRMAutoQuota @PSBoundParameters `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.AutoQuotaUpdatedMessage) `
                    -f $Path
                ) -join '' )
        }
        else
        {
            # Create the Auto Quota
            New-FSRMAutoQuota @PSBoundParameters `
                -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.AutoQuotaCreatedMessage) `
                    -f $Path
                ) -join '' )
        }
    }
    else
    {
        Write-Verbose -Message ( @(
            "$($MyInvocation.MyCommand): "
            $($LocalizedData.EnsureAutoQuotaDoesNotExistMessage) `
                -f $Path
            ) -join '' )

        if ($AutoQuota)
        {
            # The Auto Quota shouldn't exist - remove it
            Remove-FSRMAutoQuota -Path $Path -ErrorAction Stop

            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                $($LocalizedData.AutoQuotaRemovedMessage) `
                    -f $Path
                ) -join '' )
        } # if
    } # if
} # Set-TargetResource

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $Disabled,

        [System.String]
        $Template
    )
    # Flag to signal whether settings are correct
    [Boolean] $desiredConfigurationMatch = $true

    Write-Verbose -Message ( @(
        "$($MyInvocation.MyCommand): "
        $($LocalizedData.TestingAutoQuotaMessage) `
            -f $Path
        ) -join '' )

    # Check the properties are valid.
    Test-ResourceProperty @PSBoundParameters

    # Lookup the existing Quota
    $AutoQuota = Get-AutoQuota -Path $Path

    if ($Ensure -eq 'Present')
    {
        # The Auto Quota should exist
        if ($AutoQuota)
        {
            # The Auto Quota exists already - check the parameters
            if (($PSBoundParameters.ContainsKey('Disabled')) `
                -and ($AutoQuota.Disabled -ne $Disabled))
                {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.AutoQuotaPropertyNeedsUpdateMessage) `
                        -f $Path,'Disabled'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }

            if (($PSBoundParameters.ContainsKey('Template')) `
                -and ($AutoQuota.Template -ne $Template)) {
                Write-Verbose -Message ( @(
                    "$($MyInvocation.MyCommand): "
                    $($LocalizedData.AutoQuotaPropertyNeedsUpdateMessage) `
                        -f $Path,'Template'
                    ) -join '' )
                $desiredConfigurationMatch = $false
            }
        }
        else
        {
            # Ths Auto Quota doesn't exist but should
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.AutoQuotaDoesNotExistButShouldMessage) `
                    -f  $Path
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
    }
    else
    {
        # The Auto Quota should not exist
        if ($AutoQuota) {
            # The Auto Quota exists but should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.AutoQuotaExistsButShouldNotMessage) `
                    -f  $Path
                ) -join '' )
            $desiredConfigurationMatch = $false
        }
        else
        {
            # The Auto Quota does not exist and should not
            Write-Verbose -Message ( @(
                "$($MyInvocation.MyCommand): "
                 $($LocalizedData.AutoQuotaDoesNotExistAndShouldNotMessage) `
                    -f  $Path
                ) -join '' )
        }
    } # if
    return $desiredConfigurationMatch
} # Test-TargetResource

# Helper Functions
Function Get-AutoQuota {
    param (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path
    )
    try
    {
        $AutoQuota = Get-FSRMAutoQuota -Path $Path -ErrorAction Stop
    }
    catch [Microsoft.Management.Infrastructure.CimException] {
        $AutoQuota = $null
    }
    catch {
        Throw $_
    }
    Return $AutoQuota
}
<#
.Synopsis
    This function validates the parameters passed. Called by Test-Resource.
    Will throw an error if any parameters are invalid.
#>
Function Test-ResourceProperty {
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [ValidateSet('Present','Absent')]
        [System.String]
        $Ensure = 'Present',

        [System.Boolean]
        $Disabled,

        [System.String]
        $Template
    )
    # Check the path exists
    if (-not (Test-Path -Path $Path))
    {
        $errorId = 'AutoQuotaPathDoesNotExistError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AutoQuotaPathDoesNotExistError) -f $Path
    }
    if ($Ensure -eq 'Absent')
    {
        # No further checks required if Auto Quota should be removed.
        return
    }
    if ($Template)
    {
        # Check the template exists
        try
        {
            $null = Get-FSRMQuotaTemplate -Name $Template -ErrorAction Stop
        }
        catch [Microsoft.PowerShell.Cmdletization.Cim.CimJobException] {
            $errorId = 'AutoQuotaTemplateNotFoundError'
            $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
            $errorMessage = $($LocalizedData.AutoQuotaTemplateNotFoundError) -f $Path,$Template
        }
    }
    else
    {
        # A template wasn't specifed - it needs to be
        $errorId = 'AutoQuotaTemplateEmptyError'
        $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidArgument
        $errorMessage = $($LocalizedData.AutoQuotaTemplateEmptyError) -f $Path
    }
    if ($errorId)
    {
        $exception = New-Object -TypeName System.InvalidOperationException `
            -ArgumentList $errorMessage
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord `
            -ArgumentList $exception, $errorId, $errorCategory, $null

        $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
}

Export-ModuleMember -Function *-TargetResource
