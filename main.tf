# AWS Provider Configuration
provider "aws" {
  region = var.aws_region  # Specify the desired region
  profile = "DeveloperAccess-251539659924"
}

# Use existing VPC and Subnet


data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}



# Security Group for allowing RDP (port 3389)
resource "aws_security_group" "windows_bs_sg" {
  name        = "windows_bs-sg"
  description = "Allow RDP access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
     cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "windows_instance" {
  ami                     = var.ami_id  # Windows Server 2016 Base AMI for ap-south-1, change as per your region
  instance_type           = "t2.medium"              # Modify based on your instance type
  subnet_id               = var.subnet_id
  vpc_security_group_ids  = [aws_security_group.windows_bs_sg.id]  # Corrected reference to the security group
  key_name                = var.ec2_key     # Change to your key pair name if needed
  associate_public_ip_address = true
  # User Data - PowerShell script to change the admin password
  user_data = <<-EOF
   <powershell>

$newPassword = "nx2Tech2025!"


net user Administrator $newPassword


"Administrator password has been reset successfully." | Out-File C:\AdminPasswordResetLog.txt


$LocalTempDir = $env:TEMP
$ChromeInstaller = "ChromeInstaller.exe"
(new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller")
& "$LocalTempDir\$ChromeInstaller" /silent /install

$Process2Monitor = "ChromeInstaller"
Do {
    $ProcessesFound = Get-Process | Where-Object {$Process2Monitor -contains $_.Name} | Select-Object -ExpandProperty Name
    If ($ProcessesFound) {
        "Still running: $($ProcessesFound -join ', ')" | Write-Host
        Start-Sleep -Seconds 2
    } else {
        Remove-Item "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose
    }
} Until (!$ProcessesFound)



$pythonInstallerUrl = "https://www.python.org/ftp/python/3.13.2/python-3.13.2-amd64.exe"
$installerPath = "$env:TEMP\python_installer.exe"

Invoke-WebRequest -Uri $pythonInstallerUrl -OutFile $installerPath
Start-Process -FilePath $installerPath -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" -Wait
Remove-Item -Path $installerPath -Force

$pythonVersion = python --version 2>$null
if ($pythonVersion) { Write-Host "Python Installed Successfully: $pythonVersion" }
else { Write-Host "Python Installation Failed!" }


</powershell>
  EOF

  tags = {
    Name = "Rush-Windows-bs-Instance-frank"
  }
}

# Output the EC2 instance ID and public IP
output "instance_id" {
  value = aws_instance.windows_instance.id
}

output "public_ip" {
  value = aws_instance.windows_instance.public_ip
}
