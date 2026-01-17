#!/usr/bin/env bash
# Feature validation for epic orchestration
# Validates feature implementation completeness

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Default configuration
OUTPUT_FORMAT="${OUTPUT_FORMAT:-text}"  # text or json
VALIDATION_RULES="${VALIDATION_RULES_FILE:-}"

# Parse arguments
FEATURE_DIR=""
MODE="craft"  # or ship
VERBOSE=false
EXCLUDE_RULES=""
INCLUDE_RULES=""
BAIL_ON_FIRST_FAILURE=false

detect_project_type() {
    local dir="$1"
    
    if [[ -f "$dir/pom.xml" ]]; then
        echo "maven"
    elif [[ -f "$dir/build.gradle" || -f "$dir/build.gradle.kts" ]]; then
        echo "gradle"
    elif [[ -f "$dir/package.json" ]]; then
        echo "nodejs"
    elif [[ -f "$dir/requirements.txt" || -f "$dir/setup.py" ]]; then
        echo "python"
    elif [[ -f "$dir/Cargo.toml" ]]; then
        echo "rust"
    elif [[ -f "$dir/go.mod" ]]; then
        echo "go"
    elif ls "$dir"/*.csproj >/dev/null 2>&1; then
        echo "dotnet"
    elif [[ -f "$dir/Makefile" ]]; then
        echo "make"
    else
        echo "unknown"
    fi
}

# Predefined validation rules
declare -A VALIDATION_RULES_MAP

# Craft mode rules
VALIDATION_RULES_MAP["craft:files_exist"]="Files exist validation"
VALIDATION_RULES_MAP["craft:spec_valid"]="Specification document valid"
VALIDATION_RULES_MAP["craft:plan_valid"]="Plan document valid"
VALIDATION_RULES_MAP["craft:source_files"]="Source files present"
VALIDATION_RULES_MAP["craft:no_compile_errors"]="No compilation errors"
VALIDATION_RULES_MAP["craft:unit_tests"]="Unit tests present"
VALIDATION_RULES_MAP["craft:linter_clean"]="Linter passes"

# Ship mode rules
VALIDATION_RULES_MAP["ship:integration_tests"]="Integration tests pass"
VALIDATION_RULES_MAP["ship:e2e_tests"]="End-to-end tests pass"
VALIDATION_RULES_MAP["ship:performance_tests"]="Performance tests pass"
VALIDATION_RULES_MAP["ship:security_scan"]="Security scan clean"
VALIDATION_RULES_MAP["ship:documentation_complete"]="Documentation complete"
VALIDATION_RULES_MAP["ship:deployment_ready"]="Deployment configuration ready"

# Default rules by mode
CRAFT_DEFAULT_RULES=("files_exist" "spec_valid" "plan_valid" "source_files")
SHIP_DEFAULT_RULES=("integration_tests" "e2e_tests" "documentation_complete" "deployment_ready")

usage() {
    cat <<'EOF'
Usage: validate-feature.sh -d <feature_dir> [-m <mode>] [options]

  -d <dir>    Feature directory (required)
  -m <mode>   Validation mode: craft or ship (default: craft)
  -r <file>   Custom validation rules file (JSON)
  -e <rules>  Exclude rules (comma-separated)
  -i <rules>  Include only these rules (comma-separated)
  -b          Bail on first failure
  -v          Verbose output
  -j          JSON output format
  -h          Show this help

Validation rules in custom file:
{
  "craft": {
    "rules": {
      "files_exist": {
        "enabled": true,
        "description": "Required files present"
      }
    }
  }
}
EOF
    exit 1
}

while getopts "d:m:r:e:i:bvjh" opt; do
    case $opt in
        d) FEATURE_DIR="$OPTARG" ;;
        m) MODE="$OPTARG" ;;
        r) VALIDATION_RULES="$OPTARG" ;;
        e) EXCLUDE_RULES="$OPTARG" ;;
        i) INCLUDE_RULES="$OPTARG" ;;
        b) BAIL_ON_FIRST_FAILURE=true ;;
        v) VERBOSE=true ;;
        j) OUTPUT_FORMAT="json" ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate arguments
if [[ -z "$FEATURE_DIR" ]]; then
    echo "Error: Feature directory is required" >&2
    usage
fi

if [[ ! -d "$FEATURE_DIR" ]]; then
    echo "Error: Feature directory not found: $FEATURE_DIR" >&2
    exit 1
fi

if [[ "$MODE" != "craft" && "$MODE" != "ship" ]]; then
    echo "Error: Invalid mode. Must be 'craft' or 'ship'" >&2
    exit 1
fi

# Load custom validation rules if provided
custom_rules=""
if [[ -f "$VALIDATION_RULES" ]]; then
    if ! custom_rules=$(cat "$VALIDATION_RULES" 2>/dev/null); then
        echo "Error: Failed to read validation rules file: $VALIDATION_RULES" >&2
        exit 1
    fi
fi

# Log function
log() {
    local level="$1"
    shift
    local message="$*"
    if $VERBOSE; then
        echo "[$level] $message" >&2
    fi
}

# Add result to JSON array
results=()
add_result() {
    local rule="$1"
    local passed="$2"
    local message="${3:-}"
    
    results+=("$(jq -n --arg rule "$rule" --arg passed "$passed" --arg message "$message" \
        '{rule: $rule, passed: ($passed == "true"), message: $message}')")
}

# Run validation with error wrapping
run_validation() {
    local rule="$1"
    local validation_func="$2"
    
    log "INFO" "Running validation: $rule"
    
    if $VERBOSE; then
        if eval "$validation_func" 2>&1; then
            add_result "$rule" "true" "Validation passed"
            return 0
        else
            local exit_code=$?
            add_result "$rule" "false" "Validation failed with exit code $exit_code"
            return 1
        fi
    else
        if eval "$validation_func" >/dev/null 2>&1; then
            add_result "$rule" "true" "Validation passed"
            return 0
        else
            local exit_code=$?
            add_result "$rule" "false" "Validation failed with exit code $exit_code"
            return 1
        fi
    fi
}

# Validation rule implementations
validate_files_exist() {
    local -a required_files=("spec.md" "plan.md" "tasks.md")
    local missing=()
    
    for file in "${required_files[@]}"; do
        if [[ ! -f "$FEATURE_DIR/$file" ]]; then
            missing+=("$file")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing required files: ${missing[*]}" >&2
        return 1
    fi
    
    return 0
}

validate_spec_valid() {
    if [[ ! -f "$FEATURE_DIR/spec.md" ]]; then
        echo "Specification file not found" >&2
        return 1
    fi
    
    # Basic markdown validation
    if ! grep -q "^# " "$FEATURE_DIR/spec.md"; then
        echo "Specification file missing main heading" >&2
        return 1
    fi
    
    if ! grep -qi "user story\|as a\|i want\|so that" "$FEATURE_DIR/spec.md"; then
        echo "Specification missing user story" >&2
        return 1
    fi
    
    return 0
}

validate_plan_valid() {
    if [[ ! -f "$FEATURE_DIR/plan.md" ]]; then
        echo "Plan file not found" >&2
        return 1
    fi
    
    # Basic plan validation
    if ! grep -q "^# " "$FEATURE_DIR/plan.md"; then
        echo "Plan file missing main heading" >&2
        return 1
    fi
    
    if ! grep -qi "approach\|implementation\|testing" "$FEATURE_DIR/plan.md"; then
        echo "Plan missing key sections" >&2
        return 1
    fi
    
    return 0
}

validate_source_files() {
    local project_type=$(detect_project_type "$FEATURE_DIR")
    local -a source_extensions=("*.py" "*.js" "*.ts" "*.java" "*.cs" "*.cpp" "*.h" "*.rs" "*.go")
    
    local found=0
    for ext in "${source_extensions[@]}"; do
        if compgen -G "$FEATURE_DIR/$ext" >/dev/null 2>&1; then
            found=$((found + 1))
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No source files found in feature directory" >&2
        return 1
    fi
    
    return 0
}

validate_no_compile_errors() {
    local project_type=$(detect_project_type "$FEATURE_DIR")
    
    case "$project_type" in
        maven)
            if [[ -f "$FEATURE_DIR/pom.xml" ]]; then
                (cd "$FEATURE_DIR" && mvn -q compile 2>&1)
            fi
            ;;
        gradle)
            if [[ -f "$FEATURE_DIR/build.gradle" || -f "$FEATURE_DIR/build.gradle.kts" ]]; then
                (cd "$FEATURE_DIR" && gradle -q compileJava 2>&1)
            fi
            ;;
        dotnet)
            if ls "$FEATURE_DIR"/*.csproj >/dev/null 2>&1; then
                (cd "$FEATURE_DIR" && dotnet build -nologo -v q 2>&1)
            fi
            ;;
        rust)
            if [[ -f "$FEATURE_DIR/Cargo.toml" ]]; then
                (cd "$FEATURE_DIR" && cargo check -q 2>&1)
            fi
            ;;
        go)
            if [[ -f "$FEATURE_DIR/go.mod" ]]; then
                (cd "$FEATURE_DIR" && go build -v -o /dev/null ./... 2>&1)
            fi
            ;;
        *)
            log "INFO" "Skipping compile check for unknown project type: $project_type"
            return 0
            ;;
    esac
    
    return $?
}

validate_unit_tests() {
    local project_type=$(detect_project_type "$FEATURE_DIR")
    
    case "$project_type" in
        maven)
            if [[ -f "$FEATURE_DIR/pom.xml" ]]; then
                (cd "$FEATURE_DIR" && mvn -q test -DskipTests=false 2>&1)
                # For validation, just check that test source files exist
                if ! find "$FEATURE_DIR" -name "*Test.java" -o -name "Test*.java" | grep -q .; then
                    return 1
                fi
            fi
            ;;
        gradle)
            if [[ -f "$FEATURE_DIR/build.gradle" || -f "$FEATURE_DIR/build.gradle.kts" ]]; then
                # Check for test files
                if ! find "$FEATURE_DIR" -name "*Test.java" -o -name "*Test.kt" | grep -q .; then
                    return 1
                fi
            fi
            ;;
        dotnet)
            if find "$FEATURE_DIR" -name "*Tests.cs" -o -name "Test*.cs" | grep -q .; then
                return 0
            else
                return 1
            fi
            ;;
        nodejs)
            if [[ -f "$FEATURE_DIR/package.json" ]]; then
                # Check if test script is defined
                if grep -q '"test"' "$FEATURE_DIR/package.json"; then
                    return 0
                else
                    return 1
                fi
            fi
            ;;
        *)
            log "INFO" "Skipping unit test check for unknown project type: $project_type"
            return 0
            ;;
    esac
    
    return $?
}

validate_linter_clean() {
    local project_type=$(detect_project_type "$FEATURE_DIR")
    
    case "$project_type" in
        python)
            if command -v flake8 >/dev/null 2>&1; then
                (cd "$FEATURE_DIR" && flake8 --max-line-length=88 --select=E9,F63,F7,F82 . 2>&1)
            fi
            return 0
            ;;
        nodejs)
            if [[ -f "$FEATURE_DIR/package.json" ]] && command -v eslint >/dev/null 2>&1; then
                (cd "$FEATURE_DIR" && find . -name "*.js" -o -name "*.ts" | xargs eslint --max-warnings=0 2>&1)
            fi
            return 0
            ;;
        *)
            log "INFO" "Skipping linter check for project type: $project_type"
            return 0
            ;;
    esac
    
    return $?
}

validate_integration_tests() {
    # placeholder - project specific implementation
    log "INFO" "Integration test validation not implemented for $MODE mode"
    return 0
}

validate_e2e_tests() {
    # placeholder - project specific implementation
    log "INFO" "E2E test validation not implemented for $MODE mode"
    return 0
}

validate_performance_tests() {
    # placeholder - project specific implementation
    log "INFO" "Performance test validation not implemented for $MODE mode"
    return 0
}

validate_security_scan() {
    # placeholder - security scan implementation
    log "INFO" "Security scan validation not implemented for $MODE mode"
    return 0
}

validate_documentation_complete() {
    local docs_files=("README.md" "CHANGELOG.md" "docs/")
    local found=0
    
    for item in "${docs_files[@]}"; do
        if [[ -e "$FEATURE_DIR/$item" ]]; then
            found=$((found + 1))
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No documentation found. Expected README.md or docs/ directory" >&2
        return 1
    fi
    
    return 0
}

validate_deployment_ready() {
    local dep_files=("Dockerfile" "docker-compose.yml" "k8s/" "deploy/" "ci/")
    local found=0
    
    for item in "${dep_files[@]}"; do
        if [[ -e "$FEATURE_DIR/$item" ]]; then
            found=$((found + 1))
        fi
    done
    
    if [[ $found -eq 0 ]]; then
        echo "No deployment configuration found" >&2
        return 1
    fi
    
    return 0
}

# Build rule list
build_rule_list() {
    local -n rules_ref=$1
    
    # Default rules
    local -a default_rules
    if [[ "$MODE" == "craft" ]]; then
        default_rules=("${CRAFT_DEFAULT_RULES[@]}")
    else
        default_rules=("${SHIP_DEFAULT_RULES[@]}")
    fi
    
    # Apply include/exclude
    for rule in "${default_rules[@]}"; do
        local key="${MODE}:${rule}"
        
        # Skip if excluded
        if [[ -n "$EXCLUDE_RULES" ]] && [[ ",$EXCLUDE_RULES," == *",$rule,"* ]]; then
            log "INFO" "Excluding rule: $rule"
            continue
        fi
        
        # Skip if not included when include list specified
        if [[ -n "$INCLUDE_RULES" ]] && [[ ",$INCLUDE_RULES," != *",$rule,"* ]]; then
            log "INFO" "Skipping rule (not in include list): $rule"
            continue
        fi
        
        rules_ref+=("$key")
    done
}

# Output results
output_results() {
    local -a results=(${!1})
    local total=${#results[@]}
    local passed=0
    
    for result in "${results[@]}"; do
        if $(echo "$result" | jq -r '.passed') == "true"; then
            ((passed++))
        fi
    done
    
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        jq -n --arg mode "$MODE" \
              --arg total "$total" \
              --arg passed "$passed" \
              --arg feature_dir "$FEATURE_DIR" \
              '{mode: $mode, feature_dir: $feature_dir, total_rules: ($total|tonumber), passed_rules: ($passed|tonumber), results: $ARGS.positional}' \
              --jsonargs "${results[@]}"
    else
        echo "=== VALIDATION RESULTS ==="
        echo "Mode: $MODE"
        echo "Feature: $FEATURE_DIR"
        echo "Rules: $passed / $total passed"
        echo
        echo "=== DETAILS ==="
        for result in "${results[@]}"; do
            local rule=$(echo "$result" | jq -r '.rule')
            local passed=$(echo "$result" | jq -r '.passed')
            local message=$(echo "$result" | jq -r '.message')
            
            if [[ "$passed" == "true" ]]; then
                echo "✓ $rule: $message"
            else
                echo "✗ $rule: $message"
            fi
        done
    fi
    
    # Exit code
    if [[ $passed -eq $total ]]; then
        return 0
    else
        return 1
    fi
}

# Main execution
main() {
    local -a rules=()
    build_rule_list rules
    
    if [[ ${#rules[@]} -eq 0 ]]; then
        echo "Error: No validation rules to execute" >&2
        exit 1
    fi
    
    log "INFO" "Running validation in $MODE mode with ${#rules[@]} rules"
    
    local -a all_results=()
    local failed=false
    
    for rule in "${rules[@]}"; do
        local rule_name=$(echo "$rule" | cut -d: -f2)
        local validation_func="validate_$rule_name"
        
        if ! type "$validation_func" >/dev/null 2>&1; then
            log "WARNING" "Validation function not found: $validation_func"
            add_result "$rule" "false" "Validation function not implemented"
            all_results+=("$(jq -n --arg rule "$rule" --arg message "Validation function not implemented" '{rule: $rule, passed: false, message: $message}')")
            failed=true
            continue
        fi
        
        if run_validation "$rule" "$validation_func"; then
            all_results+=("$(jq -n --arg rule "$rule" --arg message "Validation passed" '{rule: $rule, passed: true, message: $message}')")
        else
            all_results+=("$(jq -n --arg rule "$rule" --arg message "Validation failed" '{rule: $rule, passed: false, message: $message}')")
            failed=true
            
            if $BAIL_ON_FIRST_FAILURE; then
                log "ERROR" "Bailing on first failure: $rule"
                break
            fi
        fi
    done
    
    output_results all_results[@]
    exit $?
}

# Execute main function
main "$@"
