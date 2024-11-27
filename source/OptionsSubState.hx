package;

import engine.Paths;
import flixel.text.FlxText;
import engine.Options;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import objects.Alphabet;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Controls', 'Gameplay', 'Graphics', 'Audio'];
	var menuItemGroups:Array<SelectableOptions> = [
		{
			group: "Gameplay",
			options: [
				{
					text: "Use Ghost Tapping",
					nameOfOption: "ghostTapping"
				},
				{
					text: "Use Downscroll",
					nameOfOption: "downscroll"
				},
				{
					text: "Allow Distractions",
					nameOfOption: "allowDistractions"
				},
				{
					text: "Use Mod Charts",
					nameOfOption: "allowModCharts"
				}
			]
		},
		{
			group: "Graphics",
			options: [
				{
					text: "Increase Max FPS",
					nameOfOption: "maxFPS"
				},
				{
					text: "Limit Flashing Lights",
					nameOfOption: "limitFlashing"
				},
				{
					text: "Force Default Note Style",
					nameOfOption: "forceDefaultStyle"
				}
			]
		}
	];

	var optionItems:FlxTypedGroup<Alphabet> = new FlxTypedGroup();
	var innerOptionItems:FlxTypedGroup<Alphabet> = new FlxTypedGroup();

	var lastSelected:Int = 0;
	var curSelected:Int = 0;
	var innerMenu:Bool = false;

	var optionCam:FlxCamera;

	var bg:FlxSprite;
	var optionBackdrop:FlxSprite;
	var camFollow:FlxObject = new FlxObject();
	var infoText:Alphabet;

	public function new(?useTransparentBG:Bool = true, ?useTransIn:Bool = true)
	{
		optionCam = new FlxCamera();
		optionCam.bgColor = FlxColor.TRANSPARENT;
		if (useTransIn)
			optionCam.alpha = 0;

		this.camera = optionCam; // fuck you
		FlxG.cameras.add(optionCam, false);

		persistentUpdate = persistentDraw = false;

		super();

		camFollow.x = FlxG.width / 2;
		optionCam.follow(camFollow, LOCKON, 0.06);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		if (useTransparentBG)
			add(bg);

		optionBackdrop = new FlxSprite().makeGraphic(Math.round(FlxG.width / 4), FlxG.height, FlxColor.BLACK);
		optionBackdrop.alpha = 0.7;
		optionBackdrop.scrollFactor.set(1, 0);
		add(optionBackdrop);

		infoText = new Alphabet(0, 0, "Green means Enabled, Red means Disabled.", true, false, -24);
		infoText.screenCenter(X);
		infoText.scrollFactor.set();
		infoText.scale.set(0.5, 0.5);
		infoText.visible = false;
		// add(infoText); // eh, i feel like it's self explanatory

		createMenuItems();

		optionItems.camera = optionCam;
		add(optionItems);

		innerOptionItems.camera = optionCam;
		add(innerOptionItems);

		if (useTransIn)
			FlxTween.tween(optionCam, {alpha: 1}, 0.25);
	}

	var inButtonRemap:Bool = false; // leave it to me to come up with the most dumbest solutions
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		// The idea is that the substate pauses while in the ButtonRemapState, so on the next frame when it's closed, it'll just toggle this shit.
		if (inButtonRemap) {
			FlxTween.tween(bg, {alpha: 0}, 0.25);
			camFollow.x = FlxG.width / 2;
			innerMenu = false;

			inButtonRemap = false;
		}

		if (controls.BACK && !closing) {
			FlxG.sound.play(Paths.getSound("cancelMenu"));

			if (!innerMenu)
				close();
			else {
				for (option in innerOptionItems)
					option.destroy();
				innerOptionItems.clear();

				innerMenu = false;
				curSelected = lastSelected;

				infoText.visible = false;
				camFollow.x = FlxG.width / 2;
				FlxTween.tween(bg, {alpha: 0}, 0.25);

				updateMenuItems();
			}
		}
		else if (controls.ACCEPT && !closing) {
			FlxG.sound.play(Paths.getSound("confirmMenu"));

			if (!innerMenu) {
				innerMenu = true;

				// Open Inner Option Menu, or Open Substate.
				switch (optionItems.members[curSelected].text.toLowerCase()) {
					default:
						lastSelected = curSelected;
						infoText.visible = true;

						createInnerMenuItems(optionItems.members[lastSelected].text);
					case 'controls':
						inButtonRemap = true;
						openSubState(new ButtonRemapSubstate());
					case 'audio':
						inButtonRemap = true; // too lazy to change variable name
						openSubState(new LatencySubstate());
				}

				FlxTween.tween(bg, {alpha: 0.7}, 0.25);
				camFollow.x = (FlxG.width / 2) + optionBackdrop.width;
			}
			else {
				var nameOfOption:String = innerOptionItems.members[curSelected].data.nameOfOption;
				Options.set(nameOfOption, !Options.get(nameOfOption));
				updateMenuItems();
			}
		}

		if ((controls.UP_P || controls.DOWN_P) && !closing)
		{
			if (controls.UP_P && curSelected > 0){
				--curSelected;
				FlxG.sound.play(Paths.getSound("scrollMenu"));
			}
			else if (controls.DOWN_P && (innerMenu && curSelected < innerOptionItems.length - 1 || !innerMenu && curSelected < optionItems.length - 1)) {
				++curSelected;
				FlxG.sound.play(Paths.getSound("scrollMenu"));
			}
			else {
				var rand:Float = new FlxRandom().int(1, 3);
				FlxG.sound.play(Paths.getSound("badnoise" + rand));
			}
			
			updateMenuItems();
		}
	}

	// doubt this function needs to exist but hey, ya never know.
	// update: function was not neccessary.
	function createMenuItems(){
		for (item in optionItems)
			item.destroy();
		optionItems.clear();

		for (i in 0...textMenuItems.length) {
			var opt = new Alphabet(16, 16 + (96 * i), textMenuItems[i], true, false, -32);
			opt.scale.set(0.75, 0.75);
			optionItems.add(opt);
		}

		curSelected = 0;
		updateMenuItems();
	}

	function createInnerMenuItems(selected:String) {
		var group:Array<SelectableOptionData> = [];
		for (g in menuItemGroups){
			if (g.group.toLowerCase() == selected.toLowerCase())
				group = g.options;
		}

		for (i in 0...group.length) {
			var opt = new Alphabet(0, 16 + (96 * i), group[i].text, true, false, -24);
			opt.scale.set(0.5, 0.5);
			
			opt.screenCenter(X);
			// opt.x -= FlxG.width / 2;
			opt.scrollFactor.x = 0;

			opt.data = group[i]; // append the option information
			innerOptionItems.add(opt);
		}

		curSelected = 0;
		updateMenuItems();
	}

	function updateMenuItems(){
		var items:FlxTypedGroup<Alphabet>;
		if (innerMenu)
			items = innerOptionItems;
		else
			items = optionItems;

		for (i in 0...items.length) {
			if (i == curSelected){
				camFollow.y = (items.members[i].y + (items.members[i].height / 2)) - 16;
				items.members[i].alpha = 1;
			}
			else
				items.members[i].alpha = 0.7;
			
			if (innerMenu && items.members[i].data != null) {
				var data:SelectableOptionData = items.members[i].data;

				if (Options.get(data.nameOfOption) == true)
					items.members[i].color = FlxColor.GREEN;
				else
					items.members[i].color = FlxColor.RED;
			}
		}
	}

	var closing:Bool = false;
	override public function close(){
		if (!closing){
			closing = true;

			FlxTween.tween(optionCam, {alpha: 0}, 0.15, {onComplete: function(v){
				FlxG.cameras.remove(optionCam);
	
				close();
			}});
		}
		else {
			super.close();
		}
	}
}

typedef SelectableOptions =
{
	var group:String;
	var ?options:Array<SelectableOptionData>;
	var ?substate:MusicBeatSubstate;
}

typedef SelectableOptionData =
{
	var text:String;
	var nameOfOption:String;
}