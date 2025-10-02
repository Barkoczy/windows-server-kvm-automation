# Windows Server VM - Post-Installation Guide

## During Windows Installation

### 1. Load VirtIO Drivers
When Windows setup asks "Where do you want to install Windows?" and shows no drives:

1. Click **"Load driver"**
2. Click **"Browse"**
3. Select the **virtio-win** CD-ROM drive
4. Navigate to and select:
   - `viostor\2k19\amd64` (for Windows Server 2019) - **Storage driver**
   - OR `viostor\2k22\amd64` (for Windows Server 2022)
5. Click **OK** → **Next**
6. The installation disk should now appear

### 2. Optional: Network Driver (if needed)
If Windows installer doesn't detect network during setup:
- Load driver from: `NetKVM\2k19\amd64` (or `2k22` for 2022)

## After First Boot

### 1. Install VirtIO Guest Tools
**IMPORTANT:** Install this immediately after Windows boots for full hardware support!

1. Open **File Explorer**
2. Navigate to the **virtio-win** CD-ROM drive
3. Run: `virtio-win-guest-tools-XXX.exe` (where XXX is version number)
4. Follow the installation wizard (install all components)
5. Reboot when prompted

**Installed components:**
- VirtIO Network driver (NetKVM)
- VirtIO Balloon driver (memory management)
- VirtIO Serial driver
- QEMU Guest Agent (for better host↔guest integration)
- QXL/Spice graphics drivers

### 2. Network Configuration

#### NAT Network (default)
- VM automatically gets IP from libvirt DHCP: `192.168.122.x`
- **Outbound internet:** ✅ Works automatically
- **Inbound connections:** Requires port forwarding on host

#### Enable RDP (Remote Desktop)
```powershell
# Run in PowerShell as Administrator
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

#### Port Forwarding (host→guest RDP)
On Ubuntu host, forward port 3389:
```bash
# Get VM IP
sudo virsh domifaddr winlab

# Forward host port 13389 to VM RDP port 3389
sudo iptables -t nat -A PREROUTING -p tcp --dport 13389 -j DNAT --to-destination 192.168.122.X:3389
sudo iptables -A FORWARD -p tcp -d 192.168.122.X --dport 3389 -j ACCEPT

# Make persistent (install iptables-persistent)
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

Connect from host: `rdesktop localhost:13389` or `xfreerdp /u:Administrator /v:localhost:13389`

### 3. Performance Optimization

#### Windows Update
Update to latest patches for better VirtIO driver compatibility

#### Disable Unnecessary Services
```powershell
# Disable Windows Search (saves RAM)
Stop-Service WSearch
Set-Service WSearch -StartupType Disabled
```

#### Enable High Performance Power Plan
```powershell
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
```

## Verification Checklist

✅ **Device Manager** shows:
- "Red Hat VirtIO SCSI controller" under Storage controllers
- "Red Hat VirtIO Ethernet Adapter" under Network adapters
- No yellow warning icons

✅ **Services** running:
- "QEMU Guest Agent" (automatic startup)

✅ **Network**:
- Can ping 8.8.8.8
- Can browse internet from VM

✅ **Integration**:
- Host can see VM IP: `sudo virsh domifaddr winlab`
- VM responds to shutdown from host: `sudo virsh shutdown winlab`

## Troubleshooting

### No Network After Install
1. Verify VirtIO network driver loaded: Device Manager → Network adapters
2. Check Windows Firewall isn't blocking
3. Verify NAT network active: `sudo virsh net-list --all`

### Poor Performance
1. Confirm VirtIO drivers installed (not IDE/E1000 emulation)
2. Check host CPU/RAM allocation: `make status`
3. Enable MSI interrupts for VirtIO devices (advanced)

### Can't Connect from Host
- NAT network isolates VM from host by default
- Use second host-only network, or configure port forwarding (see above)

## References
- VirtIO drivers: https://github.com/virtio-win/kvm-guest-drivers-windows
- KVM networking: https://wiki.libvirt.org/Networking.html
- Windows Server docs: https://learn.microsoft.com/windows-server/
