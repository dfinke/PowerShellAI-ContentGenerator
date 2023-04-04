#Requires -Module PowerShellAI
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [int]$max_tokens = 256,
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [decimal]$temperature = .7
)

Add-Type -AssemblyName presentationframework

$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStartupLocation="CenterScreen"
        Title="PowerShell - AI Content Generator" 
        Height="450" Width="750"
        Background="lightgray" >

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="33"/>
            <RowDefinition Height="28"/>
            <RowDefinition Height="33"/>
            <RowDefinition Height="28"/>            
            <RowDefinition />
            <RowDefinition Height="40" />
        </Grid.RowDefinitions>

        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="150"/>
            <ColumnDefinition/>
        </Grid.ColumnDefinitions>
        
        <Label Content="_Tone" Grid.Row="0" Grid.Column="0" Margin="3"/>
        <ComboBox x:Name="cboTone" Grid.Row="1" Grid.Column="0" SelectedIndex="0" Margin="3">
            <ComboBoxItem>Analytical</ComboBoxItem>
            <ComboBoxItem>Argumentative</ComboBoxItem>
            <ComboBoxItem>Cause and Effect</ComboBoxItem>
            <ComboBoxItem>Compare and Contrast</ComboBoxItem>
            <ComboBoxItem>Critical</ComboBoxItem>
            <ComboBoxItem>Descriptive</ComboBoxItem>
            <ComboBoxItem>Expository</ComboBoxItem>
            <ComboBoxItem>Formal</ComboBoxItem>
            <ComboBoxItem>Humorous</ComboBoxItem>
            <ComboBoxItem>Informal</ComboBoxItem>
            <ComboBoxItem>Inspirational</ComboBoxItem>
            <ComboBoxItem>Narrative</ComboBoxItem>
            <ComboBoxItem>Objective</ComboBoxItem>
            <ComboBoxItem>Persuasive</ComboBoxItem>
            <ComboBoxItem>Reflective</ComboBoxItem>
            <ComboBoxItem>Romantic</ComboBoxItem>
            <ComboBoxItem>Satirical</ComboBoxItem>
            <ComboBoxItem>Subjective</ComboBoxItem>
            <ComboBoxItem>Tragic</ComboBoxItem>
        </ComboBox>

        <Label Content="Ty_pe" Grid.Row="2" Grid.Column="0" Margin="3"/>
        <ComboBox x:Name="cboType" Grid.Row="3" Grid.Column="0" SelectedIndex="0" Margin="3">
            <ComboBoxItem>Tweet</ComboBoxItem>
            <ComboBoxItem>Blog Post</ComboBoxItem>
            <ComboBoxItem>YouTube Description</ComboBoxItem>
        </ComboBox>

        <GroupBox Header=" Topic " Grid.Row="0" Grid.Column="1" Grid.RowSpan="4" Margin="3">
            <TextBox x:Name="tbTopic" Margin="3"
                FontFamily="Consolas"
                FontSize="14"
                AcceptsReturn="True"
                AcceptsTab="True"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"
                TextWrapping="Wrap"
                Text="Announce a new version of PowerShell"
            />
        </GroupBox>

        <GroupBox Header=" Result " Grid.Row="4" Grid.Column="9" Grid.ColumnSpan="2" Margin="3">
            <TextBox x:Name="tbResult" Margin="3"
                FontFamily="Consolas"
                FontSize="14"
                AcceptsReturn="True"
                AcceptsTab="True"
                VerticalScrollBarVisibility="Visible"
                HorizontalScrollBarVisibility="Visible"
                TextWrapping="Wrap"
                IsReadOnly="True"
            />
        </GroupBox>
        
        <StackPanel Grid.Row="5" Grid.Column="1" Margin="3" Orientation="Horizontal">        
            <Label Content="How Many?" VerticalAlignment="Center" />
            <TextBox x:Name="tbHowMany" Text="1" Width="30" Margin="3" VerticalAlignment="Center" />

            <Button x:Name="btnGetGPt3" Content="_Generate" Margin="3" HorizontalAlignment="Left" Width="60"/>

            <Button x:Name="btnSave" Content="_Save" Margin="3" HorizontalAlignment="Left" Width="60"/>
        </StackPanel>
    </Grid>
</Window>
'@

function SaveFileDialog([string]$title, [string]$filter, [string]$defaultExt) {
    $dialog = New-Object Microsoft.Win32.SaveFileDialog
    $dialog.Title = $title
    $dialog.Filter = $filter
    $dialog.DefaultExt = $defaultExt
    $null = $dialog.ShowDialog() 
    $dialog.FileName
}

$Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader ([xml]$XAML)))

$tbTopic = $Window.FindName("tbTopic")
$tbResult = $Window.FindName("tbResult")
$cboTone = $Window.FindName("cboTone")
$cboType = $Window.FindName("cboType")
$btnGetGPt3 = $Window.FindName("btnGetGPt3")
$btnSave = $Window.FindName("btnSave")
$tbHowMany = $Window.FindName("tbHowMany")

$btnSave.Add_Click({
        $Window.Cursor = [System.Windows.Input.Cursors]::Wait
        $Window.Title = 'Saving ...'
        $filename = SaveFileDialog -title 'Save Result' -filter 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*' -defaultExt '.txt'
        if ($filename) {
            $tbResult.Text | Out-File -FilePath $filename -Encoding UTF8
        }
        $Window.Title = 'PowerShell - AI Content Generator'
        $Window.Cursor = [System.Windows.Input.Cursors]::Arrow
    })

$btnGetGPt3.Add_Click({
        $result = @()
        $Window.Cursor = [System.Windows.Input.Cursors]::Wait
        $Window.Title = 'Generating - {0} {1} ...' -f $cboTone.Text, $cboType.Text
        $prompt = 'Write a {0} in the style tone {1} about {2}' -f $cboType.Text, $cboTone.Text, $tbTopic.Text

        Write-Verbose $prompt

        for ($i = 0; $i -lt $tbHowMany.Text; $i++) {
            $result += Get-GPT3Completion -prompt $prompt -max_tokens $max_tokens -temperature $temperature 
        }
        $tbResult.Text = $result -join "`n"
        $Window.Title = 'PowerShell - AI Content Generator'
        $Window.Cursor = [System.Windows.Input.Cursors]::Arrow
    })


$null = $Window.ShowDialog()