local ToolItems = {
	["336a7328-4d50-432c-8698-2ed511187cc7"] = sm.uuid.new("c4966054-2c7e-451a-b946-090604696d78"), --TommyGun
	["d8ba1dfe-172c-41ea-83e1-2c977e21d9e9"] = sm.uuid.new("7a716b53-04a5-4a39-874b-4a13986dcc69"), --PPSH
	["8f97ff41-6498-46f7-84aa-fd0c11918512"] = sm.uuid.new("9df34886-8dbb-4c67-ad4d-1b280673b786"), --PTRD
	["e4ed32d5-d891-40e3-b82e-db975884dbb3"] = sm.uuid.new("db67924a-39b0-4522-a3a5-270ef2a8538b"), --M1911
	["1e5f445b-934a-4366-b5c2-0bc11fd3580f"] = sm.uuid.new("873b01f3-4b50-460f-b7fc-98bbdf4b50e3"), --P38
	["d64d4f6c-1a21-47f5-adf9-63397aa6a3a0"] = sm.uuid.new("dc99f421-04c4-4e64-bce5-ea1d83f8b40c"), --MP40
	["96f3b45c-8729-4573-bc14-bbe1cc7fd2bb"] = sm.uuid.new("d9d3c67a-0186-45c2-af76-4bb1b0951c21"), --Magnum44
	["5a1ca305-513f-42db-ae71-52bd0a9247fc"] = sm.uuid.new("03cca028-d7d9-40bb-b733-211929d5b6d8"), --eoka
	["c0cb7836-075a-478a-af3d-0b7360721527"] = sm.uuid.new("0f3d71b7-93fd-4703-8263-dacdf648a667"), --Mosin
	["0ca4320e-5ddb-4dc1-843d-6037d65b2e4a"] = sm.uuid.new("4f0340c8-3d62-4ee9-a363-b4dbd6a5e014"), --Garand
	["c3e4dc43-a841-4c0f-82a6-7225d1bf210e"] = sm.uuid.new("9ba22a32-89d8-435a-b969-2006b3531ac6"), --HandheldGrenade
	["0c27e043-0cff-492b-9bcf-091520a99764"] = sm.uuid.new("f41176ae-095c-4749-9954-448b63e44ce8"), --FragGrenade
	["872b6328-37d4-4922-847d-0aef8803ac94"] = sm.uuid.new("25e799e2-cc38-4994-a4b0-bd1742026ac8"), --Bazooka
	["b0c08b35-4b40-40fe-b933-ca123f99eef8"] = sm.uuid.new("d9c36e6d-0878-4a87-909d-d71b4dca51e7"), --DoubleBarrel
}

local oldGetToolProxyItem = GetToolProxyItem
function getToolProxyItemHook( toolUuid )
	local item = oldGetToolProxyItem( toolUuid )
	if not item then
		item = ToolItems[tostring( toolUuid )]
	end

	return item
end
GetToolProxyItem = getToolProxyItemHook