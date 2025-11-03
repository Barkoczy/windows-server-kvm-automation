# Windows Server ISO Download Guide

## Automatické Stažení (Doporučeno)

### Základní Použití
```bash
# Stáhnout verzi z config.yml
make download-ws-iso

# Nebo přímo ze skriptu
./scripts/download-windows-iso.sh 2019
```

### Podporované Verze
- **2016** - Windows Server 2016 (≈6.5 GB) ⚠️ **Extended Support končí 12.1.2027**
- **2019** - Windows Server 2019 (5.3 GB)
- **2022** - Windows Server 2022 (5.2 GB)
- **2025** - Windows Server 2025 (5.4 GB)

Všechny verze jsou **180-day evaluation** z Microsoft Evaluation Center.

## Přímé Download Linky

### Windows Server 2016 (⚠️ EOL Warning)
```bash
curl -L -o WinServer2016.iso \
  'https://software-download.microsoft.com/download/pr/Windows_Server_2016_Datacenter_EVAL_en-us_14393_refresh.ISO'
```

> **⚠️ Životní cyklus Windows Server 2016**:
> - **Mainstream support skončil**: 11. ledna 2022
> - **Extended support končí**: 12. ledna 2027
> - **Doporučení**: Pro nové projekty zvažte novější verzi (2019/2022/2025)
> - **Poznámka**: Evaluation ISO je stále dostupné, ale podpora končí za ~1.5 roku

### Windows Server 2019
```bash
curl -L -o WinServer2019.iso \
  'https://software-download.microsoft.com/download/pr/17763.737.190906-2324.rs5_release_svc_refresh_SERVER_EVAL_x64FRE_en-us_1.iso'
```

### Windows Server 2022
```bash
curl -L -o WinServer2022.iso \
  'https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso'
```

### Windows Server 2025
```bash
curl -L -o WinServer2025.iso \
  'https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
```

## Ruční Stažení

### Přes Browser
```bash
make download-ws-iso-manual
```

Nebo navštivte přímo:
- **2016**: https://www.microsoft.com/evalcenter/evaluate-windows-server-2016
- **2019**: https://www.microsoft.com/evalcenter/download-windows-server-2019
- **2022**: https://www.microsoft.com/evalcenter/evaluate-windows-server-2022
- **2025**: https://www.microsoft.com/evalcenter/evaluate-windows-server-2025

## Verifikace Stažení

### Kontrola Velikosti
```bash
ls -lh iso/WinServer*.iso
```

Očekávané velikosti:
- 2016: ~6.5 GB
- 2019: ~5.3 GB
- 2022: ~5.2 GB
- 2025: ~5.4 GB

### SHA256 Checksum (Volitelné)
```bash
# Spustit s verifikací
VERIFY_CHECKSUM=1 ./scripts/download-windows-iso.sh 2019

# Nebo manuálně
sha256sum iso/WinServer2019.iso
```

## Licenční Informace

### Evaluation Edition
- **Platnost**: 180 dní od instalace
- **Aktivace**: Vyžadována do 10 dní (internet nutný)
- **Restart**: Po 10 dnech bez aktivace - automatický restart každou hodinu
- **Konverze**: Lze převést na plnou licenci pomocí product key

### Edice v ISO
Každé ISO obsahuje obě edice:
- **Standard Edition** - základní funkce
- **Datacenter Edition** - plná funkcionalita (doporučeno)
  - Unlimited virtualizace
  - Software Defined Storage
  - Shielded VMs
  - Storage Replica

### Instalační Režimy
- **Server Core** - minimální instalace, pouze CLI (doporučeno pro VM)
- **Desktop Experience** - GUI (vyžaduje více RAM/CPU)

## Troubleshooting

### Stažení Selhává
```bash
# Zkontrolovat připojení k internetu
ping software-download.microsoft.com

# Zkusit s verbose režimem
curl -v -L -o test.iso 'URL...'

# Použít wget jako alternativu
wget -O WinServer2019.iso 'URL...'
```

### SSL/TLS Chyby
```bash
# Aktualizovat CA certifikáty
sudo apt update && sudo apt install ca-certificates
sudo update-ca-certificates
```

### Nedostatek Místa
```bash
# Zkontrolovat volné místo v projektu
df -h .

# Změnit cílový adresář v config.yml (použít externí disk)
paths:
  iso_dir: /mnt/storage/isos
```

## Pokročilé Možnosti

### Paralelní Stažení (aria2)
```bash
# Instalace aria2
sudo apt install aria2

# Rychlejší download s 16 spojeními
aria2c -x16 -s16 -o WinServer2019.iso \
  'https://software-download.microsoft.com/...'
```

### Resume Přerušeného Stažení
```bash
# curl podporuje resume automaticky
curl -C - -L -o WinServer2019.iso 'URL...'

# wget také
wget -c -O WinServer2019.iso 'URL...'
```

## Reference
- Microsoft Evaluation Center: https://www.microsoft.com/evalcenter
- Windows Server Docs: https://learn.microsoft.com/windows-server/
- ISO velikosti ověřeny: Říjen 2025
