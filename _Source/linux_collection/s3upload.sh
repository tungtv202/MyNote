
# https://docs.aws.amazon.com/cli/latest/reference/s3api/put-object.html
if [ -z "$2" ]
SUFFIX=""
then
    SUFFIX="tmp/$1"
else
    SUFFIX=$2
    
fi
aws s3api put-object --bucket tungexplorer --acl public-read --key $SUFFIX --body $1 > /tmp/awslog.txt
echo "https://tungexplorer.s3.ap-southeast-1.amazonaws.com/$SUFFIX"