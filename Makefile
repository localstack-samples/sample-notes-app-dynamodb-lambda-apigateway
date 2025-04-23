export AWS_ACCESS_KEY_ID ?= test
export AWS_SECRET_ACCESS_KEY ?= test
export AWS_DEFAULT_REGION=us-east-1
SHELL := /bin/bash

## Show this help
usage:
		@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'

## Check if all required prerequisites are installed
check:
	@command -v docker > /dev/null 2>&1 || { echo "Docker is not installed. Please install Docker and try again."; exit 1; }
	@command -v node > /dev/null 2>&1 || { echo "Node.js is not installed. Please install Node.js and try again."; exit 1; }
	@command -v aws > /dev/null 2>&1 || { echo "AWS CLI is not installed. Please install AWS CLI and try again."; exit 1; }
	@command -v localstack > /dev/null 2>&1 || { echo "LocalStack is not installed. Please install LocalStack and try again."; exit 1; }
	@command -v cdk > /dev/null 2>&1 || { echo "CDK is not installed. Please install CDK and try again."; exit 1; }
	@command -v cdklocal > /dev/null 2>&1 || { echo "cdklocal is not installed. Please install cdklocal and try again."; exit 1; }
	@command -v yarn > /dev/null 2>&1 || { echo "Yarn is not installed. Please install Yarn and try again."; exit 1; }
	@command -v aws > /dev/null 2>&1 || { echo "AWS CLI is not installed. Please install AWS CLI and try again."; exit 1; }
	@command -v awslocal > /dev/null 2>&1 || { echo "awslocal is not installed. Please install awslocal and try again."; exit 1; }
	@echo "All required prerequisites are available."

## Install dependencies
install:
		@if [ ! -d "node_modules" ]; then \
			echo "node_modules not found. Running yarn install..."; \
			yarn install; \
		fi
		@echo "All required dependencies are available."

## Build and deploy the frontend
frontend:
		yarn prepare:frontend-local
		yarn build:frontend
		yarn cdklocal bootstrap --app="node dist/aws-sdk-js-notes-app-frontend.js"
		yarn cdklocal deploy --app="node dist/aws-sdk-js-notes-app-frontend.js"
		@distributionId=$$(awslocal cloudfront list-distributions | jq -r '.DistributionList.Items[0].Id') && \
		echo "Access the frontend at: http://localhost:4566/cloudfront/$$distributionId/"

## Deploy the infrastructure
deploy:
		yarn build:backend;
		yarn cdklocal bootstrap;
		yarn cdklocal deploy;

## Run the tests
test:
		yarn test

## Start LocalStack in detached mode
start:
		localstack start -d

## Stop the Running LocalStack container
stop:
		@echo
		localstack stop

## Make sure the LocalStack container is up
ready:
		@echo Waiting on the LocalStack container...
		@localstack wait -t 30 && echo LocalStack is ready to use! || (echo Gave up waiting on LocalStack, exiting. && exit 1)

## Save the logs in a separate file
logs:
		@localstack logs > logs.txt

.PHONY: usage install check start ready deploy frontend logs stop
