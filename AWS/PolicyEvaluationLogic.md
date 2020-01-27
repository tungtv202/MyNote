# Policy Evaluation Logic
- đã deny thì chắc chắn bị deny cho dù có rule allow cho object/bucket đó.
- ko deny thì chưa chắc đã allow, cần define rõ thì mới allow đc.
- ref : https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
- IAM Policy giống như việc bạn được cấp 1 giấy phép lái xe ô tô, nghĩa là bạn được quyền ngồi lên ô tô và lái xe đi; còn S3 là nơi bạn muốn lái xe đến, chỗ đó có cho phép bạn vào hay không thì tùy thuộc vào Policy ở đấy.       

![PolicyEvaluate](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/PolicyEvaluationHorizontal.png)

![Policy2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/policy2.JPG)
- Cross-Account Policy Evaluation Logic: sẽ có 1 logic evaluate riêng
https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic-cross-account.html
