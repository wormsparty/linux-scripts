# Howto flash Android CAT S42

## Bootloader

1. Prendre image pachée ici https://xdaforums.com/t/cat-s42.4341469/
2. ```shell
git clone https://github.com/bkerler/mtkclient
cd mtkclient
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
sudo usermod -a -G plugdev $USER # Adapter en fonction de l'OS
sudo usermod -a -G dialout $USER
sudo cp Setup/Linux/*.rules /etc/udev/rules.d
sudo udevadm control -R
```

Après avoir rebooté pour prendre en compte les règles udev, il faut
- Arrêter complètement l'appareil, sans USB
- Lancer le script `python mtk.py w vbmeta_a,vbmeta_system_a,vbmeta_vendor_a vbmeta.img,vbmeta.img,vbmeta.img`
- Brancher l'USB et booter (rien d'autre)
- Normalement il se fait flasher assez vite

## Image

1. Prendre une image a64 (=arm32) https://sourceforge.net/projects/andyyan-gsi/
2. Avec les tools Android:
```shell
fastboot reboot fastboot
fastboot flash system lineage-xxx.img
fastboot reboot bootloader
fastboot -w # (ne marche pas? whipe possible depuis le téléphone si boot rate)
fastboot reboot
```
