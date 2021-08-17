<cfcomponent displayname="Cardano Address" output="false">

	<cffunction name="init" output="false" access="public" returntype="any" hint="Instantiate (and optionally populate) the response object">
		<cfargument name="path" type="string" required="true" />

		<cfif NOT fileExists("#arguments.path#/cardano-address")>
			<cfthrow message="cardano-address executable not found in path: #arguments.path#" />
		<cfelse>
			<cfset variables.addressPath = arguments.path />
		</cfif>

		<cfreturn this />
	</cffunction>

	<cffunction name="generatePhrase" access="public" returntype="array" output="false">

		<cfset var lPhrase = "" />
		<cfset var aPhrase = arrayNew(1) />

		<cfexecute name="#variables.addressPath#/cardano-address" arguments="recovery-phrase generate" variable="lPhrase" />

		<cfif listLen(lPhrase," ") EQ 24>
			<cfset aPhrase = listToArray(lPhrase," ") />
		</cfif>

		<cfreturn aPhrase />
	</cffunction>

</cfcomponent>
