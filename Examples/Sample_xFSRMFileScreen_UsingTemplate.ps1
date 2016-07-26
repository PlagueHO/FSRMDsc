configuration Sample_FSRMFileScreen_UsingTemplate
{
    Import-DscResource -Module FSRMDsc

    Node $NodeName
    {
        FSRMFileScreen DUsersFileScreens
        {
            Path = 'd:\users'
            Description = 'File Screen for Blocking Some Files'
            Ensure = 'Present'
            Template = 'Block Some Files'
            MatchesTemplate = $true
        } # End of FSRMFileScreen Resource
    } # End of Node
} # End of Configuration
