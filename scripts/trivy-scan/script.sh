#!/usr/bin/env bash

tmp_dir=".trivy"
scans_dir="$tmp_dir/scans"

mkdir -p "$scans_dir"

# shellcheck disable=SC2154
for img in "${images[@]}"; do
  img_name=${img//_/-}
  drv_varname="${img}_drv"
  tag_varname="${img}_tag"
  destoci=".trivy/$img_name"
  destsarif="$scans_dir/$img_name.sarif"
  skopeo --insecure-policy copy nix:"${!drv_varname}" oci:"$destoci"
  trivy image --input "$destoci" --scanners vuln -f sarif -o "$destsarif"
  sed -i "s|$destoci|${!tag_varname}|" "$destsarif"
  sed -i 's/"repoTags": null/"repoTags": ["'"${!tag_varname}"'"]/' "$destsarif"
done

jq -s '{ "$schema": "https://json.schemastore.org/sarif-2.1.0", "version": "2.1.0", "runs": map(.runs) | add }' $scans_dir/*.sarif > $tmp_dir/all.sarif

find $tmp_dir -mindepth 1 -maxdepth 1 -type d -exec rm -rf {} \;
