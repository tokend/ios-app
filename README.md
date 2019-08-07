# TokenD iOS wallet
This is a template wallet app that provides access to any TokenD-based system. Read more about TokenD platform on <a href="http://tokend.org/" target="_blank">tokend.org</a>.

<a href="https://demo.tokend.io/downloads" target="_blank">Download app</a>

## Supported features

* Account creation & recovery
* Transfers
* Deposit & withdrawal
* Investments
* Trades
* Token explorer
* Security preferences management

## Customization
App appearance can be customized in file `Theme.swift`. Various colors and fonts can be changed there.

### Network config
The api configuration file `APIConfiguration.plist` contains 4 fields that represent network params of a specific TokenD-based system:
`api_endpoint`, `storage_endpoint`, `amount_precision` and `terms_address`.

The app allows user to specify a TokenD-based system to work with by scanning a QR code with network params. In this case, network params from the configuration will be used and displayed by default.

### Branding
In order to change the application branding you have to update following resources:

* `AppIcon` and `Icon` in `Assets` – app logos
* `Bundle display name` field in `Info.plist` – displayed application name
* `Bundle identifier` in target settings

## Credits
⛏ <a href="https://distributedlab.com/" target="_blank">Distributed Lab</a>, 2018
