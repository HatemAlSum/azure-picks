function Expand-ZIPFile($file, $destination)
 {
 $shell = new-object -com shell.application
 $zip = $shell.NameSpace($file)
 foreach($item in $zip.items())
 {
 $shell.Namespace($destination).copyhere($item)
 }
 }


$path =(Get-Item -Path ".\" -Verbose).FullName
Invoke-WebRequest https://github.com/danielpalme/MVCBlog/archive/master.zip -OutFile master.zip
$extract_folder= $path +'\master'
$zip_file= $path +'\master.zip'
mkdir master -Force
Expand-ZIPFile –File $zip_file –Destination $extract_folder
cp -r .\master\MVCBlog-master C:\inetpub

#(new-object -com shell.application).namespace($extract_folder).CopyHere((new-object -com shell.application).namespace($zip_file).Items(),16)

NET USE \\c9-mssql-2014.eastus.cloudapp.azure.com\IPC$ /u:C9SQL2014\cloud9ers Cl0ud9er$
Robocopy /MIR /MT 'C:\inetpub\MVCBlog' '\\c9-mssql-2014.eastus.cloudapp.azure.com\c$\inetpub\MVCBlog'



NET USE \\c9-iis-asp-demo.eastus.cloudapp.azure.com\IPC$ /u:C9IISDEMO\cloud9ers Cl0ud9er$
Robocopy /MIR /MT 'C:\inetpub\MVCBlog' '\\c9-iis-asp-demo.eastus.cloudapp.azure.com\c$\inetpub\MVCBlog'

NET USE \\c9-mssql-2008.eastus.cloudapp.azure.com\IPC$ /u:C9SQL2008\cloud9ers Cl0ud9er$

Robocopy /MIR /MT 'D:\Backups' '\\c9-mssql-2008.eastus.cloudapp.azure.com\d$'