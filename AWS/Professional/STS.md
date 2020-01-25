# AWS `Security Token Service`
- Giống với việc sử dụng accesskey + secretKey (đã được gán role, permission...) để access vào resource. Nhưng khác là accessKey,secretKey của STS thì có `expire time`
## 1. Implementation
### 1.1 Step Overview
- Step 1. Create a Cross Account Role in IAM
- Step 2. Attach a S3ReadOnly policy to that IAM Role (`S3ReadOnly` chỉ là ví dụ)
- Step 3. Allow user to  `Assume Role` with STS
- Step 4. Remove all other policy from user except `Assume Role`
### 1.2 Create IAM Account
![STS_CreateAccount](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/sts/STS_CreateUser.JPG)
- Tại client (client dùng awscli), kiểm tra với `aws s3 ls` để đảm bảo hiện tại client không thể access vào resource S3 
```
An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
```
### 1.3 Create IAM Role
https://console.aws.amazon.com/iam/home?region=us-east-2#/roles$new?step=type&roleType=crossAccount
- Role type: `Another AWS Account`
    - Input `Account ID*`
- Attach permissions policies    
    - S3ReadOnly
    ![STS_CreateRole](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/sts/STS_CreateRole.JPG)
```
arn:aws:iam::168146697673:role/sts_role_1
```
### 1.4 Set Role to IAM Account
- Add permission
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::168146697673:role/sts_role_1"
        }
    ]
}
```

### 1.5 Generate STS
```bash
aws sts assume-role --role-arn arn:aws:iam::168146697673:role/sts_role_1 --role-session-name tungexplorer
```
- result example    
![STS_Generate](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/sts/STS_GenerateSTS.JPG)
- // có thể truyền thêm param để set `duration time` cho sts sinh ra

### 1.6 Sử dụng STS tại client
- Ex: client dùng aws cli
- `nano .aws/credential`
```bash
[sts_user_1]
aws_access_key_id       = ASIASOJSS7XE6Y7LZWUJ
aws_secret_access_key   = rhWjBXKA+54vhliP7lYw96ISMJko6RdQK7c+wjjj
aws_session_token       = FwoGZXIvYXdzEPL//////////wEaDK2sBRQ4KgL8M5xLECKwAaeA18ks+90pnrgFDGGriH9cN2GW/5hz3giGZZX/Kn3d9UkPz9N+Iz2Mtv35bI2mj13Ad5imOZZOEL1QwPsAIXMcDxKKiwoQW31u8sX6yfxWFbQS$
```
- Test `sts`
```bash
aws s3 ls --profile sts_user_1
```
```bash
# Example result
ubuntu@tungexplorer:~$ aws s3 ls --profile sts_user_1
2020-01-25 13:12:52 config-bucket-168146697673
2020-01-25 13:04:09 elasticbeanstalk-ap-east-1-168146697673
2019-09-24 03:09:42 no-see-20190924
2019-09-24 02:14:22 ocr-test-20190924
2019-09-27 05:49:15 test-flog-log-20190927
```

## 2. Use case
- **Console Access with Broker**    

`Use Case`: SSO to IAM console access using local directory service; no SAML

`Flow`: User Requests browses to proxy; auth against directory which returns group membership; proxy gets list of roles from groups via STS; user selects role; proxy calls STS:AssumeRole then returns auth package; proxy generates console redirect.

`Con`: IAM user required for proxy server

- **API Access with Broker**

`Use Case`: an app needs access to AWS resources via API; no SAML

`Flow`: App requests session from proxy; auth against directory which returns entitlements; proxy requests session from STS using STS:GetFederationToken; STS returns session; app calls AWS API using session

`Cons`: The IAM user associated to the proxy must have GetFederationToken policy and all the premissions for all of the users; and GetFederationToken does not support MFA

- **AssumeRole with SAML**          

`Use Case`: SSO to IAM console without proxy server against AD or other SAML IdP

`Background`: AD and it’s hosted version AWS Directory Service, LDAP and SAML can be integrated into IAM; generally you map groups in the ID provider to IAM roles

`Flow`: Auth with IdP which returns SAML token; with token in-hand the user is redirected to AWS sign-in endpoint for SAML at https://signin.aws.amazon.com/saml; the endpoint calls AssumeRoleWithSAML then creates and passes the user a console URL redirect; Roles must be configured to include the “saml:group”: “groupname”

`Pro`: No dedicated proxy on the corporate side and the proxy requires no IAM user or permissions

ref: http://ric.mclaughlin.today/posts/aws-sts
