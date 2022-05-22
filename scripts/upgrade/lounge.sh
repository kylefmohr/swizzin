#!/usr/bin/env bash

function _yarnlounge() {
    #shellcheck source=sources/functions/npm
    . /etc/swizzin/sources/functions/npm

    if [[ $active == "active" ]]; then
        systemctl stop lounge
    fi
    npm uninstall --quiet -g thelounge --save >> /dev/null 2>&1
    yarn_install
    yarn --non-interactive global add thelounge >> $log 2>&1
    yarn --non-interactive cache clean >> $log 2>&1
    chown -R lounge: /opt/lounge
    sudo -u lounge bash -c "thelounge install thelounge-theme-zenburn" >> ${log} 2>&1
    # Replace with new execstart line
    sed -i "s|ExecStart=.*|ExecStart=$(which thelounge) start|g" /etc/systemd/system/lounge.service
    systemctl daemon-reload
    if [[ $active == "active" ]]; then
        systemctl start lounge
    fi
}

if [[ ! -f /install/.lounge.lock ]]; then
    echo "lounge does not appear to be installed!"
    exit 1
fi

if [[ $(systemctl is-active lounge) == "active" ]]; then
    wasActive="true"
    echo_progress_start "Shutting down lounge"
    systemctl stop lounge
    echo_progress_done
fi

if thelounge --version lt 4.3.1 >> /dev/null 2>&1; then
    _yarnlounge
fi

if ! /usr/bin/yarn --non-interactive global upgrade thelounge >> "$log" 2>&1; then
    echo_error "Lounge failed to update, please investigate the logs"
fi

if [[ $wasActive = "true" ]]; then
    echo_progress_start "Restarting lounge"
    systemctl start lounge
    echo_progress_done
fi

