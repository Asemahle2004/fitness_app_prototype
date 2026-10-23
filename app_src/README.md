# ESP32 Secure Android App

This branch contains the source used by GitHub Actions to build an installable Android APK for the university project:

**Low-Cost Smart Security Monitoring System Using ESP32**

## Prototype defaults
- MQTT broker: broker.emqx.io:1883
- MQTT topic: home/security/camera/capture
- ESP32-CAM image: http://192.168.137.69/latest.jpg

The app interprets:
- CAPTURE = motion alert, bright environment, normal image
- CAPTURE_FLASH = motion alert, dark environment, flash image

No Wi-Fi password or private credential is embedded in the app.

The public MQTT broker is for prototype/demo use only. Production should use authenticated TLS/private infrastructure.

## Android behavior
- Receives MQTT alerts while the app process is running.
- Shows native Android notifications when permission is granted.
- Stores alert history/settings locally.
- Loads the latest ESP32-CAM JPEG over the local network.
- The camera URL can be changed from Settings when DHCP changes the ESP32-CAM IP.
