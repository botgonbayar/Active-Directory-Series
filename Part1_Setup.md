# 🧱 Part 1: Active Directory Lab Setup

This section outlines the setup of the lab environment including Windows Server 2025 installation, network configuration, and promoting the server to a Domain Controller.

---

## 🔧 Environment Details

- **Hypervisor**: VMware Workstation Pro 17
- **Network Mode**: Host-only
- **IP Range**: 192.168.100.0/24
- **Domain Controller (DC)**: `Secora-DC01` – 192.168.100.10
- **Client Machines**: Windows 11 – 192.168.100.20–30
- **Domain Name**: `secora.local`

---

## 🪟 Windows Server 2025 Configuration

1. Install Windows Server 2025 on a new VM
2. Assign static IP: `192.168.100.10`
3. Rename the computer to `Secora-DC01`
4. Enable RDP and install all Windows updates
5. Set up a secure local administrator password

---

## ⚙️ Install Active Directory Domain Services

```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

