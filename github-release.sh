#!/bin/bash
#
# Copyright © 2021, Samar Vispute "SamarV-121" <samarvispute121@gmail.com>
#
# SPDX-License-Identifier: Apache-2.0
# --
# export GITHUB_TOKEN=token
# github-release.sh iamthecloverly/releases tag master "description" filename
# eg.
# export GITHUB_TOKEN=2345htrvdcse234rbfbgn345
# github-release.sh iamthecloverly/releases 1.0.2 master "Test release" test.zip
#

if [ "$5" ]; then
	REPO="$1"
	TAG="$2"
	BRANCH="$3"
	DESC="$4"
	FILE="$5"

	GITHUB_REPO="https://api.github.com/repos/$REPO"
	AUTH="Authorization: token $GITHUB_TOKEN"
	TAG_INFO=$(curl -H "$AUTH" "$GITHUB_REPO/releases/tags/$TAG")

	# Use existing tag otherwise, create a new one
	TAG_ID=$(jq .id <<<"$TAG_INFO")
	[ "$TAG_ID" = null ] &&
		TAG_ID=$(curl -X POST "$GITHUB_REPO/releases" -H "$AUTH" -d "{\"tag_name\": \"$TAG\", \"target_commitish\": \"$BRANCH\", \"name\": \"$TAG\", \"body\": \"$DESC\"}" | jq '.id')

	# Remove old asset with same filename if exists
	ASSET_ID="$(echo "$TAG_INFO" | jq -r '.assets[] | select(.name == '\""$FILE"\"').id')" 2>/dev/null
	[ "$ASSET_ID" ] &&
		curl -X "DELETE" -H "$AUTH" "$GITHUB_REPO/releases/assets/$ASSET_ID"

	# Upload file
	GITHUB_ASSET="https://uploads.github.com/repos/$REPO/releases/$TAG_ID/assets?name=$(basename "$FILE")"
	echo "Uploading $FILE... "
	LOG=$(curl --data-binary @"$FILE" -H "$AUTH" -H "Content-Type: application/octet-stream" "$GITHUB_ASSET")
	DLOAD_URL=$(echo "$LOG" | jq -r '.browser_download_url')
	if [ "$DLOAD_URL" = null ]; then
		echo -e "Failed to upload\n$(<"$LOG")"
	else
		echo -e "Succesfully uploaded\nDownload URL: $DLOAD_URL"
	fi
else
	sed -n '/^$/q;/# --/,$ s/^#*//p' "$0"
fi
