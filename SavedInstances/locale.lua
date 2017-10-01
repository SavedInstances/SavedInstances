-- my custom locale file - more streamlined than AceLocale and no lib dependency

-- To help with missing translations please go here:
local url = "http://www.wowace.com/addons/saved_instances/localization/"

local addonName, vars = ...
local Ld, La = {}, {}
local locale = GAME_LOCALE or GetLocale()
if locale == "enGB" then locale = "enUS" end

vars.L = setmetatable({},{
  __index = function(t, s)
    if locale ~= "enUS" and Ld[s] and
      not La[s] and url and not vars.locale_warning then
      vars.locale_warning = true
      print(string.format("*** %s needs help translating to your language! (%s)", addonName, locale))
      print("*** If you speak English, you can contribute by visiting:")
      print("*** "..url)
    end
    return La[s] or Ld[s] or rawget(t,s) or s
  end
})

--@localization(locale="enUS", format="lua_additive_table", table-name="Ld")@

if locale == "frFR" then
  --@localization(locale="frFR", format="lua_additive_table", table-name="La")@
    La["|cffffff00Left-click|r to detach tooltip"] = "|cffffff00Clic-gauche|r pour détacher l'infobulle."
    La["|cffffff00Middle-click|r to show Blizzard's Raid Information"] = "|cffffff00Clic-milieu|r pour afficher les Infos Raid de Blizzard."
    La["|cffffff00Right-click|r to configure SavedInstances"] = "|cffffff00Clic-droit|r pour configurer SavedInstances."
    La["Abbreviate keystones"] = "Noms de donjons abrégés"
    La["Abbreviate Mythic keystone dungeon names"] = "Abréger les noms des donjons de clés mythiques"
    La["Account"] = "Compte"
    La["Account Summary"] = "Résumé du compte"
    La["Alternating columns are colored differently"] = "Les colonnes alternées sont colorées différemment"
    La["Always show"] = "Toujours afficher"
    La["Always show new instances"] = "Toujours afficher les nouvelles instances"
    La["Are you sure you want to remove %s from the SavedInstances character database?"] = "Êtes-vous sûr de vouloir supprimer le personnage %s de la base de données SavedInstances ?"
    La["Are you sure you want to reset the SavedInstances character database? Characters will be re-populated as you log into them."] = "Êtes-vous sûr de vouloir remettre à zéro votre base de données de personnages pour SavedInstances ? Les données des personnages seront re-récupérées au moment où vous les connecterez."
    La["Attempt to recover completed daily quests for this character. Note this may recover some additional, linked daily quests that were not actually completed today."] = "Tente de récupérer les quêtes journalières accomplies par ce personnage. Notez que cela peut récupérer certaines quêtes supplémentaires liées qui n'ont pas été accomplies aujourd'hui."
    La["Augment bonus loot frame"] = "Augmenter la taille du cadre des butins bonus"
    La["Automatically shrink the tooltip to fit on the screen"] = "Réduit automatiquement la taille de l'infobulle pour la faire tenir sur l'écran."
    La["Battleground Deserter"] = "Déserteur"
    La["Bind a key to toggle the SavedInstances tooltip"] = "Associez une touche à l'affichage de l'infobulle de SavedInstance."
    La["Bonus rolls"] = "Jets de dé bonus"
    La["Boss kill information is missing for this lockout.\\nThis is a Blizzard bug affecting certain old raids."] = "Les informations de mort des boss manquent pour ce verrouillage d'instance.\\nC'est un bogue de Blizzard qui touche certains vieux raids."
    La["Categories"] = "Catégories"
    La["Character column style"] = "Style de la colonne de personnage"
    La["Characters"] = "Personnages"
    La["Color currency by cap"] = "Colorer les monnaies par cap"
    La["Columns are colored according to the characters class"] = "Les colonnes sont colorées en fonction de la classe des personnages"
    La["Columns are the same color as the whole tooltip"] = "Les colonnes sont de la même couleur que l'infobulles"
    La["Combine LFR"] = "Fusionner les RdR"
    La["Combine World Bosses"] = "Fusionner les boss extérieurs"
    La["Connected Realms"] = "Royaumes connectés"
    La["Crops growing"] = "Cultures en croissance "
    La["Crops harvested today"] = "Cultures récoltées aujourd'hui "
    La["Crops planted today"] = "Cultures plantées aujourd'hui "
    La["Crops ready"] = "Cultures prêtes "
    La["Currency settings"] = "Monnaies"
    La["Daily Quests"] = "Quêtes journalières"
    La["Debug Mode"] = "Mode débogage"
    La["Day"] = "Jour"
    La["Disable mouseover"] = "Désactiver le survol avec la souris"
    La["Disable tooltip display on icon mouseover"] = "Désactive l'affichage de l'infobulle lors du survol de la souris."
    La["Display instances in order of recommended level from lowest to highest"] = "Affiche les instances dans l'ordre du niveau recommandé le plus bas au plus élevé."
    La["Display instances with space inserted between categories"] = "Affiche les instances avec un espace entre les catégories."
    La["Dump time debugging information"] = "Enregistrer les informations de débogage des timings"
  	La["Dump quest debugging information"] = "Enregistrer les informations de débogage des quêtes"
    La["Emissary Missing"] = "Émissaire manquant"
    La["Expansion"] = "Extension"
    La["Expired Lockout - Can be extended"] = "Verrouillage expiré - Peut être étendu"
    La["Extended Lockout - Not yet saved"] = "Verrouillage étendu - Pas encore sauvegardé"
    La["Facets of Research"] = "Facettes de recherche"
    La["Farm crops"] = "Récoltes de la ferme"
    La["Farm Crops"] = "Cultures de la ferme"
    La["Fit to screen"] = "Ajuster à la taille de l'écran"
    La["Flex"] = "Dynamique"
    La["Format large numbers"] = "Formater les grands nombres"
    La["General settings"] = "Options générales"
    La["Group"] = "Grouper"
    La["Hold Alt to show all data"] = "Maintenez Alt pour afficher toutes les données."
    La["Hover mouse on indicator for details"] = "Survolez les indicateurs avec la souris pour plus d'informations."
    La["Ignore"] = "Ignorer"
    La["Indicators"] = "Indicateurs"
    La["Instances"] = "Instances"
    La["Instance limit in Broker"] = "Limite d'instance dans la barre (libBroker)"--A VERIFIER
    La["Interleave"] = "Entrelacer"
    La["Last updated"] = "Dernière mise à jour :"
    La["Last Week Reward Usable"] = "Cache hebdomadaire disponible"
    La["Legion Transmute"] = "Transmutation Légion"
    La["Level %d Characters"] = "Personnages de niveau %d"
    La["LFG cooldown"] = "Recherche de groupe"
    La["LFR"] = "RdR"
    La["List categories from the current expansion pack first"] = "Liste les catégories de l'extension actuelle en premier."
    La["List raid categories before dungeon categories"] = "Liste les catégories de raids avant celles des donjons."
    La["Lockouts"] = "Verrouillages"
    La["Manage"] = "Gérer"
    La["Miscellaneous Tracking"] = "Suivis divers "
    La["Most recent first"] = "Les plus récents en premier"
    La["Move down"] = "Déplacer vers le bas"
    La["Move up"] = "Déplacer vers le haut"
    La["Mythic Best"] = "Meilleur temps mythique"
    La["Mythic Keystone"] = "Clé Mythique"
    La["Mythic Key Best"] = "Meilleur niveau de clé"
    La["Never show"] = "Ne jamais afficher"
    La["Opacity of the tooltip row highlighting"] = "Opacité de la mise en évidence des rangées de l'infobulle."
    La["Open config"] = "Ouvrir la configuration"
    La["Plant"] = "Plantes"
    La["Raids before dungeons"] = "Raids avant les donjons"
    La["Recent Bonus Rolls"] = "Jets de dé bonus récents"
    La["Recent Instances"] = "instance(s) récente(s) "
    La["Recover Dailies"] = "Récupérer les journalières"
    La["Remind about weekly charm quest"] = "Rappel de la quête hebdo. de charmes"
    La["Reminder: You need to do quest %s"] = "Rappel : vous devez faire la quête %s"
    La["Report instance resets to group"] = "Indiquer les réinitialisations d'instances au groupe"
    La["Reset Characters"] = "Remise à zéro des personnages"
    La["Reverse ordering"] = "Ordre inversé"
    La["Roll Bonus"] = "Jets de dé bonus"
    La["Row Highlight"] = "Surbrillance des rangées"
    La["Seed"] = "Graine"
    La["Seeds"] = "Graines"
    La["Set All"] = "Tout régler sur :"
    La["Show category names"] = "Noms des catégories"
    La["Show category names in the tooltip"] = "Affiche les noms des catégories dans l'infobulle."
    La["Show cooldown for characters to use battleground system"] = "Affiche le temps restant avant que les personnages déserteurs ne puissent rejoindre un champs de bataille à nouveau."
    La["Show cooldown for characters to use LFG dungeon system"] = "Affiche le temps restant avant que les personnages ne puissent utiliser l'outil Recherche de groupe à nouveau."
    La["Show currency max"] = "Voir le total maximum de monnaie"
    La["Show currency earned"] = "Voir les monnaies gagnées"
    La["Show Expired"] = "Afficher les expirés"
    La["Show expired instance lockouts"] = "Affiche les verrouillages d'instances expirés."
    La["Show Holiday"] = "Evènements saisonniers"
    La["Show holiday boss rewards"] = "Affiche les récompenses des boss d’événements saisonniers."
    La["Show minimap button"] = "Bouton sur la mini-carte"
    La["Show name for a category when all displayed instances belong only to that category"] = "Affiche le nom d'une catégorie quand toutes les instances affichées appartiennent uniquement à cette catégorie."
    La["Show only current server"] = "Serveur actuel uniquement"
    La["Show Random"] = "Sacoches Recherche de groupe"
    La["Show random dungeon bonus reward"] = "Affiche les récompenses bonus des donjons aléatoires."
    La["Show self always"] = "Toujours afficher soi-même"
    La["Show self first"] = "Afficher soi-même en premier"
    La["Show server name"] = "Afficher le nom du serveur"
    La["Show the SavedInstances minimap button"] = "Affiche le bouton de SavedInstances sur la mini-carte."
    La["Show tooltip hints"] = "Astuces sur l'infobulle"
    La["Show When"] = "Montrer quand"
    La["Show when not saved"] = "Afficher quand non sauvegardé"
    La["Show when saved"] = "Quand inscrit"
    La["Show/Hide the SavedInstances tooltip"] = "Afficher/cacher l'infobulle de SavedInstances"
    La["Similarly, the words KILLED and TOTAL will be substituted with the number of bosses killed and total in the lockout."] = "De la même manière, les mots KILLED et TOTAL seront remplacés par le nombre de boss tués et le nombre total de boss du raid pour ce verrouillage."
    La["Single category name"] = "Nom de catégorie unique"
    La["Sort by server"] = "Trier par serveur"
    La["Sort categories by"] = "Trier les catégories par :"
    La["Sort Order"] = "Ordre de tri"
    La["Space between categories"] = "Espacer les catégories"
    La["Text"] = "Texte"
    La["The Four Celestials"] = "Les Quatre Astres"
    La["These are the instances that count towards the %i instances per hour account limit, and the time until they expire."] = "Ces instances comptent dans la limite de %i instances par heure pour le compte, et le temps avant qu'elles n'expirent."
    La["This should only be used for characters who have been renamed or deleted, as characters will be re-populated when you log into them."] = "Ceci ne devrait être utilisé que pour les personnages qui ont été renommés ou supprimés car les personnages seront de toutes façons ré-affichés lorsque vous vous connecterez avec."
    La["Throw"] = "Lancer"
    La["Time /played"] = "Temps /joué"
    La["Time Left"] = "Temps restant "
    La["Tooltip Scale"] = "Taille de l'infobulle"
    La["Track"] = "Suivre"
  	La["Track Mythic Keystone best run"] = "Suivre le meilleur temps pour la clé de donjon mythique"
    La["Trade Skill Cooldowns"] = "Échéances des métiers"
    La["Trade skills"] = "Échéances des métiers"
    La["Transmute"] = "Transmutation"
    La["Type"] = "Type"
    La["Use class color"] = "Colorer par classe"
  	La["Warn about instance limit"] = "Alerte sur la limite d'instance"
    La["Warning: You've entered about %i instances recently and are approaching the %i instance per hour limit for your account. More instances should be available in %s."] = "Attention : vous êtes entré dans %i instances récemment et approchez la limite de %i instances par heure pour ce compte. Plus d'instances seront disponibles dans environ %s."
    La["Weekly Quests"] = "Quêtes hebdomadaires"
    La["Wild Transmute"] = "Transmutation sauvage"
    La["World Boss"] = "Boss extérieur"
    La["World Bosses"] = "Boss extérieurs"
    La["You can combine icons and text in a single indicator if you wish. Simply choose an icon, and insert the word ICON into the text field. Anywhere the word ICON is found, the icon you chose will be substituted in."] = "Si vous le souhaitez, vous pouvez combiner les icônes et le texte en un seul indicateur. Il vous suffit de choisir une icône et d'insérer le mot ICON dans la zone de texte. Partout où le mot ICON sera trouvé, l'icône que vous avez choisi sera mise à la place."
    La["EoA"] = "Œil d'Azshara"
    La["DHT"] = "Fourré sombrecoeur"
    La["BRH"] = "Bastion du Freux"
    La["HoV"] = "Salles des valeureux"
    La["Nelt"] = "Repaire de Neltharion"
    La["VotW"] = "Caveau des Gardiennes"
    La["MoS"] = "Gueule des âmes"
    La["Arc"] = "Arcavia"
    La["CoS"] = "Cour des étoiles"
    La["L Kara"] = "Karazhan (bas)"
    La["CoEN"] = "Cathédrale de la nuit éternelle"
    La["U Kara"] = "Karazhan (haut)"
    La["SotT"] = "Siège du Triumviraat"
elseif locale == "deDE" then
  --@localization(locale="deDE", format="lua_additive_table", table-name="La")@
elseif locale == "koKR" then
  --@localization(locale="koKR", format="lua_additive_table", table-name="La")@
    La["EoA"] = "아즈"
    La["DHT"] = "어숲"
    La["BRH"] = "검까"
    La["HoV"] = "용맹"
    La["Nelt"] = "넬타"
    La["VotW"] = "감시관"
    La["MoS"] = "아귀"
    La["Arc"] = "비전로"
    La["CoS"] = "별궁"
    La["L Kara"] = "하층"
    La["CoEN"] = "대성당"
    La["U Kara"] = "상층"
    La["SotT"] = "삼두정"
elseif locale == "esMX" then
  --@localization(locale="esMX", format="lua_additive_table", table-name="La")@
elseif locale == "ruRU" then
  --@localization(locale="ruRU", format="lua_additive_table", table-name="La")@
elseif locale == "zhCN" then
  --@localization(locale="zhCN", format="lua_additive_table", table-name="La")@
elseif locale == "esES" then
  --@localization(locale="esES", format="lua_additive_table", table-name="La")@
elseif locale == "zhTW" then
  --@localization(locale="zhTW", format="lua_additive_table", table-name="La")@
elseif locale == "ptBR" then
  --@localization(locale="ptBR", format="lua_additive_table", table-name="La")@
elseif locale == "itIT" then
  --@localization(locale="itIT", format="lua_additive_table", table-name="La")@
end
