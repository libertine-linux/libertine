# COPYRIGHT


environment_parseCommandLineArguments_printHelp()
{
	local exitCode="$1"
	printf '%s' "$environment_parseCommandLineArguments_message"
	exit $exitCode
}

environment_parseCommandLineArguments_errorHelp()
{
	local cause="$1"

	# See https://man.openbsd.org/sysexits.3
	local EX_USAGE=64
	{
		printf '%s:%s\n\n' "$program_name" "${cause}."

		environment_parseCommandLineArguments_printHelp $EX_USAGE
	} 1>&2
}

environment_parseCommandLineArguments_alreadyParsed()
{
	local alreadyParsed="$1"
	if $alreadyParsed; then
		environment_parseCommandLineArguments_errorHelp "Already parsed the value for the argument '$key'"
	fi
}

environment_parseCommandLineArguments_missingArgument()
{
	if [ $# -lt 2 ]; then
		environment_parseCommandLineArguments_errorHelp "Missing value for the argument '$key'"
	fi

	value="$2"
}

environment_makeFolderPathAbsolute()
{
	cd "$1" 1>/dev/null 2>/dev/null
		absoluteFolderPath="$(pwd)"
	cd - 1>/dev/null 2>/dev/null
}

depends uname awk
environment_sha512sum()
{
	local filePath="$1"
	local operatingSystem="$(uname -s)"
	
	case "$operatingSystem" in
		
		Darwin)
			depends shasum
			sha512="$(shasum --algorithm 512 --binary "$filePath" | awk '{print $1}')"
		;;
		
		Linux)
			depends sha512sum
			sha512="$(sha512sum "$filePath" | awk '{print $1}')"
		;;
		
		*)
			fail "Operating system ${operatingSystem} is unsupported."
		;;
		
	esac
}

depends curl
environment_download()
{
	local folder="$1"
	local url="$2"
	
	local fileName="${url##*/}"
	downloadedFile="$folder"/"$fileName"
	
	set +e
		curl --proto '=https' --tlsv1.2 --silent --show-error --fail --location "$url" --output "$downloadedFile"
		local exitCode="$?"
	set -e
	
	if [ $exitCode -ne 0 ]; then
		fail "Failed to download from $url because of curl code $exitCode."
	fi
}

depends head awk
environment_downloadWithSha512Hash()
{
	local folder="$1"
	local url="$2"
	local expectedSha512="$3"
	
	environment_download "$folder" "$url"
	
	local sha512
	environment_sha512sum "$downloadedFile"
	
	if [ "$sha512" != "$expectedSha512" ]; then
		fail "URL when downloaded was expected to have SHA-512 hash $expectedSha512 but actually had hash $sha512."
	fi
}

environment_tac()
{
	if command -v tac 1>/dev/null 2>/dev/null; then
		tac "$@"
	else
		# Darwin (MacOS), BSDs, etc, but not BusyBox.
		depends tail
		tail -r -- "$@"
	fi
}
