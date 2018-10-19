#! /bin/bash

set -euo pipefail

main() {

    # Global for the cleanup. We make this random, to make sure that
    # parallel build of the same package file, or parallel CI jobs
    # do not interfere
    CONTAINER=$(make_uuid | tr -d -- '-')
    CLEANUPIMAGE=
    trap cleanup 0

    # TODO: parse args
    declare package="$1"
    local image=rhub/debian-gcc-devel
    local envvars=$(echo foo=bar; echo foo2=baz)
    local checkargs=""

    check_requirements || exit $?

    download_package "$package" || exit $?
    package="$REPLY"

    detect_platform "$image"
    local platform="$REPLY"
    echo "Sysreqs platform: $platform"
    export RHUB_PLATFORM="$platform"

    # Install sysreqs and create a image from it
    install_sysreqs "$package" "$image" "$CONTAINER" "platform"
    image="$REPLY"

    create_env_file "$package" "$envvars" "$checkargs"
    local envfile=$REPLY

    run_check "$package" "$image" "$CONTAINER" "$envfile"

    get_artifacts $CONTAINER

    # Cleanup is automatic
}

make_bad_uuid()  {
    local N B C='89ab'
    for (( N=0; N < 16; ++N ))
    do
	B=$(( $RANDOM%256 ))
	case $N in
	    6)
		printf '4%x' $(( B%16 ))
		;;
	    8)
		printf '%c%x' ${C:$RANDOM%${#C}:1} $(( B%16 ))
		;;
	    3 | 5 | 7 | 9)
		printf '%02x-' $B
		;;
	    *)
		printf '%02x' $B
		;;
	esac
    done
    echo
}

make_uuid() {
    cat /proc/sys/kernel/random/uuid 2>/dev/null ||
	uuidgen 2>/dev/null || make_bad_uuid
}

check_requirements() {
    # Check for R and the packages we need
    if ! R --slave -e 'x <- 1' 2>/dev/null; then
	>&2 echo "Cannot find R :("
	return 1
    fi
    if ! R --slave -e 'library(sysreqs)' 2>/dev/null; then
	>&2 echo "Cannot load the sysreqs package :("
	return 2
    fi
}

download_package() {
    declare -r package="$1"
    REPLY=$(basename $(mktemp).tar.gz)
    if [[ "$package" =~ ^https?:// ]]; then
	echo ">>>>>==================== Downloading package file"
	if ! wget -O "$REPLY" "$package"; then
	    >&2 echo "Cannot download package file :("
	    return 3
	fi
    else
	cp "$package" "$REPLY"
    fi
}

detect_platform() {
    declare -r image="$1"
    REPLY=$(docker run --user docker \
		   --rm ${image} \
		   sh -c 'echo $RHUB_PLATFORM')
}

get_desc() {
    declare -r package="$1"
    local desc=$(tar tzf "$package" | grep "^[^/]*/DESCRIPTION$")
    local dir=$(mktemp -d)
    tar xzf "$package" -C "$dir" "$desc"
    REPLY="${dir}/${desc}"
}

install_sysreqs() {
    declare -r package="$1" image="$2" container="$3" platform="$4"
    get_desc "$package"
    local desc=$REPLY
    local cmd="library(sysreqs); cat(sysreq_commands(\"$desc\"))"
    local sysreqs=$(Rscript -e "$cmd")
    rm -f "$desc"

    # Install them, if there is anything to install
    if [[ ! -z "${sysreqs}" ]]; then
	echo ">>>>>==================== Installing system requirements"
	local sysreqsfile=$(mktemp)
	echo "${sysreqs}" > "$sysreqsfile"
	docker create --user root --name "${container}-1" \
	       "$image" bash /root/sysreqs.sh
	docker cp "$sysreqsfile" "${container}-1:/root/sysreqs.sh"
	docker start -i -a "${container}-1"
	REPLY=$(docker commit "${container}-1")
	CLEANUPIMAGE="$image"
    else
	# If there is nothing to install we just use the stock image
	REPLY="$image"
    fi
}

create_env_file() {
    declare -r package="$1" envvars="$2" checkargs="$3"
    local envfile=$(mktemp)

    # These can be overriden by the user supplied env vars
    echo R_REMOTES_STANDALONE=true              >> "$envfile"
    echo R_REMOTES_NO_ERRORS_FROM_WARNINGS=true >> "$envfile"
    echo TZ=Europe/London                       >> "$envfile"
    local mirror="${RHUB_CRAN_MIRROR:-https://cloud.r-project.org}"
    echo RHUB_CRAN_MIRROR="$mirror"             >> "$envfile"
    echo _R_CHECK_FORCE_SUGGESTS_=${_R_CHECK_FORCE_SUGGESTS_:-false} \
	 >> "$envfile"

    # User supplied env vars
    echo "envvars"  >> "$envfile"

    # These canot be overriden
    echo checkArgs="${checkargs}" >> "$envfile"  # note the uppercase!
    local basepackage=$(basename "$package")
    echo package="$basepackage"   >> "$envfile"
    REPLY="$envfile"
}

run_check() {
    echo ">>>>>==================== Starting Docker container"
    declare package="$1" image="$2" container="$3" envfile="$4"
    local basepackage=$(basename "$package")

    docker create -i --user docker --env-file "$envfile" \
	   --name "${container}-2" "$image" /bin/bash /tmp/build.sh \
	   "/tmp/$basepackage"
    docker cp linux-worker.sh "${container}-2:/tmp/build.sh"
    docker cp "$package" "${container}-2:/tmp/$basepackage"
    docker start -i -a "${container}-2"
}

get_artifacts() {
    declare container="$1"
    local tmp=$(mktemp -d -p .)

    if ! docker cp "${container}-2:/tmp/artifacts" "$tmp"; then
	>&2 echo "No artifacts were saved :("
	return
    fi

    local packagename=$(cat "${tmp}/artifacts/packagename")
    echo $packagename
    local output=${JOB_BASE_NAME:-${packagename}-${container}}
    echo $output
    if [[ -e "$output" ]]; then
	local i=1
	while [[ -e "${output}-${i}" ]]; do i=$((i+1)); done
	output="${output}-${i}"
    fi
    echo $output

    mv "${tmp}/artifacts" "$output"

    echo Saved artifacts in "$output"

    if [[ "x$RHUB_ARTIFACTS" = "xlocal" ]]; then
	cp -r ${output} /artifacts/
    fi
}

cleanup() {
    docker rm -f -v "${CONTAINER}-1" >/dev/null 2>/dev/null || true
    docker rm -f -v "${CONTAINER}-2" >/dev/null 2>/dev/null || true
    docker rmi -f   "$CLEANUPIMAGE"  >/dev/null 2>/dev/null || true
}

[[ "$0" == "$BASH_SOURCE" ]] && main "$@"
