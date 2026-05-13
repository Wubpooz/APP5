# MyPizzaApp CTF Walkthrough
**Table des matières**
- [MyPizzaApp CTF Walkthrough](#mypizzaapp-ctf-walkthrough)
  - [Consignes](#consignes)
  - [Plan](#plan)
    - [Phase 1: Static Code Analysis](#phase-1-static-code-analysis)
    - [Phase 2: Dynamic Analysis \& Recon](#phase-2-dynamic-analysis--recon)
    - [Phase 3: The Exploitation Chain (Getting the Flags)](#phase-3-the-exploitation-chain-getting-the-flags)
    - [Phase 4: Writing the Sysreptor Report](#phase-4-writing-the-sysreptor-report)
  - [Phase 1: SAST](#phase-1-sast)
    - [Hardcoded Secrets](#hardcoded-secrets)
    - [SQL Injection (SQLi)](#sql-injection-sqli)
    - [Business Logic Flaws](#business-logic-flaws)
    - [Insecure File Upload](#insecure-file-upload)
    - [Command Injection](#command-injection)


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
Map the Application: Register a user, log in, view items, add to cart, check out. Capture this traffic using a proxy like Burp Suite or OWASP ZAP on your local machine if you can route it, or use the browser's Network tab.  

Directory Bruteforcing: Even with source code, it helps to map the live app. Use dirb or dirbuster on the VM with a SecLists wordlist to find hidden directories that might not be obvious in the code structure:
```Bash
dirb https://app1.tiweb.tp.ubik.academy /usr/share/seclists/Discovery/Web-Content/common.txt
```

### Phase 3: The Exploitation Chain (Getting the Flags)
Based on the lab description, you need a chain of exploits to compromise the server. A typical CTF kill-chain looks like this:
- Initial Access: Exploit a SQLi (using sqlmap to automate it once you find it in the code) to bypass login, or exploit a logic flaw to steal an admin's session. [Flag 1]
- Privilege Escalation (Web): Once logged in as a normal user, find an IDOR (Insecure Direct Object Reference) to change another user's password or elevate your role to "Admin". [Flag 2]
- Remote Code Execution (RCE): As an admin, find a feature that interacts with the underlying OS (like a "ping" diagnostic tool, or an image upload feature). Upload a reverse shell or exploit a command injection vulnerability to get a shell on the server. [Flag 3]
- System Privilege Escalation (Root): Once you have a shell on the server as the www-data or app user, you need to become root.
  Check sudo permissions: `sudo -l`
  Check for SUID binaries: `find / -perm -4000 -type f 2>/dev/null`
  Check running processes: `htop` or `ps aux`
- Search GTFOBins online for ways to exploit standard Linux binaries with misconfigured permissions. [Final Flag]

### Phase 4: Writing the Sysreptor Report
As you go, take screenshots of everything. A good Sysreptor report should be professional and structured:
Executive Summary: A non-technical summary saying "MyPizzaApp is critically vulnerable. An attacker can manipulate prices and ultimately take control of the hosting server."

Vulnerability Details (For each bug):
- Title: e.g., Unauthenticated SQL Injection in Login Portal.
- Description: Explain the flaw in the code.
- Proof of Concept (PoC): Step-by-step instructions on how to reproduce it, including your exact payloads and screenshots.
- Impact: What does this allow an attacker to do? (e.g., "Allows dumping of the entire customer database").
- Remediation: Provide the exact fixed code (e.g., "Implement prepared statements using PDO...").
- Attack Scenario: Tell the story of your kill-chain from step 1 to full server compromise, just like they asked in the prompt.


---


## Phase 1: SAST
### Hardcoded Secrets

### SQL Injection (SQLi)

### Business Logic Flaws

### Insecure File Upload

### Command Injection


