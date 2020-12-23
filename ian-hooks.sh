# -*- coding: utf-8; mode: shell-script; tab-width: 4 -*-
#-- hooks ------------------------------------------------------------

function notify-clean {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-clean-hook; then
		log-info "exec ian-clean-hook"
		ian-run ian-clean-hook
    fi
}

function notify-release {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-release-hook; then
		log-info "exec ian-release-hook"
		ian-run ian-release-hook
    fi
}

function notify-build-start {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-build-start-hook; then
		log-info "exec ian-build-start-hook"
		ian-run ian-build-start-hook
    fi
}

function notify-build-end {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-build-end-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-end-hook
    fi

    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-build-hook; then
		log-info "exec ian-build-end-hook"
		ian-run ian-build-hook
    fi
}

function notify-install {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-install-hook; then
		log-info "exec ian-install-hook"
		ian-run ian-install-hook
    fi
}

function notify-upload-start {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-upload-start-hook; then
		log-info "exec ian-upload-start-hook"
		ian-run ian-upload-start-hook
    fi
}

function notify-upload-end {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-upload-end-hook; then
		log-info "exec ian-upload-end-hook"
		ian-run ian-upload-end-hook
    fi
}

function notify-remove {
    if ! sc-var-defined IAN_DISABLE_HOOKS && sc-function-exists ian-remove-hook; then
		log-info "exec ian-remove-hook"
		ian-run ian-remove-hook
    fi
}


 # FIXME: rename hooks
 # ian-build-pre-hook
 # ian-build-ok-book
 # ian-build-fail-hook
 # ian-install-ok-hook
 # ian-install-fail-hook
 # ian-upload-pre-hook
 # ian-upload-ok-hook
 # ian-upload-fail-hook
 # ian-remove-hook
