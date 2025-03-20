#!/bin/bash

if [[ "$UID" -eq 0 ]]; then
    #define configs before running script
    ftp_user="hcomftp"
    root_folder="/home/$ftp_user/ftp"
    files_folder="$root_folder/hcom"
    log_folder="/var/log/xferlog"
    vsftpd_config_file="/etc/vsftpd.conf"
    vsftpd_allow_list_file="/etc/vsftpd.userlist"

    #install vsFTPd
    echo "Installing vsFTPd..."
    sudo apt update > /dev/null # 2>&1
    sudo apt install -y vsftpd # &> /dev/null
    echo "Sucessfully installed vsFTPd."
    echo

    #creates all folders and files
    echo "Creating files and folder..."
    mkdir -p "$files_folder"
    mkdir -p "$log_folder"
    touch "$vsftpd_config_file"
    echo "$ftp_user" > "$vsftpd_allow_list_file"   #adds the user to allow_list
    echo "Files and folders created sucessfully."
    echo

    #creates user for access
    echo "Please enter informations regarding the user $ftp_user, used for the ftp connection:"
    sudo adduser -q "$ftp_user"
    echo "User $ftp_user created sucessfully."

    #adjust rwx privleges to folders
    echo "Adjusting folders and file permissions..."
    sudo chown nobody:nogroup "$root_folder"
    sudo chmod a-w "$root_folder"
    sudo chown "$ftp_user":"$ftp_user" "$files_folder"
    echo "Permissions adjusted."
    echo

    #adjusts configs for vsftpd
    echo "Setting up vsFTPd config file..."
    > "$vsftpd_config_file"
    cat <<EOF >> "$vsftpd_config_file"
#SETTINGS FOR THE CONNECTION
listen=YES
listen_port=21
listen_ipv6=NO
pasv_enable=YES
pasv_min_port=1000
pasv_max_port=1200
use_localtime=YES
idle_session_timeout=600   #default 300
utf8_filesystem=YES

#SECURITY SETTINGS AND TLS
#pam_service=vsftpd
ssl_enable=NO
#rsa_cert_file=/etc/ssl/certs/certificate.pem
#rsa_private_key_file=/etc/ssl/private/certificate.key
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
user_sub_token=\$USER
local_root=/home/\$USER/ftp
userlist_enable=YES
userlist_file=$vsftpd_allow_list_file
userlist_deny=NO

#LOGGING
#log_ftp_protocol=YES
xferlog_enable=YES
xferlog_file=$log_folder/vsftpd.log
EOF
    sudo chmod 644 "$vsftpd_config_file"
    sudo chmod 644 "$vsftpd_allow_list_file"
    sudo chown root:root "$vsftpd_config_file"
    sudo chown root:root "$vsftpd_allow_list_file"
    echo "vsFTPd config file done!"

    #restart service
    echo "Restarting vsFTPd service..."
    sudo systemctl restart vsftpd.service
    echo "Service restarted"
    echo

    systemctl status vsftpd > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    echo "Service is running or was running."
    else
    echo "Service is not running or failed to start."
    echo
    fi

    echo "End of instalation, please try to connect to the FTP in the following adrress(es):"
    ip addr | grep -w inet | grep -v 127.0.0.1 | awk '{print $2}' | cut -d'/' -f1

else 
    echo "********** Please run this script with sudo privileges **********"
    exit 1
fi