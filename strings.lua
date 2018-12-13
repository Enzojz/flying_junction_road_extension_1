local descEN = [[With this mod it's possible to construct rail/road flying intersections is different forms.


Implemented functions:
* Crossing angle between 5° and 89° with increment of 1°
* Seperation of lower level
* Independent adjustment of cuvres of road/track
* Left handed or right handed
* Built in concrete or stone bricks
* Raising or trenche transition tracks in possible forms of bridge, terra or solid construction.
* Flying-junction-like structure or bridge-like structure
* Build with slope
* Altitude Adjustment

ATTENTION:
The flying junction mod is needed to use it.

Changelog
1.18
* All tracks are modifiable free edges after construction (with support from the Final Patch)
* Change of menu entry from Rail Depot to Asset/junctions
1.17
* Terrain alignment reimplemented to get rid to zig-zags
* Added 90° options in crossing angle (It's actually 89.95°)
* Improved coliision detection on modification
* Option to choose road era
* Version alignment
1.6
* Model errors when mirrored is set on are fixed
1.5
* Update to be compatible with Flying junction 1.15
1.4
* CommonAPI support
1.3
* Fixed catenary construction error before it's apperance
1.2
* Fixed track number count bug
1.1
* Fixed crash when modifying lower level length when altitude equals to or greater than 100%, or higher level when altitude is 0%
]]


local descFR = [[Avec ce mod c'est possible de construir le pont rail/route sous formes différentes.

Caractéristiques:
* Angle de croisement entre 5° et 89° avec incrément de 1°
* Séparation des voies dans la tunnel
* Changement indépendant de courbure des voies
* Gaucher ou droitier
* Construction en pente
* Voies de transition montant/désendant sous formes de pont, terre ou construction solide.
* Structure comme saut de mouton ou comme pont simple
* Changement d'altitude
* Construction en concrete ou pierre de taille

ATTENTION:
Le mod "Saut de mouton" est exigé pour son utilisation.

Changelog:
1.18
* Tous les voies soitent modifiable après la construction (avec support de patche finale)
* Changement d'entrée de construction du dêpot ferroviaire à asset/junctions
1.17
* Réimplémentation de alignment terrain pour éffacer les zigzags
* Ajoute d'option 90° pour l'angle de croisement (C'est actuellement 89.95°)
* Détection de colission améliorée
* Option pour choisir l'époque de route
* Alignment de version
1.6
* Correction des erreurs des maquettes lors l'infrastructure est en miroir
1.5
* Mise à jour pour être compatible avec Saut de mouton 1.15
1.4
* Support de CommonAPI
1.3
* Correction d'erreur de caténaire construit avant son époque d'existance
1.2
* Correction de nombre de voie
1.1
* Correction de plantage lors modification du longueur du niveau bas, quand l'altitude est équal à ou superieur à 100%, ou pour le niveau haut quand l'altitude est à 0%.]]


local descCN = [[本MOD提供建设各种形式立体道口和公路立交的可能。

特点:
* 5°到89°度的交汇角，调整幅度为1°
* 隧道里面可以设置分组
* 四个独立的轨道曲线调整选项
* 坡度选项
* 高度选项
* 水泥或石砖建造
* 上升/下降的过渡轨道可以以桥、堆土或者实心形式展现
* 整体结构可以为桥或者疏解桥

注意：
需要同“欧式疏解桥”MOD一起使用。


Changelog:
1.18
* 所有的轨道在建设完成后都可以自由修改（需要Final Patch的支持）
* 菜单入口移至 资产/junctions 下
1.17
* 重写了地面重整的算法，消除了锯齿
* 增加了90度交会角的选项
* 改进了碰撞检测
* 增加了道路年代的选项
* 版本对齐
1.6
* 修正了镜像下的模型错误
1.5
* 欧式疏解1.15版兼容升级
1.4
* 增加了CommonAPI支持
1.3
* 修正了在接触网出现年代之前的接触网建造错误
1.2
* 修正了错误的轨道数
1.1
* 修复了在高度调整为100%或者更高的情况下，修改下层长度，以及在高度调整为0%修改上层长度时引发的游戏崩溃]]


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
            ["Road Era"] = "Epoque de route",
            ["Ancien"] = "Ancienne",
            ["Modern"] = "Moderne",
            
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
            ["Road Era"] = "道路年代",
            ["Ancien"] = "古代",
            ["Modern"] = "现代",
            
            ["Rail/Road Exchange Crossing"] = "换位立交道口",
            ["Rail/Road Crossing"] = "立交道口",
            ["A flyover rail/road crossing for exchang positions, built in bricks"] = "一个石砖建造的用于换位的立交道口",
            ["A flyover rail/road crossing, built in bricks"] = "一个石砖建造的立交道口",
            ["A flyover rail/road crossing for exchang positions, built in concrete"] = "一个水泥建造的用于换位的立交道口",
            ["A flyover rail/road crossing, built in concrete"] = "一个水泥建造的立交道口",
        }
    }
end
