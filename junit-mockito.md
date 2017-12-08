# Junit + Mockito wikipedia
```
<!-- Topic trình bày cách dùng, lưu trữ code mẫu, thư viện của Junit, Mockito, SpringMVC Test -->
```
## 1. Junit

Là 1 thư viện testing của Java. Mục đích cuối cùng là để kiểm thử xem kết quả của các phương thức có chạy đúng với logic + kết quả mong muốn.

*Import bằng maven sau*
```java
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.11</version>
    <scope>test</scope>
</dependency>
```

* Cần annotation trước phương thức test. Ngoài ra còn có thể thêm các annotation chỉ định những việc phải làm trước và sau khi test.

```java
@BeforeClass  // ví dụ tạo các biến static
@Before    // gán, set, get, tính logic
@Test    // test
@After  //
@AfterClass // ví dụ đóng kết nối database
```

* Các phương thức Assert()  - cái quyết định kết quả của Junit Test
```java
assertEquals() // So sánh 2 giá trị để kiểm tra bằng nhau. Test sẽ được chấp nhận nếu các giá trị bằng nhau.
assertFalse()  // Test sẽ được chấp nhận nếu biểu thức sai.
assertNotNull() // Test sẽ được chấp nhận nếu tham chiếu đối tượng khác null.
assertNotSame() // Test sẽ được chấp nhận nếu cả 2 đều tham chiếu đến các đối tượng khác nhau
assertNull() // Test sẽ được chấp nhận nếu tham chiếu là null.
assertSame() //  Test sẽ được chấp nhận nếu cả 2 đều tham chiếu đến cùng một đối tượng.
assertTrue() //Test sẽ được chấp nhận nếu biểu thức đúng fail()
```

*Run As Junit Test*

* Muốn chạy nhiều Class Test liên tục, có thể tạo 1 class Test và khai báo như sau:

```java
@RunWith(Suite.class)
@SuiteClasses({CarTest.class, CompanyTest.class})
public class SystemTest{
}
```

# 2. Mockito

* Dùng để giả lập hoạt động (kết quả trả về, action) của các interface. Nó không test trên real object, mà tạo ra một object "ảo" rồi instrument các method mà bạn muốn vào object ảo đó.

```java
Mockito.when(T methodCall)
// dùng để giả lập một lời gọi hàm nào đó được sử dụng bên trong method đang được kiểm thử.  thường đi kèm với .thenReturn(), .thenAnswer(), .thenThrow() để chỉ định kết quả trả lại.
Ví dụ:
Mockito.when(method_A()).thenReturn("demoValue");
Mockito.when(method_B()).thenThrow(new Exception("demoError"));
Mockito.when(method_C()).thenAnswer(new Answer<String>(){ public String answer(InvocationOnMock invocation){ String str = “demoNewAnswer”; return str; } });
```
* Tham khảo các annotation

```java
@InjectMocks 
@Mock
//@InjectMocks: yêu cầu MockitoJUnitRunner tạo đối tượng cho biến,  gán các đối tượng mock cho các thuộc tính bên trong đối tượng này.
```
# 3. Unit Testing of Spring MVC Controllers: REST API

* Maven lib

```java
<dependency>
    <groupId>org.hamcrest</groupId>
    <artifactId>hamcrest-all</artifactId>
    <version>1.3</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>junit</groupId>
    <artifactId>junit</artifactId>
    <version>4.11</version>
    <scope>test</scope>
    <exclusions>
        <exclusion>
            <artifactId>hamcrest-core</artifactId>
            <groupId>org.hamcrest</groupId>
        </exclusion>
    </exclusions>
</dependency>
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>1.9.5</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>org.springframework</groupId>
    <artifactId>spring-test</artifactId>
    <version>3.2.3.RELEASE</version>
    <scope>test</scope>
</dependency>
<dependency>
    <groupId>com.jayway.jsonpath</groupId>
    <artifactId>json-path</artifactId>
    <version>0.8.1</version>
    <scope>test</scope>
</dependency>
// thao tác với Json
<dependency>
    <groupId>com.jayway.jsonpath</groupId>
    <artifactId>json-path-assert</artifactId>
    <version>0.8.1</version>
    <scope>test</scope>
</dependency>
```

**a) Test get List**

* Code phía Controller

```java
@Controller
public class TodoController {
 
    private TodoService service;
 
    @RequestMapping(value = "/api/todo", method = RequestMethod.GET)
    @ResponseBody
    public List<TodoDTO> findAll() {
        List<Todo> models = service.findAll();
        return createDTOs(models);
    }
}
```

Ví dụ kết quả trả về

```json
[
    {
        "id":1,
        "description":"Lorem ipsum",
        "title":"Foo"
    },
    {
        "id":2,
        "description":"Lorem ipsum",
        "title":"Bar"
    }
]
```

Code class Test

```java
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import org.springframework.test.context.web.WebAppConfiguration;
import org.springframework.test.web.servlet.MockMvc;
 
import java.util.Arrays;
 
import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
 
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = {TestContext.class, WebAppContext.class})
@WebAppConfiguration
public class TodoControllerTest {
 
    private MockMvc mockMvc;
 
    @Autowired
    private TodoService todoServiceMock;
 
    @Test
    public void findAll_TodosFound_ShouldReturnFoundTodoEntries() throws Exception {
        Todo first = new TodoBuilder()
                .id(1L)
                .description("Lorem ipsum")
                .title("Foo")
                .build();
        Todo second = new TodoBuilder()
                .id(2L)
                .description("Lorem ipsum")
                .title("Bar")
                .build();
        // khi service todoServiceMock.findAll được gọi, thì Mock sẽ giả lập trả về List do mình tự tạo ra để Test
        when(todoServiceMock.findAll()).thenReturn(Arrays.asList(first, second));
 
        mockMvc.perform(get("/api/todo"))    // Execute a GET request to url ‘/api/todo’
                .andExpect(status().isOk())  // Verify HTTP Status 200 returned
                .andExpect(content().contentType(TestUtil.APPLICATION_JSON_UTF8))
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].id", is(1)))
                .andExpect(jsonPath("$[0].description", is("Lorem ipsum")))
                .andExpect(jsonPath("$[0].title", is("Foo")))
                .andExpect(jsonPath("$[1].id", is(2)))
                .andExpect(jsonPath("$[1].description", is("Lorem ipsum")))
                .andExpect(jsonPath("$[1].title", is("Bar")));
        // xác minh phương thức findAll() chỉ được gọi 1 lần
        verify(todoServiceMock, times(1)).findAll();
        // xác minh rằng không có chỗ nào khác gọi tới service này
        verifyNoMoreInteractions(todoServiceMock);
    }
}
```

**b) Test get Entry**

* code Controller
```java
private TodoService service;

@RequestMapping(value = "/api/todo/{id}", method = RequestMethod.GET)
    @ResponseBody
    public TodoDTO findById(@PathVariable("id") Long id) throws TodoNotFoundException {
        Todo found = service.findById(id);
        return createDTO(found);
    }
```
* Example result
```json
{
    "id":1,
    "description":"Lorem ipsum",
    "title":"Foo"
}
```

* Code Test (case NotFound)

```java
@Test
    public void findById_TodoEntryNotFound_ShouldReturnHttpStatusCode404() throws Exception {
        when(todoServiceMock.findById(1L)).thenThrow(new TodoNotFoundException(""));
 
        mockMvc.perform(get("/api/todo/{id}", 1L))
                .andExpect(status().isNotFound());
 
        verify(todoServiceMock, times(1)).findById(1L);
        verifyNoMoreInteractions(todoServiceMock);
    }
```

* Code Test (case Found)

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = {TestContext.class, WebAppContext.class})
@WebAppConfiguration
public class TodoControllerTest {
 
    private MockMvc mockMvc;
 
    @Autowired
    private TodoService todoServiceMock;
 
    @Test
    public void findById_TodoEntryFound_ShouldReturnFoundTodoEntry() throws Exception {
        Todo found = new TodoBuilder()
                .id(1L)
                .description("Lorem ipsum")
                .title("Foo")
                .build();
 
        when(todoServiceMock.findById(1L)).thenReturn(found);
 
        mockMvc.perform(get("/api/todo/{id}", 1L))
                .andExpect(status().isOk())
                .andExpect(content().contentType(TestUtil.APPLICATION_JSON_UTF8))
                .andExpect(jsonPath("$.id", is(1)))
                .andExpect(jsonPath("$.description", is("Lorem ipsum")))
                .andExpect(jsonPath("$.title", is("Foo")));
 
        verify(todoServiceMock, times(1)).findById(1L);
        verifyNoMoreInteractions(todoServiceMock);
    }
}
```

**c) Test ADD DTO via POST**

* Code phía Controller
```java
private TodoService service;
 
    @RequestMapping(value = "/api/todo", method = RequestMethod.POST)
    @ResponseBody
    public TodoDTO add(@Valid @RequestBody TodoDTO dto) {
        Todo added = service.add(dto);
        return createDTO(added);
    }
```

* Code Class DTO (có ràng buộc về độ dài, và not Empty)

```java
import org.hibernate.validator.constraints.Length;
import org.hibernate.validator.constraints.NotEmpty;
 
public class TodoDTO {
 
    private Long id;
 
    @Length(max = 500)
    private String description;
 
    @NotEmpty
    @Length(max = 100)
    private String title;
    //Constructor and other methods are omitted.
}
```
*Nếu valid faile, thì http trả về mã 400, và Json trả về lỗi, format Json lỗi:*

```json
{
    "fieldErrors":[
        {
            "path":"description",
            "message":"The maximum length of the description is 500 characters."
        },
        {
            "path":"title",
            "message":"The maximum length of the title is 100 characters."
        }
    ]
}
```

* Class Test (Case valid lỗi)

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = {TestContext.class, WebAppContext.class})
@WebAppConfiguration
public class TodoControllerTest {
 
    private MockMvc mockMvc;
 
    @Autowired
    private TodoService todoServiceMock;
 
    @Test
    public void add_TitleAndDescriptionAreTooLong() throws Exception {
        \\ tạo các chuỗi String có kích thước lần lượt là 101 và 501
        String title = TestUtil.createStringWithLength(101); 
        String description = TestUtil.createStringWithLength(501);
 
        TodoDTO dto = new TodoDTOBuilder()
                .description(description)
                .title(title)
                .build();
 
        mockMvc.perform(post("/api/todo")
                .contentType(TestUtil.APPLICATION_JSON_UTF8)
                .content(TestUtil.convertObjectToJsonBytes(dto))
        )
                .andExpect(status().isBadRequest())  //HTTP status code 400 is returned
                .andExpect(content().contentType(TestUtil.APPLICATION_JSON_UTF8))
                .andExpect(jsonPath("$.fieldErrors", hasSize(2)))
                .andExpect(jsonPath("$.fieldErrors[*].path", containsInAnyOrder("title", "description")))
                .andExpect(jsonPath("$.fieldErrors[*].message", containsInAnyOrder(
                        "The maximum length of the description is 500 characters.",
                        "The maximum length of the title is 100 characters."
                )));
 
        verifyZeroInteractions(todoServiceMock);
    }
}
```

* Case Test (add database thành công)

```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = {TestContext.class, WebAppContext.class})
@WebAppConfiguration
public class TodoControllerTest {
 
    private MockMvc mockMvc;
 
    @Autowired
    private TodoService todoServiceMock;
 
    @Test
    public void add_NewTodoEntry_ShouldAddTodoEntryAndReturnAddedEntry() throws Exception {
        TodoDTO dto = new TodoDTOBuilder()
                .description("description")
                .title("title")
                .build();
 
        Todo added = new TodoBuilder()
                .id(1L)
                .description("description")
                .title("title")
                .build();
 
        when(todoServiceMock.add(any(TodoDTO.class))).thenReturn(added);
 
        mockMvc.perform(post("/api/todo")
                .contentType(TestUtil.APPLICATION_JSON_UTF8)
                .content(TestUtil.convertObjectToJsonBytes(dto))
        )
                .andExpect(status().isOk())
                .andExpect(content().contentType(TestUtil.APPLICATION_JSON_UTF8))
                .andExpect(jsonPath("$.id", is(1)))
                .andExpect(jsonPath("$.description", is("description")))
                .andExpect(jsonPath("$.title", is("title")));
 
        ArgumentCaptor<TodoDTO> dtoCaptor = ArgumentCaptor.forClass(TodoDTO.class);
        verify(todoServiceMock, times(1)).add(dtoCaptor.capture());
        verifyNoMoreInteractions(todoServiceMock);
 
        TodoDTO dtoArgument = dtoCaptor.getValue();
        assertNull(dtoArgument.getId());
        assertThat(dtoArgument.getDescription(), is("description"));
        assertThat(dtoArgument.getTitle(), is("title"));
    }
}
```
URL tham khảo : https://www.petrikainulainen.net/programming/spring-framework/unit-testing-of-spring-mvc-controllers-rest-api/
