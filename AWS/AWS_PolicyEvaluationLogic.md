---
title: AWS - Policy Evaluation Logic
date: 2019-12-21 18:00:26
updated: 2019-12-21 18:00:26
tags:
    - aws
    - evaluation logic
category: 
    - aws
---

# Policy Evaluation Logic

- If a request is denied, it is definitively denied, regardless of any allow rule for the object/bucket.
- If a request is not denied, it does not necessarily mean it is allowed; explicit allow must be defined for it to be granted.
- Reference: [AWS IAM Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html)
- IAM Policy is like a driver's license that permits you to drive a car; whether or not you are allowed to enter a certain place (e.g., an S3 bucket) depends on the policies set for that place.

![PolicyEvaluate](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/PolicyEvaluationHorizontal.png)

![Policy2](https://tungexplorer.s3.ap-southeast-1.amazonaws.com/aws/policy2.JPG)

- Cross-Account Policy Evaluation Logic has its own evaluation logic.
  Reference: [Cross-Account Policy Evaluation Logic](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic-cross-account.html)
