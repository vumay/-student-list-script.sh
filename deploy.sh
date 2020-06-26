#!/bin/bash
# Script written by EAZYTraining

if ! [ -x "$(command -v cowsay)" ]; then
  echo 'cowsay is needed  before using this script, we are going to install it for you : sudo apt install cowsay' >&2
  sudo apt install cowsay -y
fi

cowsay -f tux EAZYTraining like LINUX 

# This script is used to deploy student list app : https://github.com/diranetafen/student-list.git
if [[ $EUID -ne 0 && `lsb_release -i | cut -f 2-` == Debian ]]; then
  
  echo "############## Install all the prerequisite ##########"
  echo ""
  # update package list
  sudo apt update
  # install dependencies and apache server
  sudo apt install -y  python-dev python3-dev libsasl2-dev libldap2-dev libssl-dev python-pip apache2 php

  # install python library dependencies
  sudo pip install flask flask_httpauth flask_simpleldap python

  echo "############## Deploy backend ##########"

  # copy the application to the right folder
  sudo cp student_age.py /student_age.py && sudo chmod 755 /student_age.py

  # create service to manage the application lifecycle
  sudo tee <<EOF /lib/systemd/system/student_age.service >/dev/null
[Unit]
Description=manage student_age script.

[Service]
Type=simple
ExecStart=/usr/bin/python /student_age.py

[Install]
WantedBy=multi-user.target
EOF

sudo tee <<EOF  /etc/systemd/system/student_age.service >/dev/null
[Unit]
Description=manage student_age script.

[Service]
Type=simple
ExecStart=/usr/bin/python /student_age.py

[Install]
WantedBy=multi-user.target
EOF
  sudo chmod 644 /etc/systemd/system/student_age.service /lib/systemd/system/student_age.service

  # Create folder to store app data
  (sudo mkdir /data > /dev/null 2>&1 ) && (sudo chmod -R 777 /data)

  # Copy data file that contain student list in json format
  sudo cp student_age.json /data/student_age.json

  # start backend (API)
  sudo systemctl daemon-reload
  sudo systemctl restart student_age # we use restart to ensure that the service reload the change
  echo ""
  echo "############## Deploy frontend ##########"
  echo ""

  # remove the default index.html to prevent apache to use it
  sudo rm /var/www/html/index.html

  # copy frontend code source
  sudo cp index.php /var/www/html/index.php

  # set ownership to frontend application
  sudo chown -R www-data:www-data /var/www

  # start frontend (apache server)
  sudo systemctl restart apache2 # we restart to ensure that the service reload the change

  # make fronted and backend to be started at server startup
  sudo systemctl enable student_age
  sudo systemctl enable apache2

  # good bye message
  echo ""
  echo "############## application student list state ################"
  echo ""
  echo "frontend: $(sudo systemctl is-active  apache2)" 
  echo "backend: $(sudo systemctl is-active  student_age)" 
  echo ""
  echo "WARNING: If any service is down, inactive, deactive, or not started, please debug yourself"
  echo ""
  echo "############### Check the operation of the application #########"
  echo "check your application: http://<your server ip>"
  echo "Enjoy and good bye !"

  cowsay Hey Hey Hey

elif [[ $EUID -eq 0 ]]
  then
  echo "This script must NOT be run as root" 1>&2
  exit 1
else
  echo "Your distribution is not Debian, the script only support Debian OS" 1>&2
  exit 2
fi

