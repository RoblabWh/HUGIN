# 🐦‍⬛ HUGIN & MUNIN - Intelligente FPV-Drohnenplattform

## Über das Projekt

Hugin und Munin sind zwei intelligente FPV-Drohnen, benannt nach den Raben des nordischen Gottes Odin. In der nordischen Mythologie fliegen [Hugin („Gedanke“) und Munin („Erinnerung“)](https://de.wikipedia.org/wiki/Hugin_und_Munin) täglich über die Welt, um Odin Wissen zu bringen. Unser Drohnenprojekt verfolgt ein ähnliches Ziel: Die Entwicklung einer autonomen und leistungsfähigen Drohnenplattform mit erweiterter Sensorik, KI-Verarbeitung und FPV-Funktionalität.

![HUGIN](images/2025-02-10-10-55-34-681.jpg)

## Drohnenübersicht

- **Hugin** – Erste Version der Drohne mit leistungsstarker Rechenplattform (Jetson Orin Nano), FPV-System und Navigationsmodulen.
- **Munin** – Schwesterdrohne

## Komponenten

| Komponenten                               | Beschreibung                            |
|-------------------------------------------|-----------------------------------------|
| **Flugsteuerung**                         |                                         |
| Matek H743 Slim V3 (STM32H743VIH6, DPS310, ICM42688, ICM42688)                        | Flight Controller mit H7-Prozessor      |
| **ESC & Antrieb**                         |                                         |
| Flywoo GOKU G55M 128K 3-6S 45A BLHeli_32 ESC | 45A 4-in-1 ESC für Motorsteuerung       |
| DJI FPV Motoren                           | Brushless-Motoren der DJI FPV           |
| DJI FPV Props (5328S 3-Blade)                            | Propeller der DJI FPV                   |
| Skystars Propeller Mount Adapter          | Adapter für Pushed Montage              |
| **Energieversorgung**                     |                                         |
| 6S 1P Sony / Murata Konion US18650VTC6 3120mAh - 30A                                | 6S Li-Ion Akku mit VTC6 Zellen          |
| Pololu 12V, 15A Step-Down Regulator       | Spannungsregler 12V, 15A                |
| Pololu 5V, 2.5A Step-Down Regulator       | Spannungsregler 5V, 2.5A                |
| **Navigation & Sensoren**                 |                                         |
| Ark Flow (PAW3902, S50LV85D, ICM-42688-P)                                  | Optical Flow Sensor + Rangefinder + IMU      |
| Matek M10Q-5883 (u-blox M10, QMC5883L)                | GPS und Kompassmodul                    |
| **Computer & Peripherie**                 |                                         |
| NVIDIA Jetson Orin NX 16GB                | KI-gestützter Mini-Computer             |
| Seedstudio A603 Carrier                   | Carrier Board für Jetson Orin NX      |
| Luxonis OAK-FFC 4P                        | FFC-Kamera-Modul                        |
| LB-Link BL-M8812EU2 (RTL8812EU-CG)        | WiFi-Modul mit RTL8812EU-CG Chip        |
| Foxeer Lollipop 4 Plus UFL RHCP           |                                         |
| 20P FFC Cable (5CM, Reverse, 0.5mm)       | Flexkabel für Kamera oder Peripherie    |
| 20P FFC Breakout Board                    | Adapterplatine für FFC-Kabel            |


## Installation Jetson

### Flash Jetson Linux

#### Abhängigkeiten
* Ubuntu 22.04 Host-Computer

#### Durchführung
1. (Optional) Neustart in die Recovery mit Login:
    ```bash
    sudo systemctl --reboot-argument=forced-recovery reboot
    ```
2. Folgen der [offiziellen Anleitung von seeed studio](https://wiki.seeedstudio.com/reComputer_A603_Flash_System/) für JP6.2, dabei zu beachten ist:
    * Wenn das Jetson schon in der Recovery ist, "Enter Force Recovery Mode" überspringen
    * Nach "Step 2" sollte direkt der Standardnutzer erstellt werden (Passwort eintragen):
        ```bash
        sudo ./tools/l4t_create_default_user.sh -u roblabuser -p CHANGE_THIS -n hugin --accept-license
        ```

### Aufspielen der Software

#### Abhängigkeiten
* Jetpack 7.2 [L4T 39.2.0]

#### Durchführung
1. Mit rsync den relevanten Ordner auf das Jetson kopieren, z.B.:
    ```bash
    rsync -auL --delete --info=progress2 jetson/. roblabuser@hugin.local:hugin_setup
    ```
2. SSH auf das Jetson, z.B.:
    ```bash
    ssh roblabuser@hugin.local
    ```
3. Installationsskript ausführen
    ```bash
    sudo ~/hugin_setup/install.sh
    ```
4. Neustarten, um alle Änderungen zu übernehmen
    ```bash
    sudo reboot
    ```

## Installation SteamDeck
### Abhängigkeiten
* SteamOS 3.7
* SteamDeck Wireless Module

### Durchführung
#### Grundeinrichtung direkt auf dem Steam Deck
1. In Steam anmelden
2. Wechsel zum Desktopmodus
    * Steam -> Power -> Switch to Desktop
3. Tastaturlayout einstellen
    * Settings -> Input Devices -> Keyboard -> Layouts
4. Mit lokalem Netzwerk verbinden
5. Root-Passwort erstellen
    ```bash
    passwd
    ```
6. Systemd Services für Remote-Verbindung aktivieren
    ```bash
    sudo systemctl enable --now sshd
    sudo systemctl enable --now avahi-daemon
    ```
7. Desktopmodus als Standard setzen
    ```bash
    steamos-session-select plasma-wayland-persistent
    ```
#### Automatische Einrichtung der restlichen Komponenten und Treiber
1. Das Wireless Modul anschließen
2. Mit rsync den relevanten Ordner auf das Steam Deck kopieren:
    ```bash
    rsync -auL --delete --info=progress2 steamdeck/. steamdeck:hugin_setup
    ```
3. SSH auf das Steam Deck:
    ```bash
    ssh deck@steamdeck.local
    ```
4. Installationsskript ausführen
    ```bash
    sudo ~/hugin_setup/install.sh
    ```
#### QGroundControl Konfiguration
!!TODO!!

## Installation FlightController
### Abhängigkeiten
* [MissionPlanner](https://ardupilot.org/planner/docs/mission-planner-installation.html)
* Docker

### Durchführung
1. Bauen der Firmware mittels Skript, z.B.:
    ```bash
    ardupilot/build_firmware.sh
    ```
2. Firmware nach offizieller Anleitung flashen, die *.apj und *.hex Dateien befinden sich in dem Ordner `ardupilot`
    * [Bei Update](https://ardupilot.org/copter/docs/common-loading-firmware-onto-pixhawk.html)
    * [Bei Erstinstallation](https://ardupilot.org/copter/docs/common-loading-firmware-onto-chibios-only-boards.html)
3. Aufspielen der Parameter mittels MissionPlanner
    1. Verbindung mit FlightController herstellen
    2. Nach `CONFIG` -> `Full Parameter List` navigieren
    3. Die *.param Datei aus dem `ardupilot` Ordner mit `Load from File` laden (hierbei können Meldungen auftreten, diese mit `OK` bestätigen)
    4. Die Änderungen mit `Write Params` übernehmen (hierbei können wieder Meldungen auftreten, diese wieder mit `OK` bestätigen)
    5. Den FlightController mittels `SETUP` -> `Mandatory Hardware` -> `Compass` -> `Reboot` neustarten
    6. Die Schritte `ii.` bis `v.` wiederholen, bis keine Änderungen nach Schritt `iii.` mehr auftreten (erkennbar durch `Modified` Checkbox in `Full Parameter List`, meist nach drei Iterationen)
