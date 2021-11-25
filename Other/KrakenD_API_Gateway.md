---
title: KrakendD API Gateway
date: 2021-11-25 18:00:26
updated: 2021-11-25 18:00:26
tags:
    - krakend
    - kong
    - api gateway
category: 
    - other
---

## Introduce

- Docker hub: [https://hub.docker.com/r/devopsfaith/krakend](https://hub.docker.com/r/devopsfaith/krakend)
- Web page: [https://www.krakend.io](https://www.krakend.io)
- Github: [https://github.com/luraproject/lura](https://github.com/luraproject/lura)

## Note

- When install, It doesn't need a database for persisting config. (Don't like Kong API Gateway, which needs an SQL database). All endpoint & routing configs will storage in a SINGLE json file.
- Sample config file: [https://github.com/devopsfaith/krakend-ce/blob/master/krakend.json](https://github.com/devopsfaith/krakend-ce/blob/master/krakend.json)
- KrakenD don't support admin web API for config. In order to generate JSON config, You need access here [https://designer.krakend.io/](https://designer.krakend.io), Create it online => download it => moves it to the directory config of krakenD when startup. (Hope that in the future, We will have web admin for that, like as KongHQ)
- We have a command for validate the json config file
- If you want to customize something, like extract metric/log for request/response (more detailed compared to default), you need to know GoLang syntax.
- It is very easy to config `rate limit` via IP or Header. This is the default feature, that don't need to install any more plugins.
- The config by `SINGLE` json files, special is `endpoint` is very "manual", many boilerplate. EX:
    - We need to declare each HTTP Method (GET/POST/DELETE...). We can't group by it in one line. 
- Metric is very poor: It only supports the metric for the number hit to each endpoint. (total fails, total passes...)
- Log info is very poor. In `production` mode, the log info is only the access to the endpoint (Has IP, When I lab, It only a private IP, I don't sure it support Public IP). We can't extract request/response body, even header info not. As I searched, the authors of KrakenD said have a plugin for extracting more info, but they also warning we should not use it in a live environment. Because performance is low. 
- KrakenD has a tending the restrict all by default. If you want to `whitelist` some config, you need to define it clearly. For example: If the API request will be authentication by `X-Token` Header, You need to declare the `X-Token` in while-list (headers_to_pass property), if not `X-Token` value will not forward to the backend. The same thing will happen with `Accept`,`Content-Type` headers.

## Performance

- According to advertisement, krakenD is better than Kong (lab: not yet)
- Key is reactive (lab: not lab)



