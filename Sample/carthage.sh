# carthage.sh
# Usage example: ./carthage.sh build --platform iOS

set -euo pipefail

pushd ../ > /dev/null
CWD=$(pwd)
popd > /dev/null

#set local repo with current branch in Cartfile"
BRANCH=$(git branch --show-current)
echo "git \"file://$CWD\" \"$BRANCH\"" > Cartfile

carthage "$@"
