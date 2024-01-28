#!/bin/bash

ID=$(id -u)

R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"
MONGODB_HOST=mongodb.daws86s.online

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"

echo "script started excuting at $TIMESTAMP" &>> $LOGFILE

VALIDATE() {
    if [ $1 -ne 0 ]
    then 
      echo -e "$2 ... $R FAILED $N"
    else
     echo -e "$2 ... $G SUCCESS $N"
    fi
}


if [ $ID -ne 0 ]
then
   echo -e "ERROR:: $R Please run this script with root access $N"
   exit 1
else 
   echo "your are a root user"
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "DIsabling current NodeJS"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabling NodeJS:18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $?  "Installing NodeJS:18"

useradd roboshop 
VALIDATE $? "creating roboshop user"

mkdir /app 
VALIDATE $? "creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip  &>> $LOGFILE
VALIDATE $? "Downloading catalogue application"

cd /app 

unzip /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "unzipping catalogue"

npm install &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/centos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "catalogue daemon reload"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "starting catalogue"

cp /home/centos/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo"

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "Installing MongoDB client"

mongo --host $MONGODB_HOST </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "Loading catalogue data into MongoDB"

