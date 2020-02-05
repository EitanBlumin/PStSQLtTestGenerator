$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

. "$PSScriptRoot\constants.ps1"

Describe "$CommandName Unit Tests" -Tag 'UnitTests' {
    Context "Validate parameters" {
        [object[]]$params = (Get-Command $CommandName).Parameters.Keys | Where-Object { $_ -notin ('whatif', 'confirm') }
        [object[]]$knownParameters = 'SqlInstance', 'SqlCredential', 'Database', 'Schema', 'Table', 'OutputPath', 'Creator', 'TemplateFolder', 'TestClass', 'InputObject', 'EnableException'
        $knownParameters += [System.Management.Automation.PSCmdlet]::CommonParameters
        It "Should only contain our specific parameters" {
            (@(Compare-Object -ReferenceObject ($knownParameters | Where-Object { $_ }) -DifferenceObject $params).Count ) | Should Be 0
        }
    }
}

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {

    BeforeAll {
        $server = Connect-DbaInstance -SqlInstance $script:sqlinstance

        if ($server.Databases.Name -notcontains $script:database) {
            $query = "CREATE DATABASE $($script:database)"
            $server.Query($query)

            Invoke-DbaQuery -SqlInstance $script:sqlinstance -Database $script:database -File (Join-Path -Path $PSScriptRoot -ChildPath "database.sql")

            $server.Databases.Refresh()
        }

        if (-not (Test-Path -Path $script:unittestfolder)) {
            $null = New-Item -Path $script:unittestfolder -ItemType Directory
        }
    }

    Context "Create Table Constraint Test" {
        $result = @()
        $result += New-PSTGTableConstraintTest -SqlInstance $script:sqlinstance -Database $script:database -OutputPath $script:unittestfolder -EnableException

        $file = Get-Item -Path $result[0].FileName

        It "Should return a result" {
            $result | Should -Not -Be $null
        }

        It "Should have created a file" {
            $file | Should -Not -Be $null
        }

        It "Result should have correct values" {
            $file.FullName | Should -Be $result[0].FileName
        }
    }

    <# Context "Using Pipeline" {
        $tables = $server.Databases[$($script:database)].Tables

        $result = @()
        $result += $tables.Name | New-PSTGTableConstraintTest -SqlInstance $script:sqlinstance -Database $script:database -OutputPath $script:unittestfolder -EnableException

        $file = Get-Item -Path $result[0].FileName

        It "Should return a result" {
            $result | Should -Not -Be $null
        }

        It "Should have created a file" {
            $file | Should -Not -Be $null
        }

        It "Result should have correct values" {
            $file.FullName | Should -Be $result[0].FileName
        }
    } #>

    AfterAll {
        $null = Remove-DbaDatabase -SqlInstance $script:sqlinstance -Database $script:database -Confirm:$false

        $null = Remove-Item -Path $script:unittestfolder -Recurse -Force -Confirm:$false
    }
}