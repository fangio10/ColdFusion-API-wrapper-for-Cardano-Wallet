

<cfset oW = createObject("component","wallet").init() />

<cfset stNetwork = oW.networkInformation() />

<cfif stNetwork.bSuccess>
	<cfdump var="#stNetwork.data#" />
</cfif>


<cfset oA = createObject("component","address").init(expandPath("./")) />

<cfset stMnemonic = oW.generatePhrase() />

<cfif stMnemonic.bSuccess>
	<cfdump var="#stMnemonic.data#">
</cfif>

