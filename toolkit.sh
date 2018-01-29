#!/bin/bash

# Initial Setup: Fill out config.json and add required python packages to requirements.txt
# Build -> Run this to install all requiremed packages using the lambdaci container. Packages are added to the ./src folder.
# Pack -> Package necessary files in the ./src directory to a zip file excluding folder and files. Zipped package is added to the ./dist folder.
# Upload -> Checks for existing lambda. Create if it doesn't exist or Update if it exists.
# Test -> Run lambda and output results to local logs.

function readJson {  
  UNAMESTR=`uname`
  if [[ "$UNAMESTR" == 'Linux' ]]; then
    SED_EXTENDED='-r'
  elif [[ "$UNAMESTR" == 'Darwin' ]]; then
    SED_EXTENDED='-E'
  fi; 

  VALUE=`grep -m 1 "\"${2}\"" ${1} | sed ${SED_EXTENDED} 's/^ *//;s/.*: *"//;s/",?//'`

  if [ ! "$VALUE" ]; then
    echo "Error: Cannot find \"${2}\" in ${1}" >&2;
    exit 1;
  else
    echo $VALUE ;
  fi; 
}


NAME=`readJson config.json name` || exit 1;
HANDLER=`readJson config.json handler` || exit 1;
REGION=`readJson config.json region` || exit 1;
ROLE=`readJson config.json role` || exit 1;
RUNTIME=`readJson config.json runtime` || exit 1;
TIMEOUT=`readJson config.json timeout` || exit 1;
MEMORY=`readJson config.json memory` || exit 1;
TIMESTAMP="`date +%Y%m%d%H%M%S`";

echo "START OF LOG" > log/toolkit-$TIMESTAMP.txt

if [ $1 == "build" ]
then
    echo
    QUESTION="Have you filled in the requirements.txt file properly? (y/n) "
    echo $QUESTION >> log/toolkit-$TIMESTAMP.txt
    read -p "$QUESTION" -n 1 -r
    echo
    echo "User Input Recorded: $REPLY " >> log/toolkit-$TIMESTAMP.txt
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        echo
        echo "Installing required packages..." | tee -a log/toolkit-$TIMESTAMP.txt
        docker run -it -v $PWD:/host/user -e "USER=$USER" -e "HOME=/host/user" --rm -w /host/user lambci/lambda:build-python3.6 bash -c "pip3 install -r requirements.txt -t ./src" >> log/toolkit-$TIMESTAMP.txt
        echo
        echo "All packages installed." | tee -a log/toolkit-$TIMESTAMP.txt
        echo
    fi
fi

if [ $1 == "pack" ]
then
    echo
    echo Packaging lambda... | tee -a log/toolkit-$TIMESTAMP.txt
    echo
    cd src
    zip -r --exclude=*.dist-info* --exclude=*.vscode* --exclude=*pycache* --exclude=*.git --exclude=*.zip ../dist/lambda_function.zip . >> ../log/toolkit-$TIMESTAMP.txt
    echo "Packaging complete. The zip file can be found in the dist folder." | tee -a ../log/toolkit-$TIMESTAMP.txt
    cd ..
    echo
fi

if [ $1 == "upload" ]
then
    echo
    echo "Checking if lambda exists." | tee -a log/toolkit-$TIMESTAMP.txt
    echo
    LAMBDA=$(aws lambda get-function --function-name $NAME 2>> log/toolkit-$TIMESTAMP.txt)
    echo $LAMBDA >> log/toolkit-$TIMESTAMP.txt
    if [[ $LAMBDA = *"Configuration"* ]]
    then
        QUESTION="A lambda already exists with this name. Do you wish to update (y/n) "
        echo $QUESTION >> log/toolkit-$TIMESTAMP.txt
        read -p "$QUESTION" -n 1 -r
        echo "User Input Recorded: $REPLY " >> log/toolkit-$TIMESTAMP.txt
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo
            echo Updating lambda code... | tee -a log/toolkit-$TIMESTAMP.txt
            echo
            RESULT=$(aws lambda update-function-code --function-name $NAME --zip-file fileb://dist/lambda_function.zip)
            echo $RESULT >> log/toolkit-$TIMESTAMP.txt
            if [[ $RESULT = *"FunctionName"* ]]
            then
                echo "The lambda was updated successfully." | tee -a log/toolkit-$TIMESTAMP.txt
                echo
            else
                echo "The lambda was not updated successfully. Please inspect the logs." | tee -a log/toolkit-$TIMESTAMP.txt
                echo
            fi
            >> log/toolkit-$TIMESTAMP.txt
        else
            echo
            echo "The lambda was not uploaded." | tee -a log/toolkit-$TIMESTAMP.txt
            echo
        fi
    else
        QUESTION="No lambda exists with this name. Do you wish to create (y/n) "
        echo $QUESTION >> log/toolkit-$TIMESTAMP.txt
        read -p "$QUESTION" -n 1 -r
        echo "User Input Recorded: $REPLY " >> log/toolkit-$TIMESTAMP.txt
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
            echo
            echo Creating lambda... | tee -a log/toolkit-$TIMESTAMP.txt
            echo
            RESULT=$(aws lambda create-function --function-name $NAME --region $REGION --zip-file fileb://dist/lambda_function.zip --role $ROLE --handler $HANDLER --runtime $RUNTIME --timeout $TIMEOUT --memory-size $MEMORY)
            echo $RESULT >> log/toolkit-$TIMESTAMP.txt
            if [[ $RESULT = *"FunctionName"* ]]
            then
                echo "The lambda was created successfully." | tee -a log/toolkit-$TIMESTAMP.txt
                echo
            else
                echo "The lambda was not created successfully. Please inspect the logs." | tee -a log/toolkit-$TIMESTAMP.txt
                echo
            fi
        else
            echo
            echo "The lambda was not uploaded." | tee -a log/toolkit-$TIMESTAMP.txt
            echo
        fi
    fi
fi

if [ $1 == "test" ]
then
    echo
    echo Testing lambda... | tee -a log/toolkit-$TIMESTAMP.txt
    echo
    # docker run --rm -v $PWD:/var/task lambci/lambda:build-python3.6 /bin/sh -c $HANDLER
    aws lambda invoke --invocation-type RequestResponse --function-name $NAME --region $REGION --log-type Tail log/run-$TIMESTAMP.txt >> log/toolkit-$TIMESTAMP.txt
    echo Run complete. | tee -a log/toolkit-$TIMESTAMP.txt
    echo 
    echo To see output of lambda go to $PWD/log/run-$TIMESTAMP.txt | tee -a log/toolkit-$TIMESTAMP.txt
    echo
fi 
echo To see logs go to $PWD/log/toolkit-$TIMESTAMP.txt | tee -a log/toolkit-$TIMESTAMP.txt
echo