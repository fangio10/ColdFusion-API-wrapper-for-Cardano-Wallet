<!-- ABOUT THE PROJECT -->
## About The Project

cf_cardanowallet facilitates communication between a coldfusion server and the Cardano blockchain via the official [cardano-wallet](https://github.com/input-output-hk/cardano-wallet)


### Prerequisites

Access to a server running cardano-wallet as well as a copy of cardano-address on your coldfusion server.

* A running instance of [cardano-wallet](https://github.com/input-output-hk/cardano-wallet/releases/tag/v2021-06-11)
* A copy of the [cardano-address](https://github.com/input-output-hk/cardano-addresses/releases/tag/3.5.0) asset on your coldfusion server


### Installation

Clone the repo
   ```sh
   git clone https://github.com/fangio10/cf_cardanowallet.git
   ```

<!-- USAGE EXAMPLES -->
## Usage

Instantiate wallet and address objects during application start

   ```sh
   <cfset oW = createObject("component","wallet").init(ipAddress="127.0.0.1") />
   <cfset oA = createObject("component","address").init("/path/to/cardano-address") />
   ```

make a call to cardano-wallet, eg show network information

   ```sh
   <cfset stNetwork = oW.networkInformation() />
   <cfdump var="#stNetwork#" />
   ```

make a call to cardano-address, eg generate a passphrase

   ```sh
   <cfset mnemonic = oA.generatePhrase() />
   <cfdump var="#mnemonic#" />
   ```


<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request



<!-- LICENSE -->
## License

Distributed under the APACHE License 2.0. See `LICENSE` for more information.



<!-- CONTACT -->
## Contact

Franco - [@adaversePools](https://twitter.com/AdaversePools) - staking@adaverse.com

Project Link: [https://github.com/fangio10/cf_cardanowallet](https://github.com/fangio10/cf_cardanowallet)
