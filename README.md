# 🐦‍⬛ HUGIN & MUNIN - Intelligente FPV-Drohnenplattform

## Über das Projekt

Hugin und Munin sind zwei intelligente FPV-Drohnen, benannt nach den Raben des nordischen Gottes Odin. In der nordischen Mythologie fliegen [Hugin („Gedanke“) und Munin („Erinnerung“)](https://de.wikipedia.org/wiki/Hugin_und_Munin) täglich über die Welt, um Odin Wissen zu bringen. Unser Drohnenprojekt verfolgt ein ähnliches Ziel: Die Entwicklung einer autonomen und leistungsfähigen Drohnenplattform mit erweiterter Sensorik, KI-Verarbeitung und FPV-Funktionalität.

## Drohnenübersicht

- **Hugin** – Erste Version der Drohne mit leistungsstarker Rechenplattform (Jetson Orin Nano), FPV-System und Navigationsmodulen.
- **Munin** – Schwesterdrohne

## Komponenten

| Komponenten                               | Beschreibung                            |
|-------------------------------------------|-----------------------------------------|
| **Flugsteuerung**                         |                                         |
| Matek H743 Slim                           | Flight Controller mit H7-Prozessor      |
| **ESC & Antrieb**                         |                                         |
| Mamba F40 ESC                             | 40A 4-in-1 ESC für Motorsteuerung       |
| DJI FPV Motoren                           | Brushless-Motoren der DJI FPV           |
| DJI FPV Props                             | Propeller der DJI FPV                   |
| Skystars Propeller Mount Adapter          | Adapter für Pushed Montage              |
| **Energieversorgung**                     |                                         |
| 6S 1P VTC6                                | 6S Li-Ion Akku mit VTC6 Zellen          |
| Pololu 12V, 15A Step-Down Regulator       | Spannungsregler 12V, 15A                |
| Pololu 5V, 2.5A Step-Down Regulator       | Spannungsregler 5V, 2.5A                |
| **Navigation & Sensoren**                 |                                         |
| Ark Flow                                  | Optical Flow Sensor + Rangefinder       |
| Matek M10Q-5883                           | GPS und Kompassmodul                    |
| **Computer & Peripherie**                 |                                         |
| Jetson Orin Nano                          | KI-gestützter Mini-Computer             |
| Seedstudio A603 Carrier                   | Carrier Board für Jetson Orin Nano      |
| Luxonis OAK-FFC 4P                        | FFC-Kamera-Modul                        |
| LB-Link BL-M8812EU2 (RTL8812EU-CG)        | WiFi-Modul mit RTL8812EU-CG Chip        |
| Foxeer Lollipop 4 Plus UFL RHCP           |                                         |
| 20P FFC Cable (5CM, Reverse, 0.5mm)       | Flexkabel für Kamera oder Peripherie    |
| 20P FFC Breakout Board                    | Adapterplatine für FFC-Kabel            |
