param (
	[Parameter(Mandatory=$true)]
	$Url,
	$Cred,
	[switch]$UseWebLogin
)

if ($UseWebLogin.ToBool() -eq $false)
{
    if ($Cred -eq $null)
    {
        $Cred = Get-Credential
    }

	Write-Host "Connect to $Url using credentials"

    Connect-PnPOnline -Url $Url -Credentials $Cred
}
else
{
	Write-Host "Connect to $Url using webLogin"

    Connect-PnPOnline -Url $Url -UseWebLogin
}

#region Add jQuery

Write-Host "Add jQuery..."

$jsLink = Add-PnPJavaScriptLink -Name "jQuery" -Url "https://code.jquery.com/jquery.min.js" -Sequence 10 -Scope Site

#endregion
#region Create FAQ list

Write-Host "Create FAQ list..."

$listname = "FAQ"

$list = New-PnPList -Title $listname -Template GenericList -Url "lists/faq" -OnQuickLaunch:$false

$f = Add-PnPFieldFromXml -List $listname -FieldXml ([string](Get-Content .\Columns\Language.xml))
$f = Add-PnPFieldFromXml -List $listname -FieldXml ([string](Get-Content .\Columns\Answer.xml))

#endregion
#region Rename Title field

Write-Host "Rename Title field..."

$field = Get-PnPField -List $listname -Identity "Title"
$field.Title = "Question"
$field.Update()
Invoke-PnPQuery

#endregion
#region Create Scripts list

Write-Host "Create Scripts list..."

$list = Get-PnPList -Identity "Scripts" -ErrorAction SilentlyContinue

if ($list -eq $null)
{
    $list = New-PnPList -Title "Scripts" -Template DocumentLibrary -Url "scripts" -OnQuickLaunch:$false
}

#endregion
#region Upload script file

Write-Host "Upload script file..."

$f = Add-PnPFile -Path .\HTML-JavaScript\Load-FAQ.html -Folder "scripts" 

#endregion
#region Add wiki page

Write-Host "Add wiki page..."

$serverRelativeUrl = (Get-PnPList -Identity "Site Pages").RootFolder.ServerRelativeUrl
$pageUrl = "$serverRelativeUrl/FAQ.aspx"

$p = Add-PnPWikiPage -ServerRelativePageUrl $pageUrl -Layout OneColumn

#endregion
#region Add Content Editor Webpart

Write-Host "Add Content Editor Webpart..."

$wp = Add-PnPWebPartToWikiPage -ServerRelativePageUrl $pageUrl -Path '.\Webparts\Content Editor.dwp' -Row 1 -Column 1

$webpart = Get-PnPWebPart -ServerRelativePageUrl $pageUrl -Identity "Content Editor"

Set-PnPWebPartProperty -ServerRelativePageUrl $pageUrl -Identity $webpart.Id -Key ContentLink -Value $f.ServerRelativeUrl
Set-PnPWebPartProperty -ServerRelativePageUrl $pageUrl -Identity $webpart.Id -Key ChromeType -Value 2  # set the ChromeType to "None"

#endregion
#region Add link to quicklaunch

Write-Host "Add link to quicklaunch..."

$q = Add-PnPNavigationNode -Location QuickLaunch -Title "FAQ" -Url $pageUrl

#endregion
#region Clean-up quicklaunch...

Write-Host "Clean-up quicklaunch..."

$node = Get-PnPNavigationNode -Location QuickLaunch | Where { $_.Title -eq "Recent" }

if ($node -ne $null)
{
    Remove-PnPNavigationNode -Identity $node.Id -Force
}

#endregion

Write-Host "Done."
