"""
Complétez les parties marquées TODO.

Rappel de l'algorithme FloodSet:
- Chaque processus maintient un ensemble W de valeurs connues
- Au début: W = {ma_valeur_initiale}
- À chaque round: on envoie W à tout le monde, on reçoit les W des autres
- On fusionne tout dans notre W: W = W UNION tous_les_W_reçus
- Après f+1 rounds, on décide:
    - Si W contient une seule valeur -> on décide cette valeur
    - Sinon -> on décide la valeur par défaut v0
"""

# PARAMÈTRES DE LA SIMULATION

from typing import Set


n: int = 4                           # Nombre de processus
f: int = 1                           # Nombre maximum de crashs
total_rounds: int = f + 1            # Nombre de rounds à exécuter
default_value: int = 0               # Valeur par défaut v0

# Scenario 1
initial_values = [1, 1, 1, 1]
crashed = [False, False, False, False]

# Scenario 2
# initial_values = [1, 2, 3, 4]
# crashed = [False, False, False, False]

# Scenario 3
# initial_values = [5, 1, 2, 3]
# crashed = [False, False, True, False]  # P2 crash après round

# # Scenario D
# initial_values = [1, 2, 2, 4]
# crashed = [False, True, False, True]


# État de chaque processus: W[i] = ensemble des valeurs connues par le processus i
# Au début, chaque processus ne connaît que sa propre valeur initiale
W: list[Set[int]] = [set() for _ in range(n)]
for i in range(n):
    W[i] = {initial_values[i]}

# decision[i] = la décision du processus i (None si pas encore décidé)
decision: list[int | None] = [None] * n


# EXERCICE 1: Compléter cette fonction

def receive_and_merge(process_id: int, messages_received: list[Set[int] | None]) -> None:
    """
    Fusionne les messages reçus dans W[process_id].
    
    Cette fonction implémente la ligne du pseudo-code:
        W := W UNION Union_{tous les pj} Xj
    
    W devient l'union de W avec tous les ensembles reçus.
    
    Arguments:
        process_id: l'identifiant du processus (0 à n-1)
        messages_received: liste de n éléments
            - messages_received[j] = ensemble W du processus j (ce qu'il a envoyé)
            - messages_received[j] = None si le processus j n'a pas envoyé (CRASHED)
    
    Exemple:
        Si W[process_id] = {1} et messages_received = [{1,2}, None, {3}]
        Alors après la fonction: W[process_id] = {1, 2, 3}
    
    Indice: 
        - Pour faire l'union de deux ensembles: set1.union(set2)
        - Ou bien: set1 = set1 | set2
    """
    # Pour chaque message reçu (s'il n'est pas None), 
    # ajouter son contenu à W[process_id]
    
    for msg in messages_received:
        if msg is not None:
            W[process_id] = W[process_id].union(msg)


# EXERCICE 2: Compléter cette fonction
def decide(process_id: int) -> None:
    """
    Applique la règle de décision pour le processus process_id.
    
    Cette fonction implémente le pseudo-code:
        Si |W| = 1 alors
            decision := l'unique élément de W
        Sinon
            decision := v0 (valeur par défaut)
    
    La décision doit être stockée dans decision[process_id].
    
    Arguments:
        process_id: l'identifiant du processus (0 à n-1)
    
    Indice:
        - len(W[process_id]) donne le nombre d'éléments dans W
        - Pour extraire l'unique élément d'un ensemble à 1 élément:
          list(W[process_id])[0]  ou  next(iter(W[process_id]))
        - default_value contient v0
    """
    # Vérifier la taille de W[process_id] et décider en conséquence
    if len(W[process_id]) == 1:
        decision[process_id] = next(iter(W[process_id]))  # L'unique élément de W
    else:
        decision[process_id] = default_value  # Valeur par défaut v0


# SIMULATION (ne pas modifier)
def run_simulation():
    """Exécute la simulation FloodSet."""
    
    print(f"Configuration: n={n}, f={f}, rounds={total_rounds}")
    print(f"Valeurs initiales: {initial_values}")
    print(f"Valeur par défaut v0 = {default_value}")
    print()
    
    # Exécuter f+1 rounds
    for round_num in range(1, total_rounds + 1):
        print(f"=== ROUND {round_num} ===")
        
        # Chaque processus prépare son message (son W actuel)
        messages = []
        for i in range(n):
            if crashed[i]:
                messages.append(None)
                print(f"  P{i}: [CRASHED]")
            else:
                messages.append(W[i].copy())
                print(f"  P{i} envoie W = {W[i]}")
        
        # Chaque processus reçoit les messages et met à jour son W
        for i in range(n):
            if not crashed[i]:
                receive_and_merge(i, messages)
        
        # Afficher l'état après le round
        print(f"  État après round {round_num}:")
        for i in range(n):
            if crashed[i]:
                print(f"    P{i}: [CRASHED]")
            else:
                print(f"    P{i}: W = {W[i]}")
        print()
    
    # Phase de décision
    print("=== DÉCISION ===")
    for i in range(n):
        if not crashed[i]:
            decide(i)
            print(f"  P{i}: W = {W[i]} -> décide {decision[i]}")
    
    # Vérification
    print()
    decisions_faites = [decision[i] for i in range(n) if not crashed[i]]
    if None in decisions_faites:
        print("ERREUR: Certains processus n'ont pas décidé")
        print("   Vérifiez votre fonction decide()")
    elif len(set(decisions_faites)) > 1:
        print("ERREUR: Les processus ont décidé des valeurs différentes!")
        print(f"   Décisions: {decisions_faites}")
    else:
        print(f"Consensus. Tout le monde a décidé: {decisions_faites[0]}")

# =============================================================================

# EXERCICE 3: Tester différents scénarios

# Exécutez ce fichier pour tester votre implémentation
# Modifiez les paramètres ci-dessus pour tester différents cas:
#
# Scénario 1: Le cas trivial
# Tout le monde a la même valeur, personne ne crashe.
# Résultat attendu: Tout le monde décide 1.
# initial_values = [1, 1, 1, 1]
# crashed = [False, False, False, False]

# Scénario 2: Le cas de base
# Valeurs différentes, pas de crash.
# Résultat attendu: Tout le monde voit {1,2,3,4} et décide v0 (0).
# initial_values = [1, 2, 3, 4]
# crashed = [False, False, False, False]

# Scénario 3: Le "Crash Critique" (La raison d'être de f+1)
# P0 a une info secrète (5). Il la donne à P1 au round 1, puis crashe.
# P1 la donne à P2 au round 2.
# Si on s'arrêtait à f rounds (f=1), P2 ne l'aurait jamais eue 
#
# Scénario D: Créez et expliquez votre propre scénario 

# ============================================================================
if __name__ == "__main__":
  run_simulation()