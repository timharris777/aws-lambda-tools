# aws-lambda-tools-python

Before using this tool the following needs to be done:

1. Install the aws-cli: `brew install awscli`
1. Install docker
1. Install docker container: `docker pull lambci/lambda:build-python3.6`

In order to use the tool do the following:

1. Clone aws-lambda-tools-python repo `git clone https://github.com/timharris777/aws-lambda-tools.git`
1. Open config.json and edit appropriatly.
1. Add required python packages to requirements.txt
1. Edit ./src/lambda_function.py as it is your lambda file.
1. Make sure you are logged in to your aws account via aws-cli
1. Use the toolkit.sh file as follows:
    
    **./toolkit.sh build** -> This will use the lambci docker container to build python packages that are compatible with AWS architecture.

    **./toolkit.sh pack** -> This will package everything into a zip file and dump it in the ./dist folder.

    **./toolkit.sh upload** -> This will check if there is already a lambda with the current name. If so it will update the existing one, else it will create a new one.

    **./toolkit.sh test** -> This will run the lambda and output the results to local files in the ./log folder.

Thanks!