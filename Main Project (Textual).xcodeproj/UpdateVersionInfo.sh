#!/bin/sh

cd "${PROJECT_DIR}/Resources/"

bundleVersion=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleShortVersionString\"" Info.plist)

gitBundle=`which git`
gitDescribe=`${gitBundle} describe --long`
gitRefInfo=$(echo $gitDescribe | grep -oE "([0-9]{1,3})\-([a-zA-Z0-9]{8})")
gitCommitCount=`${gitBundle} rev-list HEAD --count`

buildRef="${bundleVersion}-${gitRefInfo}-${TEXTUAL_GITREF_BUILD_ID}"

echo "Building Textual (Build Reference: ${gitRefInfo})"

bundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print \"CFBundleIdentifier\"" Info.plist)

test "${bundleIdentifier}" != "${TEXTUAL_BUNDLE_ID}" && \
	/usr/libexec/PlistBuddy -c "Set :\"CFBundleIdentifier\" ${TEXTUAL_BUNDLE_ID}" Info.plist

mkdir -p "${PROJECT_DIR}/.tmp/"

cd "${PROJECT_DIR}/.tmp/"

echo "/* ANY CHANGES TO THIS FILE WILL NOT BE SAVED AND WILL NOT BE COMMITTED */" > BuildConfig.h
echo "" >> BuildConfig.h
echo "#define TXBundleCommitCount		@\"${gitCommitCount}\"" >> BuildConfig.h

if [ -n "$CODE_SIGN_IDENTITY" ]; then
echo "#define TXBundleBuildReference	@\"${buildRef}\"" >> BuildConfig.h
else
echo "#define TXBundleBuildReference	@\"${buildRef},nocdsign\"" >> BuildConfig.h
echo "#define TXBundleBuiltWithoutCodeSigning                   1" >> BuildConfig.h
fi
