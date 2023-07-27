func_service (){
  echo -e "\e[31m>>>>>>>>>>> Copied ${component} service <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  cp ${component}.service /etc/systemd/system/${component}.service
}

func_exit_status (){
  if [ $? -eq 0 ]; then
    echo -e "\e[31m Success \e[0m"
  else
    echo -e "\e[31m Failure \e[0m"
  fi
}

func_application_requirements () {
    #Add application user, setup app directory, download application code, install dependencies
    echo -e "\e[35m>>>>>>>>>>> Create application user <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    id roboshop &>>/tmp/roboshop.log
    if [ $? -ne 0 ]; then
      useradd roboshop &>>/tmp/roboshop.log
    fi
    func_exit_status
    echo -e "\e[36m>>>>>>>>>>> Removed existing directory <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    rm -rf /app &>>/tmp/roboshop.log
    func_exit_status
    echo -e "\e[31m>>>>>>>>>>> Created directory <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    mkdir /app &>>/tmp/roboshop.log
    func_exit_status
    curl -o /tmp/${component}.zip https://roboshop-artifacts.s3.amazonaws.com/${component}.zip &>>/tmp/roboshop.log
    func_exit_status
    echo -e "\e[32m>>>>>>>>>>> Extracting ${component} content <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    cd /app || return &>>/tmp/roboshop.log
    unzip /tmp/${component}.zip &>>/tmp/roboshop.log
    func_exit_status
    echo -e "\e[33m>>>>>>>>>>> Installing Dependencies <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    cd /app || return &>>/tmp/roboshop.log
    npm install &>>/tmp/roboshop.log
    func_exit_status
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

  if ("${component}" =! "cart") then
  func_mongodb
  $?
  func_schema
  $?
  fi
  func_systemd
  $?
}

func_mongodb (){
    echo -e "\e[32m>>>>>>>>>>> Copied mongodb repo <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
    cp mongo.repo /etc/yum.repos.d/mongo.repo
    func_exit_status
    if [ "${component}" == "mongod" ]; then
      #Install MongoDB
      echo -e "\e[32m>>>>>>>>>>> Installing mongodb <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
      yum install mongodb-org -y &>>/tmp/roboshop.log
      func_exit_status
    else
      #Install mongodb
      echo -e "\e[34m>>>>>>>>>>> Installing mongodb <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
      yum install mongodb-org-shell -y
      func_exit_status
    fi
}

func_mongod (){
  func_mongodb
  func_ip
  func_systemd
}

func_schema (){
  if [ "${schema_type}" == "mongodb" ]; then
  #Load mongodb schema
  echo -e "\e[35m>>>>>>>>>>> Loading schema <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  mongo --host mongodb.naveen3607.online </app/schema/${component}.js
  $?
}


func_ip (){
  if ("${component}" =! "redis") then
  echo -e "\e[33m>>>>>>>>>>> Updating ip in configuration file <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  sed -i -e 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf &>>/tmp/roboshop.log
  $?
  else
  #Update listen address from 127.0.0.1 to 0.0.0.0 in /etc/redis.conf
  echo -e "\e[34m>>>>>>>>>>> Update ip in configuration file <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  sed -i 's/127.0.0.1/0.0.0.0/' /etc/redis.conf /etc/redis/redis.conf &>> /tmp/roboshop.log
  $?
  fi
}

func_systemd (){
  #Reload, enable & start the service
  echo -e "\e[36m>>>>>>>>>>> Starting ${component} service <<<<<<<<<<\e[0m" | tee -a /tmp/roboshop.log
  systemctl daemon-reload
  systemctl enable ${component}
  systemctl restart ${component}
}