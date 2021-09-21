<cfcomponent displayname="Cardano Wallet" output="false">

    <cffunction name="init" output="true" access="public" returntype="any" hint="Instantiate and configuire cardano wallet object">
        <cfargument name="proto" type="string" required="true" default="http" />
        <cfargument name="ipAddress" type="string" required="true" default="127.0.0.1" />
        <cfargument name="port" type="string" required="true" default="8090" />
        <cfargument name="version" type="string" required="true" default="v2" />
        <cfargument name="logFile" type="string" required="false" hint="pass in a filename to enable logging" />

        <cfset variables.requestURL = arguments.proto&"://"&arguments.ipAddress&":"&arguments.port&"/"&arguments.version />
        <cfset variables.bLog = false />

        <cfif structKeyExists(arguments,"logFile")>
            <cfset variables.bLog = true>
            <cfset variables.logFile = arguments.logFile />
        </cfif>

        <cfreturn this />
    </cffunction>

    <cffunction name="sendRequest" access="private" returntype="any" output="true" hint="sends request to wallet">
        <cfargument name="endPoint" type="string" required="true" hint="cardano wallet endpoint" />
        <cfargument name="requestType" type="string" required="true" default="get" hint="http request method" />
        <cfargument name="stData" type="struct" required="false" hint="parameters to pass to endpoint" />
        <cfargument name="bLogInputs" type="boolean" requires="true" default="true" />
                
        <cfset var stRequest = structNew() />
        <cfset var stResponse = structNew() />
        <cfset var stParam = structNew("ordered") />
        <cfset var inputLog = "" />
        
        <cfset stResponse.bSuccess = false />
        <cfset stResponse.logLevel = "error" />
        
        <cfif structKeyExists(arguments,"stData")>
            <cfloop list="#structKeyList(arguments.stData)#" index="param">
                <cfif NOT isNull(arguments.stData[param])>
                    <cfset stParam[param] = arguments.stData[param] />
                </cfif>
            </cfloop>
        </cfif>

        <cfset structDelete(stParam,"walletId") />

        <cfhttp 
            method="#arguments.requestType#" 
            url="#variables.requestURL##arguments.endPoint#" 
            result="stRequest">

            <cfif NOT structIsEmpty(stParam)>
                <cfhttpparam type="header" name="Content-Type" value="application/json" />
                <cfhttpparam type="body" value="#serializeJSON(stParam)#" />
            </cfif>

        </cfhttp>

        <cfif bLogInputs>
            <cfset inputLog = "[#serializeJSON(stParam)#]" />
        <cfelse>
            <cfset inputLog = "[inputs omitted - sensitive]" />
        </cfif>

        <cfset stResponse.code = stRequest.status_code />

        <cfswitch expression="#stResponse.code#">

            <cfcase value="200,201,202,204">
                <cfset stResponse.bSuccess = true />
                <cfset stResponse.logLevel = "information" />
                <cfset stResponse.logMessage = "Made request to #arguments.endPoint# #inputLog#" />
                <cfif isJSON(stRequest.fileContent)>
                    <cfset stResponse.data = deserializeJSON(stRequest.fileContent) />
                </cfif>
            </cfcase>

            <cfcase value="400,403,404,406,409,415">
                <cfset stResponse.logMessage = "Request to #arguments.endPoint# Failed HTTP error #stRequest.errorDetail# with message #stRequest.fileContent# #inputLog#" />
            </cfcase>

            <cfcase value="0">
                <cfset stResponse.logLevel = "fatal" />
                <cfset stResponse.logMessage = "Connection failure, is Cardano Wallet running? #stRequest.errorDetail#" />
            </cfcase>

            <cfdefaultcase>
                <cfset stResponse.logLevel = "warning" />
                <cfset stResponse.logMessage = "Request to #arguments.endPoint# Failed HTTP error #stResponse.code# with message #stRequest.fileContent# #inputLog#" />
            </cfdefaultcase>

        </cfswitch>

        <cfif variables.bLog>
            <cfset logEvent(stResponse.logLevel,stResponse.logMessage) />
        </cfif>
    
        <cfreturn stResponse />
    </cffunction>

    <cffunction name="logEvent" access="private" returntype="void" output="false">
        <cfargument name="logLevel" type="string" required="true" />
        <cfargument name="logMessage" type="string" required="true" />

        <cflog type="#arguments.logLevel#" text="#arguments.logMessage#" file="#variables.logFile#" />

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

        <cfreturn sendRequest(endPoint="/wallets",requestType="POST",stData=arguments,bLogInputs=false) />
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

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#",requestType="delete") />
    </cffunction>

    <cffunction name="walletUpdateMetadata" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#",requestType="put") />
    </cffunction>

    <cffunction name="walletUpdatePassphrase" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/passphrase",requestType="put") />
    </cffunction>


    <!--- // addresses --->
    <cffunction name="addressList" access="public" returntype="struct" output="true">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="state" type="string" required="false" hint="used, unused" />

        <cfset var filter = "" />

        <cfif structKeyExists(arguments,"state")>
            <cfif arguments.state EQ "unused">
                <cfset filter = "?state=unused" />
            <cfelseif arguments.state EQ "used">
                <cfset filter = "?state=used" />
            </cfif>
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/addresses#filter#") />
    </cffunction>

    <cffunction name="addressInspectAddress" access="public" returntype="struct" output="false">
        <cfargument name="addressId" type="string" required="true" hint="string <base58>" />

        <cfreturn sendRequest(endPoint="/addresses/#arguments.addressId#") />
    </cffunction>

    <cffunction name="addressConstructAddress" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="payment" type="string" required="false" hint="public key" />
        <cfargument name="stake" type="string" required="false" hint="public key" />
        <cfargument name="validation" type="string" required="false" hint="required,recommended" />

        <cfreturn sendRequest(endPoint="/addresses",requestType="post",stData=arguments) />
    </cffunction>


    <!--- // transaction --->
    <cffunction name="transactionEstimateFee" access="public" returntype="struct" output="true">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="payments" type="array" required="true" hint=">= 0 items" />
        <cfargument name="withdrawal" type="string" required="false" hint="null, self" />
        <cfargument name="metadata" type="struct" required="false" />
        <cfargument name="time_to_live" type="numeric" required="false" hint="int seconds" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/payment-fees",requestType="post",stData=arguments) />
    </cffunction>

    <cffunction name="transactionCreate" access="public" returntype="struct" output="true">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="passphrase" type="string" required="true" hint="0 .. 255 characters" />
        <cfargument name="payments" type="array" required="false" hint=">= 0 items" />
        <cfargument name="withdrawal" type="string" required="false" hint="null, self" />
        <cfargument name="metadata" type="struct" required="false" />
        <cfargument name="time_to_live" type="numeric" required="false" hint="int seconds" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions",requestType="post",stData=arguments,bLogInputs=false) />
    </cffunction>

    <cffunction name="transactionList" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="start" type="date" required="false" hint="string ISO 8601" />
        <cfargument name="end" type="date" required="false" hint="string ISO 8601" />
        <cfargument name="order" type="string" required="false" hint="ascending, descending" />
        <cfargument name="minWithdrawal" type="numeric" required="false" hint=">= 1" />

        <cfset var filter = "?" />

        <cfif structKeyExists(arguments,"start") AND isValid("date",arguments.start)>
            <cfset filter = listAppend(filter,"start=#getIsoTime(arguments.start)#","&") />
        </cfif>

        <cfif structKeyExists(arguments,"end") AND isValid("date",arguments.end)>
            <cfset filter = listAppend(filter,"end=#getIsoTime(arguments.end)#","&") />
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions#filter#") />
    </cffunction>

    <cffunction name="transactionGet" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="transactionId" type="string" required="true" hint="64 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions/#arguments.transactionId#") />
    </cffunction>

    <cffunction name="transactionForget" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="transactionId" type="string" required="true" hint="64 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions/#arguments.transactionId#",requestType="delete") />
    </cffunction>

    <!--- // keys --->
    <cffunction name="createAccountPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="transactionId" type="string" required="true" hint="64 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/trasactions/#arguments.transactionId#") />
    </cffunction>

    <cffunction name="getAccountPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/keys") />
    </cffunction>

    <cffunction name="getPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true" hint="40 characters" />
        <cfargument name="role" type="string" required="true" hint="utxo_external, utxo_internal, mutable_account" />
        <cfargument name="index" type="string" required="true" hint="Example: 1852H" />

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/keys/#arguments.role#/#arguments.index#") />
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
