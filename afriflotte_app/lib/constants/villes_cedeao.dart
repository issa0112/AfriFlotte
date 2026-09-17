/// Villes suggérées par pays CEDEAO, pour assister la saisie des champs
/// ville (demande de transport, camion...) — cf. `VilleAutocompleteField`.
///
/// Liste indicative (villes principales/économiques), pas exhaustive : le
/// champ associé reste toujours du texte libre, une ville absente d'ici
/// reste acceptée. Complétez cette table au besoin, aucun autre fichier n'a
/// à changer.
const Map<String, List<String>> villesParPays = {
  'BJ': [
    'Cotonou', 'Porto-Novo', 'Parakou', 'Djougou', 'Bohicon', 'Kandi',
    'Abomey', 'Natitingou', 'Lokossa', 'Ouidah', 'Abomey-Calavi', 'Pobè',
    'Savé', 'Nikki', 'Kérou',
  ],
  'BF': [
    'Ouagadougou', 'Bobo-Dioulasso', 'Koudougou', 'Banfora', 'Ouahigouya',
    'Kaya', 'Tenkodogo', 'Fada N\'Gourma', 'Dédougou', 'Réo', 'Gaoua',
    'Dori', 'Ziniaré', 'Pouytenga', 'Houndé',
  ],
  'CV': [
    'Praia', 'Mindelo', 'Santa Maria', 'Assomada', 'Espargos',
    'Pedra Badejo', 'Tarrafal', 'Sal Rei', 'Porto Novo', 'São Filipe',
  ],
  'CI': [
    'Abidjan', 'Bouaké', 'Yamoussoukro', 'Daloa', 'San-Pédro', 'Korhogo',
    'Man', 'Divo', 'Gagnoa', 'Abengourou', 'Anyama', 'Agboville',
    'Grand-Bassam', 'Soubré', 'Bondoukou', 'Ferkessédougou', 'Odienné',
  ],
  'GM': [
    'Banjul', 'Serekunda', 'Brikama', 'Bakau', 'Farafenni', 'Lamin',
    'Sukuta', 'Basse Santa Su', 'Gunjur', 'Soma',
  ],
  'GH': [
    'Accra', 'Kumasi', 'Tamale', 'Sekondi-Takoradi', 'Sunyani',
    'Cape Coast', 'Obuasi', 'Tema', 'Koforidua', 'Ho', 'Wa', 'Bolgatanga',
    'Techiman',
  ],
  'GN': [
    'Conakry', 'Nzérékoré', 'Kankan', 'Kindia', 'Labé', 'Mamou', 'Boké',
    'Faranah', 'Kissidougou', 'Guéckédou', 'Siguiri', 'Dabola',
    'Dinguiraye', 'Fria', 'Coyah',
  ],
  'GW': [
    'Bissau', 'Bafatá', 'Gabú', 'Bissorã', 'Bolama', 'Cacheu', 'Catió',
    'Farim', 'Mansôa', 'Buba',
  ],
  'LR': [
    'Monrovia', 'Gbarnga', 'Kakata', 'Buchanan', 'Zwedru', 'Voinjama',
    'Harper', 'Ganta', 'Robertsport', 'Greenville',
  ],
  'ML': [
    'Bamako', 'Sikasso', 'Mopti', 'Koutiala', 'Ségou', 'Kayes', 'Gao',
    'Kati', 'Koulikoro', 'San', 'Tombouctou', 'Kidal', 'Bougouni',
    'Markala', 'Niono', 'Nioro du Sahel',
  ],
  'NE': [
    'Niamey', 'Zinder', 'Maradi', 'Agadez', 'Tahoua', 'Dosso', 'Diffa',
    'Tillabéri', 'Arlit', 'Birni N\'Konni', 'Gaya', 'Dogondoutchi',
  ],
  'NG': [
    'Lagos', 'Kano', 'Ibadan', 'Abuja', 'Port Harcourt', 'Benin City',
    'Kaduna', 'Enugu', 'Zaria', 'Aba', 'Onitsha', 'Warri', 'Sokoto',
    'Calabar', 'Uyo', 'Ilorin', 'Maiduguri', 'Jos', 'Owerri', 'Abeokuta',
  ],
  'SN': [
    'Dakar', 'Touba', 'Thiès', 'Kaolack', 'Mbour', 'Rufisque',
    'Saint-Louis', 'Ziguinchor', 'Diourbel', 'Louga', 'Tambacounda',
    'Kolda', 'Richard-Toll', 'Kédougou', 'Matam',
  ],
  'SL': [
    'Freetown', 'Bo', 'Kenema', 'Makeni', 'Koidu', 'Lunsar', 'Port Loko',
    'Waterloo', 'Kabala', 'Kailahun',
  ],
  'TG': [
    'Lomé', 'Sokodé', 'Kara', 'Kpalimé', 'Atakpamé', 'Dapaong', 'Tsévié',
    'Aného', 'Mango', 'Bassar',
  ],
};
