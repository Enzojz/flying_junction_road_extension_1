local descEN = [[With this mod it's possible to construct rail/road flying intersections is different forms.
The flying junction mod is needed to use it.]]


local descFR = [[Avec ce mod c'est possible de construir le pont rail/route sous formes différentes.
Le mod "Saut de mouton" est exigé pour son utilisation.]]


local descCN = [[本MOD提供建设各种形式立体道口和公路立交的可能。
需要同“欧式疏解桥”MOD一起使用。]]


function data()
    return {
        en = {
            ["name"] = "Flying Junction Road Extension",
            ["desc"] = descEN,
        },
        fr = {
            ["name"] = "Pont route & Saut de mouton routier",
            ["desc"] = descFR,
            
            ["Curved levels"] = "Niveaux avec courbes",
            ["Crossing angles"] = "Angle de croisement",
            ["Tracks per group"] = "Nombre de voie par groupe",
            ["Form"] = "Forme",
            ["Axis"] = "Axe",
            ["Radius"] = "Rayon",
            ["Slope"] = "Pente",
            ["Mirrored"] = "En miroir",
            ["General Slope"] = "Pente générale",
            ["Tunnel Height"] = "Hauteur de tunnel",
            ["Altitude Adjustment"] = "Ajustement d'altitude",
            ["Bridge"] = "Pont",
            ["Terra"] = "Terre",
            ["Solid"] = "Solide",
            ["Both"] = "Tous",
            ["Lower"] = "Bas",
            ["Upper"] = "Haut",
            ["None"] = "Aucun",
            ["All"] = "Toutes",
            ["Common"] = "Commune",
            
            ["Number of tracks"] = "Nombre des voies",
            ["Road Type"] = "Type de voie routière",
            ["Street"] = "Rue",
            ["Route"] = "Route",
            ["Sepeated road lanes"] = "Séparation des voie routière",
            ["Road slope factor"] = "Coef. pente de route",
            ["Layout"] = "Disposition",
            ["Rail"] = "Rail",
            ["Road"] = "Route",
            ["Structure Form"] = "Forme de structure",
            ["Simple"] = "Simple",
            ["Flying junction"] = "Saut de mouton",
            ["Lower level length"] = "Longueur du niveau bas",
            ["Upper level length"] = "Longueur du niveau haut",
            ["Radius of lower level"] = "Rayon du niveau bas",
            ["Radius of upper level"] = "Rayon du niveau haut",
            
            ["Rail/Road Exchange Crossing"] = "Pont rail/route de changement de position",
            ["Rail/Road Crossing"] = "Pont rail/route",
            ["A flyover rail/road crossing for exchang positions, built in bricks"] = "Un pont rail/route pour changement de positions, construction en pierre de taille",
            ["A flyover rail/road crossing, built in bricks"] = "Un pont rail/route ordinaire, construction en pierre de taille",
            ["A flyover rail/road crossing for exchang positions, built in concrete"] = "Un pont rail/route pour changement de positions, construction en concrete",
            ["A flyover rail/road crossing, built in concrete"] = "Un pont rail/route ordinaire, construction en concrete",
        },
        zh_CN = {
            ["name"] = "立体道口和公路立交",
            ["desc"] = descCN,
            
            ["Curved levels"] = "曲线部分",
            ["Transition A"] = "A过渡区段",
            ["Transition B"] = "B过渡区段",
            ["Form"] = "形式",
            ["Axis"] = "倾斜轴",
            ["Radius"] = "半径",
            ["Slope"] = "坡度",
            ["Crossing angles"] = "交汇角",
            ["Tracks per group"] = "每组轨道数量",
            ["Mirrored"] = "镜像",
            ["General Slope"] = "整体坡度",
            ["Altitude Adjustment"] = "高度调整",
            ["Catenary applied for"] = "接触网用于",
            ["Bridge"] = "桥",
            ["Terra"] = "堆土",
            ["Solid"] = "实心",
            ["Both"] = "两者",
            ["Lower"] = "下层",
            ["Upper"] = "上层",
            ["None"] = "无",
            ["All"] = "所有",
            ["Common"] = "共轴",
            ["Tunnel Height"] = "隧道净高",
            
            ["Number of tracks"] = "下层轨道数量",
            ["Road Type"] = "道路类型",
            ["Street"] = "市政道路",
            ["Route"] = "公路",
            ["Sepeated road lanes"] = "分离车道",
            ["Road slope factor"] = "道路坡度系数",
            ["Layout"] = "布局",
            ["Rail"] = "铁路",
            ["Road"] = "道路",
            ["Structure Form"] = "结构形式",
            ["Simple"] = "简易",
            ["Flying junction"] = "疏解式",
            ["Lower level length"] = "下层轨道长度",
            ["Upper level length"] = "上层轨道长度",
            ["Radius of lower level"] = "下层半径",
            ["Radius of upper level"] = "上层半径",
            
            ["Rail/Road Exchange Crossing"] = "换位立交道口",
            ["Rail/Road Crossing"] = "立交道口",
            ["A flyover rail/road crossing for exchang positions, built in bricks"] = "一个石砖建造的用于换位的立交道口",
            ["A flyover rail/road crossing, built in bricks"] = "一个石砖建造的立交道口",
            ["A flyover rail/road crossing for exchang positions, built in concrete"] = "一个水泥建造的用于换位的立交道口",
            ["A flyover rail/road crossing, built in concrete"] = "一个水泥建造的立交道口",
        }
    }
end
