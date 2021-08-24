
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-object.html
aws s3api put-object --bucket tungexplorer --acl public-read --key $2 --body $1
echo "https://tungexplorer.s3.ap-southeast-1.amazonaws.com/$2"