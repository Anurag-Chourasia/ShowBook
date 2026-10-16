#!/bin/bash
set -euo pipefail
# Credentials are repository-specific read-only deploy keys, never personal tokens.
# Call only from trusted same-repository CI; do not use pull_request_target.
umask 077
credential_dir="$RUNNER_TEMP/shared-kit-credentials"
mkdir -p "$credential_dir"
printf '%s\n' "$FOUNDATIONKIT_DEPLOY_KEY" > "$credential_dir/FoundationKit"
test -n "$FOUNDATIONKIT_DEPLOY_KEY"
test -n "$LOCALIZATIONKIT_DEPLOY_KEY"
printf '%s\n' "$LOCALIZATIONKIT_DEPLOY_KEY" > "$credential_dir/LocalizationKit"
test -n "$DEVELOPERPROFILEKIT_DEPLOY_KEY"
printf '%s\n' "$DEVELOPERPROFILEKIT_DEPLOY_KEY" > "$credential_dir/DeveloperProfileKit"
cp Scripts/github_known_hosts "$credential_dir/known_hosts"
cat > "$credential_dir/ssh_config" <<CONFIG
Host developerprofilekit-ci
  HostName github.com
  User git
  IdentityFile $credential_dir/DeveloperProfileKit
  IdentitiesOnly yes
  StrictHostKeyChecking yes
  UserKnownHostsFile $credential_dir/known_hosts
Host foundationkit-ci
  HostName github.com
  User git
  IdentityFile $credential_dir/FoundationKit
  IdentitiesOnly yes
  StrictHostKeyChecking yes
  UserKnownHostsFile $credential_dir/known_hosts
Host localizationkit-ci
  HostName github.com
  User git
  IdentityFile $credential_dir/LocalizationKit
  IdentitiesOnly yes
  StrictHostKeyChecking yes
  UserKnownHostsFile $credential_dir/known_hosts
CONFIG
git config --file "$credential_dir/gitconfig" url."ssh://git@foundationkit-ci/Anurag-Chourasia/FoundationKit.git".insteadOf https://github.com/Anurag-Chourasia/FoundationKit.git
git config --file "$credential_dir/gitconfig" url."ssh://git@localizationkit-ci/Anurag-Chourasia/LocalizationKit.git".insteadOf https://github.com/Anurag-Chourasia/LocalizationKit.git
git config --file "$credential_dir/gitconfig" url."ssh://git@developerprofilekit-ci/Anurag-Chourasia/DeveloperProfileKit.git".insteadOf https://github.com/Anurag-Chourasia/DeveloperProfileKit.git
printf 'GIT_CONFIG_GLOBAL=%s\n' "$credential_dir/gitconfig" >> "$GITHUB_ENV"
printf 'GIT_SSH_COMMAND=ssh -F %s\n' "$credential_dir/ssh_config" >> "$GITHUB_ENV"
