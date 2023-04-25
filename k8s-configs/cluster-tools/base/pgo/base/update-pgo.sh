#!/bin/bash
set -e

if [ ! $# -eq 1 ];then
   echo "pass arguments: to $0 <commit_sha>"
   exit 1
fi

if [[ ! "$(pwd)" =~ "k8s-configs/cluster-tools/base/pgo/base" ]]; then
    echo "Script run source sanity check failed. Please only run this script in k8s-configs/cluster-tools/base/pgo/base"
    exit 1
fi

# TODO: take a SHA to pull a specific version of the example repo

source ../../../../../utils.sh

# Update the PGO CRDs, other resources based on the github.com/CrunchyData/postgres-operator-examples repo.
# NOTE: only run this script in the k8s-configs/cluster-tools/base/pgo/base directory
cur_date=$(date -I seconds)
tmp_dir="/tmp/pgo/${cur_date}"
example_repo="postgres-operator-examples"
commit_sha="${1}"
repo_dir="${tmp_dir}/${example_repo}"
repo_dir_kustomize="${repo_dir}/kustomize/install"

log "Creating tmp dir - ${tmp_dir}"
mkdir -p "${tmp_dir}"

git clone "https://github.com/CrunchyData/${example_repo}" "${tmp_dir}/${example_repo}"
cd ${tmp_dir}/${example_repo}
git reset --hard ${commit_sha}

# Remove the singlenamespace dir, we don't use it
rm -rf "${repo_dir_kustomize}/singlenamespace"

# Copy the massaged repo directory to this directory
rsync -rv "${repo_dir_kustomize}/" .

# Replace default crunchydata image to our ECR image
ECR_REPO_NAME='value: "public.ecr.aws/r2h3l6e4/pingcloud-clustertools'
CRUNCHY_DATA_REPO='value: "registry.developers.crunchydata.com'

find . -name '*.yaml' -exec sed -i '' "s@$CRUNCHY_DATA_REPO@$ECR_REPO_NAME@g" {} \;

log "PGO update complete, check your 'git diff' to see what changed"
