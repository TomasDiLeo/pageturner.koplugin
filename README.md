# PageTurner KoReader Plugin

A KoReader plugin that allows remote page turning via UDP commands from a Page Turning Companion app or any UDP client.

## Features

- UDP server for receiving page turn commands
- Configurable port (default: 8134)
- Support for next/previous page navigation
- Persistent settings for trusted IP addresses 

## Installation

1. Download the release zip containing `pageturner.koplugin` or clone the repository
2. Move the `pageturner.koplugin` folder into KOReader’s `plugins/` directory.
3. Restart KOReader.
4. The plugin will appear under `Tools` as `Page Turner`
5. Download and install the Page Turner Companion apk from the release section
[Page Turner Companion source code](https://github.com/TomasDiLeo/koreader_pageturner_companion)

The plugin has been tested on KOReader 2025.10 on a Kindle PW5,

## Usage

1. Open the plugin menu from KoReader's menu: `Tools → PageTurner`
2. Press `Start Service`. When the plugin's service starts you will see an Info screen detailing the IP of your device and the UDP port it is using (8134 by default). You can press `Show network info` to see this information again

<img src="/images/start_service.png" alt="drawing" width="300"/>
<img src="/images/service_started_popup.png" alt="drawing" width="300"/>

2. Open the Page Turning Companion App

<img src="/images/companion_home.jpg" alt="drawing" width="300"/>

3. Configure the IP address (Write the IP adress shown in the `Show network info` pop-up)
4. The port is 8134 by default, don't change this unless you modified the koplugin to use another port.
5. Press `CONNECT` to send a request to the plugin
6. A pop-up will appear on your KOReader device asking for confirmation. Press `Accept`

<img src="/images/confirmation.png" alt="drawing" width="300"/>

7. Once you press `Accept` the control screen will appear in the Page Turner Companion App

<img src="/images/companion_control.jpg" alt="drawing" width="300"/>

8. With a document opened, press the `PREVIOUS` and `NEXT` buttons to control your KOReader device. Alternatively you can use the volume control butttons to turn pages!

<img src="/images/video.gif" alt="drawing" width="300"/>


## Notes

- **Port**: This plugin uses the same port that the Calibre plugin uses to connect. To avoid problems press `Stop service` on the Page Turner plugin before using the Calibre Plugin to transfer files. Or configure the plugin to use another port (Note that some ports are not opened on certain devices, I used the port that Calibre uses because it works)
- **Network**: Make sure both the KOReader device and your Android phone are connected to the same network. You can look at your network information by going to `Settings → Network → Network info`.
- **Hotspot**: This plugin and app works via the network and does not require connection to the internet. You can use a mobile Hotspot to control the plugin.

Confirmed IP's are stored, you can forget IPs by going to `Tools → Page Turner → IP Managment` and deleting the IP

## Commands for custom implementations

The plugin accepts the following UDP commands (case-sensitive):
- `REQUEST` to request confirmation from the plugin, upon confirmation the plugin saves the IP as a trusted IP that autoconnects and sends an `ACCEPTED` command back. If you deny the request the plugin send a `DENIED` command
- `NEXT` or `PREV` to control the page turning
