$linuxUser = "azur1"
$linuxPassword = "YourSecurePassword123!" | ConvertTo-SecureString -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($linuxUser, $linuxPassword)
$location = "uksouth"
$resourceGroupName = "mate-azure-task-10"
$networkSecurityGroupName = "defaultnsg"
$virtualNetworkName = "vnet"
$subnetName = "default"
$vnetAddressPrefix = "10.0.0.0/16"
$subnetAddressPrefix = "10.0.0.0/24"
$sshKeyName = "linuxboxsshkey"
$vmSize = "Standard_B1s"
$vmImage = "Ubuntu2204"
$vm1Name = "matevm1"
$vm2Name = "matebvm2"
$zone1 = "1"
$zone2 = "2"

if (-not (Test-Path "$HOME\.ssh\$linuxUser.pub")) {
    Write-Host "SSH-ключ не найден. Генерируем новый..." -ForegroundColor Cyan
    ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\$linuxUser" -N "" | Out-Null
}

$sshKeyPublicKey = (Get-Content "$HOME\.ssh\$linuxUser.pub" -Raw).Trim()

Write-Host "Creating a resource group $resourceGroupName ..." -ForegroundColor Cyan
New-AzResourceGroup -Name $resourceGroupName -Location $location

Write-Host "Creating a network security group $networkSecurityGroupName ..." -ForegroundColor Cyan
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig -Name SSH -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsgRuleHTTP = New-AzNetworkSecurityRuleConfig -Name HTTP -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
$nsg = New-AzNetworkSecurityGroup -Name $networkSecurityGroupName -ResourceGroupName $resourceGroupName -Location $location -SecurityRules $nsgRuleSSH,$nsgRuleHTTP

# 4. Создание виртуальной сети и подсети
Write-Host "Creating Virtual Network..." -ForegroundColor Cyan
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressPrefix -NetworkSecurityGroup $nsg
New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName `
    -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig | Out-Null

# 5. Создание SSH ключа в Azure
Write-Host "Creating SSH Key in Azure..." -ForegroundColor Cyan
New-AzSshKey -Name $sshKeyName -ResourceGroupName $resourceGroupName -PublicKey $sshKeyPublicKey | Out-Null

New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vm1Name `
-Location $location `
-Image $vmImage `
-Size $vmSize `
-Credential $credential `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone $zone1


New-AzVm `
-ResourceGroupName $resourceGroupName `
-Name $vm2Name `
-Location $location `
-Image $vmImage `
-Size $vmSize `
-Credential $credential `
-SubnetName $subnetName `
-VirtualNetworkName $virtualNetworkName `
-SecurityGroupName $networkSecurityGroupName `
-SshKeyName $sshKeyName `
-Zone $zone2
