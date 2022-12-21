<!-- ABOUT THE PROJECT -->
## About The Project

API wrapper for Cardano Wallet facilitates communication between a ColdFusion server and the Cardano blockchain via the official [cardano-wallet](https://github.com/input-output-hk/cardano-wallet)


### Prerequisites

* A running instance of [cardano-wallet](https://github.com/input-output-hk/cardano-wallet/releases/tag/v2021-06-11)
* Executable access to [cardano-address](https://github.com/input-output-hk/cardano-addresses/releases/tag/3.5.0) asset on your coldfusion server


### Installation

Clone the repo
   ```sh
   git clone https://github.com/fangio10/ColdFusion-API-wrapper-for-Cardano-Wallet.git
   ```

<!-- USAGE EXAMPLES -->
## Usage

Instantiate wallet and address objects during application start, for example under function "onApplicationStart" in Application.cfc

   ```sh
   <cfset application.oW = createObject("component","wallet").init(ipAddress="192.168.1.1",logFile="wallet.log") />
   <cfset application.oA = createObject("component","address").init("/path/to/cardano-address") />
   ```

make a call to cardano-wallet, eg show network information

   ```sh
   <cfset stNetwork = application.oW.networkInformation() />
   ```

make a call to cardano-address, eg generate a passphrase

   ```sh
   <cfset stMnemonic = application.oA.generatePhrase() />
   ```

functions return a structure with the following keys:
- bSuccess (boolean): was request successful
- code (numeric): HTTP status code
- logLevel (string): information, warning, error, fatal
- logMessage (string): request details including any errors
- data (any): data returned from cardano-wallet


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/myFeature`)
3. Commit your Changes (`git commit -m 'Adding my feature'`)
4. Push to the Branch (`git push origin feature/myFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the APACHE License 2.0. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Franco - [@adaversePools](https://twitter.com/AdaversePools) - staking@adaverse.com

Project Link: [https://github.com/fangio10/ColdFusion-API-wrapper-for-Cardano-Wallet](https://github.com/fangio10/ColdFusion-API-wrapper-for-Cardano-Wallet)
