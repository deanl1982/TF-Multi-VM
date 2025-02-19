# https://docs.microsoft.com/en-us/azure/developer/terraform/create-vm-cluster-with-infrastructure

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "test" {
  name     = "UKS-MultiVM-RG"
  location = "UK South"
}

resource "azurerm_virtual_network" "test" {
  name                = "UKS-Multi-VNET"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
}

resource "azurerm_subnet" "test" {
  name                 = "UKS-Multi-Subnet-VM"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.test.name
  address_prefix       = "10.1.2.0/24"
}

resource "azurerm_public_ip" "test" {
  name                = "publicIPForLB"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name
  allocation_method   = "Static"
}

/*resource "azurerm_lb" "test" {
  name                = "loadBalancer"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.test.id
  }
}

resource "azurerm_lb_backend_address_pool" "test" {
  resource_group_name = azurerm_resource_group.test.name
  loadbalancer_id     = azurerm_lb.test.id
  name                = "BackEndAddressPool"
}*/


resource "azurerm_network_interface" "test" {
  count               = 8
  name                = "acctni${count.index}"
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.test.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "test" {
  count                = 8
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.test.location
  resource_group_name  = azurerm_resource_group.test.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

/*resource "azurerm_availability_set" "avset" {
  name                         = "avset"
  location                     = azurerm_resource_group.test.location
  resource_group_name          = azurerm_resource_group.test.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}*/

resource "azurerm_windows_virtual_machine" "test" {
  count                 = 8
  name                  = "multi-m${count.index}"
  location              = azurerm_resource_group.test.location
  # availability_set_id   = azurerm_availability_set.avset.id
  resource_group_name   = azurerm_resource_group.test.name
  admin_username        = "hobadmin"
  admin_password        = "sZJvrlf2D64yEuLX"
  network_interface_ids = [element(azurerm_network_interface.test.*.id, count.index)]
  size               = "Standard_B2s"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  #delete_data_disks_on_termination = true

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  /* Optional data disks
  storage_data_disk {
    name              = "datadisk_new_${count.index}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = element(azurerm_managed_disk.test.*.name, count.index)
    managed_disk_id = element(azurerm_managed_disk.test.*.id, count.index)
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = element(azurerm_managed_disk.test.*.disk_size_gb, count.index)
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  } */

  tags = {
    environment = "staging"
  }
}