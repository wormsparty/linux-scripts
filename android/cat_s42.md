Voici ton markdown corrigé :

---

# How to flash Android CAT S42

## Bootloader

1. Prendre l'image patchée ici : https://xdaforums.com/t/cat-s42.4341469/
2. Pour le flasher, les outils Android ne marchent pas pour de modèle, il faut passer par mtkclient
   ```bash
   git clone https://github.com/bkerler/mtkclient
   cd mtkclient
   python3 -m venv .venv
   . .venv/bin/activate
   pip install -r requirements.txt
   sudo usermod -a -G plugdev $USER  # Adapter en fonction de l'OS
   sudo usermod -a -G dialout $USER
   sudo cp Setup/Linux/*.rules /etc/udev/rules.d
   sudo udevadm control -R
   ```

Après avoir redémarré pour prendre en compte les règles udev :

- Éteindre complètement l'appareil, sans USB
- Lancer le script :
  ```bash
  python mtk.py w vbmeta_a,vbmeta_system_a,vbmeta_vendor_a vbmeta.img,vbmeta.img,vbmeta.img
  ```
- Brancher l'USB et booter (rien d'autre)
- L'appareil se flashe normalement assez rapidement

## Image

1. Prendre une image a64 (= arm32) : https://sourceforge.net/projects/andyyan-gsi/
2. Avec les outils Android :
   ```bash
   fastboot reboot fastboot
   fastboot flash system lineage-xxx.img
   fastboot reboot
   ```
   Le whipe de données n'a pas l'air de marcher, mais si le boot rate le téléphone proposera de le faire.
