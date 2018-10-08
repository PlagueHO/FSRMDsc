$script:DSCModuleName = 'FSRMDsc'
$script:DSCResourceName = 'DSR_FSRMQuotaAction'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit
#endregion HEADER

# Begin Testing
try
{
    #region Pester Tests
    InModuleScope $script:DSCResourceName {
        $script:DSCResourceName = 'DSR_FSRMQuotaAction'

        # Create the Mock -CommandName Objects that will be used for running tests
        # General purpose Action Mocks
        $script:MockEmail = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type    = 'Email'
            Subject = '[Quota Threshold]% quota threshold exceeded'
            Body    = 'User [Source Io Owner] has exceed the [Quota Threshold]% quota threshold for quota on [Quota Path] on server [Server]. The quota limit is [Quota Limit MB] MB and the current usage is [Quota Used MB] MB ([Quota Used Percent]% of limit).'
            MailBCC = ''
            MailCC  = 'fileserveradmins@contoso.com'
            MailTo  = '[Source Io Owner Email]'
        }

        $script:MockCommand = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type              = 'Command'
            Command           = 'c:\dothis.cmd'
            CommandParameters = ''
            KillTimeOut       = 60
            RunLimitInterval  = 3600
            SecurityLevel     = 'LocalSystem'
            ShouldLogError    = $true
            WorkingDirectory  = 'c:\'
        }

        $script:MockEvent = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type      = 'Event'
            Body      = 'User [Source Io Owner] has exceed the [Quota Threshold]% quota threshold for quota on [Quota Path] on server [Server]. The quota limit is [Quota Limit MB] MB and the current usage is [Quota Used MB] MB ([Quota Used Percent]% of limit).'
            EventType = 'Warning'
        }

        $script:MockReport = New-CimInstance `
            -ClassName 'MSFT_FSRMAction' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Type        = 'Report'
            ReportTypes = @('DuplicateFiles', 'LargeFiles', 'QuotaUsage')
        }

        # Quota mocks
        $script:MockThreshold1 = New-CimInstance `
            -ClassName 'MSFT_FSRMQuotaThreshold' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Percentage = 85
            Action     = [Microsoft.Management.Infrastructure.CimInstance[]]@(
                $script:MockEmail, $script:MockCommand
            )
        }

        $script:MockThreshold2 = New-CimInstance `
            -ClassName 'MSFT_FSRMQuotaThreshold' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Percentage = 100
            Action     = [Microsoft.Management.Infrastructure.CimInstance[]]@(
                $script:MockEvent, $script:MockReport
            )
        }

        # Quota mocks
        $script:MockQuota = New-CimInstance `
            -ClassName 'MSFT_FSRMQuota' `
            -Namespace Root/Microsoft/Windows/FSRM `
            -ClientOnly `
            -Property @{
            Path        = 'c:\users'
            Description = '5 GB Hard Limit'
            Ensure      = 'Present'
            Size        = 5GB
            SoftLimit   = $false
            Threshold   = [Microsoft.Management.Infrastructure.CimInstance[]]@(
                $script:MockThreshold1, $script:MockThreshold2
            )
            Disabled    = $false
            Template    = '5 GB Limit'
        }

        $script:TestQuotaActionEmail = [PSObject]@{
            Path       = $script:MockQuota.Path
            Percentage = $script:MockQuota.Threshold[0].Percentage
            Type       = 'Email'
            Verbose    = $true
        }

        $script:TestQuotaActionSetEmail = $script:TestQuotaActionEmail.Clone()
        $script:TestQuotaActionSetEmail += [PSObject]@{
            Ensure  = 'Present'
            Subject = $script:MockEmail.Subject
            Body    = $script:MockEmail.Body
            MailBCC = $script:MockEmail.MailBCC
            MailCC  = $script:MockEmail.MailCC
            MailTo  = $script:MockEmail.MailTo
        }

        $script:TestQuotaActionEvent = [PSObject]@{
            Path       = $script:MockQuota.Path
            Percentage = $script:MockQuota.Threshold[0].Percentage
            Type       = 'Event'
            Verbose    = $true
        }

        $script:TestQuotaActionSetEvent = $script:TestQuotaActionEvent.Clone()
        $script:TestQuotaActionSetEvent += [PSObject]@{
            Ensure    = 'Present'
            Body      = $script:MockEvent.Body
            EventType = $script:MockEvent.EventType
        }

        $script:TestQuotaActionCommand = [PSObject]@{
            Path       = $script:MockQuota.Path
            Percentage = $script:MockQuota.Threshold[0].Percentage
            Type       = 'Command'
            Verbose    = $true
        }

        $script:TestQuotaActionSetCommand = $script:TestQuotaActionCommand.Clone()
        $script:TestQuotaActionSetCommand += [PSObject]@{
            Ensure            = 'Present'
            Command           = $script:MockCommand.Command
            CommandParameters = $script:MockCommand.CommandParameters
            KillTimeOut       = $script:MockCommand.KillTimeOut
            RunLimitInterval  = $script:MockCommand.RunLimitInterval
            SecurityLevel     = $script:MockCommand.SecurityLevel
            ShouldLogError    = $script:MockCommand.ShouldLogError
            WorkingDirectory  = $script:MockCommand.WorkingDirectory
        }

        $script:TestQuotaActionReport = [PSObject]@{
            Path       = $script:MockQuota.Path
            Percentage = $script:MockQuota.Threshold[0].Percentage
            Type       = 'Report'
            Verbose    = $true
        }

        $script:TestQuotaActionSetReport = $script:TestQuotaActionReport.Clone()
        $script:TestQuotaActionSetReport += [PSObject]@{
            Ensure      = 'Present'
            ReportTypes = $script:MockReport.ReportTypes
        }

        Describe "$($script:DSCResourceName)\Get-TargetResource" {
            Context 'Quota does not exist' {
                Mock -CommandName Get-FsrmQuota { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }

                It 'Should throw QuotaNotFound exception' {
                    $getTargetResourceParameters = $script:TestQuotaActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaNotFoundError) -f $getTargetResourceParameters.Path, $getTargetResourceParameters.Percentage, $getTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { $result = Get-TargetResource @getTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists but threshold does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should throw QuotaNotFound exception' {
                    $getTargetResourceParameters = $script:TestQuotaActionEmail.Clone()
                    $getTargetResourceParameters.Percentage = 99

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaThresholdNotFoundError) -f $getTargetResourceParameters.Path, $getTargetResourceParameters.Percentage, $getTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { $result = Get-TargetResource @getTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists but action does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return absent quota action' {
                    $getTargetResourceParameters = $script:TestQuotaActionEvent.Clone()
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Absent'
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota and action exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return correct quota action' {
                    $getTargetResourceParameters = $script:TestQuotaActionEmail.Clone()
                    $result = Get-TargetResource @getTargetResourceParameters
                    $result.Ensure | Should -Be 'Present'
                    $result.Type | Should -Be 'Email'
                    $result.Subject | Should -Be $script:MockEmail.Subject
                    $result.Body | Should -Be $script:MockEmail.Body
                    $result.MailBCC | Should -Be $script:MockEmail.MailBCC
                    $result.MailCC | Should -Be $script:MockEmail.MailCC
                    $result.MailTo | Should -Be $script:MockEmail.MailTo
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Set-TargetResource" {
            Context 'Quota does not exist' {
                Mock -CommandName Get-FsrmQuota -MockWith { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }
                Mock -CommandName Set-FsrmQuota

                It 'Should throw QuotaNotFound exception' {
                    $setTargetResourceParameters = $script:TestQuotaActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaNotFoundError) -f $setTargetResourceParameters.Path, $setTargetResourceParameters.Percentage, $setTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmQuota -Exactly 0
                }
            }

            Context 'Quota exists but threshold does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }
                Mock -CommandName Set-FsrmQuota

                It 'Should throw QuotaNotFound exception' {
                    $setTargetResourceParameters = $script:TestQuotaActionEmail.Clone()
                    $setTargetResourceParameters.Percentage = 99

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaThresholdNotFoundError) -f $setTargetResourceParameters.Path, $setTargetResourceParameters.Percentage, $setTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { Set-TargetResource @setTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmQuota -Exactly 0
                }
            }

            Context 'Quota exists but action does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }
                Mock -CommandName Set-FsrmQuota

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestQuotaActionSetEvent.Clone()
                    $setTargetResourceParameters.Type = 'Event'
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }
                Mock -CommandName Set-FsrmQuota

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action exists but should not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }
                Mock -CommandName Set-FsrmQuota

                It 'Should not throw exception' {
                    $setTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $setTargetResourceParameters.Ensure = 'Absent'
                    { Set-TargetResource @setTargetResourceParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                    Assert-MockCalled -CommandName Set-FsrmQuota -Exactly 1
                }
            }
        }

        Describe "$($script:DSCResourceName)\Test-TargetResource" {
            Context 'Quota does not exist' {
                Mock -CommandName Get-FsrmQuota -MockWith { throw (New-Object -TypeName Microsoft.PowerShell.Cmdletization.Cim.CimJobException) }

                It 'Should throw QuotaNotFound exception' {
                    $testTargetResourceParameters = $script:TestQuotaActionEmail.Clone()

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaNotFoundError) -f $testTargetResourceParameters.Path, $testTargetResourceParameters.Percentage, $testTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists but threshold does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should throw QuotaNotFound exception' {
                    $testTargetResourceParameters = $script:TestQuotaActionEmail.Clone()
                    $testTargetResourceParameters.Percentage = 99

                    $errorRecord = Get-InvalidArgumentRecord `
                        -Message ($($LocalizedData.QuotaThresholdNotFoundError) -f $testTargetResourceParameters.Path, $testTargetResourceParameters.Percentage, $testTargetResourceParameters.Type) `
                        -ArgumentName 'Path'

                    { Test-TargetResource @testTargetResourceParameters } | Should -Throw $errorRecord
                }

                It 'Should call expected Mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists but action does not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEvent.Clone()
                    $testTargetResourceParameters.Type = 'Event'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and matching action exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return true' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    Test-TargetResource @testTargetResourceParameters | Should -Be $true
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Subject exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.Subject = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Body exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.Body = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Mail BCC exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.MailBCC = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Mail CC exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.MailCC = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Mail To exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.MailTo = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different Command exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.Command = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different CommandParameters exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.CommandParameters = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different KillTimeOut exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.KillTimeOut = $testTargetResourceParameters.KillTimeOut + 1
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different RunLimitInterval exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.RunLimitInterval = $testTargetResourceParameters.RunLimitInterval + 1
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different SecurityLevel exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.SecurityLevel = 'NetworkService'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different ShouldLogError exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.ShouldLogError = (-not $testTargetResourceParameters.ShouldLogError)
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different WorkingDirectory exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetCommand.Clone()
                    $testTargetResourceParameters.WorkingDirectory = 'Different'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action with different ReportTypes exists' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetReport.Clone()
                    $testTargetResourceParameters.ReportTypes = @( 'LeastRecentlyAccessed' )
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }

            Context 'Quota exists and action exists but should not' {
                Mock -CommandName Get-FsrmQuota -MockWith { return @($script:MockQuota) }

                It 'Should return false' {
                    $testTargetResourceParameters = $script:TestQuotaActionSetEmail.Clone()
                    $testTargetResourceParameters.Ensure = 'Absent'
                    Test-TargetResource @testTargetResourceParameters | Should -Be $false
                }

                It 'Should call the expected mocks' {
                    Assert-MockCalled -CommandName Get-FsrmQuota -Exactly 1
                }
            }
        }
    }
    #endregion
}
finally
{
    #region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    #endregion
}