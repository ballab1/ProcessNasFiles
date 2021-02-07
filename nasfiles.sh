#!/bin/bash

#----------------------------------------------------------------
function checkFiles() {

    local target="$SRCDIR"
    echo "checking for missing files in $target"
    cd "$target" ||:
    while read -r file; do
        [ "$(basename "${file:0:1}")" = '@' ] && continue
        file="${file#$MNTDIR}"
        [ -f "$file" ] || echo "missing:  $file"
    done < "$DIRLIST"
}

#----------------------------------------------------------------
function copyDirs() {

    local target="$DSTDIR"
    echo "copying directories to $target"

    rm -rf "$target"/*
    cd "$SRCDIR" ||:
    while read -r dir; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        dir="${dir#$MNTDIR}"
        [ -z "${dir:-}" ] && continue
        base="$(dirname "$dir")"
        [ -d "$DSTDIR/$base" ] || mkdir -p "$DSTDIR/$base" ||:
        echo "cp -r $dir $DSTDIR/$base/"
        cp -r "$dir" "$DSTDIR/$base/"
    done < "$DIRLIST"
    echo
    echo
    df 
}

#----------------------------------------------------------------
function copyFiles() {

    local target="$DSTDIR"
    echo "copying files to $target"
    rm -rf "$target"/*
    cd "$SRCDIR" ||:
    while read -r file; do
        [ "$(basename "${file:0:1}")" = '@' ] && continue
        file="${file#$MNTDIR}"
        [ -z "${file:-}" ] && continue
        base="$(dirname "$file")"
        [ -d "$DSTDIR/$base" ] || mkdir -p "$DSTDIR/$base" ||:
        echo "cp $file $DSTDIR/$base/"
        cp "$file" "$DSTDIR/$base/"
    done < "$DIRLIST"
    echo
    echo
    df 
}

#----------------------------------------------------------------
function compareFiles() {

    local target="$DSTDIR"
    echo "comparing files between $SRCDIR and $DSTDIR"
    cd "$target" ||:
    while read -r file; do
        [ "$(basename "${file:0:1}")" = '@' ] && continue
       diff -q "$file" "$SRCDIR/$file" || echo "$file"
    done < <(find . -type f)
}

#----------------------------------------------------------------
function emptyDirs() {
    local target="$SRCDIR"
    echo "searching for empty on $target"
    cd "$target" ||:

    while read -r dir; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        [ "$(ls -1A "$dir" | wc -l)" -eq 0 ] && echo "$dir"
    done < <(find . -type d | awk '{split($0,arr,"/");print length(arr) "|" $0}'| sort -k 1nr | cut -d '|' -f 2)
}

#----------------------------------------------------------------
function getPrimary() {

    local file="${1:?}"
    local sha="$( sha256sum -b "$file" | cut -d ' ' -f 1 )"
    
    # search index for primary file
    local ref="$(grep "$sha" "$JSON_INDEX" | jq -sr '.[0].file')"
#    local ref="$(jq -sr '.[0]|select(.sha256 == "'"$sha"'").file' "$JSON_INDEX")"
    if [ -z "${ref:-}" ];then
        # stop if not found
        echo "unable to find file coresponding to sha: $sha"
        return
    fi

    # verify primary file exists
    ref="${ref#$MNTDIR}"
    if [ ! -f "${SRCDIR}/${ref:-}" ];then
        # stop if not found
        echo "unable to find primary file: $ref"
        return
    fi

    # check cache to see if we have verified sha256 of primary
    if ! grep -qs "$sha" "$CACHE"; then
        local refSha="$( sha256sum -b "${SRCDIR}/$ref" | cut -d ' ' -f 1 )"
        echo "$refSha" >> "$CACHE"
        if [ "$refSha" != "$sha" ]; then
            echo "files are not the same:  $file ($sha) ::  $ref ($refSha)"
            return
        fi
    fi

    echo "rm '$file'"
    rm "$file"
}

#----------------------------------------------------------------
function onExit() {
    local -i elapsed=$(( $(date '+%s') - START_TIME ))
    if [ "$elapsed" -gt 2 ]; then
        printf '\nElapsed time: %3d:%02d:%02d\n' $((elapsed / 3600)) $((elapsed % 3600 / 60)) $((elapsed % 60)) | tee -a "$LOGFILE"
    fi
}

#----------------------------------------------------------------
function removeDirs() {

    local target="$SRCDIR"
    echo "removing directories from $target"
    cd "$target" ||:
    while read -r dir; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        dir="${dir#$MNTDIR}"
        [ -z "${dir:-}" ] && continue
        if [ -d "$dir" ]; then
            echo "rm -rf $dir"
            rm -rf "$dir"
        else
            echo "No such file:  $dir"
        fi
    done < "$DIRLIST"
}

#----------------------------------------------------------------
function removeFiles() {

    local target="$SRCDIR"
    echo "removing files from $target"
    cd "$target" ||:
    local file
    while read -r file; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        file="${file#$MNTDIR}"
        [ -z "${file:-}" ] && continue
        [ -d "$file" ] && continue
        if [ -f "$file" ]; then
            echo "rm $file"
            rm "$file"
        else
            echo "No such file:  $file"
        fi
    done < "$DIRLIST"
}

#----------------------------------------------------------------
function removeEmptyDirs() {

    local target="$SRCDIR"
    echo "removing empty directories from $target"
    cd "$target" ||:

    while read -r dir; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        [ "$(ls -1A "$dir" | wc -l)" -eq 0 ] || continue
        echo "rmdir $dir"
        rmdir "$dir"
    done < <(find . -type d | awk '{split($0,arr,"/");print length(arr) "|" $0}'| sort -k 1nr | cut -d '|' -f 2)
}

#----------------------------------------------------------------
function verifyFiles() {

    local target="$DSTDIR"
    echo "veryfing files from $target"
    cd "$target" ||:

    :> "$CACHE"
    while read -r file; do
        [ "$(basename "${dir:0:1}")" = '@' ] && continue
        file="${file#$MNTDIR}"
        [ -z "${file:-}" ] && continue
        [ -f "$file" ]  &&  getPrimary "$file"
    done < <(find . -type f)
    rm "$CACHE"
}

#----------------------------------------------------------------

START_TIME="$(date '+%s')"
PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}")"
LOGFILE="${PROGRAM_DIR}/${PROGRAM_NAME//.sh}-$(date '+%y%m%d%H%M%S').log"
DSTDIR='/volumeUSB1/usbshare/WdMyCloud'
SRCDIR='/volume1/WdMyCloud'
MNTDIR='/mnt/WdMyCloud'
#DIRLIST="${PROGRAM_DIR}/nasdirsu.txt"
DIRLIST="${PROGRAM_DIR}/files_to_move.txt"
JSON_INDEX="${PROGRAM_DIR}/nasfiles_index.json"
CACHE="${PROGRAM_DIR}/nasfiles_cache.txt"
declare -i count=0
#[ "$(( ++count ))" -gt 3 ] && break


trap onExit EXIT
[ -d "$DSTDIR" ] || mkdir -p "$DSTDIR" ||:

{
    case 'doRemoveEmpty' in
        doCheck)
            checkFiles
            ;;

        doDirCopy)
            copyDirs
            ;;

        doFileCopy)
            copyFiles
            ;;

        doFindEmpty)
            emptyDirs
            ;;

        doCompare)
            compareFiles
            ;;

        doRemove)
            removeFiles
            ;;

        doRemoveEmpty)
            removeEmptyDirs
            ;;

        doVerify)
            verifyFiles
            ;;

        *)
            echo 'invalid option provided. Please specify one of:  doCheck | doCopy | doCompare | doRemove | doVerify' >&2
            ;;
    esac

} 2>&1 | tee "$LOGFILE"