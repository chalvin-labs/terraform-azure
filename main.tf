resource "azurerm_resource_group" "portfolio" {
  name     = "portfolio_rg"
  location = "southeastasia"

  tags = {
    created_by = "chalvin"
  }
}

resource "azurerm_virtual_network" "portfolio" {
  name                = "portfolio_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name
}

resource "azurerm_subnet" "portfolio" {
  name                 = "portfolio_subnet"
  resource_group_name  = azurerm_resource_group.portfolio.name
  virtual_network_name = azurerm_virtual_network.portfolio.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "apps" {
  count               = 2
  name                = "portfolio_public_ip_apps_${count.index}"
  resource_group_name = azurerm_resource_group.portfolio.name
  location            = azurerm_resource_group.portfolio.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "monitoring" {
  name                = "portfolio_public_ip_monitoring"
  resource_group_name = azurerm_resource_group.portfolio.name
  location            = azurerm_resource_group.portfolio.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "apps" {
  count               = 2
  name                = "portfolio_nic_apps_${count.index}"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name

  ip_configuration {
    name                          = "portfolio_ip_config"
    subnet_id                     = azurerm_subnet.portfolio.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.apps[count.index].id
  }
}

resource "azurerm_network_interface" "monitoring" {
  name                = "portfolio_nic_monitoring"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name

  ip_configuration {
    name                          = "portfolio_ip_config"
    subnet_id                     = azurerm_subnet.portfolio.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.monitoring.id
  }
}

resource "azurerm_network_security_group" "portfolio" {
  name                = "portfolio_nsg"
  location            = azurerm_resource_group.portfolio.location
  resource_group_name = azurerm_resource_group.portfolio.name

  security_rule {
    name                       = "allow_ssh_sg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_linux_virtual_machine" "apps" {
  count                           = 2
  name                            = "portfolio_vm_apps_${count.index}"
  resource_group_name             = azurerm_resource_group.portfolio.name
  location                        = azurerm_resource_group.portfolio.location
  size                            = "Standard_B1s"
  computer_name                   = "apps-${count.index}"
  admin_username                  = "chalvinwz"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.apps[count.index].id,
  ]

  admin_ssh_key {
    username   = "chalvinwz"
    public_key = file("./portfolio.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}

resource "azurerm_linux_virtual_machine" "monitoring" {
  name                            = "portfolio_vm_monitoring"
  resource_group_name             = azurerm_resource_group.portfolio.name
  location                        = azurerm_resource_group.portfolio.location
  size                            = "Standard_B1s"
  computer_name                   = "monitoring"
  admin_username                  = "chalvinwz"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.monitoring.id,
  ]

  admin_ssh_key {
    username   = "chalvinwz"
    public_key = file("./portfolio.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
}