---
title: Java - Junit Test
date: 2018-10-12 18:00:26
updated: 2021-08-25 18:00:26
tags:
    - junit
    - mockito
    - unit test
    - java
category: 
    - java
---
# Java - Junit Test

## 1. Junit Anotation
- Todo something before/after something
```java
//  org.junit
@BeforeClass 
@Before 
@After  
@AfterClass 
```

```java
// org.junit.jupiter.api
@BeforeEach
@BeforeAll  
@AfterEach
@AfterAll
```

- Test
```java
@Test
@RepeatTest(10) 
@ParameterizedTest
```

- Group, Tag, Other...
```java
@Tag
@Nested
@Disabled
@DisplayName
@TempDir  
```

## 2. Assert action
- Assert action
    - assertEquals 
    - assertFalse
    - assertNotNull 
    - assertNotSame 
    - assertNull
    - assertSame 
    - assertTrue
    - isTrue
    - isFalse
    - isNotNull


- Assert for collection
    - isEmpty
    - containsOnly
    - hasSameElementsAs
    - hasSize
    - containsExactlyInAnyOrder
    - contains
    - doesNotContain


- Assert Exception
```java
        assertThatCode(() -> Mono.from(testee().clear(generateMailboxId())).block())
            .doesNotThrowAnyException();
```

```java
        assertThatThrownBy(() -> blobStore.read(DEFAULT_BUCKET, blobId))
            .isInstanceOf(ObjectNotFoundException.class)
```

```java 
        // expect message of exception
        assertThatThrownBy(() -> testee().addUser(TestFixture.INVALID_USERNAME, "password"))
            .isInstanceOf(InvalidUsernameException.class)
            .hasMessageContaining("should not contain any of those characters");
```

- Assert softly

```java
        SoftAssertions.assertSoftly(softly -> {
            softly.assertThat(imapUidDAO.retrieveAllMessages().collectList().block())
                .containsExactlyInAnyOrder(MESSAGE_1);
            softly.assertThat(Flux.from(pop3MetadataStore.listAllEntries()).collectList().block())
                .containsExactlyInAnyOrder(new Pop3MetadataStore.FullMetadata(MAILBOX_ID, STAT_METADATA_1));
        });
```


# 3. Mockito
- Manual way

```java
BlobStoreDAO blobStoreDAO = mock(BlobStoreDAO.class);
when(blobStoreDAO.listBlobs(DEFAULT_BUCKET)).thenReturn(Flux.just(blobId));
when(blobStoreDAO.delete(DEFAULT_BUCKET, blobId)).thenThrow(new RuntimeException("test"));
```

- Annotation way

```java
@InjectMocks 
@Mock
//@InjectMocks: require MockitoJUnitRunner 
```

## 4. RestAPI Testing
### Using `io.rest-assured`
- [io.rest-assured](https://mvnrepository.com/artifact/io.rest-assured/rest-assured)
```xml
        <dependency>
            <groupId>io.rest-assured</groupId>
            <artifactId>rest-assured</artifactId>
        </dependency>
```
1. Build base
```java
    public static RestAssuredConfig defaultConfig() {
        return newConfig().encoderConfig(encoderConfig().defaultContentCharset(StandardCharsets.UTF_8));
    }

    RestAssured.requestSpecification  = new RequestSpecBuilder()
                .setContentType(ContentType.JSON)
                .setAccept(ContentType.JSON)
                .setConfig(defaultConfig())
                .setPort(port)
                .setBasePath("/")
                .log(LogDetail.ALL)
                .build();
```

2. Using

- Check error (ex: 404)
- Error response is Json

```java
import static org.assertj.core.api.Assertions.assertThat;

Map<String, Object> errors = 
            when()
                .get("/user/myuser1")
            .then()
                .statusCode(NOT_FOUND_404)
                .contentType(JSON)
                .extract()
                .body()
                .jsonPath()
                .getMap(".");

            assertThat(errors)
                .containsEntry("statusCode", NOT_FOUND_404)
                .containsEntry("type", ERROR_TYPE_NOTFOUND)
                .containsEntry("message", "Invalid get on user");
```


- Check value of body

```java
                given()
                    .basePath("/basepath/")
                .when()
                    .get(taskId + "/await")
                .then()
                    .statusCode(HttpStatus.OK)
                    .body("status", Matchers.is("completed"))
                    .body("taskId", Matchers.is(notNullValue()))
                    .body("type", Matchers.is(ClearMailboxContentTask.TASK_TYPE.asString()))
                    .body("startedDate", Matchers.is(notNullValue()))
                    .body("submitDate", Matchers.is(notNullValue()))
                    .body("completedDate", Matchers.is(notNullValue()))
                    .body("additionalInformation.username", Matchers.is(USERNAME.asString()));
```

- Get value of one property

```java
            String taskId = when()
                .delete(MAILBOX_NAME + "/messages")
            .then()
                .statusCode(CREATED_201)
                .extract()
                .jsonPath()
                .get("taskId");

            assertThat(taskId)
                .isNotEmpty();
```

- Compare json 

```java
val response: String = `given`
      .body("json value here")
    .when()
      .post()
    .`then`
      .statusCode(HttpStatus.SC_OK)
      .contentType(JSON)
      .extract()
      .body()
      .asString()

    assertThatJson(response)
      .isEqualTo(
        s"""
           |{
           |    "sessionState": "${SESSION_STATE.value}",
           |    "methodResponses": [
           |        [
           |            "Email/send",
           |            {
           |                "accountId": "$ACCOUNT_ID",
           |                "newState": "$${json-unit.ignore}",
           |                "created": {
           |                    "K87": {
           |                        "emailSubmissionId": "$${json-unit.ignore}",
           |                        "emailId": "$${json-unit.ignore}",
           |                        "blobId": "$${json-unit.ignore}",
           |                        "threadId": "$${json-unit.ignore}",
           |                        "size": "$${json-unit.ignore}"
           |                    }
           |                }
           |            },
           |            "c1"
           |        ]
           |    ]
           |}""".stripMargin)
```
    - `$${json-unit.ignore}` for ignore compare value

- Set queryParam for request

```java
        given()
            .queryParam("task", "purge")
            .queryParam("olderThan", "15days")
            .post()
        .then()
            .statusCode(HttpStatus.CREATED_201)
            .body("taskId", notNullValue());
```

## 5. ConditionFactory

```java
    ConditionFactory CALMLY_AWAIT = Awaitility
        .with().pollInterval(ONE_HUNDRED_MILLISECONDS)
        .and().pollDelay(ONE_HUNDRED_MILLISECONDS)
        .await()
        .atMost(TEN_SECONDS);

    @Test
    void testConditionFactory() {
        CALMLY_AWAIT.untilAsserted(() -> {
            Random random = new Random();

            assertThat(random.nextInt(10))
                .isEqualTo(7);
        });
    }    
```

## 6. RegisterExtension
- Pojo
```java
class CombinedTestSystem {
        private final boolean supportVirtualHosting;
        private final SimpleDomainList domainList;
        private final Username userAlreadyInLDAP;
        private final Username userAlreadyInLDAP2;
        private final Username userWithUnknowDomain;
        private final Username invalidUsername;

        public CombinedTestSystem(boolean supportVirtualHosting) throws Exception {
            // todo
        }

        private Username toUsername(String login) {
            return toUsername(login, DOMAIN);
        }
    }
```

- Extension

```java
class CombinedUserRepositoryExtension implements BeforeEachCallback, ParameterResolver {

        private final boolean supportVirtualHosting;
        private CombinedTestSystem combinedTestSystem;

        private CombinedUserRepositoryExtension(boolean supportVirtualHosting) {
            this.supportVirtualHosting = supportVirtualHosting;
        }

        @Override
        public void beforeEach(ExtensionContext extensionContext) throws Exception {
            combinedTestSystem = new CombinedTestSystem(supportVirtualHosting);
        }

        @Override
        public boolean supportsParameter(ParameterContext parameterContext, ExtensionContext extensionContext) throws ParameterResolutionException {
            return parameterContext.getParameter().getType() == CombinedTestSystem.class;
        }

        @Override
        public Object resolveParameter(ParameterContext parameterContext, ExtensionContext extensionContext) throws ParameterResolutionException {
            return combinedTestSystem;
        }

        public boolean isSupportVirtualHosting() {
            return supportVirtualHosting;
        }
    }
```

- Using
```java
  @RegisterExtension
  CombinedUserRepositoryExtension combinedExtension = CombinedUserRepositoryExtension...

  @BeforeEach
  void setUp(CombinedTestSystem testSystem) {
          //todo
  }

  @Test
  void test1(CombinedTestSystem testSystem) {
      // todo
  }
```

## 7. ParameterizedTest
```java
    static Stream<Arguments> storageStrategies() {
        return Stream.of(
            Arguments.of(DEDUPLICATION_STRATEGY),
            Arguments.of(PASSTHROUGH_STRATEGY)
        );
    }

    @ParameterizedTest
    @MethodSource("storageStrategies")
    void test(BlobStoreConfiguration blobStoreConfiguration) {
        // todo something
    }
```

## 8. Compare Json

```java
import net.javacrumbs.jsonunit.assertj.JsonAssertions.assertThatJson

 assertThatJson(response).isEqualTo(
      s"""{
         |  "sessionState":"${SESSION_STATE.value}",
         |  "methodResponses": [
         |    ["error", {
         |      "type": "unknownMethod",
         |      "description": "Missing capability(ies)"
         |    },"c1"]
         |  ]
         |}""".stripMargin)


    //
     assertThatJson(response)
      .whenIgnoringPaths("methodResponses[0][1].description")
      .isEqualTo(...)

    //
     assertThatJson(response)
      .inPath("methodResponses[0][1]")
      .isEqualTo(...)

```

