# COPYRIGHT


. "$(pwd)"/environment.functions.sh


alpine_linux_parseCommandLineArguments()
{
	local additionalArgumentsCallback="$1"
	local positionalArgumentsCallback="$2"
	shift 2

	alpine_linux_positionalArgumentsStartAt=0

	alpine_linux_configurationFolderPath="$(pwd)"/configuration
	local alpine_linux_configurationFolderPathParsed=false

	alpine_linux_outputFolderPath="$(pwd)"/output
	local alpine_linux_outputFolderPathParsed=false

	# Parse non-positional arguments.
	local key
	local value
	while [ $# -gt 0 ]
	do
		local key="$1"

		case "$key" in

			--)
				alpine_linux_positionalArgumentsStartAt=$((alpine_linux_positionalArgumentsStartAt + 1))
				shift 1
				break
			;;

			-h|--help|-h*)
				local EXIT_SUCCESS=0
				environment_parseCommandLineArguments_printHelp $EXIT_SUCCESS
			;;

			-c|--configuration)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_configurationFolderPathParsed
				environment_parseCommandLineArguments_missingArgument "$@"
				alpine_linux_configurationFolderPath="$value"
				alpine_linux_configurationFolderPathParsed=true

				alpine_linux_positionalArgumentsStartAt=$((alpine_linux_positionalArgumentsStartAt + 1))
				shift 1
			;;

			--configuration=*)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_configurationFolderPathParsed
				alpine_linux_configurationFolderPath="${key##--configuration=}"
				alpine_linux_configurationFolderPathParsed=true
			;;

			-c*)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_configurationFolderPathParsed
				alpine_linux_configurationFolderPath="${key##-c}"
				alpine_linux_configurationFolderPathParsed=true
			;;

			-o|--output)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_outputFolderPathParsed
				environment_parseCommandLineArguments_missingArgument "$@"
				alpine_linux_outputFolderPath="$value"
				alpine_linux_outputFolderPathParsed=true

				alpine_linux_positionalArgumentsStartAt=$((alpine_linux_positionalArgumentsStartAt + 1))
				shift 1
			;;

			--output=*)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_outputFolderPathParsed
				alpine_linux_outputFolderPath="${key##--output=}"
				alpine_linux_outputFolderPathParsed=true

			;;

			-o*)
				environment_parseCommandLineArguments_alreadyParsed $alpine_linux_outputFolderPathParsed
				alpine_linux_outputFolderPath="${key##-o}"
				alpine_linux_outputFolderPathParsed=true
			;;

			-*)
				local _additionalArgumentsCallback_shiftUp
				$additionalArgumentsCallback "$@"
				if [ $_additionalArgumentsCallback_shiftUp -gt 0 ]; then
					alpine_linux_positionalArgumentsStartAt=$((alpine_linux_positionalArgumentsStartAt + _additionalArgumentsCallback_shiftUp))
					shift $_additionalArgumentsCallback_shiftUp
				fi
			;;

			*)
				break
			;;

		esac

		alpine_linux_positionalArgumentsStartAt=$((alpine_linux_positionalArgumentsStartAt + 1))
		shift 1

	done

	# Parse positional arguments.
	$positionalArgumentsCallback "$@"
}

depends mkdir
alpine_linux_validateCommandLineArguments()
{
	if [ -z "$alpine_linux_configurationFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--configuration folder path is empty"
	fi
	if [ ! -e "$alpine_linux_configurationFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--configuration folder path '$alpine_linux_configurationFolderPath' does not exist"
	fi
	if [ ! -r "$alpine_linux_configurationFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--configuration folder path '$alpine_linux_configurationFolderPath' is not readable"
	fi
	if [ ! -d "$alpine_linux_configurationFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--configuration folder path '$alpine_linux_configurationFolderPath' is not a directory"
	fi
	if [ ! -x "$alpine_linux_configurationFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--configuration folder path '$alpine_linux_configurationFolderPath' is not searchable"
	fi
	local absoluteFolderPath
	environment_makeFolderPathAbsolute "$alpine_linux_configurationFolderPath"
	alpine_linux_configurationFolderPath="$absoluteFolderPath"

	if [ -z "$alpine_linux_outputFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--output folder path is empty"
	fi
	mkdir -m 0700 -p "$alpine_linux_outputFolderPath" || _alpine_linux_parsedCommandLineArguments_errorHelp "--output folder path '$alpine_linux_outputFolderPath' could not be created, is not a directory or is not accessible"
	if [ ! -r "$alpine_linux_outputFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--output folder path '$alpine_linux_outputFolderPath' is not readable"
	fi
	if [ ! -x "$alpine_linux_outputFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--output folder path '$alpine_linux_outputFolderPath' is not searchable"
	fi
	if [ ! -w "$alpine_linux_outputFolderPath" ]; then
		_alpine_linux_parsedCommandLineArguments_errorHelp "--output folder path '$alpine_linux_outputFolderPath' is not writable"
	fi
	local absoluteFolderPath
	environment_makeFolderPathAbsolute "$alpine_linux_outputFolderPath"
	alpine_linux_outputFolderPath="$absoluteFolderPath"
}

alpine_linux_setEnvironmentVariables()
{
	alpine_linux_temporaryFolderPath="$alpine_linux_outputFolderPath"/temp

	alpine_linux_versionFilePath="$alpine_linux_configurationFolderPath"/alpine-linux.version
	if [ ! -e "$alpine_linux_versionFilePath" ]; then
		fail "The configuration file '$alpine_linux_versionFilePath' does not exist"
	fi
	if [ ! -f "$alpine_linux_versionFilePath" ]; then
		fail "The configuration file '$alpine_linux_versionFilePath' is not a file"
	fi
	if [ ! -r "$alpine_linux_versionFilePath" ]; then
		fail "The configuration file '$alpine_linux_versionFilePath' is not a readable file"
	fi
	if [ ! -s "$alpine_linux_versionFilePath" ]; then
		fail "The configuration file '$alpine_linux_versionFilePath' is not a readable file with content"
	fi

	alpine_linux_packagesFilePath="$alpine_linux_configurationFolderPath"/alpine-linux.packages
	if [ ! -e "$alpine_linux_packagesFilePath" ]; then
		fail "The configuration file '$alpine_linux_packagesFilePath' does not exist"
	fi
	if [ ! -f "$alpine_linux_packagesFilePath" ]; then
		fail "The configuration file '$alpine_linux_packagesFilePath' is not a file"
	fi
	if [ ! -r "$alpine_linux_packagesFilePath" ]; then
		fail "The configuration file '$alpine_linux_packagesFilePath' is not a readable file"
	fi
	if [ ! -s "$alpine_linux_packagesFilePath" ]; then
		fail "The configuration file '$alpine_linux_packagesFilePath' is not a readable file with content"
	fi

	alpine_linux_busyboxStaticBinariesFilePath="$alpine_linux_configurationFolderPath"/alpine-linux.busybox-static-binaries
	if [ ! -e "$alpine_linux_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$alpine_linux_busyboxStaticBinariesFilePath' does not exist"
	fi
	if [ ! -f "$alpine_linux_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$alpine_linux_busyboxStaticBinariesFilePath' is not a file"
	fi
	if [ ! -r "$alpine_linux_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$alpine_linux_busyboxStaticBinariesFilePath' is not a readable file"
	fi
	if [ ! -s "$alpine_linux_busyboxStaticBinariesFilePath" ]; then
		fail "The configuration file '$alpine_linux_busyboxStaticBinariesFilePath' is not a readable file with content"
	fi

	alpine_linux_mirrorFolderPath="$alpine_linux_outputFolderPath"/mirror
	alpine_linux_mirrorVersionFilePath="$alpine_linux_mirrorFolderPath"/.alpine-linux.version

	alpine_linux_indexFolderPath="$alpine_linux_outputFolderPath"/index
	alpine_linux_indexVersionFilePath="$alpine_linux_indexFolderPath"/.alpine-linux.version

	alpine_linux_packagesFolderPath="$alpine_linux_outputFolderPath"/packages
	alpine_linux_packagesVersionFilePath="$alpine_linux_packagesFolderPath"/.alpine-linux.version
	alpine_linux_packagesPackagesFilePath="$alpine_linux_packagesFolderPath"/.alpine-linux.packages

	alpine_linux_extractFolderPath="$alpine_linux_outputFolderPath"/extract
	alpine_linux_extractVersionFilePath="$alpine_linux_extractFolderPath"/.alpine-linux.version
	alpine_linux_extractPackagesFilePath="$alpine_linux_extractFolderPath"/.alpine-linux.packages
	alpine_linux_extractBusyboxStaticBinariesFilePath="$alpine_linux_extractFolderPath"/.alpine-linux.busybox-static-binaries

	alpine_linux_mirror=https://alpine.global.ssl.fastly.net/alpine

	IFS=$'\t'' ' read -r alpine_linux_majorVersion alpine_linux_minorVersion alpine_linux_revisionVersion alpine_linux_apkToolsVersion <"$alpine_linux_versionFilePath"
	alpine_linux_architecture='x86_64'

	alpine_linux_versionMirror="${alpine_linux_mirror}/v${alpine_linux_majorVersion}.${alpine_linux_minorVersion}"
	alpine_linux_releasesMirror="$alpine_linux_versionMirror"/releases/"$alpine_linux_architecture"
}

alpine_linux_netbootFolderName()
{
	netbootFolderName=netboot-"${alpine_linux_majorVersion}.${alpine_linux_minorVersion}.${alpine_linux_revisionVersion}"
}

alpine_linux_repositoryMirror()
{
	local repositoryVariant="$1"

	repositoryMirror=${alpine_linux_versionMirror}/${repositoryVariant}
}

depends cmp
alpine_linux_cachedVersion()
{
	local folderPath="$1"
	local versionFilePath="$folderPath"/.alpine-linux.version

	if [ -s "$versionFilePath" ]; then
		if cmp -s "$versionFilePath" "$alpine_linux_versionFilePath"; then
			return 0
		fi
	fi

	return 1
}

depends cmp
alpine_linux_cachedPackages()
{
	local folderPath="$1"
	local packagesFilePath="$folderPath"/.alpine-linux.packages

	if [ -s "$packagesFilePath" ]; then
		if cmp -s "$packagesFilePath" "$alpine_linux_packagesFilePath"; then
			return 0
		fi
	fi

	return 1
}

depends cmp
alpine_linux_cachedBusyboxStaticBinaries()
{
	local folderPath="$1"
	local busyboxStaticBinariesFilePath="$folderPath"/.alpine-linux.busybox-static-binaries

	if [ -s "$busyboxStaticBinariesFilePath" ]; then
		if cmp -s "$busyboxStaticBinariesFilePath" "$alpine_linux_busyboxStaticBinariesFilePath"; then
			return 0
		fi
	fi

	return 1
}
