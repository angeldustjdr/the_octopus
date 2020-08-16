extends RigidBody2D

var rand = randomize()
var missionAccepted = false
var initialX_textureRect
var npcList = []

export var nb_npc = 1
export var outcomeMoney = [0,0]
export var outcomeReputation = [0,0]
export var outcomeCompromised = [0,0]
export var missionType = "?"
var isWin = 1

var speed = -400

signal ignoreTimeOut(mission_id)
signal missionTimeOut(mission_id)
signal NPCEnter(mission_id)
signal NPCExit(mission_id)
signal missionAccomplished(money,reput,compro)

# Called when the node enters the scene tree for the first time.
func _ready():
	#Set NPC socket
	var maxNPC = [$NPCRect/NPC1,$NPCRect/NPC2,$NPCRect/NPC3]
	for i in range(nb_npc):
		maxNPC[i].visible = true
	#Set Mission type label
	$Type_label.text = "Type: "+missionType
	$TimerIgnore.start()
	initialX_textureRect = $TimeLabel/TextureRect.rect_size.x 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	linear_velocity.x = speed
#Timer 
	if missionAccepted==false:
		$TimeLabel.text = str($TimerIgnore.time_left)
		$TimeLabel/TextureRect.rect_size.x = initialX_textureRect * $TimerIgnore.time_left/$TimerIgnore.wait_time
	else:
		$TimeLabel.text = str($TimerMission.time_left)
		$TimeLabel/TextureRect.rect_size.x = initialX_textureRect * $TimerMission.time_left/$TimerMission.wait_time

func _on_TimerMission_timeout():
	var successChance = 50
	for npc in npcList:
		if npc.NPC_type == "You" or npc.NPC_type == missionType:
			successChance += 30 / npcList.size()
		else:
			successChance -= 20 / npcList.size()
	var roll = randf()*100.0
	if roll<=successChance:
		isWin = 0
	else:
		isWin = 1
	emit_signal("missionTimeOut", self)

func _on_TimerIgnore_timeout():
	emit_signal("ignoreTimeOut",self)

func _on_detection_npc_area_entered(area):
	if(area.get_parent() is KinematicBody2D):
		emit_signal("NPCEnter", self)

func _on_detection_npc_area_exited(area):
	if(area.get_parent() is KinematicBody2D):
		emit_signal("NPCExit", self)

func affect_npc(npc):
	var l = len(npcList)
	if(l < nb_npc):
		if (l <= 2):
			npc.pickable = false
			npcList.append(npc)
			get_node("NPCRect/NPC"+str(l+1)).texture = npc.get_node("Sprite").texture
			$TimerIgnore.stop()
			if (l+1 < nb_npc):
				$TimerIgnore.start()
			elif (l+1 == nb_npc):
				missionAccepted = true
				$TimerMission.start()
		else:
			print("ERROR AFFECT_NPC")

func delete_on_ignoreTimeOut():
	makeNPC_pickable()
	queue_free()

func delete_on_missionTimeOut():
	makeNPC_pickable()
	emit_signal("missionAccomplished",outcomeMoney[isWin],outcomeReputation[isWin],outcomeCompromised[isWin])
	queue_free()
	
func makeNPC_pickable():
	for npc in npcList:
		npc.pickable = true

func _on_collision_NPC1_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				match len(npcList):
					1:
						unaffect_npc(0)

func unaffect_npc(num):
	var npc = npcList[num]
	npc.pickable = true
	get_node("NPCRect/NPC"+str(num+1)).texture = load("res://Assets/icons/person.png")
	npcList.remove(num)
