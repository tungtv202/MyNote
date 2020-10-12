---
title: Code Template - Google Translate
date: 2020-03-10 18:00:26
tags:
    - code template
    - google translate
    - translate
category: 
    - code_template
---

```java
package com.mservice;

import com.google.cloud.translate.Detection;
import com.google.cloud.translate.Translate;
import com.google.cloud.translate.TranslateOptions;
import com.google.cloud.translate.Translation;

import java.util.ArrayList;
import java.util.List;

public class TestGoogleTranslate {

    /*  
        <dependency>
            <groupId>com.google.cloud</groupId>
            <artifactId>google-cloud-translate</artifactId>
            <version>1.94.4</version>
        </dependency>
    */

    public static final String KEY = "gooogle_api_key";
    public static final String TEXT = "秋冬重磅货意大利软糯加厚大衣女中长款外套连帽过膝开襟开衫女 \n 开襟开衫女";
    public static final String TEXT2 = "hello";

    public static void main(String[] args) {
        Translate translate = TranslateOptions.newBuilder().setApiKey(KEY).build().getService();
        List<String> temp = new ArrayList<>();
        temp.add("秋冬重磅货意大利软糯加厚大衣女中长款外套连帽过膝开襟开衫女");
        temp.add("开襟开衫女");

        List<Translation> temp2 = translate.translate(temp, Translate.TranslateOption.sourceLanguage("zh-CN"),
                Translate.TranslateOption.targetLanguage("vi"));

        Detection detection = translate.detect(TEXT);
        String detectedLanguage = detection.getLanguage();
        Translation translation = translate.translate(TEXT, Translate.TranslateOption.sourceLanguage("zh-CN"),
                Translate.TranslateOption.targetLanguage("vi"));
        System.out.println(translation.getTranslatedText());
    }

}
```