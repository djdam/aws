#!/bin/bash
if [ $# -eq 0 ]
then
  echo "Usage: authenticate.sh <user.json file>"
  echo " See https://medium.com/@blipchin/life-is-too-short-not-to-test-your-api-served-from-aws-with-postman-713f7018ef8c"
  exit 1
fi
AUTH_POOL_ID=$(aws cognito-identity list-identity-pools --max-results 20 | grep IdentityPoolId | cut -d "\"" -f 4)
echo "Auth pool id is $AUTH_POOL_ID"
SESSION_ID=$(aws cognito-idp initiate-auth --cli-input-json file://$1.json  | grep "\"IdToken" | cut -d ":" -f 2 | cut -d "\"" -f 2)
echo "Session id is $SESSION_ID"
ACCOUNT_ID=$(aws sts get-caller-identity | grep Account | cut -d "\"" -f4)
echo "Account id is $ACCOUNT_ID"
AUTH_PROVIDER_NAME=$(aws cognito-identity describe-identity-pool --identity-pool-id $AUTH_POOL_ID | grep ProviderName -m1 | cut -d "\"" -f4)
echo "Auth provider name is $AUTH_PROVIDER_NAME"
AWS_TEMP_JSON="/tmp/aws_login_info.json"
cat <<EOT > $AWS_TEMP_JSON
{
  "AccountId": "$ACCOUNT_ID",
  "IdentityPoolId": "$AUTH_POOL_ID",
  "Logins": {"$AUTH_PROVIDER_NAME": "$SESSION_ID"}
}
EOT
echo "Generated get-id json is:\n $(cat $AWS_TEMP_JSON)"
IDENTITY_ID=$(aws cognito-identity get-id --cli-input-json "file://$AWS_TEMP_JSON" | grep "IdentityId" | cut -d "\"" -f4)
echo "Identity id is $IDENTITY_ID"
cat <<EOT > $AWS_TEMP_JSON
{
 "IdentityId": "$IDENTITY_ID",
 "Logins": { "$AUTH_PROVIDER_NAME": "$SESSION_ID" }
}
EOT
aws cognito-identity get-credentials-for-identity --cli-input-json "file://$AWS_TEMP_JSON"
