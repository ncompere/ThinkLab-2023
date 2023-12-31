# ThinkLab 2023
 
Se placer dans le dossier du projet et lancer la commande suivante:
```bash
julia
```
Une fois dans le REPL de Julia, lancer les commandes suivantes:
```julia
include("main.jl")
```
Le programme va alors se lancer. Le premier lancement prend plus de temps pour compiler le projet.
Le programme vous invite à entrer le nom du fichier de données à utiliser (sans l'extension).
Le premier temps de résolution correspond au Scatter Search et le deuxième au solveur MOA.
Vous obtenez les plots des solutions dans le dossier `plot` et un résumé des résultats dans le dossier `file`.