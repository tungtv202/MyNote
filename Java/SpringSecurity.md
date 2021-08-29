---
title: Java - Spring Security
date: 2020-07-18 18:00:26
updated: 2020-07-18 18:00:26
tags:
    - java
    - spring
    - security
category: 
    - java
---

# 1. Lý thuyết

- Nếu sử dụng đồng thời HttpSecurity và dùng `@PreAuthorize`, thì `HttpSecurity` sẽ được chạy trước
- HttpSecurity khai báo dựa trên endpoint url, còn @PreAuthorize khai báo trước method
- `@PreAuthorize` sử dụng `SPEL` (Spring Expression Language)
- `@PostAuthorize` được assessed sau khi method được execute xong
- Expressions
    ```
    hasRole, hasAnyRole
    hasAuthority, hasAnyAuthority
    permitAll, denyAll
    isAnonymous, isRememberMe, isAuthenticated, isFullyAuthenticated
    principal, authentication
    hasPermission
    ```
- @PreFilter and @PostFilter

```java
@PostFilter("filterObject.assignee == authentication.name")
List<Task> findAll(){
    ...
    }
///
@PostFilter("hasRole('MANAGER') or filterObject.assignee == authentication.name")
List<Task> findAll(){
    // ...
    }
///
@PreFilter("hasRole('MANAGER') or filterObject.assignee == authentication.name")
Iterable<Task> save(Iterable<Task> entities){
    // ...
    }
```

# 2. Code template

## 2.1. Spring security vs JWT

- `WebSecurityConfig.java`

```java

@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class WebSecurityConfig extends WebSecurityConfigurerAdapter {

    @Autowired
    private JwtAuthenticationEntryPoint unauthorizedHandler;
    @Autowired
    private JwtTokenUtil jwtTokenUtil;
    @Autowired
    private StoreRepository storeDao;
    @Autowired
    private JwtProperty jwtProperty;

    @Autowired
    public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
        //auth.userDetailsService(jwtUserDetailsService).passwordEncoder(passwordEncoderBean());
    }

    @Bean
    @Override
    public AuthenticationManager authenticationManagerBean() throws Exception {
        return super.authenticationManagerBean();
    }

    @Override
    protected void configure(HttpSecurity httpSecurity) throws Exception {
        httpSecurity.cors().and()
            // we don't need CSRF because our token is invulnerable
            .csrf().disable()
            .exceptionHandling().authenticationEntryPoint(unauthorizedHandler).and()
            // don't create session
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS).and()
            .authorizeRequests()
            .antMatchers("/api/install/**").permitAll()
            .anyRequest().authenticated();

        // Custom JWT based security filter
        JwtAuthorizationTokenFilter authenticationTokenFilter = new JwtAuthorizationTokenFilter(storeDao, jwtTokenUtil, jwtProperty.getHeader());
        httpSecurity.addFilterBefore(authenticationTokenFilter, UsernamePasswordAuthenticationFilter.class);
        httpSecurity.headers().frameOptions().disable();
    }

    @Bean
    public HttpFirewall allowUrlEncodedSlashHttpFirewall() {
        StrictHttpFirewall firewall = new StrictHttpFirewall();
        firewall.setAllowUrlEncodedSlash(true);
        firewall.setAllowSemicolon(true);
        return firewall;
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(Arrays.asList("*"));
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(Arrays.asList("authorization", "content-type", "x-auth-token"));
        configuration.setExposedHeaders(Arrays.asList("x-auth-token"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

//    @Override
//    public void configure(WebSecurity web) throws Exception {
//        super.configure(web);
//        web.httpFirewall(allowUrlEncodedSlashHttpFirewall());
//        // AuthenticationTokenFilter will ignore the below paths
//        web.ignoring().antMatchers(
//                HttpMethod.GET,
//                "/favicon.ico",
//                "/robots.txt",
//                "/**/*.css",
//                "/**/*.js"
//        );
//    }
}
```

- `JwtAuthorizationTokenFilter.java`

```java
public class JwtAuthorizationTokenFilter extends OncePerRequestFilter {
    private JwtTokenUtil jwtTokenUtil;
    private String tokenHeader;
    private StoreRepository storeDao;

    public JwtAuthorizationTokenFilter(StoreRepository storeDao, JwtTokenUtil jwtTokenUtil, String tokenHeader) {
        this.storeDao = storeDao;
        this.jwtTokenUtil = jwtTokenUtil;
        this.tokenHeader = tokenHeader;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
        if (StringUtils.equals(request.getMethod().toLowerCase(), "options")) {
            response.setStatus(200);
            response.setHeader("Access-Control-Allow-Origin", "*");
            response.setHeader("Access-Control-Max-Age", "600");
            response.setHeader("Access-Control-Allow-Headers", "*");
            response.setHeader("Access-Control-Allow-Methods", "*");
            return;
        }

        final String requestHeader = request.getHeader(this.tokenHeader);
        String username = null;
        if (requestHeader != null) {
            try {
                username = jwtTokenUtil.getUsernameFromToken(requestHeader);
            } catch (IllegalArgumentException | JwtException ignored) {
            }
        }

        if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            val store = storeDao.findbyStoreAlias(username);
            if (store != null) {
                // It is not compelling necessary to load the use details from the database. You could also store the information
                // in the token and read it from it. It's up to you ;)
                UserDetails userDetails = new JwtUser(store.getId(), username);

                // For simple validation it is completely sufficient to just check the token integrity. You don't have to call
                // the database compellingly. Again it's up to you ;)
                if (jwtTokenUtil.validateToken(requestHeader, userDetails)) {
                    UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            }
        }

        chain.doFilter(request, response);
    }
}

```

- `JwtTokenUtil.java`

```java

@Component
public class JwtTokenUtil implements Serializable {

    private static final long serialVersionUID = -3301605591108950415L;
    private final JwtProperty jwtProperty;
    private Clock clock = DefaultClock.INSTANCE;

    @Autowired
    public JwtTokenUtil(JwtProperty jwtProperty) {
        this.jwtProperty = jwtProperty;
    }

    public String getUsernameFromToken(String token) {
        return getClaimFromToken(token, Claims::getSubject);
    }

    public Date getIssuedAtDateFromToken(String token) {
        return getClaimFromToken(token, Claims::getIssuedAt);
    }

    public Date getExpirationDateFromToken(String token) {
        return getClaimFromToken(token, Claims::getExpiration);
    }

    public <T> T getClaimFromToken(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = getAllClaimsFromToken(token);
        return claimsResolver.apply(claims);
    }

    private Claims getAllClaimsFromToken(String token) {
        return Jwts.parser()
            .setSigningKey(jwtProperty.getSecret())
            .parseClaimsJws(token)
            .getBody();
    }

    private Boolean isTokenExpired(String token) {
        final Date expiration = getExpirationDateFromToken(token);
        return expiration.before(clock.now());
    }

    private Boolean isCreatedBeforeLastPasswordReset(Date created, Date lastPasswordReset) {
        return (lastPasswordReset != null && created.before(lastPasswordReset));
    }

    private Boolean ignoreTokenExpiration(String token) {
        // here you specify tokens, for that the expiration is ignored
        return false;
    }

    public String generateToken(UserDetails userDetails) {
        Map<String, Object> claims = new HashMap<>();
        return doGenerateToken(claims, userDetails.getUsername());
    }

    private String doGenerateToken(Map<String, Object> claims, String subject) {
        final Date createdDate = clock.now();
        final Date expirationDate = calculateExpirationDate(createdDate);

        return Jwts.builder()
            .setClaims(claims)
            .setSubject(subject)
            .setIssuedAt(createdDate)
            .setExpiration(expirationDate)
            .signWith(SignatureAlgorithm.HS256, jwtProperty.getSecret())
            .compact();
    }

    public Boolean canTokenBeRefreshed(String token) {
        return !isTokenExpired(token) || ignoreTokenExpiration(token);
    }

    public String refreshToken(String token) {
        final Date createdDate = clock.now();
        final Date expirationDate = calculateExpirationDate(createdDate);

        final Claims claims = getAllClaimsFromToken(token);
        claims.setIssuedAt(createdDate);
        claims.setExpiration(expirationDate);

        return Jwts.builder()
            .setClaims(claims)
            .signWith(SignatureAlgorithm.HS256, jwtProperty.getSecret())
            .compact();
    }

    public Boolean validateToken(String token, UserDetails userDetails) {
        JwtUser user = (JwtUser) userDetails;
        final String username = getUsernameFromToken(token);
        return (username.equals(user.getUsername()) && !isTokenExpired(token));
    }

    private Date calculateExpirationDate(Date createdDate) {
        return new Date(createdDate.getTime() + jwtProperty.getExpiration() * 1000);
    }
}

```

.

## 2.2. Basic Security

- `HttpBasicConfig.java`

```java

@Configuration
@EnableWebSecurity
@Order(2)
public class HttpBasicConfig extends WebSecurityConfigurerAdapter {
    private static final String[] PUBLIC_RESOURCES = new String[]{
        "/admin/payment-integrations/momo/ipn-listener",
        "/admin/payment-integrations/momo/ipn-listener.json",
        "/admin/payment-integrations/zpay/update_merchant",
        "/admin/payment-integrations/zpay/update_merchant.json",
        "/admin/momoaccuracy",
        "/admin/momoaccuracy.json"
    };

    private static final String[] PRIVATE_RESOURCES = new String[]{
        "/admin/payment-integrations/**"
    };

    @Autowired
    private UserConfig config;
    @Autowired
    private UserDetailsService userDetailsService;
    @Autowired
    private SessionUserService sessionUserService;
    @Autowired
    private PasswordEncoder passwordEncoder;
    @Autowired
    private CustomAccessDeniedHandler accessDeniedHandler;
    @Autowired
    private AuthenticationExceptionHandler authenticationExceptionHandler;

    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http.requestMatcher(new BasicRequestMatcher(sessionUserService))
            .authorizeRequests()
            .antMatchers(HttpMethod.GET, PRIVATE_RESOURCES).access(genRole("read_orders"))
            .antMatchers(HttpMethod.POST, PRIVATE_RESOURCES).access(genRole("write_orders"))
            .antMatchers(HttpMethod.PUT, PRIVATE_RESOURCES).access(genRole("write_orders"))
            .antMatchers(HttpMethod.DELETE, PRIVATE_RESOURCES).access(genRole("write_orders"))
            .antMatchers("/**").hasRole(config.getRole())
            .and().sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and().csrf().disable().httpBasic()
            .and().exceptionHandling().accessDeniedHandler(accessDeniedHandler).authenticationEntryPoint(authenticationExceptionHandler);
    }

    private String genRole(String role) {
        return String.format("hasRole('%s') or hasAuthority('%s')", config.getRole(), role);
    }

    @Autowired
    public void configureGlobal(AuthenticationManagerBuilder auth) throws Exception {
        inMemoryConfigurer()
            .passwordEncoder(passwordEncoder)
            .withUser(config.getName()).password(config.getPassword()).roles(config.getRole()).and()
            .configure(auth);
        auth.userDetailsService(userDetailsService);
    }

    private InMemoryUserDetailsManagerConfigurer<AuthenticationManagerBuilder> inMemoryConfigurer() {
        return new InMemoryUserDetailsManagerConfigurer<>();
    }

    @Override
    public void configure(WebSecurity web) throws Exception {
        super.configure(web);
        web.ignoring().antMatchers(HttpMethod.POST, PUBLIC_RESOURCES);
    }
}
```

- `SessionUserServiceImpl.java`

```java

@Service
public class SessionUserServiceImpl implements SessionUserService {
    @Autowired
    @Qualifier("redis_template_common")
    private StringRedisTemplate redisCommonTemplate;
    @Autowired
    @Qualifier("json")
    private ObjectMapper json;
    @Autowired
    private UserDao userDao;
    private ValueOperations<String, String> hashValue;

    @PostConstruct
    private void init() {
        hashValue = redisCommonTemplate.opsForValue();
    }

    @Override
    public CurrentUser getUser(Cookie cookie) {
        if (cookie != null && cookie.getValue() != null) {
            String jsonStr = hashValue.get(cookie.getValue());
            try {
                if (!StringUtils.isEmpty(jsonStr)) {
                    SessionModel sessionModel = json.readValue(jsonStr, SessionModel.class);
                    if (sessionModel != null) {
                        vn.z.service.generic.domain.User domainUser = userDao
                            .getByEmail(sessionModel.getUsername(), sessionModel.getStoreId());

                        if (domainUser != null) {
                            User user = new User();
                            user.setId(domainUser.getId());
                            user.setStoreId(sessionModel.getStoreId());
                            user.setEmail(sessionModel.getUsername());
                            user.setPassword(domainUser.getPassword());
                            user.setPermissions(domainUser.getPermissions());
                            user.setFirstName(domainUser.getFirstName());
                            user.setLastName(domainUser.getLastName());
                            user.setEmployee(sessionModel.getEmployee());
                            user.setEmpoyeeSource(sessionModel.getEmployeeSource());
                            return new CurrentUser(user);
                        }
                    }
                }
            } catch (Exception e) {
                // unhandled
            }
        }
        return null;
    }

    @Override
    public boolean containCookie(String s) {
        return redisCommonTemplate.hasKey(s);
    }
}
```

```java

@Getter
@Setter
public class SessionModel {
    private int storeId;
    private String username;
    private String employee;
    private String employeeSource;
}
```

- `AuthenticationExceptionHandler.java`

```java

@Component
public class AuthenticationExceptionHandler implements AuthenticationEntryPoint, Serializable {
    @Autowired
    private ObjectMapper jsonMain;

    @Override
    public void commence(HttpServletRequest httpServletRequest, HttpServletResponse response, AuthenticationException e) throws IOException, ServletException {
        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_UTF8_VALUE);
        response.getWriter().write(jsonMain.writeValueAsString(
            ErrorModel.newInstance().add("base", HttpStatus.UNAUTHORIZED.getReasonPhrase())));
    }
}
```

- `CustomAccessDeniedHandler.java`

```java

@Component
public class CustomAccessDeniedHandler implements AccessDeniedHandler {

    @Autowired
    private ObjectMapper jsonMain;

    @Override
    public void handle(HttpServletRequest httpServletRequest, HttpServletResponse response, AccessDeniedException e) throws IOException, ServletException {
        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_UTF8_VALUE);
        response.getWriter().write(jsonMain.writeValueAsString(
            ErrorModel.newInstance().add("base", HttpStatus.FORBIDDEN.getReasonPhrase())));
    }
}
```

## Other

![15Filter](https://www.marcobehler.com/images/filterchain-1a.png)

- [Spring Security: Authentication and Authorization In-Depth](https://www.marcobehler.com/guides/spring-security)
