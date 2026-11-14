local rgb = Color3.fromRGB

local Catalog = {
	{id = "spark", name = "Mini Spark Effect", price = 1, kind = "Pass", world = 1, stand = "Spark Atelier",
		details = "Permanent amber star particles while running.", items = {"Amber Spark"}, icon = "spark", color = rgb(255, 198, 103)},
	{id = "trail", name = "Colorful Speed Trail", price = 9, kind = "Pass", world = 1, stand = "Trail Gallery",
		details = "Permanent cyan-to-violet ribbon trail.", items = {"Prism Ribbon"}, icon = "trail", color = rgb(112, 236, 255)},
	{id = "coins", name = "Small Coin Pack", price = 24, kind = "Product", world = 2, stand = "Exchange",
		details = "300 Coins delivered once per purchase. Buy again when you choose.", coins = 300, icon = "coins", color = rgb(255, 209, 106)},
	{id = "shoes", name = "Neon Runner Shoes", price = 59, kind = "Pass", world = 2, stand = "Neon Outfitters",
		details = "Permanent neon ankle lights for your runner.", items = {"Neon Shoes"}, icon = "shoes", color = rgb(126, 252, 242)},
	{id = "starter", name = "Starter Cosmetic Bundle", price = 150, kind = "Pass", world = 3, stand = "Hidden Atelier",
		details = "Solar Ribbon trail, Victory Halo, and Aurora skin for Crystal Cub. Earn Crystal Cub in Crystal Canyon to use its skin.",
		items = {"Solar Ribbon", "Victory Halo", "Aurora Cub"}, icon = "starter", color = rgb(211, 154, 255)},
	{id = "energy", name = "Permanent 2× Speed Energy", price = 299, kind = "Pass", world = 1, stand = "Velocity Lab",
		details = "2× Speed Energy from running and spark pickups. Running uses the strongest applicable boost.",
		energy = 2, icon = "energy", color = rgb(105, 251, 188)},
	{id = "coinboost", name = "Permanent 3× Coin Earnings", price = 499, kind = "Pass", world = 5, stand = "Ember Exchange",
		details = "3× Coins earned in the world, from races, and from claims. Purchased packs deliver their listed amount.",
		coinMultiplier = 3, icon = "coinboost", color = rgb(255, 172, 91)},
	{id = "training", name = "Permanent 4× Training Energy", price = 1999, kind = "Pass", world = 4, stand = "Cloud Customization",
		details = "4× Speed Energy from running. The 4× rate takes priority when both running boosts apply.",
		training = 4, icon = "training", color = rgb(255, 224, 152)},
	{id = "founder", name = "Cosmic Founder's Bundle", price = 3999, kind = "Pass", world = 6, stand = "Founder's Observatory",
		details = "Eventide Ribbon trail, Rift Crown, and Eventide skin for Galaxy Wisp. Earn Galaxy Wisp in Cosmic Rift to use its skin.",
		items = {"Eventide Ribbon", "Rift Crown", "Eventide Wisp"}, icon = "founder", color = rgb(234, 147, 255)},
}

-- Add confirmed Roblox asset IDs by catalog key after the approved Dashboard setup.
local ids = {}
for _, entry in ipairs(Catalog) do
	entry.assetId = ids[entry.id]
end

return Catalog
