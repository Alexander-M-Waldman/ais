#!/usr/bin/env bash

EB_ENVS=$(eb list)

get_prod_env() {
  __ENV_VAR_NAME=$1
  __ENV_STATUS_NAME=$2

  # Find the environment that is either marked as staging or ready to swap in.
  for env in $EB_ENVS ; do
    # Trim carriage returns (\r) off of the env name. On windows, bash will 
    # strip the new-line (\n) characters but leave the \r.
    trimmed_env=$(echo $env | tr -d '\r')
    url=$(eb status $trimmed_env)
    vars=$(eb printenv $trimmed_env)

    echo "$url" | grep --quiet "ais-api-prod.us-east-1.elasticbeanstalk.com"
    if [ $? -eq 0 ] ; then
      eval "export $__ENV_VAR_NAME=$trimmed_env"
      echo $vars | grep --quiet "EB_BLUEGREEN_STATUS = Production"
      if [ $? -eq 0 ] ; then
          eval "export $__ENV_STATUS_NAME=Production"
          return 0
      fi
    fi
  done
  # If no environment is found, return with an error.
  return 1
}

get_staging_env() {
  __ENV_VAR_NAME=$1
  __ENV_STATUS_NAME=$2

  # Find the environment that is either marked as staging or ready to swap in.
  for env in $EB_ENVS ; do
    # Trim carriage returns (\r) off of the env name. On windows, bash will 
    # strip the new-line (\n) characters but leave the \r.
    trimmed_env=$(echo $env | tr -d '\r')
    url=$(eb status $trimmed_env)
    vars=$(eb printenv $trimmed_env)

    echo "$url" | grep --quiet "ais-api-staging.us-east-1.elasticbeanstalk.com"
    if [ $? -eq 0 ] ; then
      eval "export $__ENV_VAR_NAME=$trimmed_env"
      echo $vars | grep --quiet "EB_BLUEGREEN_STATUS = Staging"
      if [ $? -eq 0 ] ; then
          eval "export $__ENV_STATUS_NAME=Staging"
          return 0
      fi
      echo $vars | grep --quiet "EB_BLUEGREEN_STATUS = Swap"
      if [ $? -eq 0 ] ; then
          eval "export $__ENV_STATUS_NAME=Swap"
          return 0
      fi
    fi
  done

  # If no environment is found, return with an error.
  return 1
}

get_test_env() {
  __ENV_VAR_NAME=$1
  __ENV_STATUS_NAME=$2

  # Find the environment that is marked to swap in.
  for env in $EB_ENVS ; do
    # Trim carriage returns (\r) off of the env name. On windows, bash will 
    # strip the new-line (\n) characters but leave the \r.
    trimmed_env=$(echo $env | tr -d '\r')
    url=$(eb status $trimmed_env)
    vars=$(eb printenv $trimmed_env)
    echo "$url" | grep --quiet "ais-api-staging.us-east-1.elasticbeanstalk.com"
    if [ $? -eq 0 ] ; then
      eval "export $__ENV_VAR_NAME=$trimmed_env"
      echo $vars | grep --quiet "EB_BLUEGREEN_STATUS = Swap"
      if [ $? -eq 0 ] ; then
          eval "export $__ENV_STATUS_NAME=Swap"
          return 0
      fi
    fi
  done

  # If none is marked to swap, then use the environment marked as production.
  for env in $EB_ENVS ; do
    trimmed_env=$(echo $env | tr -d '\r')
    url=$(eb status $trimmed_env)
    vars=$(eb printenv $trimmed_env)
    echo "$url" | grep --quiet "ais-api-prod.us-east-1.elasticbeanstalk.com"
    if [ $? -eq 0 ] ; then
      eval "export $__ENV_VAR_NAME=$trimmed_env"
      echo $vars | grep --quiet "EB_BLUEGREEN_STATUS = Production"
      if [ $? -eq 0 ] ; then
          eval "export $__ENV_STATUS_NAME=Production"
          return 0
      fi
    fi
  done

  # If no environment is found, return with an error.
  return 1
}