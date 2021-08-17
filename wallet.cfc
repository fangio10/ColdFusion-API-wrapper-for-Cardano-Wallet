<cfcomponent displayname="Cardano Wallet" output="false">

	<cffunction name="init" output="true" access="public" returntype="any" hint="Instantiate and configuire cardano wallet object">
		<cfargument name="bProduction" type="boolean" required="true" default="0" />
		<cfargument name="logFile" type="string" required="true" default="wallet.log" />
		<cfargument name="proto" type="string" required="true" default="http" />
		<cfargument name="ipAddress" type="string" required="true" default="127.0.0.1" />
		<cfargument name="port" type="string" required="true" default="8090" />
		<cfargument name="version" type="string" required="true" default="v2" />

		<cfset variables.logFile = arguments.logFile />
		<cfset variables.requestURL = arguments.proto&"://"&arguments.ipAddress&":"&arguments.port&"/"&arguments.version />

		<cfreturn this />
	</cffunction>

	<cffunction name="sendRequest" access="private" returntype="any" output="true" hint="sends request to wallet">
		<cfargument name="endPoint" type="string" required="true" hint="cardano wallet endpoint" />
		<cfargument name="requestType" type="string" required="true" default="get" hint="http request method" />
		<cfargument name="stData" type="struct" required="false" hint="parameters to pass to endpoint" />
				
		<cfset var stRequest = structNew() />
		<cfset var stResponse = structNew() />
		<cfset var stParam = structNew() />
		
		<cfset stResponse.bSuccess = false />
		<cfset stResponse.logLevel = "error" />
		
		<cfif structKeyExists(arguments,"stData")>
			<cfloop list="#structKeyList(arguments.stData)#" index="param">
				<cfif NOT isNull(arguments.stData[param])>
					<cfset stParam[param] = arguments.stData[param] />
				</cfif>
			</cfloop>
		</cfif>

		<cfhttp 
			method="#arguments.requestType#" 
			url="#variables.requestURL##arguments.endPoint#" 
			result="stRequest">

			<cfif structKeyExists(arguments,"stData")>
				<cfhttpparam type="header" name="Content-Type" value="application/json" />
				<cfhttpparam type="body" value="#serializeJSON(stParam)#" />
			</cfif>

		</cfhttp>

		<cfset stResponse.status_code = stRequest.status_code />

		<cfswitch expression="#stResponse.status_code#">

			<cfcase value="200,201,202,204">
				<cfset stResponse.bSuccess = true />
				<cfset stResponse.logLevel = "information" />
				<cfset stResponse.message = "Made request to #arguments.endPoint# [#serializeJSON(stParam)#]" />
				<cfif isJSON(stRequest.fileContent)>
					<cfset stResponse.data = deserializeJSON(stRequest.fileContent) />
				</cfif>
			</cfcase>

			<cfcase value="400,403,404,406,409,415">
				<cfset stResponse.message = "Request to #arguments.endPoint# Failed HTTP error #stResponse.status_code# with message #stResponse.error# [#serializeJSON(stParam)#]" />
			</cfcase>

			<cfcase value="0">
				<cfset stResponse.logLevel = "fatal" />
				<cfset stResponse.message = "Connection failure, is Cardano Wallet running? #stRequest.errorDetail#" />

			</cfcase>

			<cfdefaultcase>
				<cfset stResponse.logLevel = "warning" />
				<cfset stResponse.message = "Request to #arguments.endPoint# Failed HTTP error #stResponse.status_code# with message #stResponse.error# [#serializeJSON(stParam)#]" />
			</cfdefaultcase>

		</cfswitch>

		<cfset logEvent("fatal",stResponse.message) />		
	
		<cfreturn stResponse />
	</cffunction>

	<cffunction name="logEvent" access="private" returntype="void" output="false">
		<cfargument name="logLevel" type="string" required="true" />
		<cfargument name="message" type="string" required="true" />

		<cflog type="#arguments.logLevel#" text="#arguments.message#" file="#variables.logFile#" />

		<cfreturn />
	</cffunction>

	<cffunction name="getIsoTime" access="private" returntype="string" output="false">
		<cfargument name="datetime" type="datetime" required="true" />

		<cfreturn dateFormat(arguments.datetime, "yyyy-mm-dd") & "T" & timeFormat(arguments.datetime, "HH:mm:ss") & "Z" />
	</cffunction>


	<!--- // wallet --->
	<cffunction name="walletCreate" access="public" returntype="struct" output="false">
		<cfargument name="name" type="string" required="true" hint="1 .. 255 characters" />
		<cfargument name="mnemonic_sentence" type="array" required="true" hint="15 .. 24 items" />
		<cfargument name="passphrase" type="string" required="true" hint="10 .. 255 characters" />
		<cfargument name="mnemonic_second_factor" type="arrary" required="false" hint="9 .. 12 items" />
		<cfargument name="address_pool_gap" type="numeric" required="false" hint="10 .. 100000, default 20" />

		<cfreturn sendRequest(endPoint="/wallets",requestType="POST",stData=arguments) />
	</cffunction>

	<cffunction name="walletList" access="public" returntype="struct" output="false">

		<cfreturn sendRequest(endPoint="/wallets") />
	</cffunction>

	<cffunction name="walletUTxO" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/statistics/utxos") />
	</cffunction>

	<cffunction name="walletUTxOSnap" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/utxo") />
	</cffunction>

	<cffunction name="walletGet" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#") />
	</cffunction>

	<cffunction name="walletDelete" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#",method="delete") />
	</cffunction>

	<cffunction name="walletUpdateMetadata" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#",method="put") />
	</cffunction>

	<cffunction name="walletUpdatePassphrase" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/passphrase",method="put") />
	</cffunction>


	<!--- // addresses --->
	<cffunction name="addressList" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/addresses") />
	</cffunction>

	<cffunction name="addressInspectAddress" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/addresses/#arguments.addressId#") />
	</cffunction>

	<cffunction name="addressConstructAddress" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />

		<cfreturn sendRequest(endPoint="/addresses/#arguments.addressId#") />
	</cffunction>


	<!--- // transaction --->
	<cffunction name="transactionEstimateFee" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />
		<cfargument name="payments" type="array" required="false" hint=">= 0 items" />
		<cfargument name="withdrawal" type="string" required="false" hint="null, self" />
		<cfargument name="metadata" type="string" required="false" />
		<cfargument name="time_to_live" type="numeric" required="false" hint="int seconds" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions",requestType="post",stData=arguments) />
	</cffunction>

	<cffunction name="transactionCreate" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />
		<cfargument name="passphrase" type="string" required="true" hint="0 .. 255 characters" />
		<cfargument name="payments" type="array" required="false" hint=">= 0 items" />
		<cfargument name="withdrawal" type="string" required="false" hint="null, self" />
		<cfargument name="metadata" type="string" required="false" />
		<cfargument name="time_to_live" type="numeric" required="false" hint="int seconds" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions",requestType="post",stData=arguments) />
	</cffunction>

	<cffunction name="transactionList" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />
		<cfargument name="start" type="date" required="false" hint="string ISO 8601" />
		<cfargument name="end" type="date" required="false" hint="string ISO 8601" />
		<cfargument name="order" type="string" required="false" hint="ascending, descending" />
		<cfargument name="minWithdrawal" type="numeric" required="false" hint=">= 1" />

		<cfif structKeyExists(arguments,"start")>
			<cfset arguments.start = getIsoTime(arguments.start) />
		</cfif>

		<cfif structKeyExists(arguments,"end")>
			<cfset arguments.end = getIsoTime(arguments.end) />
		</cfif>

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions",stData=arguments) />
	</cffunction>

	<cffunction name="transactionGet" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />
		<cfargument name="transactionId" type="string" required="true" hint="64 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions/#arguments.transactionId#") />
	</cffunction>

	<cffunction name="transactionForget" access="public" returntype="struct" output="false">
		<cfargument name="walletId" type="string" required="true" hint="40 characters" />
		<cfargument name="transactionId" type="string" required="true" hint="64 characters" />

		<cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions/#arguments.transactionId#",requestType="delete") />
	</cffunction>


	<!--- // network --->
	<cffunction name="networkInformation" access="public" returntype="struct" output="false">

		<cfreturn sendRequest(endPoint="/network/information") />
	</cffunction>

	<cffunction name="networkClock" access="public" returntype="struct" output="false">

		<cfreturn sendRequest(endPoint="/network/clock") />
	</cffunction>

	<cffunction name="networkParameters" access="public" returntype="struct" output="false">

		<cfreturn sendRequest(endPoint="/network/parameters") />
	</cffunction>

</cfcomponent>
