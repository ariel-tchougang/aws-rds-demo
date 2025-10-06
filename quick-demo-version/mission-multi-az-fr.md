# Mission Multi-AZ : Opération DB007

> 🏠 **Retour vers :** [README Principal](README.md) | [English Brief](mission-multi-az-en.md)

**Contexte**  
L'agent **DB007**, consultant IT d'élite, est mandaté par **DataCorp**.  
Leur défi : comment assurer la **continuité de service** de leur base de données critique face aux pannes, coupures d'AZ ou catastrophes locales ?  

La mission : démontrer qu'avec AWS RDS en **déploiement Multi-AZ**, leurs données et leurs opérations résistent aux imprévus, avec un **RPO = 0** et un **RTO minimal**.  

---

## Étapes de la mission

### 1. Mise en place du terrain d'opération
- Déployer un **VPC réparti sur deux zones de disponibilité (AZs)**.  
- **Version rapide** : Deux subnets publics pour l'application et RDS (setup simplifié).  

### 2. Activation du coffre-fort numérique
- Lancer une instance **RDS PostgreSQL (ou MySQL)** en mode **Multi-AZ**.  
- AWS crée automatiquement une **réplique synchronisée** dans la seconde AZ.  

### 3. Simulation d'activité ennemie
- Exécuter l'agent DB007 **directement depuis votre PC ou CloudShell**.  
- Génère en continu des **INSERT** et **SELECT** avec timestamps.  

### 4. Reconnaissance du terrain
- Interroger la base de données :  
  - La **primaire** est bien en **AZ1**.  
  - La **standby** attend en **AZ2**, prête à entrer en scène.  

### 5. Sabotage contrôlé
- Déclencher un **reboot avec failover** : simulation d'une panne soudaine en AZ1.  

### 6. Zone de turbulences
- Le trafic s'arrête temporairement.  
- Les applications constatent une interruption brève, mais **aucune corruption** des données.  

### 7. Réorganisation éclair
- La standby est promue en nouvelle **primaire** dans AZ2.  
- Le trafic reprend automatiquement.  

### 8. Preuves de résilience
- Les données écrites juste avant la panne sont toujours présentes.  
- Démonstration d'un **RPO = 0** et d'un **RTO de quelques secondes**.  

### 9. Nouvel ordre établi
- Confirmer l'état :  
  - **Primaire → AZ2**  
  - **Standby → recréée en AZ1**  
- DataCorp peut dormir tranquille : leur base est désormais **protégée par conception**.  

---

## Rapport de mission
> *« Mission accomplie. Grâce à AWS RDS Multi-AZ, DataCorp survit même aux pannes les plus sournoises… et DB007 garde sa licence to query. »* 🕶️

---

📚 **Pour l'implémentation technique :** Consultez le [README principal](README.md) pour le déploiement rapide (setup 5 minutes).