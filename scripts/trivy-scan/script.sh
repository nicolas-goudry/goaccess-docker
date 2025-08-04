# shellcheck shell=bash

# Global variables
readonly tmp_dir=".trivy"
readonly scans_dir="$tmp_dir/scan_results"

# Color codes
readonly nc="\e[0m" # Unset styles
readonly red="\e[31m" # Red foreground
readonly green="\e[32m" # Green foreground
readonly yellow="\e[33m" # Yellow foreground
readonly blue="\e[34m" # Blue foreground

# Logging functions
info() {
  echo -e " ${blue}i${nc} ${*}"
}

success() {
  echo -e " ${green}✔${nc} ${*}"
}

warn() {
  echo -e " ${yellow}⚠${nc} ${*}"
}

error() {
  >&2 echo -e " ${red}×${nc} ${*}"
}

# Cleanup function for error handling
cleanup() {
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    error "Script failed with exit code $exit_code"
    info "Cleaning up temporary files..."
    rm -rf "$tmp_dir" 2>/dev/null || true
  fi

  exit $exit_code
}

# Set up error handling
trap cleanup EXIT

# Initialize scan environment
init_scan_env() {
  info "Initializing scan environment..."

  # Remove existing directory if it exists to ensure clean state
  [[ -d "$tmp_dir" ]] && rm -rf "$tmp_dir"

  # Create scan directory
  mkdir -p "$scans_dir"

  success "Scan directory created: $scans_dir"
}

# Scan individual container image
scan_img() {
  local img="$1"
  local img_name=${img//_/-} # Replace underscores with hyphens
  local drv_varname="${img}_drv"
  local tag_varname="${img}_tag"
  local destoci="$tmp_dir/$img_name"
  local destsarif="$scans_dir/$img_name.sarif"

  info "Scanning image: $img"

  # Validate that required variables are set
  if [[ -z "${!drv_varname:-}" ]]; then
    error "Derivation variable $drv_varname is not set for image $img"
    return 1
  fi

  if [[ -z "${!tag_varname:-}" ]]; then
    error "Tag variable $tag_varname is not set for image $img"
    return 1
  fi

  # Copy image derivation to OCI layout
  info "Copying image derivation to OCI layout..."
  if ! skopeo --insecure-policy copy nix:"${!drv_varname}" oci:"$destoci"; then
    error "Failed to copy image derivation for $img"
    return 1
  fi

  # Scan image for vulnerabilities and generate SARIF report
  info "Scanning for vulnerabilities..."
  if ! trivy image --input "$destoci" --scanners vuln -f sarif -o "$destsarif"; then
    error "Trivy scan failed for $img"
    return 1
  fi

  # Update SARIF report with actual image tag information
  info "Updating SARIF report with image tag information..."
  if [[ -f "$destsarif" ]]; then
    # Replace OCI path with actual tag name in scan results
    sed -i "s|$destoci|${!tag_varname}|" "$destsarif"
    # Set proper repository tags in SARIF metadata
    sed -i 's/"repoTags": null/"repoTags": ["'"${!tag_varname}"'"]/' "$destsarif"

    success "Scan completed for $img -> $destsarif"
  else
    error "SARIF report not generated for $img"
    return 1
  fi
}

# Function to merge multiple SARIF files into a single consolidated report
# This combines multiple scan results while preserving the SARIF format structure
#
# Arguments:
#   $1 - Glob pattern of SARIF files to merge
#   $2 - Destination file path for the merged report
merge_sarif_files() {
  local glob_pattern="$1"
  local dest_file="$2"

  info "Merging SARIF files: $glob_pattern -> $dest_file"

  # Check if any files match the pattern
  # shellcheck disable=SC2206
  local files=($glob_pattern)
  if [[ ! -f "${files[0]}" ]]; then
    warn "No files found matching pattern: $glob_pattern"
    return 0
  fi

  # Merge SARIF files using jq to combine runs from multiple files
  # shellcheck disable=SC2086
  if ! jq -s '{
    "$schema": "https://json.schemastore.org/sarif-2.1.0",
    "version": "2.1.0",
    "runs": map(.runs) | add
  }' $glob_pattern > "$dest_file"; then
    error "Failed to merge SARIF files for pattern: $glob_pattern"
    return 1
  fi

  success "Successfully merged ${#files[@]} files into $dest_file"
}

main() {
  info "Starting container vulnerability scanning process..."

  # Check if images array is defined and not empty
  if [[ -z "${images:-}" ]] || [[ ${#images[@]} -eq 0 ]]; then
    error "No images defined in 'images' array"
    warn "Please define an array of image names before running this script"
    exit 1
  fi

  # Initialize scanning environment
  init_scan_env

  # Scan all images in the array
  info "Scanning ${#images[@]} images..."
  local failed_scans=0

  # shellcheck disable=SC2154
  for img in "${images[@]}"; do
    if ! scan_img "$img"; then
      ((failed_scans++))
      error "Failed to scan image: $img"
    fi
  done

  # Report scan summary
  local successful_scans=$((${#images[@]} - failed_scans))
  info "Scan summary: $successful_scans successful, $failed_scans failed"

  if [[ $failed_scans -gt 0 ]]; then
    warn "Some scans failed. Check the logs above for details."
  fi

  # Merge SARIF files by distribution type
  info "Merging SARIF reports by distribution..."
  merge_sarif_files "$scans_dir/alpine*.sarif" "$tmp_dir/alpine.sarif"
  merge_sarif_files "$scans_dir/debian*.sarif" "$tmp_dir/debian.sarif"
  merge_sarif_files "$scans_dir/distroless*.sarif" "$tmp_dir/distroless.sarif"
  merge_sarif_files "$scans_dir/ubuntu*.sarif" "$tmp_dir/ubuntu.sarif"

  # Cleanup intermediate OCI directories (keep SARIF files)
  info "Cleaning up intermediate files..."
  find "$tmp_dir" -mindepth 1 -maxdepth 1 -type d -not -path "$scans_dir" -exec rm -rf {} \; 2>/dev/null || true

  success "Vulnerability scanning completed successfully!"
  success "Results available in: $tmp_dir"
}

# Execute main function if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
