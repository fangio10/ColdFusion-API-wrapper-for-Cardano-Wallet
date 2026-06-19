<cfcomponent displayname="Cardano Address CLI Wrapper" output="false" hint="Production-ready wrapper for cardano-address CLI tool">

    <cffunction name="init" access="public" returntype="any" output="false" hint="Initialize cardano-address CLI wrapper">
        <cfargument name="cliPath"    type="string" required="true" hint="Path to the directory containing the cardano-address executable">
        <cfargument name="logFile"    type="string" required="false" default="" hint="Log file name to enable logging">
        <cfargument name="timeout"    type="numeric" required="false" default="30" hint="Timeout in seconds for CLI calls">

        <cfset variables.cliPath = arguments.cliPath>
        <cfset variables.timeout = arguments.timeout>
        
        <!--- Verify executable exists --->
        <cfif NOT fileExists("#variables.cliPath#/cardano-address")>
            <cfthrow type="Cardano.CLI.Error" 
                     message="cardano-address executable not found at: #variables.cliPath#/cardano-address">
        </cfif>

        <cfset variables.enableLogging = len(trim(arguments.logFile)) gt 0>
        <cfif variables.enableLogging>
            <cfset variables.logFile = arguments.logFile>
        </cfif>

        <cfreturn this>
    </cffunction>

    <!--- Core CLI Executor --->
    <cffunction name="executeCommand" access="private" returntype="struct" output="false">
        <cfargument name="args"        type="string"  required="true" hint="Arguments to pass to cardano-address">
        <cfargument name="sensitive"   type="boolean" required="false" default="false">

        <cfset var result = {
            success = false,
            output = "",
            error = "",
            exitCode = -1
        }>

        <cftry>
            <cfexecute 
                name="#variables.cliPath#/cardano-address"
                arguments="#arguments.args#"
                variable="result.output"
                errorVariable="result.error"
                timeout="#variables.timeout#"
                throwOnError="false"/>

            <cfset result.exitCode = 0>
            <cfset result.success = true>

            <cfif variables.enableLogging>
                <cfset logEvent("information", "cardano-address #arguments.args#", arguments.sensitive)>
            </cfif>

        <cfcatch>
            <cfset result.error = cfcatch.message>
            <cfset result.success = false>
            
            <cfif variables.enableLogging>
                <cfset logEvent("error", "cardano-address failed: #arguments.args# - #cfcatch.message#")>
            </cfif>
        </cfcatch>
        </cftry>

        <cfreturn result>
    </cffunction>

    <cffunction name="logEvent" access="private" returntype="void" output="false">
        <cfargument name="level"      type="string"  required="true">
        <cfargument name="message"    type="string"  required="true">
        <cfargument name="sensitive"  type="boolean" required="false" default="false">

        <cfif variables.enableLogging>
            <cflog type="#arguments.level#" 
                   file="#variables.logFile#" 
                   text="#arguments.message#">
        </cfif>
    </cffunction>

    <!--- ====================== PUBLIC METHODS ====================== --->

    <cffunction name="generatePhrase" access="public" returntype="array" output="false" hint="Generate a new 24-word recovery phrase">
        <cfset var cliResult = executeCommand(args="recovery-phrase generate", sensitive=true)>

        <cfif NOT cliResult.success>
            <cfthrow type="Cardano.CLI.Error" message="Failed to generate recovery phrase: #cliResult.error#">
        </cfif>

        <cfset var words = trim(cliResult.output)>
        <cfif listLen(words, " ") NEQ 24>
            <cfthrow type="Cardano.CLI.Error" message="Generated phrase does not contain 24 words">
        </cfif>

        <cfreturn listToArray(words, " ")>
    </cffunction>

    <cffunction name="inspectAddress" access="public" returntype="struct" output="false" hint="Inspect a Cardano address">
        <cfargument name="address" type="string" required="true">

        <cfif len(trim(arguments.address)) eq 0>
            <cfthrow type="Cardano.Validation" message="Address cannot be empty">
        </cfif>

        <cfset var cliResult = executeCommand(args="address inspect #arguments.address#")>

        <cfif NOT cliResult.success>
            <cfthrow type="Cardano.CLI.Error" message="Failed to inspect address: #cliResult.error#">
        </cfif>

        <!--- Try to parse JSON output if available --->
        <cfif isJSON(cliResult.output)>
            <cfreturn deserializeJSON(cliResult.output)>
        <cfelse>
            <cfreturn { rawOutput = cliResult.output }>
        </cfif>
    </cffunction>

    <cffunction name="generateAddress" access="public" returntype="string" output="false" hint="Generate an address from root xpub / stake xpub">
        <cfargument name="paymentKey" type="string" required="true">
        <cfargument name="stakeKey"   type="string" required="false">
        <cfargument name="network"    type="string" required="false" default="mainnet"> <!--- mainnet | testnet --->

        <cfset var cmd = "address build --payment-verification-key #arguments.paymentKey#">

        <cfif structKeyExists(arguments, "stakeKey") and len(arguments.stakeKey)>
            <cfset cmd &= " --stake-verification-key #arguments.stakeKey#">
        </cfif>

        <cfif arguments.network eq "testnet">
            <cfset cmd &= " --testnet-magic 1097911063">
        </cfif>

        <cfset var cliResult = executeCommand(args=cmd)>

        <cfif NOT cliResult.success>
            <cfthrow type="Cardano.CLI.Error" message="Failed to generate address: #cliResult.error#">
        </cfif>

        <cfreturn trim(cliResult.output)>
    </cffunction>

    <cffunction name="getVersion" access="public" returntype="string" output="false">
        <cfset var result = executeCommand(args="--version")>
        <cfreturn trim(result.output)>
    </cffunction>

    <cffunction name="getBasePath" access="public" returntype="string" output="false">
        <cfreturn variables.cliPath>
    </cffunction>

</cfcomponent>
