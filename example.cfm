<cfset oW = createObject("component","wallet").init(ipAddress="127.0.0.1") />

<cfset stNetwork = application.ada.oW.networkInformation() />

<cfdump var="#stNetwork#" />


<cfset oA = createObject("component","address").init("/path/to/cardano-address") />

<cfset mnemonic = application.ada.oW.generatePhrase() />

<cfdump var="#mnemonic#">

