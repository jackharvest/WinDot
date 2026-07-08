import Foundation

// MARK: - Emoji data

enum EmojiData {
    typealias Entry = (emoji: String, keywords: [String])

    static let categories: [(category: String, emojis: [Entry])] = [
        ("Smileys & People", [
            ("😀", ["grinning"]), ("😃", ["smiley"]), ("😄", ["smile"]), ("😁", ["grin"]),
            ("😆", ["laughing"]), ("😅", ["sweat smile"]), ("🤣", ["rofl", "rolling"]), ("😂", ["joy", "laugh", "tears"]),
            ("🙂", ["slight smile"]), ("🙃", ["upside down"]), ("😉", ["wink"]), ("😊", ["blush"]),
            ("😇", ["innocent", "halo"]), ("🥰", ["smiling hearts", "love"]), ("😍", ["heart eyes"]), ("🤩", ["star struck"]),
            ("😘", ["kiss"]), ("😗", ["kissing"]), ("😚", ["kissing closed eyes"]), ("😙", ["kissing smiling eyes"]),
            ("😋", ["yum", "delicious"]), ("😛", ["tongue"]), ("😜", ["wink tongue"]), ("🤪", ["zany", "crazy"]),
            ("😝", ["squint tongue"]), ("🤑", ["money mouth"]), ("🤗", ["hug"]), ("🤭", ["hand over mouth", "oops"]),
            ("🤫", ["shush", "quiet"]), ("🤔", ["thinking"]), ("🤐", ["zipper mouth"]), ("🤨", ["raised eyebrow", "skeptical"]),
            ("😐", ["neutral"]), ("😑", ["expressionless"]), ("😶", ["no mouth"]), ("😏", ["smirk"]),
            ("😒", ["unamused"]), ("🙄", ["eye roll"]), ("😬", ["grimace"]), ("🤥", ["lying", "pinocchio"]),
            ("😌", ["relieved"]), ("😔", ["pensive"]), ("😪", ["sleepy"]), ("🤤", ["drooling"]),
            ("😴", ["sleeping", "zzz"]), ("😷", ["mask", "sick"]), ("🤒", ["thermometer", "sick"]), ("🤕", ["head bandage", "hurt"]),
            ("🤢", ["nauseated", "sick"]), ("🤮", ["vomiting", "puke"]), ("🤧", ["sneezing"]), ("🥵", ["hot"]),
            ("🥶", ["cold", "freezing"]), ("🥴", ["woozy"]), ("😵", ["dizzy"]), ("🤯", ["mind blown"]),
            ("🤠", ["cowboy"]), ("🥳", ["party", "celebrate"]), ("😎", ["sunglasses", "cool"]), ("🤓", ["nerd"]),
            ("🧐", ["monocle"]), ("😕", ["confused"]), ("😟", ["worried"]), ("🙁", ["frown"]),
            ("☹️", ["frowning"]), ("😮", ["open mouth", "surprised"]), ("😯", ["hushed"]), ("😲", ["astonished", "shocked"]),
            ("😳", ["flushed", "embarrassed"]), ("🥺", ["pleading", "puppy eyes"]), ("😦", ["frowning open mouth"]), ("😧", ["anguished"]),
            ("😨", ["fearful", "scared"]), ("😰", ["anxious sweat"]), ("😥", ["sad relieved"]), ("😢", ["cry", "sad"]),
            ("😭", ["sob", "crying"]), ("😱", ["scream"]), ("😖", ["confounded"]), ("😣", ["persevere"]),
            ("😞", ["disappointed"]), ("😓", ["downcast sweat"]), ("😩", ["weary"]), ("😫", ["tired"]),
            ("🥱", ["yawn", "bored"]), ("😤", ["triumph"]), ("😡", ["rage", "mad"]), ("😠", ["angry"]),
            ("🤬", ["cursing", "swearing"]), ("😈", ["devil", "smiling devil"]), ("👿", ["imp", "angry devil"]), ("💀", ["skull", "dead"]),
            ("💩", ["poop"]), ("🤡", ["clown"]), ("👻", ["ghost"]), ("👽", ["alien"]),
            ("🤖", ["robot"]), ("😺", ["cat smile"]), ("😸", ["cat grin"]), ("😹", ["cat joy"]),
            ("😻", ["cat heart eyes"]), ("😼", ["cat smirk"]), ("😽", ["cat kiss"]), ("🙀", ["cat scream"]),
            ("😿", ["cat cry"]), ("😾", ["cat pouting"])
        ]),
        ("Gestures & People", [
            ("👋", ["wave", "hello", "bye"]), ("🤚", ["raised back hand"]), ("🖐️", ["hand splayed"]), ("✋", ["raised hand", "stop"]),
            ("🖖", ["vulcan", "spock"]), ("👌", ["ok hand"]), ("🤌", ["pinched fingers", "chefs kiss"]), ("🤏", ["pinch", "small"]),
            ("✌️", ["peace"]), ("🤞", ["crossed fingers", "hope"]), ("🤟", ["love you gesture"]), ("🤘", ["rock on"]),
            ("🤙", ["call me", "shaka"]), ("👈", ["point left"]), ("👉", ["point right"]), ("👆", ["point up"]),
            ("🖕", ["middle finger"]), ("👇", ["point down"]), ("☝️", ["index up"]), ("👍", ["thumbsup", "like"]),
            ("👎", ["thumbsdown", "dislike"]), ("✊", ["fist"]), ("👊", ["punch", "fist bump"]), ("🤛", ["fist left"]),
            ("🤜", ["fist right"]), ("👏", ["clap", "applause"]), ("🙌", ["raised hands", "celebration"]), ("👐", ["open hands"]),
            ("🤲", ["palms up"]), ("🙏", ["pray", "thanks", "please"]), ("✍️", ["writing"]), ("💅", ["nail polish", "sassy"]),
            ("🤳", ["selfie"]), ("💪", ["muscle", "strong", "flex"]), ("🦾", ["mechanical arm"]), ("🦵", ["leg", "kick"]),
            ("🦿", ["mechanical leg"]), ("👀", ["eyes", "looking"]), ("👁️", ["eye"]), ("🧠", ["brain", "smart"]),
            ("🦷", ["tooth"]), ("🦴", ["bone"]), ("👶", ["baby"]), ("🧒", ["child"]),
            ("👦", ["boy"]), ("👧", ["girl"]), ("🧑", ["person"]), ("👨", ["man"]),
            ("👩", ["woman"]), ("🧓", ["older person"]), ("👴", ["old man"]), ("👵", ["old woman"])
        ]),
        ("Animals & Nature", [
            ("🐶", ["dog"]), ("🐱", ["cat"]), ("🐭", ["mouse"]), ("🐹", ["hamster"]),
            ("🐰", ["rabbit", "bunny"]), ("🦊", ["fox"]), ("🐻", ["bear"]), ("🐼", ["panda"]),
            ("🐨", ["koala"]), ("🐯", ["tiger"]), ("🦁", ["lion"]), ("🐮", ["cow"]),
            ("🐷", ["pig"]), ("🐸", ["frog"]), ("🐵", ["monkey"]), ("🙈", ["see no evil"]),
            ("🙉", ["hear no evil"]), ("🙊", ["speak no evil"]), ("🐔", ["chicken"]), ("🐧", ["penguin"]),
            ("🐦", ["bird"]), ("🐤", ["chick"]), ("🦆", ["duck"]), ("🦅", ["eagle"]),
            ("🦉", ["owl"]), ("🦇", ["bat"]), ("🐺", ["wolf"]), ("🐗", ["boar"]),
            ("🐴", ["horse"]), ("🦄", ["unicorn"]), ("🐝", ["bee"]), ("🐛", ["bug"]),
            ("🦋", ["butterfly"]), ("🐌", ["snail"]), ("🐞", ["ladybug"]), ("🐢", ["turtle"]),
            ("🐍", ["snake"]), ("🦖", ["trex", "dinosaur"]), ("🐙", ["octopus"]), ("🦑", ["squid"]),
            ("🦀", ["crab"]), ("🐠", ["fish"]), ("🐬", ["dolphin"]), ("🐳", ["whale"]),
            ("🐘", ["elephant"]), ("🦒", ["giraffe"]), ("🐫", ["camel"]), ("🦘", ["kangaroo"]),
            ("🐎", ["racehorse"]), ("🐕", ["dog2"]), ("🐈", ["cat2"]), ("🌵", ["cactus"]),
            ("🌲", ["evergreen tree"]), ("🌳", ["deciduous tree"]), ("🌴", ["palm tree"]), ("🌸", ["blossom"]),
            ("🌼", ["daisy"]), ("🌻", ["sunflower"]), ("🍀", ["clover", "lucky"]), ("🍁", ["maple leaf"]),
            ("🌈", ["rainbow"]), ("☀️", ["sun"]), ("⭐", ["star"]), ("🌙", ["moon"]),
            ("🔥", ["fire", "lit", "hot"]), ("💧", ["droplet", "water"]), ("❄️", ["snowflake"])
        ]),
        ("Food & Drink", [
            ("🍏", ["green apple"]), ("🍎", ["apple"]), ("🍐", ["pear"]), ("🍊", ["orange"]),
            ("🍋", ["lemon"]), ("🍌", ["banana"]), ("🍉", ["watermelon"]), ("🍇", ["grapes"]),
            ("🍓", ["strawberry"]), ("🫐", ["blueberries"]), ("🍈", ["melon"]), ("🍒", ["cherries"]),
            ("🍑", ["peach"]), ("🥭", ["mango"]), ("🍍", ["pineapple"]), ("🥥", ["coconut"]),
            ("🥝", ["kiwi"]), ("🍅", ["tomato"]), ("🍆", ["eggplant"]), ("🥑", ["avocado"]),
            ("🥦", ["broccoli"]), ("🥬", ["leafy green"]), ("🌶️", ["hot pepper", "spicy"]), ("🌽", ["corn"]),
            ("🥕", ["carrot"]), ("🧄", ["garlic"]), ("🧅", ["onion"]), ("🥔", ["potato"]),
            ("🍞", ["bread"]), ("🥐", ["croissant"]), ("🥨", ["pretzel"]), ("🧀", ["cheese"]),
            ("🥚", ["egg"]), ("🍳", ["fried egg"]), ("🥞", ["pancakes"]), ("🧇", ["waffle"]),
            ("🥓", ["bacon"]), ("🍔", ["hamburger", "burger"]), ("🍟", ["fries"]), ("🍕", ["pizza"]),
            ("🌭", ["hotdog"]), ("🥪", ["sandwich"]), ("🌮", ["taco"]), ("🌯", ["burrito"]),
            ("🍜", ["ramen", "noodles"]), ("🍣", ["sushi"]), ("🍱", ["bento"]), ("🍩", ["donut"]),
            ("🍪", ["cookie"]), ("🎂", ["birthday cake"]), ("🍰", ["cake"]), ("🍫", ["chocolate"]),
            ("🍬", ["candy"]), ("🍭", ["lollipop"]), ("🍿", ["popcorn"]), ("🍺", ["beer"]),
            ("🍷", ["wine"]), ("🍹", ["cocktail"]), ("☕", ["coffee"]), ("🍵", ["tea"])
        ]),
        ("Activities", [
            ("⚽", ["soccer"]), ("🏀", ["basketball"]), ("🏈", ["football"]), ("⚾", ["baseball"]),
            ("🎾", ["tennis"]), ("🏐", ["volleyball"]), ("🏉", ["rugby"]), ("🎱", ["8ball", "pool"]),
            ("🏓", ["pingpong"]), ("🏸", ["badminton"]), ("🥊", ["boxing"]), ("🥋", ["martial arts"]),
            ("⛳", ["golf"]), ("🎣", ["fishing"]), ("🎽", ["running shirt"]), ("🎿", ["skiing"]),
            ("🎯", ["dart", "target"]), ("🎮", ["video game", "controller"]), ("🎲", ["dice"]), ("🧩", ["puzzle"]),
            ("🎨", ["art", "palette"]), ("🎭", ["theater masks", "drama"]), ("🎤", ["microphone", "karaoke"]), ("🎧", ["headphones"]),
            ("🎸", ["guitar"]), ("🎹", ["piano"]), ("🎺", ["trumpet"]), ("🎻", ["violin"]),
            ("🥁", ["drum"]), ("🏆", ["trophy", "win"]), ("🥇", ["gold medal", "first place"]), ("🎉", ["party popper", "tada"]),
            ("🎊", ["confetti"]), ("🎁", ["gift", "present"]), ("🎈", ["balloon"])
        ]),
        ("Travel & Places", [
            ("🚗", ["car"]), ("🚕", ["taxi"]), ("🚙", ["suv"]), ("🚌", ["bus"]),
            ("🚓", ["police car"]), ("🚑", ["ambulance"]), ("🚒", ["fire truck"]), ("🚚", ["truck"]),
            ("🚲", ["bike"]), ("🛵", ["scooter"]), ("✈️", ["airplane", "flight"]), ("🚀", ["rocket"]),
            ("🚁", ["helicopter"]), ("⛵", ["sailboat"]), ("🚢", ["ship"]), ("🗺️", ["map"]),
            ("🗽", ["statue of liberty"]), ("🗼", ["tokyo tower"]), ("🏰", ["castle"]), ("🎡", ["ferris wheel"]),
            ("🎢", ["roller coaster"]), ("🏖️", ["beach"]), ("🏝️", ["island"]), ("🏕️", ["camping"]),
            ("🏔️", ["mountain"]), ("🌋", ["volcano"]), ("🗻", ["mount fuji"]), ("🏠", ["house", "home"]),
            ("🏢", ["building", "office"]), ("⛪", ["church"]), ("🕌", ["mosque"]), ("🌉", ["bridge"]),
            ("🌃", ["night city"]), ("🌅", ["sunrise"]), ("🌇", ["sunset"])
        ]),
        ("Objects & Symbols", [
            ("⌚", ["watch"]), ("📱", ["phone"]), ("💻", ["laptop", "computer"]), ("⌨️", ["keyboard"]),
            ("🖥️", ["desktop"]), ("🖨️", ["printer"]), ("💡", ["bulb", "idea"]), ("🔦", ["flashlight"]),
            ("📷", ["camera"]), ("🎥", ["movie camera"]), ("📺", ["tv"]), ("📻", ["radio"]),
            ("☎️", ["telephone"]), ("📞", ["receiver"]), ("📟", ["pager"]), ("🔋", ["battery"]),
            ("🔌", ["plug"]), ("💰", ["money bag"]), ("💵", ["dollar", "cash"]), ("💳", ["credit card"]),
            ("✉️", ["envelope", "mail"]), ("📦", ["package", "box"]), ("📅", ["calendar"]), ("📌", ["pin"]),
            ("📎", ["paperclip"]), ("✂️", ["scissors"]), ("🔒", ["lock"]), ("🔑", ["key"]),
            ("🔨", ["hammer"]), ("🧰", ["toolbox"]), ("🧲", ["magnet"]), ("💊", ["pill"]),
            ("🚪", ["door"]), ("🪑", ["chair"]), ("🛏️", ["bed"]), ("🚽", ["toilet"]),
            ("🛁", ["bathtub"]), ("❤️", ["red heart", "love"]), ("🧡", ["orange heart"]), ("💛", ["yellow heart"]),
            ("💚", ["green heart"]), ("💙", ["blue heart"]), ("💜", ["purple heart"]), ("🖤", ["black heart"]),
            ("🤍", ["white heart"]), ("💔", ["broken heart"]), ("💯", ["100", "perfect"]), ("✅", ["check", "done"]),
            ("❌", ["cross", "no", "wrong"]), ("⚠️", ["warning"]), ("🚫", ["no entry", "banned"]), ("🔞", ["18+"]),
            ("♻️", ["recycle"]), ("💤", ["zzz", "sleep"]), ("🆗", ["ok"]), ("🆕", ["new"])
        ])
    ]

    /// Case-insensitive substring match over keywords, first N hits in category order.
    /// Good enough for a quick-filter row — not meant to rank relevance.
    static func search(_ query: String, limit: Int) -> [String] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }
        var matches: [String] = []
        outer: for (_, emojis) in categories {
            for entry in emojis {
                if entry.keywords.contains(where: { $0.contains(q) }) {
                    matches.append(entry.emoji)
                    if matches.count >= limit { break outer }
                }
            }
        }
        return matches
    }
}
