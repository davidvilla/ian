# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- hooks ------------------------------------------------------------

function notify-clean {
    if sc-function-exists ian-clean-hook; then
		log-info "exec ian-clean-hook"
		ian-run ian-clean-hook
    fi
}

function notify-release {
    if sc-function-exists ian-release-hook; then
		log-info "exec ian-release-hook"
		ian-run ian-release-hook
    fi
}

function notify-build-start {
    if sc-function-exists ian-build-start-hook; then
		log-info "exec ian-build-start-hook"
		ian-run ian-build-start-hook
    fi
}

function notify-build-end {
    if sc-function-exists ian-build-end-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-end-hook
    fi

    if sc-function-exists ian-build-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-hook
    fi
}

function notify-install {
    if sc-function-exists ian-install-hook; then
		log-info "exec ian-install-hook"
		ian-run ian-install-hook
    fi
}

function notify-upload {
    if sc-function-exists ian-upload-hook; then
		log-info "exec ian-upload-hook"
		ian-run ian-upload-hook
    fi
}
