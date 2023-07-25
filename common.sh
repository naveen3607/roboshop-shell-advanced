func_service (){
  echo -e "\e[31m>>>>>>>>>>> Copied ${component} service <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  cp ${component}.service /etc/systemd/system/${component}.service

  echo -e "\e[32m>>>>>>>>>>> Copied mongodb repo <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  cp mongo.repo /etc/yum.repos.d/mongo.repo
}

func_nodejs (){
  func_service
  $?
  #Setup NodeJS repos
  echo -e "\e[33m>>>>>>>>>>> Setup nodejs repo <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>>/tmp/roboshop.log
  #Install NodeJS
  echo -e "\e[34m>>>>>>>>>>> Installing nodejs <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  yum install nodejs -y &>>/tmp/roboshop.log
  #Add application user, setup app directory, download application code, install dependencies
  echo -e "\e[35m>>>>>>>>>>> Create application user <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  useradd roboshop &>>/tmp/roboshop.log
  echo -e "\e[36m>>>>>>>>>>> Removed existing directory <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  rm -rf /app &>>/tmp/roboshop.log
  echo -e "\e[31m>>>>>>>>>>> Created directory <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  mkdir /app &>>/tmp/roboshop.log
  curl -o /tmp/${component}.zip https://roboshop-artifacts.s3.amazonaws.com/${component}.zip &>>/tmp/roboshop.log
  echo -e "\e[32m>>>>>>>>>>> Extracting ${component} content <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  cd /app || return &>>/tmp/roboshop.log
  unzip /tmp/${component}.zip &>>/tmp/roboshop.log
  echo -e "\e[33m>>>>>>>>>>> Installing Dependencies <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  cd /app || return &>>/tmp/roboshop.log
  npm install &>>/tmp/roboshop.log
  func_mongodb
  $?
  func_systemd
  $?
}

func_mongodb (){
  #Install mongoDB
  echo -e "\e[34m>>>>>>>>>>> Installing mongodb <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  yum install mongodb-org-shell -y
  #Load mongoDB Schema
  echo -e "\e[35m>>>>>>>>>>> Loading schema <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  mongo --host mongodb.naveen3607.online </app/schema/${component}.js
}

func_systemd (){
  #Reload, enable & start the service
  echo -e "\e[36m>>>>>>>>>>> Starting ${component} service <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  systemctl daemon-reload
  systemctl enable ${component}
  systemctl restart ${component}
}