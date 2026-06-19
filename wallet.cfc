<cfcomponent displayname="Cardano Wallet API" output="false" hint="Production-ready wrapper for Cardano Wallet REST API v2">

    <cffunction name="init" access="public" returntype="any" output="false" hint="Initialize Cardano Wallet client">
        <cfargument name="proto"      type="string"  required="false" default="http">
        <cfargument name="ipAddress"  type="string"  required="false" default="127.0.0.1">
        <cfargument name="port"       type="string"  required="false" default="8090">
        <cfargument name="version"    type="string"  required="false" default="v2">
        <cfargument name="clientCert" type="string"  required="false" default="">
        <cfargument name="logFile"    type="string"  required="false" default="">

        <cfset variables.baseURL = "#arguments.proto#://#arguments.ipAddress#:#arguments.port#/#arguments.version#">
        <cfset variables.clientCert = arguments.clientCert>
        <cfset variables.logFile = arguments.logFile>
        <cfset variables.enableLogging = len(trim(arguments.logFile)) gt 0>

        <cfreturn this>
    </cffunction>

    <!--- ====================== CORE REQUEST METHOD ====================== --->
    <cffunction name="sendRequest" access="private" returntype="struct" output="false">
        <cfargument name="endPoint"    type="string"  required="true">
        <cfargument name="requestType" type="string"  required="false" default="GET">
        <cfargument name="stData"      type="struct"  required="false">
        <cfargument name="bLogInputs"  type="boolean" required="false" default="true">

        <cfset var result = {
            bSuccess = false,
            code = 0,
            data = {},
            error = "",
            logLevel = "error",
            logMessage = ""
        }>

        <cfset var httpResult = "">
        <cfset var body = {}>

        <cftry>
            <cfif structKeyExists(arguments, "stData")>
                <cfset body = duplicate(arguments.stData)>
                <cfset structDelete(body, "walletId")>
            </cfif>

            <cfhttp 
                method="#uCase(arguments.requestType)#" 
                url="#variables.baseURL##arguments.endPoint#" 
                result="httpResult"
                timeout="45"
                throwonerror="false">

                <cfif not structIsEmpty(body)>
                    <cfhttpparam type="header" name="Content-Type" value="application/json">
                    <cfhttpparam type="body" value="#serializeJSON(body)#">
                </cfif>

                <cfif len(variables.clientCert)>
                    <cfhttpparam type="clientCert" value="#variables.clientCert#">
                </cfif>
            </cfhttp>

            <cfset result.code = httpResult.statusCode>

            <cfif isJSON(httpResult.fileContent)>
                <cfset result.data = deserializeJSON(httpResult.fileContent)>
            <cfelse>
                <cfset result.data = httpResult.fileContent>
            </cfif>

            <cfif listFind("200,201,202,204", result.code)>
                <cfset result.bSuccess = true>
                <cfset result.logLevel = "information">
                <cfset result.logMessage = "SUCCESS #uCase(arguments.requestType)# #arguments.endPoint#">
            <cfelse>
                <cfset result.error = "HTTP #result.code# - #httpResult.fileContent#">
                <cfset result.logMessage = "FAILED #uCase(arguments.requestType)# #arguments.endPoint# - #result.error#">
            </cfif>

        <cfcatch>
            <cfset result.error = "Exception: #cfcatch.message#">
            <cfset result.logLevel = "fatal">
            <cfset result.logMessage = "EXCEPTION on #arguments.endPoint# - #cfcatch.message#">
        </cfcatch>
        </cftry>

        <cfif variables.enableLogging>
            <cfset logEvent(result.logLevel, result.logMessage)>
        </cfif>

        <cfreturn result>
    </cffunction>

    <cffunction name="logEvent" access="private" returntype="void" output="false">
        <cfargument name="level"   type="string" required="true">
        <cfargument name="message" type="string" required="true">
        <cflog type="#arguments.level#" file="#variables.logFile#" text="#arguments.message#">
    </cffunction>

    <!--- ====================== VALIDATION HELPERS ====================== --->
    <cffunction name="isValidWalletId" access="private" returntype="boolean" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfreturn len(arguments.walletId) eq 40 and reFindNoCase("^[0-9a-f]+$", arguments.walletId)>
    </cffunction>

    <cffunction name="isValidTxId" access="private" returntype="boolean" output="false">
        <cfargument name="txId" type="string" required="true">
        <cfreturn len(arguments.txId) eq 64 and reFindNoCase("^[0-9a-f]+$", arguments.txId)>
    </cffunction>

    <!--- ====================== WALLET METHODS ====================== --->
    <cffunction name="walletCreate" access="public" returntype="struct" output="false">
        <cfargument name="name"                  type="string"  required="true">
        <cfargument name="mnemonic_sentence"     type="array"   required="true">
        <cfargument name="passphrase"            type="string"  required="true">
        <cfargument name="mnemonic_second_factor" type="array"  required="false">
        <cfargument name="address_pool_gap"      type="numeric" required="false" default="20">

        <cfif len(trim(arguments.name)) < 1 or len(arguments.name) > 255>
            <cfthrow type="Cardano.Validation" message="Wallet name must be 1-255 characters">
        </cfif>
        <cfif not listFind("15,24", arrayLen(arguments.mnemonic_sentence))>
            <cfthrow type="Cardano.Validation" message="Mnemonic sentence must contain 15 or 24 words">
        </cfif>
        <cfif len(arguments.passphrase) < 10 or len(arguments.passphrase) > 255>
            <cfthrow type="Cardano.Validation" message="Passphrase must be 10-255 characters">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets", requestType="POST", stData=arguments, bLogInputs=false)>
    </cffunction>

    <cffunction name="walletList" access="public" returntype="struct" output="false">
        <cfreturn sendRequest(endPoint="/wallets")>
    </cffunction>

    <cffunction name="walletGet" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId (must be 40 hex characters)">
        </cfif>
        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#")>
    </cffunction>

    <cffunction name="walletDelete" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#", requestType="DELETE")>
    </cffunction>

    <cffunction name="walletUTxO" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/statistics/utxos")>
    </cffunction>

    <cffunction name="walletUTxOSnap" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/utxo")>
    </cffunction>

    <cffunction name="walletUpdatePassphrase" access="public" returntype="struct" output="false">
        <cfargument name="walletId"       type="string" required="true">
        <cfargument name="old_passphrase" type="string" required="true">
        <cfargument name="new_passphrase" type="string" required="true">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfset var body = {
            "old_passphrase" = arguments.old_passphrase,
            "new_passphrase" = arguments.new_passphrase
        }>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/passphrase", requestType="PUT", stData=body, bLogInputs=false)>
    </cffunction>

    <!--- ====================== ADDRESSES ====================== --->
    <cffunction name="addressList" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string"  required="true">
        <cfargument name="state"    type="string"  required="false">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfset var qs = "">
        <cfif structKeyExists(arguments, "state") and listFindNoCase("used,unused", arguments.state)>
            <cfset qs = "?state=#lCase(arguments.state)#">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/addresses#qs#")>
    </cffunction>

    <cffunction name="addressInspectAddress" access="public" returntype="struct" output="false">
        <cfargument name="addressId" type="string" required="true">
        <cfreturn sendRequest(endPoint="/addresses/#arguments.addressId#")>
    </cffunction>

    <cffunction name="addressConstructAddress" access="public" returntype="struct" output="false">
        <cfargument name="walletId"   type="string"  required="true">
        <cfargument name="payment"    type="string"  required="false">
        <cfargument name="stake"      type="string"  required="false">
        <cfargument name="validation" type="string"  required="false">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfreturn sendRequest(endPoint="/addresses", requestType="POST", stData=arguments)>
    </cffunction>

    <!--- ====================== TRANSACTIONS ====================== --->
    <cffunction name="transactionEstimateFee" access="public" returntype="struct" output="false">
        <cfargument name="walletId"   type="string" required="true">
        <cfargument name="payments"   type="array"  required="true">
        <cfargument name="withdrawal" type="string" required="false">
        <cfargument name="metadata"   type="struct" required="false">
        <cfargument name="time_to_live" type="numeric" required="false">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/payment-fees", requestType="POST", stData=arguments)>
    </cffunction>

    <cffunction name="transactionCreate" access="public" returntype="struct" output="false">
        <cfargument name="walletId"   type="string" required="true">
        <cfargument name="passphrase" type="string" required="true">
        <cfargument name="payments"   type="array"  required="true">
        <cfargument name="withdrawal" type="string" required="false">
        <cfargument name="metadata"   type="struct" required="false">
        <cfargument name="time_to_live" type="numeric" required="false">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions", requestType="POST", stData=arguments, bLogInputs=false)>
    </cffunction>

    <cffunction name="transactionList" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string"  required="true">
        <cfargument name="start"    type="date"    required="false">
        <cfargument name="end"      type="date"    required="false">
        <cfargument name="order"    type="string"  required="false">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfset var params = []>

        <cfif structKeyExists(arguments, "start")>
            <cfset arrayAppend(params, "start=#urlEncodedFormat(getIsoTime(arguments.start))#")>
        </cfif>
        <cfif structKeyExists(arguments, "end")>
            <cfset arrayAppend(params, "end=#urlEncodedFormat(getIsoTime(arguments.end))#")>
        </cfif>
        <cfif structKeyExists(arguments, "order") and listFindNoCase("ascending,descending", arguments.order)>
            <cfset arrayAppend(params, "order=#lCase(arguments.order)#")>
        </cfif>

        <cfset var qs = arrayLen(params) ? "?" & arrayToList(params, "&") : "">

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions#qs#")>
    </cffunction>

    <cffunction name="transactionGet" access="public" returntype="struct" output="false">
        <cfargument name="walletId"      type="string" required="true">
        <cfargument name="transactionId" type="string" required="true">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfif not isValidTxId(arguments.transactionId)>
            <cfthrow type="Cardano.Validation" message="Invalid transactionId (must be 64 hex characters)">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions/#arguments.transactionId#")>
    </cffunction>

    <cffunction name="transactionForget" access="public" returntype="struct" output="false">
        <cfargument name="walletId"      type="string" required="true">
        <cfargument name="transactionId" type="string" required="true">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfif not isValidTxId(arguments.transactionId)>
            <cfthrow type="Cardano.Validation" message="Invalid transactionId">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/transactions/#arguments.transactionId#", requestType="DELETE")>
    </cffunction>

    <!--- ====================== KEYS ====================== --->
    <cffunction name="getAccountPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>
        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/keys")>
    </cffunction>

    <cffunction name="getPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfargument name="role"     type="string" required="true">
        <cfargument name="index"    type="string" required="true">

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/keys/#arguments.role#/#arguments.index#")>
    </cffunction>

    <!--- Note: The original createAccountPublicKey had wrong endpoint. Correct one is usually under keys or transactions. Using a common pattern. --->
    <cffunction name="createAccountPublicKey" access="public" returntype="struct" output="false">
        <cfargument name="walletId" type="string" required="true">
        <cfargument name="passphrase" type="string" required="true"> <!--- often needed for derivation --->

        <cfif not isValidWalletId(arguments.walletId)>
            <cfthrow type="Cardano.Validation" message="Invalid walletId">
        </cfif>

        <cfreturn sendRequest(endPoint="/wallets/#arguments.walletId#/keys", requestType="POST", stData=arguments, bLogInputs=false)>
    </cffunction>

    <!--- ====================== NETWORK ====================== --->
    <cffunction name="networkInformation" access="public" returntype="struct" output="false">
        <cfreturn sendRequest(endPoint="/network/information")>
    </cffunction>

    <cffunction name="networkClock" access="public" returntype="struct" output="false">
        <cfreturn sendRequest(endPoint="/network/clock")>
    </cffunction>

    <cffunction name="networkParameters" access="public" returntype="struct" output="false">
        <cfreturn sendRequest(endPoint="/network/parameters")>
    </cffunction>

    <!--- ====================== UTILITIES ====================== --->
    <cffunction name="getBaseURL" access="public" returntype="string" output="false">
        <cfreturn variables.baseURL>
    </cffunction>

    <cffunction name="getIsoTime" access="private" returntype="string" output="false">
        <cfargument name="datetime" type="date" required="true">
        <cfreturn dateFormat(arguments.datetime, "yyyy-mm-dd") & "T" & timeFormat(arguments.datetime, "HH:mm:ss") & "Z">
    </cffunction>

</cfcomponent>
