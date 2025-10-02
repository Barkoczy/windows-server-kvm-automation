# Windows Server VM Automation (KVM/libvirt)

![Status](https://img.shields.io/badge/Status-Production_Ready-brightgreen)
![Platform](https://img.shields.io/badge/Platform-Ubuntu_24.04_LTS-orange)
![Hypervisor](https://img.shields.io/badge/Hypervisor-KVM%2Flibvirt-blue)
![Automation](https://img.shields.io/badge/Automation-Fully_Unattended-blue)

**Plně automatizovaná** instalace Windows Server 2019/2022/2025 VM na Ubuntu 24.04 s KVM/libvirt.
Žádná manuální interakce během instalace - vše řízeno pomocí `Autounattend.xml`.

**Optimalizováno pro:** Intel i9-13980HX, 31GB RAM, Wi-Fi networking (říjen 2025).

## 🎯 Klíčové Vlastnosti

- ✅ **Plně automatická instalace** - Zero-touch pomocí `Autounattend.xml`
- ✅ **UEFI + Q35** chipset (moderní standard pro Windows)
- ✅ **VirtIO ovladače** auto-injekce během instalace
- ✅ **NAT networking** (Wi-Fi kompatibilní - macvtap nefunguje na Wi-Fi!)
- ✅ **Host-passthrough CPU** (plný výkon i9-13980HX)
- ✅ **Automatizace přes Makefile** (jediný příkaz: `make install`)
- ✅ **Předkonfigurováno RDP** - Okamžitý vzdálený přístup po instalaci

## 📋 Požadavky

### Hostitelský Systém (Ověřeno)

- **OS:** Ubuntu 24.04 LTS (Noble Numbat)
- **CPU:** Intel/AMD s VT-x/AMD-V virtualizací
- **RAM:** Min. 4 GB volné (doporučeno 8+ GB)
- **Disk:** Min. 40 GB volné (doporučeno 60+ GB)
- **Síť:** Jakékoliv připojení (Wi-Fi, Ethernet)

### Software Dependencies

Automaticky se nainstalují přes `make deps`:

- `qemu-kvm`, `libvirt-daemon-system`, `libvirt-clients`
- `virt-manager`, `virt-viewer` (GUI správa)
- `ovmf` (UEFI firmware)
- `bridge-utils`, `cpu-checker`

## ⚙️ Konfigurace

### Config.yml (Doporučeno)

Editujte `config.yml` pro snadnou správu parametrů VM:

```yaml
vm:
  name: winlab
  version: 2019 # 2019 or 2022

hardware:
  vcpu: 12 # Number of virtual CPU cores
  ram_mb: 12288 # RAM in MB (12288 = 12 GB)
  disk_gb: 60 # Disk size in GB
```

**Výhody:**

- ✅ Centralizovaná konfigurace
- ✅ Snadná editace (YAML formát)
- ✅ Fallback na výchozí hodnoty pokud config.yml chybí

### Parametry na Příkazové Řádce

Můžete také přepsat hodnoty přímo při volání:

```bash
make install VM_NAME=winserver-prod VCPU=8 RAM_MB=16384
```

### Bez config.yml

Makefile funguje i bez config.yml - použije výchozí hodnoty:

- vCPU: 12, RAM: 12 GB, Disk: 60 GB

## 🚀 Rychlý Start (3 příkazy = hotová VM!)

### 1. Stažení VirtIO Ovladačů

```bash
make download-virtio
```

Stáhne `virtio-win-0.1.285-1.iso` (nejnovější verze k říjnu 2025).

### 2. Stažení Windows Server ISO

#### Automatické Stažení (Doporučeno)

```bash
make download-ws-iso
```

Automaticky stáhne **Windows Server 2019** (podle config.yml) přímo z Microsoft.

**Vlastnosti:**

- ✅ Oficiální Microsoft Evaluation ISO
- ✅ Přímý download bez registrace
- ✅ Progress bar (s `pv`)
- ✅ Automatická verifikace velikosti
- ✅ 180-day evaluation license

#### Jiná Verze

```bash
# Stáhnout Windows Server 2022
make download-ws-iso WS_VERSION=2022

# Nebo upravit config.yml:
vm:
  version: 2022  # 2019, 2022, nebo 2025
```

#### Ruční Stažení (Alternativa)

```bash
make download-ws-iso-manual
```

Otevře browser s Microsoft Evaluation Center pro manuální download.

### 3. Instalace VM (Plně Automatická!)

```bash
make install
```

**Co se stane automaticky:**

- ✅ Vytvoření qcow2 disku (60 GB)
- ✅ Repackaging ISO s embedded `Autounattend.xml`
- ✅ Spuštění VM s UEFI boot
- ✅ Automatické dělení disku (EFI + MSR + Windows partition)
- ✅ Automatická instalace Windows Server 2019 Datacenter
- ✅ Auto-injekce VirtIO ovladačů během instalace
- ✅ Nastavení администратора: `Admin123!Password`
- ✅ Konfigurace RDP + firewall
- ✅ Pojmenování počítače: `WINLAB`

**Výchozí konfigurace:**

- vCPU: 12 jader
- RAM: 12 GB
- Disk: 60 GB (qcow2)
- Síť: NAT (192.168.122.x)

**Vlastní konfigurace:**

```bash
make install VM_NAME=winserver-prod VCPU=8 RAM_MB=16384 DISK_GB=120
```

⏱️ **Instalace trvá ~15-20 minut** - lze sledovat přes `make console`.

### 4. Po Dokončení Instalace

#### Připojení přes RDP

```bash
# Zjistit IP adresu VM
make status

# Připojit se
make rdp  # Zobrazí instrukce a IP adresu
```

**Výchozí credentials:**

- Username: `Administrator`
- Password: `Admin123!Password`

#### Post-instalační kroky (volitelné)

Detaily viz [docs/postinstall-guide.md](docs/postinstall-guide.md) - například instalace dalších VirtIO komponent.

## 📖 Příkazy Makefile

| Příkaz                        | Popis                                            |
| ----------------------------- | ------------------------------------------------ |
| `make help`                   | Zobrazit všechny dostupné příkazy                |
| `make deps`                   | Nainstalovat KVM/libvirt závislosti              |
| `make check`                  | Ověřit hostitelský systém a síť                  |
| `make net-default`            | Aktivovat libvirt NAT síť                        |
| `make download-virtio`        | Stáhnout VirtIO ovladače                         |
| `make download-ws-iso`        | Auto-stažení Windows Server ISO (2019/2022/2025) |
| `make download-ws-iso-manual` | Ruční download guide (browser)                   |
| `make disk`                   | Vytvořit qcow2 disk                              |
| `make install`                | Spustit instalaci VM                             |
| `make start`                  | Spustit VM                                       |
| `make stop`                   | Zastavit VM (graceful shutdown)                  |
| `make reboot`                 | Restartovat VM                                   |
| `make console`                | Připojit grafickou konzolu (virt-viewer)         |
| `make status`                 | Zobrazit stav VM a IP adresu                     |
| `make destroy`                | Násilně vypnout VM                               |
| `make undefine`               | Odstranit definici VM (disk zůstává)             |
| `make clean`                  | Smazat disk VM                                   |

## 🌐 Síťová Konfigurace

### NAT Network (Výchozí)

- VM IP: `192.168.122.x` (DHCP z libvirt)
- **Internet:** ✅ Automaticky funguje
- **Host→Guest:** ❌ Vyžaduje port forwarding

### Port Forwarding (RDP přístup)

```bash
# Zjistit IP VM
sudo virsh domifaddr winlab

# Přesměrovat host port 13389 → VM RDP 3389
sudo iptables -t nat -A PREROUTING -p tcp --dport 13389 -j DNAT --to-destination 192.168.122.X:3389
sudo iptables -A FORWARD -p tcp -d 192.168.122.X --dport 3389 -j ACCEPT

# Uložit pravidla
sudo apt install iptables-persistent
sudo netfilter-persistent save
```

**Připojení z hostitele:**

```bash
xfreerdp /u:Administrator /v:localhost:13389
```

### Proč NAT místo Macvtap?

⚠️ **Wi-Fi rozhraní nepodporují macvtap/bridge!**
Původní návrh s `macvtap` na `wlo1` **nebude fungovat** (ověřeno říjen 2025).
Řešení: NAT poskytuje plnou konektivitu s port forwardingem pro inbound spojení.

## 🔧 Technické Detaily

### Struktura Projektu

```
windows-server/
├── config.yml                       # Konfigurace VM
├── Makefile                         # Automatizace (12 příkazů)
├── README.md                        # Hlavní dokumentace
├── CHANGELOG.md                     # Historie změn
├── Autounattend.xml                 # Unattended installation config
├── .gitignore                       # Git ignore
├── iso/                             # 💿 ISO soubory (lokální)
│   ├── .gitkeep                     # (tracked by git)
│   ├── WinServer2019.iso            # (ignored)
│   ├── WinServer2019_Unattended.iso # (auto-generated, ignored)
│   └── virtio-win.iso               # (ignored)
├── docs/                            # 📚 Dokumentace
│   ├── README.md
│   ├── configuration.md
│   ├── download-iso.md
│   └── postinstall-guide.md
└── scripts/
    ├── download-windows-iso.sh      # Auto-download
    └── repack-unattended-iso.sh     # ISO repackaging s Autounattend.xml
```

### Architektura VM

```
┌─────────────────────────────────────┐
│   Windows Server 2019 (Guest)       │
│   ├── VirtIO SCSI (storage)         │
│   ├── VirtIO Net (network)          │
│   ├── QXL/Spice (graphics)          │
│   └── QEMU Guest Agent              │
└─────────────────────────────────────┘
           ↕ (virtio paravirt)
┌─────────────────────────────────────┐
│      QEMU/KVM (Hypervisor)          │
│      ├── Machine: Q35 (PCIe)        │
│      ├── Firmware: UEFI (OVMF)      │
│      └── CPU: host-passthrough      │
└─────────────────────────────────────┘
           ↕ (libvirt API)
┌─────────────────────────────────────┐
│   Ubuntu 24.04 LTS (Host)           │
│   ├── Kernel: 6.14.0-32             │
│   ├── CPU: i9-13980HX (32 threads)  │
│   ├── RAM: 31 GB                    │
│   └── Network: NAT (virbr0)         │
└─────────────────────────────────────┘
```

### Optimalizace Výkonu

- **CPU:** `host-passthrough` (bez emulace, plný výkon)
- **Disk:** VirtIO SCSI, cache `writeback`, IO threads, TRIM/discard
- **RAM:** Ballooning (dynamická alokace)
- **Síť:** VirtIO (paravirtualizace)

### Ověřeno

- Ubuntu 24.04.3 LTS (kernel 6.14.0-32)
- Intel i9-13980HX (VT-x)
- VirtIO drivers 0.1.285-1
- Windows Server 2019 Evaluation (180 dní)

## 🐛 Troubleshooting

### Instalace běží moc dlouho (>30 minut)

```bash
# Zkontrolovat stav instalace
make console  # Otevřít grafickou konzoli
make status   # Zkontrolovat IP adresu (přiřadí se po instalaci)
```

### VM nemá internet

```bash
# Ověřit NAT síť
sudo virsh net-list --all
# Měla by být "active" - pokud ne:
make net-default
```

### Špatný výkon

- Ověřte VirtIO ovladače nainstalované (Device Manager)
- Zkontrolujte: `sudo virsh dominfo winlab` (mělo by být "running")
- MSI interrupts pro VirtIO (pokročilé)

### Host nemůže pingat VM

- NAT izoluje VM od hostitele (záměrné)
- Použijte port forwarding nebo přidejte host-only síť

## 📚 Dokumentace

### Návody

- [Post-Installation Guide](docs/postinstall-guide.md) - Instalace ovladačů, síť, RDP
- [Configuration Reference](docs/configuration.md) - Kompletní config.yml dokumentace
- [ISO Download Guide](docs/download-iso.md) - Automatické i ruční stažení ISO

### Externí Reference

- [Windows Server Requirements](https://learn.microsoft.com/windows-server/get-started/hardware-requirements) (Microsoft Learn)
- [KVM/libvirt Ubuntu Docs](https://documentation.ubuntu.com/server/how-to/virtualisation/libvirt/) (Canonical)
- [VirtIO Drivers](https://github.com/virtio-win/kvm-guest-drivers-windows) (GitHub)
- [Proxmox Windows Best Practices](https://pve.proxmox.com/wiki/Windows_2025_guest_best_practices) (adaptováno pro KVM)

## 📝 License

MIT License - volně použitelné pro vzdělávací i produkční účely.

## 🔄 Unattended Installation

Projekt používá **plně automatizovanou instalaci** pomocí `Autounattend.xml`:

- **Zero-touch deployment** - žádná manuální interakce
- **Automatické dělení disku** (EFI + MSR + Windows NTFS partition)
- **VirtIO ovladače** automaticky injektovány během instalace
- **Předkonfigurace:**
  - Počítač: `WINLAB`
  - Administrator: `Admin123!Password`
  - RDP povoleno + firewall otevřen
  - Timezone: UTC
  - Locale: en-US

**Technické detaily:**

- Script `scripts/repack-unattended-iso.sh` přebalí originální ISO
- `Autounattend.xml` je embedded do ISO root + `sources/` dir
- VirtIO ovladače načteny z druhého CD-ROM během instalace
- UEFI boot vyžaduje `Autounattend.xml` v `sources/` (kritické!)

---

**Vytvořeno:** Říjen 2025
**Poslední update:** Říjen 2025 (plně automatizovaná instalace s Autounattend.xml)
**Testováno na:** Ubuntu 24.04.3 LTS, KVM/libvirt, VirtIO 0.1.285-1
