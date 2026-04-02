#!/bin/bash
# Wrapper script for easy local repackaging
# Usage: ./repack.sh <marketplace_url> [version] [--arm]
#
# Examples:
#   ./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible
#   ./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible 0.0.9
#   ./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible --arm
#   ./repack.sh https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible 0.0.9 --arm

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ARM_FLAG=0
URL=""
VERSION=""

# Parse arguments
for arg in "$@"; do
	case "$arg" in
		--arm) ARM_FLAG=1 ;;
		--help|-h)
			echo ""
			echo "Usage: $0 <marketplace_url> [version] [--arm]"
			echo ""
			echo "Arguments:"
			echo "  marketplace_url  Plugin marketplace URL (required)"
			echo "  version          Plugin version, latest if omitted (optional)"
			echo "  --arm            Target ARM platform instead of x86_64"
			echo ""
			echo "Examples:"
			echo "  $0 https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible"
			echo "  $0 https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible 0.0.9"
			echo "  $0 https://marketplace.dify.ai/plugin/langgenius/openai_api_compatible --arm"
			echo ""
			exit 0
			;;
		-*)
			echo "✗ Unknown option: $arg"
			echo "  Run '$0 --help' for usage"
			exit 1
			;;
		*)
			if [[ -z "$URL" ]]; then
				URL="$arg"
			elif [[ -z "$VERSION" ]]; then
				VERSION="$arg"
			fi
			;;
	esac
done

if [[ -z "$URL" ]]; then
	echo "✗ Error: marketplace URL is required"
	echo "  Run '$0 --help' for usage"
	exit 1
fi

# Build arguments for plugin_repackaging.sh
ARGS=()
if [[ "$ARM_FLAG" -eq 1 ]]; then
	ARCH=$(uname -m)
	if [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
		ARGS+=(-p manylinux2014_aarch64 -s offline)
	else
		ARGS+=(-p manylinux2014_aarch64 -s offline-arm)
	fi
else
	ARGS+=(-p manylinux2014_x86_64 -s offline)
fi

ARGS+=(url "$URL")
[[ -n "$VERSION" ]] && ARGS+=("$VERSION")

exec "${SCRIPT_DIR}/plugin_repackaging.sh" "${ARGS[@]}"
