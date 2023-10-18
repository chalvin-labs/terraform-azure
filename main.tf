resource "azurerm_resource_group" "labs" {
  name     = "labs_rg"
  location = "southeastasia"

  tags = {
    created_by = "chalvin"
  }
}

resource "azurerm_virtual_network" "labs_south" {
  name                = "labs_south_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.labs.location
  resource_group_name = azurerm_resource_group.labs.name
}

resource "azurerm_virtual_network" "labs_east" {
  name                = "labs_east_vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.labs.name
}

resource "azurerm_subnet" "labs_south" {
  name                 = "labs_south_subnet"
  resource_group_name  = azurerm_resource_group.labs.name
  virtual_network_name = azurerm_virtual_network.labs_south.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "labs_east" {
  name                 = "labs_east_subnet"
  resource_group_name  = azurerm_resource_group.labs.name
  virtual_network_name = azurerm_virtual_network.labs_east.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "labs" {
  name                = "labs_nsg"
  location            = azurerm_resource_group.labs.location
  resource_group_name = azurerm_resource_group.labs.name

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

  security_rule {
    name                       = "allow_icmp_sg"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "app" {
  count = 3
  name                = "labs_public_ip_app_${count.index}"
  resource_group_name = azurerm_resource_group.labs.name
  location            = azurerm_resource_group.labs.location
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "prometheus" {
  name                = "labs_public_ip_prometheus"
  resource_group_name = azurerm_resource_group.labs.name
  location            = "eastasia"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "grafana" {
  name                = "labs_public_ip_grafana"
  resource_group_name = azurerm_resource_group.labs.name
  location            = "eastasia"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "app" {
  count = 3
  name                = "labs_nic_app_${count.index}"
  location            = azurerm_resource_group.labs.location
  resource_group_name = azurerm_resource_group.labs.name

  ip_configuration {
    name                          = "labs_ip_app_config_${count.index}"
    subnet_id                     = azurerm_subnet.labs_south.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.app[count.index].id
  }
}

resource "azurerm_network_interface" "prometheus" {
  name                = "labs_nic_prometheus"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.labs.name

  ip_configuration {
    name                          = "labs_ip_prometheus_config"
    subnet_id                     = azurerm_subnet.labs_east.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.prometheus.id
  }
}

resource "azurerm_network_interface" "grafana" {
  name                = "labs_nic_grafana"
  location            = "eastasia"
  resource_group_name = azurerm_resource_group.labs.name

  ip_configuration {
    name                          = "labs_ip_grafana_config"
    subnet_id                     = azurerm_subnet.labs_east.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.grafana.id
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  count = 3
  name                            = "labs_vm_app_${count.index}"
  resource_group_name             = azurerm_resource_group.labs.name
  location                        = azurerm_resource_group.labs.location
  size                            = "Standard_B1s"
  computer_name                   = "app-${count.index}"
  admin_username                  = "chalvinwz"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.app[count.index].id,
  ]

  admin_ssh_key {
    username   = "chalvinwz"
    public_key = file("./labs.pub")
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

resource "azurerm_linux_virtual_machine" "prometheus" {
  name                            = "labs_vm_prometheus"
  resource_group_name             = azurerm_resource_group.labs.name
  location                        = "eastasia"
  size                            = "Standard_B2s"
  computer_name                   = "prometheus"
  admin_username                  = "chalvinwz"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.prometheus.id,
  ]

  admin_ssh_key {
    username   = "chalvinwz"
    public_key = file("./labs.pub")
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

resource "azurerm_linux_virtual_machine" "grafana" {
  name                            = "labs_vm_grafana"
  resource_group_name             = azurerm_resource_group.labs.name
  location                        = "eastasia"
  size                            = "Standard_B1s"
  computer_name                   = "grafana"
  admin_username                  = "chalvinwz"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.grafana.id,
  ]

  admin_ssh_key {
    username   = "chalvinwz"
    public_key = file("./labs.pub")
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
