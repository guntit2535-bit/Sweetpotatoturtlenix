--!strict
-- Every word a player sees lives here, in English and Thai.
-- English is the default for every player; Thai is picked in Settings -> Language and saved.
--
--   Text.get("LanguageEnglish", "th")
--   Text.get("SomeLine", lang, { count = 3 })   -- "{count}" in the line is replaced
--
-- No requires: this module is also loaded by the pure tests (tests/Text.spec.luau).

export type Lang = "en" | "th"
-- Values are shown with tostring. `any` (not string | number) so a literal like { count = 3 }
-- type-checks at the call site without a cast.
export type Vars = { [string]: any }

local DEFAULT: Lang = "en"

local Text = {}

Text.GameName = "Sweetpotatoturtlenix" -- same in both languages
Text.Languages = { "en", "th" } :: { Lang }
Text.Default = DEFAULT

-- [key] = { en = ..., th = ... }. Every key needs both languages with the same {placeholders}
-- (checked by tests/Text.spec.luau). Lines are added by the task that first needs them.
Text.Lines = {
	-- Settings -> Language (each language names itself)
	LanguageEnglish = { en = "English", th = "English" },
	LanguageThai = { en = "ไทย (Thai)", th = "ไทย" },

	-- Saves (task 1.2)
	DataLoadFailed = {
		en = "Could not load your data. Please rejoin.",
		th = "โหลดข้อมูลไม่สำเร็จ กรุณาเข้าเกมใหม่อีกครั้ง",
	},
	DataSessionEnded = {
		en = "Your data was opened in another server. Please rejoin.",
		th = "ข้อมูลของคุณถูกเปิดในเซิร์ฟเวอร์อื่น กรุณาเข้าเกมใหม่อีกครั้ง",
	},

	-- Pens, signs, likes (tasks 1.8 / 1.9)
	PenFree = { en = "Free pen", th = "คอกว่าง" },
	PenOwner = { en = "{name}'s Pen", th = "คอกของ {name}" },
	PenYours = { en = "YOUR PEN", th = "คอกของคุณ" },
	PenLikes = { en = "{count} Likes", th = "{count} ไลก์" },
	LikePrompt = { en = "Like", th = "กดไลก์" },
	LikeDone = { en = "You liked {name}'s pen! x2 speed for 5 minutes", th = "คุณกดไลก์คอกของ {name} แล้ว! วิ่งเร็ว x2 นาน 5 นาที" },
	LikeGot = { en = "{name} liked your pen!", th = "{name} กดไลก์คอกของคุณ!" },
	LikeAlready = { en = "You already liked this pen today", th = "วันนี้คุณกดไลก์คอกนี้แล้ว" },
	LikeOwn = { en = "This is your own pen", th = "นี่คือคอกของคุณเอง" },
	PenFull = { en = "Your pen is full ({max} cats)", th = "คอกเต็มแล้ว ({max} ตัว)" },
	MyCatsButton = { en = "My Cats", th = "แมวของฉัน" },
	MyCatsTitle = { en = "My Cats", th = "แมวของฉัน" },
	MyCatsCount = { en = "{count} / {max} cats", th = "แมว {count} / {max} ตัว" },
	MyCatsEmpty = { en = "No cats yet. Catch one with your rod!", th = "ยังไม่มีแมว ไปตกแมวด้วยเบ็ดกันเลย!" },
	MyCatsTap = { en = "Tap a cat to choose it", th = "แตะแมวเพื่อเลือก" },
	CatIncome = { en = "${money}/s", th = "${money}/วิ" },
	CatKg = { en = "{kg} kg", th = "{kg} กก." },
	Sell = { en = "Sell", th = "ขาย" },
	SellSure = { en = "Sure?", th = "แน่ใจ?" },
	Lock = { en = "Lock", th = "ล็อก" },
	Locked = { en = "Locked", th = "ล็อกแล้ว" },
	SoldCat = { en = "Sold {name} for ${money}", th = "ขาย {name} ได้ ${money}" },
	CatIsLocked = { en = "Unlock this cat first", th = "ปลดล็อกแมวตัวนี้ก่อน" },
	TierBasic = { en = "Basic", th = "Basic" },
	TierRare = { en = "Rare", th = "Rare" },
	TierEpic = { en = "Epic", th = "Epic" },
	TierLegendary = { en = "Legendary", th = "Legendary" },
	TierMythical = { en = "Mythical", th = "Mythical" },
	TierSecret = { en = "Secret", th = "Secret" },

	-- Wild cats, fishing, carrying, bat (tasks 1.10 - 1.14)
	CatLabel = { en = "{tier} · {kg} kg", th = "{tier} · {kg} กก." },
	CatNeed = { en = "Need {kg} Strength", th = "ต้องมีพลัง {kg}" },
	NeedStrength = { en = "You need {kg} Strength for this cat. Lift weights!", th = "ต้องมีพลัง {kg} ถึงจะตกแมวตัวนี้ได้ ไปยกเวทก่อนนะ!" },
	FishNoCat = { en = "No cat in range. Walk closer!", th = "ไม่มีแมวในระยะ เดินเข้าไปใกล้อีกหน่อย!" },
	FishHoldHint = { en = "Hold to keep the cat in the green zone!", th = "กดค้างให้แมวอยู่ในโซนสีเขียว!" },
	FishHold = { en = "HOLD", th = "กดค้าง" },
	FishGiveUp = { en = "Give up", th = "ยอมแพ้" },
	FishCaught = { en = "You caught {name}! ({tier}, {kg} kg)", th = "ตกได้ {name}! ({tier}, {kg} กก.)" },
	FishLost = { en = "{name} caught it first!", th = "{name} ตกได้ก่อน!" },
	FishEscaped = { en = "The cat got away!", th = "แมวหนีไปแล้ว!" },
	FishGaveUp = { en = "You stopped fishing", th = "เลิกตกแมวแล้ว" },
	CatBusy = { en = "That cat can't be fished right now", th = "ตอนนี้ตกแมวตัวนี้ไม่ได้" },
	CarryHint = { en = "Carry it to your pen! Watch out for bats!", th = "ถือกลับไปใส่คอก! ระวังโดนตี!" },
	CatHome = { en = "{name} is in your pen!", th = "{name} เข้าคอกแล้ว!" },
	BatDropped = { en = "{name} knocked your cat loose!", th = "{name} ตีแมวของคุณหลุดมือ!" },
	BatHitCat = { en = "You knocked {name}'s cat loose! Catch it!", th = "คุณตีแมวของ {name} หลุดแล้ว! รีบตกเลย!" },
	CaughtTitle = { en = "Caught!", th = "ตกได้แล้ว!" },

	-- Training and zone gates (tasks 1.15 / 1.16)
	TrainUpgrade = { en = "Upgrade ${cost}", th = "อัปเกรด ${cost}" },
	TrainingJumpHint = { en = "Jump to stop", th = "กระโดดเพื่อหยุด" },
	TrainMax = { en = "Max level", th = "เลเวลสูงสุด" },
	WeightsName = { en = "Weights Lv {level}", th = "ยกเวท Lv {level}" },
	TreadName = { en = "Treadmill Lv {level}", th = "ลู่วิ่ง Lv {level}" },
	WeightsUp = { en = "Weights level {level}!", th = "ยกเวทเลเวล {level}!" },
	TreadUp = { en = "Treadmill level {level}!", th = "ลู่วิ่งเลเวล {level}!" },
	NotEnoughMoney = { en = "Not enough money (${cost})", th = "เงินไม่พอ (${cost})" },
	NotYourGym = { en = "Use the gym at your own pen", th = "ใช้อุปกรณ์หน้าคอกของคุณเอง" },
	ZoneLocked = { en = "{zone} needs {strength} Strength (or {rebirths} rebirths)", th = "{zone} ต้องมีพลัง {strength} (หรือรีเบิร์ธ {rebirths} ครั้ง)" },
	ZoneBackyard = { en = "Backyard", th = "Backyard" },
	ZoneTownMarket = { en = "Town Market", th = "Town Market" },
	ZoneForest = { en = "Forest", th = "Forest" },
	ZoneSnowMountain = { en = "Snow Mountain", th = "Snow Mountain" },
	ZoneSkyIslands = { en = "Sky Islands", th = "Sky Islands" },

	-- HUD (task 1.17)
	ShopButton = { en = "Shop", th = "ร้านค้า" },
	Speed2xButton = { en = "x2 Speed", th = "เร็ว x2" },
	TradeButton = { en = "Trade", th = "เทรด" },
	ComingSoon = { en = "Coming in the next update!", th = "จะมาในอัปเดตถัดไป!" },
	StrengthLabel = { en = "Strength", th = "พลัง" },
	KgValue = { en = "{kg} kg", th = "{kg} กก." },
	WeightsLv = { en = "Weights Lv {level}/{max}", th = "ยกเวท Lv {level}/{max}" },
	TreadLv = { en = "Treadmill Lv {level}/{max}", th = "ลู่วิ่ง Lv {level}/{max}" },
	SpeedValue = { en = "Speed {speed}", th = "ความเร็ว {speed}" },
	IncomeRate = { en = "+${money}/s", th = "+${money}/วิ" },
	EventNext = { en = "{event} in {time}", th = "{event} ใน {time}" },
	EventLive = { en = "{event} cat out! {time}", th = "แมว {event} ออกมาแล้ว! {time}" },
	EventMythical = { en = "Mythical", th = "Mythical" },
	EventSecret = { en = "Secret", th = "Secret" },

	-- Events (task 1.18)
	EventOutMythical = { en = "A MYTHICAL cat appeared! Follow the light!", th = "แมว MYTHICAL ปรากฏตัวแล้ว! ตามแสงไปเลย!" },
	EventOutSecret = { en = "A SECRET cat appeared!!! Follow the light!", th = "แมว SECRET ปรากฏตัวแล้ว!!! ตามแสงไปเลย!" },
	EventEscaped = { en = "The {event} cat ran away...", th = "แมว {event} หนีไปแล้ว..." },
	EventCaught = { en = "{name} caught the {event} cat!", th = "{name} ตกแมว {event} ได้แล้ว!" },
	EventDistance = { en = "{event} · {m} m", th = "{event} · {m} ม." },
	EventMoved = { en = "The {event} cat broke free and hid somewhere new!", th = "แมว {event} หลุดเบ็ดแล้วไปซ่อนที่ใหม่!" },

	-- Shop (tasks 2.1 - 2.5)
	ShopTitle = { en = "Shop", th = "ร้านค้า" },
	TabRods = { en = "Rods", th = "เบ็ด" },
	TabShoes = { en = "Shoes", th = "รองเท้า" },
	TabPen = { en = "Pen", th = "คอก" },
	TabTreats = { en = "Treats", th = "ขนมแมว" },
	TabCrates = { en = "Crates", th = "กล่องสุ่ม" },
	Buy = { en = "Buy ${cost}", th = "ซื้อ ${cost}" },
	Owned = { en = "Owned", th = "มีแล้ว" },
	InUse = { en = "In use", th = "ใช้อยู่" },
	BuyPrevious = { en = "Buy the one before first", th = "ต้องซื้ออันก่อนหน้าก่อน" },
	RodName = { en = "{material} Rod {n}", th = "เบ็ด{material} {n}" },
	RodEffect = { en = "Green zone +{zone}% · Meter +{fill}% · Luck +{luck}%", th = "โซนเขียว +{zone}% · หลอด +{fill}% · โชค +{luck}%" },
	MatWood = { en = "Wood", th = "ไม้" },
	MatIron = { en = "Iron", th = "เหล็ก" },
	MatGold = { en = "Gold", th = "ทอง" },
	MatCrystal = { en = "Crystal", th = "คริสตัล" },
	MatCosmic = { en = "Cosmic", th = "จักรวาล" },
	ShoeEffect = { en = "+{speed} walk speed", th = "เดินเร็วขึ้น +{speed}" },
	ShoeSneakers = { en = "Sneakers", th = "รองเท้าผ้าใบ" },
	ShoeSportShoes = { en = "Sport Shoes", th = "รองเท้ากีฬา" },
	ShoeRunningShoes = { en = "Running Shoes", th = "รองเท้าวิ่ง" },
	ShoeBouncyBoots = { en = "Bouncy Boots", th = "รองเท้าเด้งดึ๋ง" },
	ShoeRocketShoes = { en = "Rocket Shoes", th = "รองเท้าจรวด" },
	ShoeCloudSteppers = { en = "Cloud Steppers", th = "รองเท้าเมฆ" },
	ShoeLightningBoots = { en = "Lightning Boots", th = "รองเท้าสายฟ้า" },
	ShoeCometKicks = { en = "Comet Kicks", th = "รองเท้าดาวหาง" },
	PenItem = { en = "+{n} pen slots", th = "ช่องคอก +{n}" },
	PenEffect = { en = "{now} -> {next} slots", th = "{now} -> {next} ช่อง" },
	PenMax = { en = "Your pen is as big as it gets", th = "คอกใหญ่สุดแล้ว" },
	TreatLuckyTreat = { en = "Lucky Treat", th = "ขนมนำโชค" },
	TreatGoldenFish = { en = "Golden Fish", th = "ปลาทองคำ" },
	TreatCatnip = { en = "Catnip", th = "แคทนิป" },
	TreatLuckyTreatDesc = { en = "Luck x1.5 for 10 minutes", th = "โชค x1.5 นาน 10 นาที" },
	TreatGoldenFishDesc = { en = "Money x2 for 10 minutes", th = "เงิน x2 นาน 10 นาที" },
	TreatCatnipDesc = { en = "Easier fishing for 10 minutes", th = "ตกแมวง่ายขึ้น นาน 10 นาที" },
	TreatLeft = { en = "Active: {time}", th = "เหลือ {time}" },
	Bought = { en = "Bought {name}!", th = "ซื้อ {name} แล้ว!" },

	-- Crates, mutations, book, rebirth (tasks 2.6 - 2.9)
	CratePaper = { en = "Paper Crate", th = "กล่องกระดาษ" },
	CrateWood = { en = "Wood Crate", th = "กล่องไม้" },
	CrateGold = { en = "Gold Crate", th = "กล่องทอง" },
	CrateDiamond = { en = "Diamond Crate", th = "กล่องเพชร" },
	CrateOdds = { en = "Chances:", th = "โอกาส:" },
	CrateGot = { en = "You got {name}!", th = "ได้ {name}!" },
	CrateOpening = { en = "Opening...", th = "กำลังเปิด..." },
	MutGold = { en = "Gold", th = "ทอง" },
	MutRainbow = { en = "Rainbow", th = "รุ้ง" },
	MutGlow = { en = "Glow", th = "เรืองแสง" },
	MutTag = { en = "{mutation} x{mult}", th = "{mutation} x{mult}" },
	BookButton = { en = "Book", th = "สมุด" },
	BookTitle = { en = "Collection Book", th = "สมุดสะสมแมว" },
	BookProgress = { en = "{seen} / {total} cats found", th = "พบแมวแล้ว {seen} / {total} ตัว" },
	BookBonus = { en = "Full tier: +{pct}% money · All 400: +{all}%", th = "สะสมครบระดับ: เงิน +{pct}% · ครบ 400: +{all}%" },
	BookUnknown = { en = "???", th = "???" },
	RebirthButton = { en = "Rebirth", th = "รีเบิร์ธ" },
	RebirthTitle = { en = "Rebirth {n}", th = "รีเบิร์ธครั้งที่ {n}" },
	RebirthNeed = { en = "Needs {strength} Strength (you have {have})", th = "ต้องมีพลัง {strength} (ตอนนี้ {have})" },
	RebirthGives = { en = "Money x1.5 and Strength x3.95 forever, every cat x3.6 heavier, new zones open", th = "เงิน x1.5 และพลัง x3.95 ถาวร แมวทุกตัวหนักขึ้น x3.6 และเปิดโซนใหม่" },
	RebirthResets = { en = "Resets money, Strength, Speed and the weights / treadmill levels. Cats, rods, shoes and pen stay.", th = "รีเซ็ตเงิน พลัง ความเร็ว และเลเวลยกเวท/ลู่วิ่ง แมว เบ็ด รองเท้า และคอกยังอยู่" },
	RebirthGo = { en = "Rebirth!", th = "รีเบิร์ธ!" },
	RebirthDone = { en = "Rebirth {n}! Money x1.5, Strength x3.95, cats x3.6 heavier", th = "รีเบิร์ธครั้งที่ {n}! เงิน x1.5 พลัง x3.95 แมวหนักขึ้น x3.6" },
	RebirthMax = { en = "Every rebirth is done!", th = "รีเบิร์ธครบทุกครั้งแล้ว!" },
	RebirthNotYet = { en = "Not strong enough yet", th = "พลังยังไม่พอ" },

	-- Rewards (tasks 2.10 - 2.16)
	RewardsButton = { en = "Rewards", th = "รางวัล" },
	RewardsTitle = { en = "Rewards", th = "รางวัล" },
	TabDaily = { en = "Daily", th = "รายวัน" },
	TabGifts = { en = "Gifts", th = "ของขวัญ" },
	TabQuests = { en = "Quests", th = "เควส" },
	TabCodes = { en = "Codes", th = "โค้ด" },
	TabGroup = { en = "Group", th = "กลุ่ม" },
	RewardMoney = { en = "+${money}!", th = "+${money}!" },
	OfflineIncome = { en = "Welcome back! Your cats earned ${money} while you were away ({min} min)", th = "ยินดีต้อนรับกลับ! แมวหาเงินได้ ${money} ตอนคุณไม่อยู่ ({min} นาที)" },
	LoginDay = { en = "Day {n}", th = "วันที่ {n}" },
	Claim = { en = "Claim", th = "รับ" },
	Claimed = { en = "Claimed", th = "รับแล้ว" },
	ComeBack = { en = "Tomorrow", th = "พรุ่งนี้" },
	GiftAt = { en = "{min} min", th = "{min} นาที" },
	GiftWait = { en = "{time} left", th = "อีก {time}" },
	RewardMoneyLine = { en = "Money", th = "เงิน" },
	RewardCrate = { en = "{crate}", th = "{crate}" },
	QuestCatch = { en = "Catch {goal} cats", th = "ตกแมว {goal} ตัว" },
	QuestCatchRare = { en = "Catch {goal} Rare or better cats", th = "ตกแมว Rare ขึ้นไป {goal} ตัว" },
	QuestTrain = { en = "Train for {goal} seconds", th = "ฝึก {goal} วินาที" },
	QuestHit = { en = "Knock {goal} cats loose with the bat", th = "ตีแมวให้หลุดมือ {goal} ครั้ง" },
	QuestCrate = { en = "Open {goal} crates", th = "เปิดกล่องสุ่ม {goal} กล่อง" },
	QuestLike = { en = "Like {goal} pen", th = "กดไลก์คอก {goal} ครั้ง" },
	QuestProgress = { en = "{n} / {goal}", th = "{n} / {goal}" },
	CodeHint = { en = "Type a code", th = "พิมพ์โค้ด" },
	CodeRedeem = { en = "Redeem", th = "ใช้โค้ด" },
	CodeBad = { en = "That code does not exist", th = "ไม่มีโค้ดนี้" },
	CodeUsed = { en = "You already used this code", th = "คุณใช้โค้ดนี้ไปแล้ว" },
	GroupText = { en = "Join our Roblox group, then claim: ${money} + Lucky Treat 30 min", th = "เข้ากลุ่ม Roblox ของเกม แล้วกดรับ: ${money} + ขนมนำโชค 30 นาที" },
	GroupJoinFirst = { en = "Join the game's group first!", th = "เข้ากลุ่มของเกมก่อนนะ!" },
	LeaderIncome = { en = "Top Money / sec", th = "อันดับเงินต่อวินาที" },
	LeaderCats = { en = "Top Cat Collectors", th = "อันดับนักสะสมแมว" },

	-- Trading (task 2.17)
	TradeTitle = { en = "Trade", th = "เทรด" },
	TradeWith = { en = "Trading with {name}", th = "เทรดกับ {name}" },
	TradeRequest = { en = "Ask", th = "ขอเทรด" },
	TradeNoPlayers = { en = "Nobody else is in this server", th = "ไม่มีผู้เล่นอื่นในเซิร์ฟเวอร์" },
	TradeInvite = { en = "{name} wants to trade!", th = "{name} อยากเทรดกับคุณ!" },
	TradeAccept = { en = "Accept", th = "รับ" },
	TradeDecline = { en = "No", th = "ไม่" },
	TradeYou = { en = "You", th = "คุณ" },
	TradeMyCats = { en = "Tap your cats to add or remove (max 6)", th = "แตะแมวของคุณเพื่อใส่หรือเอาออก (สูงสุด 6)" },
	TradeReadyButton = { en = "Ready", th = "พร้อม" },
	TradeNotReady = { en = "Cancel ready", th = "ยกเลิกพร้อม" },
	TradeWaiting = { en = "Both press Ready", th = "รอทั้งสองฝ่ายกดพร้อม" },
	TradeIn = { en = "Swap in {n}...", th = "แลกใน {n}..." },
	TradeCancelButton = { en = "Cancel", th = "ยกเลิก" },
	TradeDone = { en = "Trade done!", th = "เทรดสำเร็จ!" },
	TradeCancelled = { en = "The trade was cancelled", th = "การเทรดถูกยกเลิก" },
	TradeSent = { en = "Asked {name} to trade", th = "ส่งคำขอเทรดถึง {name} แล้ว" },
	TradeBusy = { en = "{name} is busy", th = "{name} ไม่ว่าง" },
	TradeFailNoRoom = { en = "A pen has no room for these cats", th = "คอกมีช่องไม่พอ" },
	TradeFailLocked = { en = "Locked cats can't be traded", th = "แมวที่ล็อกเทรดไม่ได้" },
	TradeFailGone = { en = "A cat is no longer there", th = "มีแมวที่ไม่อยู่แล้ว" },
	TradeFailEmpty = { en = "Put in at least one cat", th = "ใส่แมวอย่างน้อย 1 ตัว" },
	TradeFailTooMany = { en = "6 cats at most", th = "ใส่ได้ไม่เกิน 6 ตัว" },
	TradeFailBad = { en = "Something was wrong with the offer", th = "ข้อเสนอไม่ถูกต้อง" },

	-- Robux (tasks 2.18 - 2.20)
	TabRobux = { en = "Robux", th = "Robux" },
	PassSpeed = { en = "x2 Speed", th = "เร็ว x2" },
	PassCash = { en = "x2 Cash", th = "เงิน x2" },
	PassStrength = { en = "x2 Strength", th = "พลัง x2" },
	PassLucky = { en = "Lucky", th = "นำโชค" },
	PassVIP = { en = "VIP", th = "VIP" },
	PassSpeedDesc = { en = "Walk twice as fast (switch on / off)", th = "เดินเร็ว 2 เท่า (เปิด/ปิดได้)" },
	PassCashDesc = { en = "Your cats earn x2 money", th = "แมวหาเงินได้ x2" },
	PassStrengthDesc = { en = "x2 Strength from lifting", th = "ยกเวทได้พลัง x2" },
	PassLuckyDesc = { en = "x2 luck: more Gold, Rainbow and Glow cats", th = "โชค x2: เจอแมวกลายพันธุ์บ่อยขึ้น" },
	PassVIPDesc = { en = "VIP tag + 10% more money", th = "ป้าย VIP + เงินเพิ่ม 10%" },
	ProductSlots = { en = "+20 Pen Slots", th = "ช่องคอก +20" },
	ProductCashS = { en = "Small Cash Pack", th = "แพ็กเงินเล็ก" },
	ProductCashM = { en = "Medium Cash Pack", th = "แพ็กเงินกลาง" },
	ProductCashL = { en = "Large Cash Pack", th = "แพ็กเงินใหญ่" },
	ProductCashXL = { en = "Huge Cash Pack", th = "แพ็กเงินยักษ์" },
	ProductCashDesc = { en = "${money} now (grows with your income)", th = "รับ ${money} ทันที (เพิ่มตามรายได้)" },
	ProductStrength = { en = "Strength Pack", th = "แพ็กพลัง" },
	ProductStrengthDesc = { en = "+{kg} kg Strength now", th = "พลัง +{kg} กก. ทันที" },
	ProductLuck3 = { en = "Luck x3 (15 min)", th = "โชค x3 (15 นาที)" },
	ProductLuck3Desc = { en = "x3 luck for 15 minutes: more Gold, Rainbow and Glow cats", th = "โชค x3 นาน 15 นาที: ได้แมวทอง สีรุ้ง เรืองแสงบ่อยขึ้น" },
	ProductServerLuck = { en = "Server Luck (15 min)", th = "โชคทั้งเซิร์ฟเวอร์ (15 นาที)" },
	ProductServerLuckDesc = { en = "Everyone here gets x2 luck, with your name announced", th = "ทุกคนในเซิร์ฟเวอร์ได้โชค x2 และประกาศชื่อคุณ" },
	ProductSummonMythical = { en = "Summon a Mythical Cat", th = "เรียกแมว Mythical" },
	ProductSummonDesc = { en = "A Mythical cat appears now: everyone can try to catch it!", th = "แมว Mythical ปรากฏทันที ทุกคนแย่งกันตกได้!" },
	ProductStarter = { en = "Starter Pack", th = "แพ็กเริ่มต้น" },
	ProductStarterDesc = { en = "Iron Rod + $10K + Lucky Treat + Golden Fish (once)", th = "เบ็ดเหล็ก + $10K + ขนมนำโชค + ปลาทองคำ (ครั้งเดียว)" },
	Owned2 = { en = "Owned", th = "มีแล้ว" },
	NotOnSaleYet = { en = "Not on sale yet", th = "ยังไม่เปิดขาย" },
	SpeedOn = { en = "x2 Speed: ON", th = "เร็ว x2: เปิด" },
	SpeedOff = { en = "x2 Speed: OFF", th = "เร็ว x2: ปิด" },
	ServerLuckOn = { en = "{name} gave the whole server x2 luck for 15 minutes!", th = "{name} ให้โชค x2 ทั้งเซิร์ฟเวอร์ 15 นาที!" },
	PurchaseThanks = { en = "Thank you! {name} received", th = "ขอบคุณ! ได้รับ {name} แล้ว" },

	-- Settings window (task 1.1)
	SettingsButton = { en = "Settings", th = "ตั้งค่า" },
	SettingsTitle = { en = "Settings", th = "ตั้งค่า" },
	SettingsLanguage = { en = "Language", th = "ภาษา" },
	SettingsLanguageNote = { en = "Every text in the game", th = "ข้อความทั้งหมดในเกม" },
	SettingsMusic = { en = "Music", th = "เพลง" },
	SettingsMusicNote = { en = "Background music", th = "เพลงประกอบในเกม" },
	SettingsSfx = { en = "Sound effects", th = "เสียงเอฟเฟกต์" },
	SettingsSfxNote = { en = "Buttons, catching, bats, crates", th = "ปุ่ม การจับแมว ไม้เบสบอล กล่องสุ่ม" },
	SettingOn = { en = "ON", th = "เปิด" },
	SettingOff = { en = "OFF", th = "ปิด" },
	Close = { en = "Close", th = "ปิด" },
} :: { [string]: { en: string, th: string } }

-- leaderstats column names are shared by every player in the server, so they stay in English.
Text.StatMoney = "Money"
Text.StatStrength = "Strength"

function Text.isLang(value: unknown): boolean
	return value == "en" or value == "th"
end

-- Saved setting -> language to show. Anything unknown (old saves, bad data) -> English.
function Text.resolve(setting: unknown): Lang
	if setting == "th" then
		return "th"
	end
	return DEFAULT
end

-- Placeholder names in a line, sorted: "{a} and {b}" -> { "a", "b" }.
function Text.placeholders(line: string): { string }
	local names = {}
	for name in string.gmatch(line, "{(%w+)}") do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

-- A line in the given language with {placeholders} filled in. A missing key returns the key itself
-- (easy to spot in testing); a missing variable leaves its {placeholder} in place.
function Text.get(key: string, lang: Lang, vars: Vars?): string
	local line = Text.Lines[key]
	if not line then
		return key
	end
	local text = if lang == "th" then line.th else line.en
	if vars then
		text = string.gsub(text, "{(%w+)}", function(name: string): string
			local value = vars[name]
			if value == nil then
				return `\{{name}\}`
			end
			return tostring(value)
		end)
	end
	return text
end

return Text
