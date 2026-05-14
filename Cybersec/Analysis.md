# MyPizzaApp CTF Walkthrough
**Table des matières**
- [MyPizzaApp CTF Walkthrough](#mypizzaapp-ctf-walkthrough)
  - [Consignes](#consignes)
  - [Plan](#plan)
    - [Phase 1: Static Code Analysis](#phase-1-static-code-analysis)
    - [Phase 2: Dynamic Analysis \& Recon](#phase-2-dynamic-analysis--recon)
    - [Phase 3: The Exploitation Chain (Getting the Flags)](#phase-3-the-exploitation-chain-getting-the-flags)
    - [Phase 4: Writing the Sysreptor Report](#phase-4-writing-the-sysreptor-report)
  - [Phase 1: SAST and manual analysis](#phase-1-sast-and-manual-analysis)
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
      - [SSRF via Image URLs (CWE-918)](#ssrf-via-image-urls-cwe-918)
      - [Route Guard Bypass on Client-Side Checks (CWE-602)](#route-guard-bypass-on-client-side-checks-cwe-602)
      - [Weak Admin Guard and Role Bypass (CWE-269)](#weak-admin-guard-and-role-bypass-cwe-269)
      - [Bearer Token Bypass \& Algorithm Confusion (CWE-347)](#bearer-token-bypass--algorithm-confusion-cwe-347)
      - [Mitm via Insecure CORS \& HTTP Origins (CWE-319)](#mitm-via-insecure-cors--http-origins-cwe-319)
      - [Nginx Reverse Proxy Misconfiguration](#nginx-reverse-proxy-misconfiguration)
      - [Cleartext Credential or Token Interception](#cleartext-credential-or-token-interception)
      - [Privilege Escalation: Self-Role Modification (CWE-269)](#privilege-escalation-self-role-modification-cwe-269)
      - [Timing Attack Lure Vulnerability (CWE-697, CWE-208)](#timing-attack-lure-vulnerability-cwe-697-cwe-208)
    - [Data Exposure](#data-exposure)
    - [Supply Chain Vulnerabilities](#supply-chain-vulnerabilities)


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

## Plan
### Phase 1: Static Code Analysis
Open the downloaded MyPizzaApp folder in your local VSCode. Look for the following classic vulnerabilities in the source code:
- Hardcoded Secrets: Search for database passwords, API keys, or JWT secret keys.
- SQL Injection (SQLi): Search the codebase for SELECT, UPDATE, or INSERT. Look for areas where user input is concatenated directly into the query instead of using parameterized queries/prepared statements.
- Business Logic Flaws: The prompt mentions paying with "UBIKs" (virtual currency). Look closely at the purchasing logic. Can you alter the price of a pizza to a negative number? Can you cause an integer overflow? Can you buy something without having enough UBIKs?
- Insecure File Upload: If the app lets users upload a profile picture or a pizza recipe, check if the code properly validates file extensions. If it doesn't, you might be able to upload a .php or .jsp web shell.
- Command Injection: Search for dangerous functions (e.g., system(), exec(), os.system, eval()). Are any user inputs passed to these?

### Phase 2: Dynamic Analysis & Recon
Now launch the app on the VM (./LaunchApp.sh) and navigate to https://app1.tiweb.tp.ubik.academy on your local browser (or the VM's browser).

Map the application in the browser and in a proxy:
- Register a normal user and verify the exact request/response bodies for `/register` and `/token`.
- Log in and inspect where `access_token` is stored, how it is reused, and whether it survives refresh.
- Open the admin routes and confirm which checks are only client-side.
- Create a comment payload and check whether it is rendered with HTML interpretation or sanitization.
- Submit a pizza with a crafted `imageUrl` and observe whether the frontend or bot later fetches it.
- Record every request that carries credentials, because the report needs direct evidence for interception risk.

Capture this traffic using a proxy like Burp Suite or OWASP ZAP on your local machine if you can route it, or use the browser's Network tab.

Directory bruteforcing still helps for recon and evidence collection:
```Bash
dirb https://app1.tiweb.tp.ubik.academy /usr/share/seclists/Discovery/Web-Content/common.txt
```

Useful checks during recon:
- Verify whether `http://` is redirected to `https://` or stays reachable.
- Check browser DevTools for sourcemaps and exposed bundle content.
- Inspect whether route guards can be bypassed by editing `localStorage.access_token`.
- Confirm whether `xss-poller` is reachable directly and whether it accepts unauthenticated requests.


### Phase 3: The Exploitation Chain (Getting the Flags)
Based on the lab description, you need a chain of exploits to compromise the server. A practical kill-chain for this app is:
1. **Initial access: comment XSS or weak token forgery** [Flag 1]
  - Use the comment field or another editable surface to inject stored XSS.
  - The payload should steal `localStorage.access_token` when the admin bot opens the page.
  - If the JWT secret is recoverable from source or config, forge an admin token directly instead.
2. **Privilege escalation in the web layer** [Flag 2]
  - Reuse the stolen or forged admin token to open the admin interface.
  - Modify user data through the user edition flow if role checks are weak.
  - Demonstrate that route guards are only cosmetic by bypassing them in the browser.
3. **Server-side compromise** [Flag 3]
  - Use admin access to reach the pizza creation path that accepts unsafe object input.
  - Trigger the dangerous deserialization path or any equivalent code execution primitive.
  - Document the exact payload, request, and resulting server-side effect.
4. **Post-exploitation and root** [Final Flag]
  - Once you have shell access as the application user, enumerate privileges.
  - Check sudo permissions: `sudo -l`
  - Check for SUID binaries: `find / -perm -4000 -type f 2>/dev/null`
  - Check running processes: `htop` or `ps aux`
  - Search GTFOBins online for standard Linux binaries with misconfigured permissions.

For the report, write the chain as a single story:
- public app exposure
- token theft or forgery
- admin UI access
- server-side code execution
- local privilege escalation
- final flag capture

### Phase 4: Writing the Sysreptor Report
As you go, take screenshots of everything. A good Sysreptor report should be professional and structured:
Executive Summary:
- One paragraph for non-technical readers.
- State that MyPizzaApp allows authentication bypass, stored XSS, token theft, privilege escalation, and server-side compromise.

Scope and Methodology:
- State that this was a white-box audit with source code review and live validation.
- List the main tools used: browser DevTools, proxy, source inspection, and manual validation.
- Mention which findings were confirmed in source and which were validated dynamically.

Vulnerability Details for each issue:
- Title: short, precise, and specific.
- Affected component: file and route or page.
- Description: explain the flaw and why it matters.
- Proof of Concept: exact steps, payloads, and screenshots.
- Impact: what an attacker gains in practice.
- Remediation: concrete fix guidance, ideally with code or validation rules.
- Detection notes: optional, but useful for repeatability.

Attack Scenario:
- Show the kill-chain from first foothold to final flag.
- Keep it chronological.
- Make each step depend on the previous one so the story is easy to follow.

Evidence checklist:
- Screenshot of the vulnerable request.
- Screenshot of the browser or proxy response.
- Screenshot of the admin or bot action where relevant.
- Screenshot of the terminal or shell once RCE is achieved.
- Screenshot of the final flag capture.

Recommended report ordering:
1. Authentication and session issues.
2. Client-side authorization and route bypasses.
3. Stored XSS and bot abuse.
4. Server-side injection and deserialization.
5. Post-exploitation and root access.

&nbsp;  

---

&nbsp;  


## Phase 1: SAST and manual analysis
### Insecure Credentials
#### Hardcoded Secrets
- **Gravité:** Critique
 - **Référence:** CWE-798 - Use of Hard-coded Credentials: https://cwe.mitre.org/data/definitions/798.html
- **Constat:** Plusieurs secrets sensibles sont codés en dur dans l'orchestration Docker et dans la configuration applicative.
  - JWT secret statique: `SuperSecretKeyThatIsTottalyNotRandom` (MyPizzaApp/docker-compose.yml)
  - URL de base de données avec identifiants en clair: `postgresql+asyncpg://awefull_pizza_shop:awefull_password@postgres/awefullpizzashop` (MyPizzaApp/docker-compose.yml)
  - Mot de passe PostgreSQL en clair: `POSTGRES_PASSWORD: awefull_password` (MyPizzaApp/docker-compose.yml)
  - Valeur par défaut de secours côté backend: `JWT_SECRET_KEY = "changeme"`  (MyPizzaApp\backend\src\awefull_pizza_shop\webserver\config.py)
- **Impact:**
  - Forge de JWT possible en cas d'accès au code/config (boîte blanche, fuite repo, backup, logs).
  - Mouvement latéral facilité vers la base de données.
- **Remédiation:**
  - Supprimer tout secret du dépôt.
  - Injecter les secrets via variables d'environnement/secret manager.
  - Rotation immédiate des secrets exposés.
  - Interdire les valeurs faibles par défaut en production

1. **backend/.../security/service.py: hash bcrypt hardcodé**
   - **Verdict:** À nuancer (faux positif partiel)
   - **Pourquoi:** La constante `PROTECTION_AGAINST_TIMING_ATTACK` ressemble à un hash de mot de passe, mais elle sert de valeur factice pour uniformiser le temps de vérification en cas d'utilisateur inconnu.
   - **Risque réel:** Faible à modéré ici (pas un secret opérationnel), mais l'alerte reste pertinente d'un point de vue gouvernance (chaîne codée en dur).
   - **Remédiation:**
     - Documenter explicitement cette constante comme leurre anti-timing.
     - Optionnel: déplacer en configuration non sensible ou générer au démarrage.

2. **docker-compose.yml: mot de passe PostgreSQL en dur**
   - **Verdict:** Confirmé (Blocker)
   - **Pourquoi:** Credentials DB et secret JWT en clair dans compose.
   - **Remédiation:**
     - Utiliser des variables d'environnement externes (`.env` non versionné) ou Docker secrets.
     - Rotation des secrets existants.


- **Gravité:** Haute
- **Référence:** CWE-1392 - Default Credentials in Configuration: https://cwe.mitre.org/data/definitions/1392.html
- **Constat:** 
  - `config.py` line 42: `JWT_SECRET_KEY: str = "changeme"` — weak default secret
  - `alembic.ini` line 17: Exposed DB credentials in config file
  - Docker Compose: `POSTGRES_PASSWORD=awefull_password` — trivial default
- **Impact:**
  - JWT tokens are trivially forgeable with default secret
  - Database credentials discoverable in version control
  - Any actor with code access can generate valid admin tokens
- **PoC:**
  ```python
  import jwt
  payload = {'sub': 'username:admin_user', 'role': 'Admin', 'exp': 9999999999}
  token = jwt.encode(payload, "changeme", algorithm="HS256")
  # Token now valid for all admin endpoints
  ```
- **Remédiation:**
  - Remove all default credentials from code
  - Inject secrets via environment variables only (raise error if missing)
  - Use `.env.example` as template without actual values
  - Implement config validation rejecting weak defaults at startup


#### Weak JWT Design and Role-in-Token Trust
- **Gravité:** Critique
- **Référence:** CWE-345 - Insufficient Verification of Data Authenticity: https://cwe.mitre.org/data/definitions/345.html
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
- **Remédiation:**
  - Treat JWT claims as untrusted hints on the client.
  - Enforce authorization on the server for every privileged action.
  - Keep the token minimal and avoid relying on the UI role for anything security-critical.

#### Weak Token Storage in localStorage
- **Gravité:** Critique
- **Référence:** CWE-922 - Insecure Storage of Sensitive Information: https://cwe.mitre.org/data/definitions/922.html
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
- **Remédiation:**
  - Prefer HttpOnly secure cookies for session material.
  - If storage is unavoidable, reduce token lifetime and rotate often.
  - Never expose long-lived admin tokens to frontend JavaScript.

#### Weak Cryptography & Guessable Hashes (CWE-327, CWE-330)
- **Gravité:** Élevée
- **Référence:** CWE-327 - Use of a Broken or Risky Cryptographic Algorithm: https://cwe.mitre.org/data/definitions/327.html
- **Constat:**
  - JWT Algorithm: HS256 (symmetric) with weak secret (~32 bits entropy vs 256+ recommended)
  - JWT Secret: `"SuperSecretKeyThatIsTottalyNotRandom"` (dictionary phrase, human-guessable)
  - No rate limiting on token generation or password verification
- **Impact:**
  - Brute-force JWT secret offline or via dictionary attack
  - Forge unlimited valid tokens once secret is known
  - Potential GPU-based password hash cracking if bcrypt cost is weak
- **PoC:**
  ```bash
  # Offline brute-force with wordlists
  john --wordlist=rockyou.txt jwt_token
  # Or try common weak secrets
  for secret in "changeme" "SuperSecretKeyThatIsTottalyNotRandom" "test"; do
    python3 -c "import jwt; print(jwt.encode({'role':'Admin'}, '$secret', 'HS256'))"
  done
  ```
- **Remédiation:**
  - Use RS256 (asymmetric) with 2048+ bit RSA keys or EdDSA
  - If HS256 required, enforce 256-bit random secret: `secrets.token_hex(32)`
  - Enforce bcrypt cost >= 13
  - Implement rate limiting on `/token` endpoint (max 5 attempts/minute)
  - Add secret rotation strategy

### Unexpected Content Injection
#### XSS
- **Gravité:** Élevée
 - **Référence (XSS):** CWE-79 - Cross-site Scripting: https://cwe.mitre.org/data/definitions/79.html
- **Constat 1: chaîne d'attaque XSS stockée + bot admin**
  - Les commentaires utilisateurs acceptent du HTML arbitraire.
  - Le frontend force l'affichage via `bypassSecurityTrustHtml`.
  - À chaque création de commentaire, le backend déclenche un bot qui visite la page pizza avec un token admin injecté dans localStorage.
- **Preuves (code):**
  - `MyPizzaApp/frontend/AwefullPizzaShop/src/app/pizza/pizza-comment-card/pizza-comment-card.component.ts`
  - `MyPizzaApp/frontend/AwefullPizzaShop/src/app/pizza/pizza-comment-card/pizza-comment-card.component.html`
  - `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/comment.py`
  - `MyPizzaApp/xss-poller.mjs`
- **Impact:**
  - Vol de session admin via payload XSS (lecture de `localStorage.access_token`).
  - Prise de contrôle des endpoints admin.

3. **frontend/.../pizza-comment-card.component.ts: désactivation de sanitization Angular**
    - **Référence (XSS guidance):** OWASP XSS Prevention Cheat Sheet: https://cheatsheetseries.owasp.org/cheatsheets/XSS_Prevention_Cheat_Sheet.html
   - **Verdict:** Confirmé (Blocker)
   - **Pourquoi:** `bypassSecurityTrustHtml` appliqué sur du contenu utilisateur.
   - **Impact:** XSS stockée exploitable, aggravée par le bot admin.
   - **Remédiation:**
     - Ne pas utiliser `bypassSecurityTrustHtml` pour des données non fiables.
     - Utiliser rendu texte ou sanitization stricte côté serveur.


- **Gravité:** Média
- **Référence:** CWE-79 - Cross-site Scripting: https://cwe.mitre.org/data/definitions/79.html
- **Constat:**
  - If `image_url` rendered directly in HTML (e.g., `<img src="{image_url}" />`), JavaScript URLs can be injected
  - Example: `image_url="javascript:alert('XSS')"`
- **Impact:**
  - XSS execution on image load/error
  - Token theft, page modification, user redirect
- **PoC:**
  ```bash
  curl -X POST http://localhost:7465/pizza/create \
    -d '{"image_url":"javascript:alert(document.cookie)",...}'
  ```
- **Remédiation:**
  - Validate image_url to ONLY allow `http://`, `https://` schemes
  - Reject `javascript:`, `data:`, `vbscript:`, etc.
  - Use Pydantic `HttpUrl` validator
  - Render safely in Angular with DomSanitizer


- **Gravité:** Critique
- **Référence:** CWE-79 - Cross-site Scripting: https://cwe.mitre.org/data/definitions/79.html
- **Constat:**
  - `pizza-comment-card.component.ts` uses `bypassSecurityTrustHtml` on user content.
  - `pizza-comment-card.component.html` binds that value via `[innerHTML]`.
  - The mock comments already contain a working script payload.
- **Impact:**
  - Stored XSS against any user who opens the comment view.
  - The payload can steal `access_token` from `localStorage` and trigger the admin bot.
- **PoC:**
  - Render the mock comment containing `<script>alert('XSS')</script>` and observe execution if sanitization is bypassed.
- **Remédiation:**
  - Remove `bypassSecurityTrustHtml` for untrusted input.
  - Render comments as plain text or sanitize on the server with a strict allowlist.

- **Gravité:** Critique
- **Référence:** CWE-306 - Missing Authentication for Critical Function: https://cwe.mitre.org/data/definitions/306.html
- **Constat:**
  - `xss-poller.mjs` exposes a public `GET /:id` endpoint.
  - The handler launches a browser, injects an admin JWT into `localStorage`, and visits `/pizza/${id}` without any authentication or authorization.
  - `Dockerfile-XSS-poller` builds the bot as a standalone service, making it easy to run in the challenge environment.
- **Impact:**
  - Any attacker who can reach the service can make the admin bot browse arbitrary pizza pages.
  - This is the force multiplier for stored XSS and comment injection payloads.
- **PoC:**
  ```bash
  curl http://localhost:3000/123
  ```
  - The bot opens the page and carries an admin token in browser storage.
- **Remédiation:**
  - Protect the bot endpoint with authentication and request validation.
  - Restrict it to trusted internal callers only.
  - Never expose privileged browsing automation on a public interface.


#### SQLi
- **Gravité:** Haute
 - **Référence:** CWE-89 - SQL Injection: https://cwe.mitre.org/data/definitions/89.html
- **Constat:** Injection SQL via concaténation de la variable utilisateur `category` dans une clause SQL textuelle.
- **Preuves (code):**
  - `MyPizzaApp/backend/src/awefull_pizza_shop/database/pizza/repository.py`
    - `text(f"category='{category}'")`
  - Endpoint exposé:
    - `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/pizza.py`
    - route: `/pizza/category/{category}`
- **PoC (exemple):**
  - Requête sur `/api/pizza/category/meat'%20OR%201=1--`
  - Effet attendu: contournement du filtre de catégorie et retour d'un plus grand jeu de résultats.
- **Impact:**
  - Exfiltration de données de la table ciblée.
  - Contournement de logique applicative basée sur les filtres.
- **Remédiation:**
  - Supprimer la construction SQL manuelle.
  - Utiliser une requête paramétrée/ORM safe:
    - comparer directement `Pizza.category == category` après validation stricte de l'énumération.
  - Rejeter les catégories hors liste blanche (`MEAT`, `FISH`, `VEGAN`).

#### Command Injection
- **Gravité:** Critique (via primitive équivalente RCE)
 - **Référence (Deserialization):** CWE-502 - Deserialization of Untrusted Data: https://cwe.mitre.org/data/definitions/502.html
- **Constat:** Pas de `os.system`/`subprocess` directement exposé avec entrée utilisateur, mais présence d'une désérialisation dangereuse menant à exécution potentielle de code.
- **Preuves (code):**
  - `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/pizza.py`
    - `jsonpickle.decode(await request.body(), safe=False)`
  - Couplage frontend orienté objet Python:
    - `MyPizzaApp/frontend/AwefullPizzaShop/src/app/pizza/pizza.service.ts`
    - ajout de méta-clés `jsonpickle` pour créer des objets côté serveur
- **Impact:**
  - Exécution de code arbitraire côté backend (RCE) possible selon payload de désérialisation.
  - Compromission complète de l'application et pivot système.
- **Remédiation:**
  - Supprimer complètement `jsonpickle.decode(..., safe=False)` sur des données non fiables.
  - Accepter un schéma JSON strict via Pydantic (`PizzaCreation`) sans polymorphisme dynamique.
  - Refuser toute méta-clé de sérialisation (ex: `py/object`, `py/reduce`, etc.).

#### Validation Issues
Unsafe Deserialization (CWE-502)
- **Source:** Snyk Code (python/Deserialization)
- **Severity:** High (Priority Score 757)
- **Résumé:** Unsanitized input from an HTTP parameter flows into `jsonpickle.decode`, enabling unsafe deserialization.
- **Preuves (code):**
  - `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/pizza.py`
    - `pizza_data = jsonpickle.decode(await request.body(), safe=False)`
- **Contexte:**
  - This endpoint is protected by `validate_user_admin`, but an admin token can be stolen (see XSS + xss-poller chain). Unsafe deserialization here enables creating objects that may trigger code execution server-side.
- **PoC (concept):**
  - Construct a JSON payload containing a `py/object` tag or other jsonpickle gadget payload that, when deserialized, invokes a pickler/unpickler path which executes arbitrary code. POST to `/api/pizza/create` with admin auth.
- **Impact:**
  - Remote code execution as the application process user; full compromise of app container and pivot to infra.
- **Immediate Mitigations:**
  - Restrict access to the endpoint by IP/network in addition to auth where possible.
  - Disable `jsonpickle.decode(..., safe=False)` in runtime (return 400/422 on presence of suspicious keys).
  - Monitor and rotate admin credentials and JWT secret after remediation.
- **Remediation (recommended):**
  - Replace jsonpickle-based deserialization with a safe path:
    - Accept plain JSON and validate/parse with Pydantic models (e.g., `schemas.PizzaCreation.model_validate_json()`), avoiding dynamic class instantiation.
    - If jsonpickle must be used temporarily, enable/implement a strict allowlist of classes and block `py/*` tags; better yet, remove it.
  - Add request schema validation (FastAPI body model) so malformed/malicious payloads are rejected by the framework before any deserialization.

- **Gravité:** Critique
- **Référence:** CWE-20 - Improper Input Validation: https://cwe.mitre.org/data/definitions/20.html
- **Constat:**
  - Pizza creation and editing accept free-form `name`, `description`, `imageUrl`, and `category` values.
  - User edition accepts `email`, `name`, and `role` through `user-edit-dialog.component.ts`.
  - Login and register flows submit values with weak front-end validation only.
  - The UI does not enforce server-safe allowlists before sending content that can later be rendered or processed.
- **Impact:**
  - Stored XSS payloads can enter comments or descriptions.
  - Malicious image URLs can be used for SSRF or JavaScript URL tricks.
  - User-role tampering becomes possible when paired with weak backend authorization.
- **PoC:**
  - Submit payloads such as `<script>alert(1)</script>` in comments or `javascript:alert(1)` in image fields.
  - If backend validation is weak, the payload persists and later executes in the browser.
- **Remédiation:**
  - Validate all fields server-side with strict allowlists.
  - Mirror the validation in Angular, but do not rely on it for security.
  - Reject dangerous URL schemes and HTML in free-text fields that are rendered as markup.


### Identity Usurpation
#### IDOR
- **Gravité:** Haute
- **Référence:** CWE-639 - Authorization Bypass Through User-Controlled Key: https://cwe.mitre.org/data/definitions/639.html
- **Constat:**
  - `backend/src/awefull_pizza_shop/webserver/routers/user.py` line 18: `/users/{user_id}` returns user by ID without ownership check
  - Line 27: `/users/{user_id}` POST allows updating ANY user with only admin role check
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
- **Remédiation:**
  - Add strict ownership checks in update endpoint
  - Prevent role changes by unprivileged users
  - Paginate or rate-limit ID enumeration
  - Log suspicious sequential access patterns

#### SSRF via Image URLs (CWE-918)
- **Gravité:** Média-Haute
- **Référence:** CWE-918 - Server-Side Request Forgery: https://cwe.mitre.org/data/definitions/918.html
- **Constat:**
  - `schemas/pizza.py` line 17: `image_url: str` with NO validation
  - Pizza endpoints accept ANY URL without protocol or domain checking
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
- **Remédiation:**
  - Whitelist URL schemes: only `http://` and `https://`
  - Reject `javascript:`, `data:`, `file://`, `gopher://`, `dict://`, etc.
  - Validate domain against allowlist (e.g., CDN domains only)
  - Implement timeout and size limits on URL fetches
  - Use Pydantic `HttpUrl` validator for stricter validation

#### Route Guard Bypass on Client-Side Checks (CWE-602)
- **Gravité:** Haute
- **Référence:** CWE-602 - Client-Side Enforcement of Server-Side Security: https://cwe.mitre.org/data/definitions/602.html
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
- **Remédiation:**
  - Move trust to the backend and keep guards as UX only.
  - Fetch the current user profile from the server and verify it before rendering sensitive pages.
  - Clear state on decode errors instead of treating them as partial success.

#### Weak Admin Guard and Role Bypass (CWE-269)
- **Gravité:** Critique
- **Référence:** CWE-285 - Improper Authorization: https://cwe.mitre.org/data/definitions/285.html
- **Constat:**
  - `admin.guard.ts` checks only `isLoggedIn()` and then trusts `getUserRole()` from the decoded JWT.
  - The guard is purely client-side and can be bypassed by modifying storage or the token payload.
  - The `AuthGuard` and `AdminGuard` only protect navigation, not the backend.
- **Impact:**
  - UI-only authorization can be bypassed without any server compromise.
  - Attackers can directly call privileged endpoints even if the menu is hidden.
- **PoC:**
  - Replace the stored token with a forged one whose payload contains `role: Admin` and revisit `/admin`.
- **Remédiation:**
  - Keep route guards as convenience only.
  - Enforce every privileged action on the server.
  - Do not use decoded client-side claims as proof of authorization.

#### Bearer Token Bypass & Algorithm Confusion (CWE-347)
- **Gravité:** Média-Haute
- **Référence:** CWE-347 - Improper Verification of Cryptographic Signature: https://cwe.mitre.org/data/definitions/347.html
- **Constat:**
  - `security/service.py` line 49: `jwt.decode()` may accept multiple algorithms
  - No explicit check that token's `alg` field matches expected algorithm
  - Potential for `alg: "none"` (unsigned) token bypass
  - Potential for algorithm confusion (HS256 vs RS256 if public key is known)
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
- **Remédiation:**
  - Enforce strict algorithm: `jwt.decode(..., algorithms=["HS256"])` ONLY
  - Verify `exp` (expiration) is validated
  - Reject tokens with `alg: "none"`
  - Use PyJWT 2.x with strict defaults
  - Verify algorithm matches exactly before processing

#### Mitm via Insecure CORS & HTTP Origins (CWE-319)
- **Gravité:** Média-Haute
- **Référence:** CWE-319 - Cleartext Transmission of Sensitive Information: https://cwe.mitre.org/data/definitions/319.html
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
- **Remédiation:**
  - Enforce HTTPS in production:
    ```python
    if not settings.DEBUG:
      ALLOWED_ORIGINS = ["https://app.example.com"]
    ```
  - Implement HSTS: `Strict-Transport-Security: max-age=63072000; includeSubDomains`
  - Set secure cookie flags: `HttpOnly`, `Secure`, `SameSite=Strict`
  - Remove all `http://` origins in production
  - Force HTTPS redirect

#### Nginx Reverse Proxy Misconfiguration
- **Gravité:** Moyenne à élevée
- **Référence:** CWE-319 - Cleartext Transmission of Sensitive Information: https://cwe.mitre.org/data/definitions/319.html
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
- **Remédiation:**
  - Add a dedicated HTTP server block that returns `301` to HTTPS.
  - Keep backend traffic internal only and expose only the TLS listener.
  - Add security headers at the proxy layer.

#### Cleartext Credential or Token Interception
- **Gravité:** Élevée
- **Référence:** CWE-319 - Cleartext Transmission of Sensitive Information: https://cwe.mitre.org/data/definitions/319.html
- **Constat:**
  - The login/register pages exchange credentials through the browser, and any HTTP fallback or proxy downgrade exposes them.
  - The app stores the bearer token in browser storage and then reuses it on every request.
- **Impact:**
  - Passwords and tokens can be sniffed by a reverse proxy, browser extension, hostile Wi-Fi, or injected script if transport is not fully hardened.
- **PoC:**
  - Intercept the `/token` exchange in the browser DevTools or a proxy and inspect the form body and Authorization header.
- **Remédiation:**
  - Enforce HTTPS everywhere, including redirects from port 80.
  - Use secure cookie-based sessions if possible instead of bearer tokens in the browser.
  - Add HSTS so the browser never falls back to HTTP.

#### Privilege Escalation: Self-Role Modification (CWE-269)
- **Gravité:** Crítica
- **Référence:** CWE-269 - Improper Access Control: https://cwe.mitre.org/data/definitions/269.html
- **Constat:**
  - `schemas/user.py` line 13: `UserUpdate` includes `role: UserRole` field
  - `routers/user.py` line 26: Update endpoint does NOT validate role change authorization
  - Unprivileged users can POST with `"role": "Admin"` to escalate
- **Impact:**
  - Normal user → Admin escalation in single request
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
- **Remédiation:**
  - Remove `role` field from `UserUpdate` schema
  - Or create separate admin-only endpoint for role changes
  - Add explicit authorization check preventing self-escalation

#### Timing Attack Lure Vulnerability (CWE-697, CWE-208)
- **Gravité:** Média
- **Référence:** CWE-208 - Observable Timing Discrepancy: https://cwe.mitre.org/data/definitions/208.html
- **Constat:**
  - `security/service.py` line 22: Hardcoded bcrypt hash `PROTECTION_AGAINST_TIMING_ATTACK` used as lure
  - This **predictable** fake hash enables targeted timing attacks
  - Attacker can enumerate usernames via response time measurement
  - No constant-time password comparison in `verify_password()`
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
- **Remédiation:**
  - Generate **random** lure hash at runtime (never reused)
  - Implement constant-time password comparison using `secrets.compare_digest()`
  - Rate limit `/token` endpoint to prevent timing attack exploitation


### Data Exposure
- **Constat 2: exposition trop large des commentaires**
  - L'endpoint `/pizza/{pizza_id}/comment/` ne filtre pas réellement par `pizza_id` et peut retourner l'ensemble des commentaires.
- **Preuves (code):**
  - `MyPizzaApp/backend/src/awefull_pizza_shop/webserver/routers/comment.py`
  - `MyPizzaApp/backend/src/awefull_pizza_shop/database/comment/service.py`
- **Impact:**
  - Fuite de données inter-ressources, utile pour la reconnaissance et la préparation d'attaque.

- **Remédiations:**
  - Interdire le HTML utilisateur (ou sanitization stricte côté serveur avec allowlist minimale).
  - Supprimer `bypassSecurityTrustHtml` pour des données non fiables.
  - Ne jamais injecter de token admin dans un navigateur automatisé déclenché par des entrées utilisateur.
  - Filtrer strictement les commentaires par `pizza_id` côté repository.
1.  **xss-poller.mjs: divulgation de version framework (Express)**
      - **Référence (HTTP headers):** OWASP Secure Headers Project: https://owasp.org/www-project-secure-headers/
    - **Verdict:** Confirmé (faible)
    - **Pourquoi:** Express expose `X-Powered-By` par défaut.
    - **Remédiation:**
      - Ajouter `app.disable('x-powered-by')`.

- **Gravité:** Faible à moyenne
- **Référence:** CWE-425 - Direct Request for 'Hidden' File or Resource: https://cwe.mitre.org/data/definitions/425.html
- **Constat:**
  - `app.routes.ts` has the wildcard route commented out.
  - Invalid routes are not centrally handled, which makes probing and error behavior more predictable.
- **Impact:**
  - Attackers can enumerate route structure from error handling and fallback behavior.
  - Missing 404 routing often exposes application internals during probing.
- **PoC:**
  - Navigate to random paths such as `/adminn`, `/pizza/../login`, or `/does-not-exist` and inspect the behavior.
- **Remédiation:**
  - Reintroduce a catch-all route with a safe 404 component.
  - Make invalid routes return a consistent, non-informative response.

- **Gravité:** Moyenne
- **Référence:** CWE-200 - Exposure of Sensitive Information to an Unauthorized Actor: https://cwe.mitre.org/data/definitions/200.html
- **Constat:**
  - `environment.ts` ships the API base URL into the browser bundle.
  - `tsconfig.json` enables `sourceMap: true`, which is dangerous if production builds keep sourcemaps enabled.
  - Sourcemaps and bundle artifacts can reveal source paths, component names, comments, and implementation details in Chrome DevTools.
- **Impact:**
  - Attackers can reconstruct the frontend codebase and discover hidden routes or logic.
  - Internal endpoints, comments, and helper names become easier to target.
- **PoC:**
  - Open DevTools on a production build and inspect loaded `.map` files or source trees.
- **Remédiation:**
  - Disable sourcemaps for production unless they are access-controlled.
  - Keep environment files free of secrets.
  - Audit the build output to ensure no unintended debug metadata is shipped.


### Supply Chain Vulnerabilities
1. **Dockerfile-XSS-poller: npm install sans `--ignore-scripts`**
   - **Verdict:** Confirmé (risque réel)
   - **Pourquoi:** Les hooks `preinstall/postinstall` des dépendances NPM peuvent exécuter du code à la build.
   - **Remédiation:**
     - Privilégier `npm ci` avec lockfile.
     - Ajouter `--ignore-scripts` si compatible avec les dépendances réellement nécessaires.
     - Exécuter sous utilisateur non root si possible.
1. **backend/Dockerfile: pip sans `--only-binary :all:`**
   - **Verdict:** Confirmé (durcissement recommandé)
   - **Pourquoi:** Sans contrainte binaire, `pip` peut construire depuis source et exécuter des scripts de build de dépendances.
   - **Remédiation:**
     - Ajouter `--only-binary :all:` lorsque possible.
     - Utiliser des wheels de confiance.
     - Exécuter l'installation dans une étape de build contrôlée.
---
