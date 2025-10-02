# Documentation Index

Kompletní dokumentace pro Windows Server VM na Ubuntu 24.04.

## 📖 Návody

### [Post-Installation Guide](postinstall-guide.md)
Průvodce po instalaci Windows Server:
- ✅ Instalace VirtIO ovladačů
- ✅ Konfigurace sítě (NAT, RDP)
- ✅ Port forwarding pro přístup z hostitele
- ✅ Optimalizace výkonu
- ✅ Troubleshooting

**Kdy číst**: Hned po instalaci Windows Server

---

### [Configuration Reference](configuration.md)
Kompletní dokumentace config.yml:
- ⚙️ Všechny konfigurační parametry
- ⚙️ Výchozí hodnoty a doporučení
- ⚙️ Příklady pro různé scénáře
- ⚙️ Priorita konfigurace
- ⚙️ Troubleshooting

**Kdy číst**: Před úpravou config.yml

---

### [ISO Download Guide](download-iso.md)
Průvodce stahováním Windows Server ISO:
- 💾 Automatické stažení (2019/2022/2025)
- 💾 Přímé download linky
- 💾 Ruční stažení přes browser
- 💾 Verifikace a checksums
- 💾 Troubleshooting stahování

**Kdy číst**: Před `make download-ws-iso`

---

## 🚀 Rychlý Start

1. **Základní Setup**
   - Edituj [`config.yml`](../config.yml) (volitelné)
   - Spusť `make deps` (instalace závislostí)

2. **Stažení ISO**
   - Spusť `make download-virtio`
   - Spusť `make download-ws-iso`
   - Viz [ISO Download Guide](download-iso.md)

3. **Instalace VM**
   - Spusť `make install`
   - Load VirtIO drivers během Windows setup
   - Viz hlavní [README.md](../README.md)

4. **Post-Install**
   - Instaluj `virtio-win-guest-tools.exe`
   - Konfiguruj RDP (volitelné)
   - Viz [Post-Installation Guide](postinstall-guide.md)

## 📋 Časté Otázky

### Konfigurace

**Q: Jak změním počet CPU/RAM?**
- A: Edituj `config.yml` nebo použij `make install VCPU=16 RAM_MB=16384`
- Viz [Configuration Reference](configuration.md#hardware-settings)

**Q: Funguje to bez config.yml?**
- A: Ano, použijí se výchozí hodnoty (12 CPU, 12 GB RAM, 60 GB disk)

**Q: Jak změním verzi Windows Server?**
- A: Edituj `vm.version` v `config.yml` nebo `make download-ws-iso WS_VERSION=2022`
- Viz [ISO Download Guide](download-iso.md#jiná-verze)

### Instalace

**Q: Proč Windows nevidí disk během instalace?**
- A: Musíš načíst VirtIO storage driver
- Viz [README.md - Load VirtIO Drivers](../README.md#load-virtio-drivers)

**Q: Lze použít macvtap pro síť?**
- A: NE! Wi-Fi nepodporuje macvtap. Použij NAT (výchozí)
- Viz [README.md - Síťová Konfigurace](../README.md#síťová-konfigurace)

**Q: Jak dlouho trvá instalace?**
- A: ~30-60 minut (závisí na HW a rychlosti disku)

### Post-Install

**Q: VM nemá internet?**
- A: Zkontroluj NAT síť: `make net-default`
- Viz [Post-Installation Guide - Troubleshooting](postinstall-guide.md#no-network-after-install)

**Q: Jak se připojím na VM přes RDP?**
- A: Nastav port forwarding na hostiteli
- Viz [Post-Installation Guide - Enable RDP](postinstall-guide.md#enable-rdp-remote-desktop)

**Q: VM je pomalá?**
- A: Ověř, že máš nainstalované VirtIO ovladače
- Viz [Post-Installation Guide - Performance Optimization](postinstall-guide.md#performance-optimization)

## 🔧 Technická Reference

### Architektura
```
┌─────────────────────────────────────┐
│   Windows Server (Guest)            │
│   └── VirtIO drivers (storage/net) │
└─────────────────────────────────────┘
           ↕ (virtio paravirt)
┌─────────────────────────────────────┐
│   QEMU/KVM + Q35 + UEFI             │
└─────────────────────────────────────┘
           ↕ (libvirt API)
┌─────────────────────────────────────┐
│   Ubuntu 24.04 LTS                  │
│   └── NAT network (virbr0)          │
└─────────────────────────────────────┘
```

### Klíčové Technologie
- **Hypervisor**: KVM (Kernel-based Virtual Machine)
- **Management**: libvirt
- **Chipset**: Q35 (PCIe)
- **Firmware**: UEFI (OVMF)
- **Drivers**: VirtIO 0.1.285-1
- **Network**: NAT (Wi-Fi compatible)

### Soubory Projektu
```
windows-server/
├── config.yml              # Konfigurace VM
├── Makefile                # Automatizační příkazy
├── README.md               # Hlavní dokumentace
├── .gitignore              # Git ignore pravidla
├── docs/                   # Dokumentace
│   ├── README.md           # Tento soubor
│   ├── configuration.md    # Config reference
│   ├── download-iso.md     # ISO download guide
│   └── postinstall-guide.md # Post-install návod
└── scripts/
    └── download-windows-iso.sh  # Auto-download skript
```

## 📚 Externí Zdroje

### Oficiální Dokumentace
- [Windows Server Docs](https://learn.microsoft.com/windows-server/) - Microsoft
- [Ubuntu KVM Guide](https://documentation.ubuntu.com/server/how-to/virtualisation/libvirt/) - Canonical
- [libvirt Documentation](https://libvirt.org/docs.html) - libvirt.org
- [VirtIO Drivers](https://github.com/virtio-win/kvm-guest-drivers-windows) - GitHub

### Community Resources
- [Proxmox Windows Best Practices](https://pve.proxmox.com/wiki/Windows_2025_guest_best_practices)
- [QEMU Wiki](https://wiki.qemu.org/)
- [r/homelab](https://reddit.com/r/homelab) - Reddit community

### Troubleshooting Resources
- [libvirt FAQ](https://wiki.libvirt.org/FAQ.html)
- [Windows Server Forums](https://learn.microsoft.com/answers/tags/331/windows-server)

## 🤝 Přispívání

Chyby nebo návrhy na zlepšení? Vytvořte issue nebo pull request!

## 📝 License

MIT License - viz [LICENSE](../LICENSE)

---

**Poslední aktualizace**: Říjen 2025
**Verze**: 1.0
**Ověřeno na**: Ubuntu 24.04.3 LTS, Intel i9-13980HX
