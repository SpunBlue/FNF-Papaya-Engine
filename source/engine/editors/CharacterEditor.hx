package engine.editors;

import flixel.addons.ui.FlxUINumericStepper;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
import lime.ui.FileDialog;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
#if debug
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.math.FlxPoint;
import openfl.Assets;
import haxe.Json;
import flixel.FlxSprite;
import objects.Character;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import lime.system.Clipboard;

using StringTools;

class CharacterEditor extends FlxState
{
    var char:String = 'bf';

    var music:FlxSound = new FlxSound();
    var vocals:FlxSound = new FlxSound();

    var offsetText:FlxText = new FlxText();

    var character:Character;
    var selectedAnimation:AnimationData;

    var camCursor:FlxSprite;

    var curAnimIndex:Int = 0;

    var data:CharacterData;
    var isPlayer:Bool = true;

    var uiCam:FlxCamera = new FlxCamera();
    var drawGroup:FlxGroup = new FlxGroup();

    var ui_box:FlxUITabMenu;

    var xStepper:FlxUINumericStepper;
    var yStepper:FlxUINumericStepper;

    var camXStepper:FlxUINumericStepper;
    var camYStepper:FlxUINumericStepper;

    public function new(?character:String = 'bf', ?data:CharacterData) {
        if (character != null)
            char = character;
        else
            char = 'unknown';

        this.data = data;

        super();
    }

    override function create() {
        if (data == null) {
            var path:String = Paths.getJSON('characters/$char');
            if (Assets.exists(path))
                data = Json.parse(Assets.getText(path));
            else if (Assets.exists(Paths.getJSON("characters/dad"))) {
                // Just so they have smth to use a template
                data = Json.parse(Assets.getText(Paths.getJSON("characters/dad")));
                isPlayer = false;
            }
            else {
                trace('If you see this, you likely deleted the dad character. I\'d suggest reimplementing him because this likely is going to crash now...');
    
                data = {
                    imagePath: "DADDY_DEAREST",
                    animations: [
                        {
                            name: "idle",
                            prefix: "Dad idle dance",
                            fps: 24,
                            loop: false,
                            offsets: [0, 0]
                        }
                    ]
                }

                isPlayer = false;
            }    
        }

        reloadCharacter();

        curAnimIndex = 0;
        selectedAnimation = data.animations[curAnimIndex];

        var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
		bg.antialiasing = true;
		bg.scrollFactor.set(0.9, 0.9);
		bg.active = false;

		var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		stageFront.antialiasing = true;
		stageFront.scrollFactor.set(0.9, 0.9);
		stageFront.active = false;

        var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
		stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
		stageCurtains.updateHitbox();
		stageCurtains.antialiasing = true;
		stageCurtains.scrollFactor.set(1.3, 1.3);
		stageCurtains.active = false;

        add(bg);
        add(stageFront);
        add(drawGroup);
        add(stageCurtains);

        FlxG.cameras.add(uiCam, false);
        uiCam.bgColor = FlxColor.TRANSPARENT;

        camCursor = new FlxSprite().loadGraphic("assets/images/cursor.png");
        camCursor.alpha = 0.5;
        add(camCursor);

        // ui
        offsetText.setFormat(null, 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.GRAY);
        offsetText.camera = uiCam;
        add(offsetText);
        
        final tabs = [
            {name: "Character", label: "Character"}
        ];
        ui_box = new FlxUITabMenu(null, tabs, true);
        
        ui_box.resize(300, 300);
        ui_box.x = FlxG.width - ui_box.width - 20;
        ui_box.y = 20;
        ui_box.camera = uiCam;

        // Assistant Functions
        final generateCheckBox = function(x:Float, y:Float, name:String, callback:FlxUICheckBox->Void, menu:FlxUI, ?startValue:Null<Bool>, ?defValue:Bool = false) {
            var box = new FlxUICheckBox(x, y, null, null, name, 80);

            if (startValue != null)
                box.checked = startValue;
            else
                box.checked = defValue;

            box.callback = () -> { callback(box); };

            menu.add(box);
        };

        // Character Menu
        var character_ui = new FlxUI(null, ui_box);
        character_ui.name = "Character";

        var selectCharacter:FlxButton = new FlxButton(20, 20, "Load Character", ()->{
            var fileDialog = new FileDialog();

            fileDialog.onOpen.add((res)->{
                FlxG.switchState(new CharacterEditor(null, Json.parse(res)));
            });

            fileDialog.open(null, null, "Character JSON");
        });
        character_ui.add(selectCharacter);

        var saveCharacter:FlxButton = new FlxButton(120, 20, "Save Character", saveCharacter);
        character_ui.add(saveCharacter);

        generateCheckBox(20, 50, "Flip X", (box) -> {
            data.flipX = box.checked;
            reloadCharacter();
        }, character_ui, data.flipX, false);

        generateCheckBox(120, 50, "Antialiasing", (box) -> {
            data.antialiasing = box.checked;
            reloadCharacter();
        }, character_ui, data.antialiasing, true);

        var positionOffsetsText:FlxText = new FlxText(20, 100);
        positionOffsetsText.setFormat(null, 12, FlxColor.WHITE);
        positionOffsetsText.text = "Position Offsets (X, Y)";
        character_ui.add(positionOffsetsText);

        xStepper = new FlxUINumericStepper(20, 120, 5, 0, -4096, 4096, 1);
        if (data.positionOffsets != null)
            xStepper.value = data.positionOffsets[0];
        character_ui.add(xStepper);

        yStepper = new FlxUINumericStepper(120, 120, 5, 0, -4096, 4096, 1);
        if (data.positionOffsets != null)
            yStepper.value = data.positionOffsets[1];
        character_ui.add(yStepper);

        var camOffsetsText:FlxText = new FlxText(20, 170);
        camOffsetsText.setFormat(null, 12, FlxColor.WHITE);
        camOffsetsText.text = "Camera Position Offsets (X, Y)";
        character_ui.add(camOffsetsText);

        camXStepper = new FlxUINumericStepper(20, 190, 5, 0, -4096, 4096, 1);
        if (data.camOffsets != null)
            camXStepper.value = data.camOffsets[0];
        character_ui.add(camXStepper);

        camYStepper = new FlxUINumericStepper(120, 190, 5, 0, -4096, 4096, 1);
        if (data.camOffsets != null)
            camYStepper.value = data.camOffsets[1];
        character_ui.add(camYStepper);

        add(ui_box);

        ui_box.addGroup(character_ui);

        FlxG.camera.focusOn(character.getMidpoint());

        super.create();

        FlxG.sound.music.stop();
        FlxG.mouse.visible = true;

        playRandomInst();
    }

    function reloadCharacter() {
        if (character != null && character.exists)
            character.destroy();

        var position:FlxPoint = new FlxPoint(100, 100);
        if (isPlayer)
            position.set(770, 450);

        character = new Character(position.x, position.y, char, false, data);
        drawGroup.add(character);
    }

    function playRandomInst() {
        var songs:Array<String> = [];

		var temp = CoolUtil.coolTextFile('assets/data/freeplaySonglist.txt');
		for (song in temp)
			songs.push(song.split(':')[0]);

        var rand:Int = FlxG.random.int(0, songs.length - 1);

        music.loadEmbedded(Paths.getSong(songs[rand].toLowerCase(), "Inst"), true);
        music.play();

        if (Assets.exists(Paths.getSong(songs[rand].toLowerCase(), "Voices"))) {
            vocals.loadEmbedded(Paths.getSong(songs[rand].toLowerCase(), "Voices"), true);
            vocals.play();
        }
        else {
            vocals.stop();
        }
    }

    override function update(elapsed:Float) {
        if (FlxG.keys.pressed.J)
            FlxG.camera.scroll.x -= 5;
        else if (FlxG.keys.pressed.K)
            FlxG.camera.scroll.y += 5;
        else if (FlxG.keys.pressed.I)
            FlxG.camera.scroll.y -= 5;
        else if (FlxG.keys.pressed.L)
            FlxG.camera.scroll.x += 5;

        if (FlxG.keys.pressed.LBRACKET)
            FlxG.camera.zoom -= 0.001;
        else if (FlxG.keys.pressed.RBRACKET)
            FlxG.camera.zoom += 0.001;

        if (FlxG.keys.justPressed.P)
            playRandomInst();
        else if (FlxG.keys.justPressed.R)
            reloadCharacter();
        else if (FlxG.keys.justPressed.TAB) {
            isPlayer = !isPlayer;

            reloadCharacter();
            FlxG.camera.focusOn(character.getMidpoint());
        }
        
        super.update(elapsed);

        if (data.positionOffsets != null) {
            if (data.positionOffsets[0] != xStepper.value) {
                character.x -= data.positionOffsets[0];
                character.x += xStepper.value;

                data.positionOffsets[0] = xStepper.value;
            }
            else if (data.positionOffsets[1] != yStepper.value) {
                character.y -= data.positionOffsets[1];
                character.y += yStepper.value;

                data.positionOffsets[1] = yStepper.value;
            }
        }
        else {
            data.positionOffsets = [0, 0];
        }

        if (data.camOffsets != null) {
            if (data.camOffsets[0] != camXStepper.value)
                data.camOffsets[0] = camXStepper.value;
            if (data.camOffsets[1] != camYStepper.value)
                data.camOffsets[1] = camYStepper.value;

            camCursor.setPosition(character.getMidpoint().x + data.camOffsets[0], character.getMidpoint().y + data.camOffsets[1]);
        }
        else {
            camCursor.setPosition(character.getMidpoint().x, character.getMidpoint().y);
            data.camOffsets = [0, 0];
        }

        music.update(elapsed);
        if (vocals != null)
            vocals.update(elapsed);
        
        if (vocals != null && vocals.playing && (vocals.time > music.time + 20 || vocals.time < music.time - 20))
			vocals.time = music.time;

        offsetText.text = '';
        for (animation in data.animations) {
            if (animation.offsets == null)
                animation.offsets = [0, 0];

            var sub:String = "";
            if (data.animations[curAnimIndex] == animation)
                sub = '<';

            offsetText.text += '"${animation.name}" : [${animation.offsets[0]}, ${animation.offsets[1]}] $sub\n';
        }

        if (character.animation.curAnim.name != selectedAnimation.name || character.animation.curAnim.finished)
            character.playAnim(selectedAnimation.name);

        var addition:Int = 1;
        if (FlxG.keys.pressed.SHIFT)
            addition = 5;

        xStepper.stepSize = yStepper.stepSize = camXStepper.stepSize = camYStepper.stepSize = addition;

        if (!FlxG.mouse.overlaps(ui_box)) {
            if (!FlxG.keys.pressed.CONTROL) {
                if (FlxG.keys.anyJustPressed([A, S, W, D])) {
                    // for some reason this has to be flipped around?
                    if (FlxG.keys.pressed.W)
                        selectedAnimation.offsets[1] += addition;
                    else if (FlxG.keys.pressed.S)
                        selectedAnimation.offsets[1] -= addition;
        
                    if (FlxG.keys.pressed.A)
                        selectedAnimation.offsets[0] += addition;
                    else if (FlxG.keys.pressed.D)
                        selectedAnimation.offsets[0] -= addition;
        
                    data.animations[curAnimIndex] = selectedAnimation;
        
                    // reloadCharacter();
                    character.addOffset(selectedAnimation.name, selectedAnimation.offsets[0], selectedAnimation.offsets[1]);
                    character.playAnim(selectedAnimation.name);
                }
    
                if (FlxG.keys.anyJustPressed([Q, E])) {
                    if (FlxG.keys.pressed.Q && curAnimIndex > 0)
                        --curAnimIndex;
                    else if (FlxG.keys.pressed.E && curAnimIndex < data.animations.length - 1)
                        ++curAnimIndex;
    
                    selectedAnimation = data.animations[curAnimIndex];
                }
            }
            else {
                if (FlxG.keys.justPressed.S) {
                    /*#if cpp
                    sys.io.File.saveContent("character.json", Json.stringify(data, "\t"));
                    FlxG.log.notice("Saved Character JSON as 'character.json'");
                    #else
                    Clipboard.text = Json.stringify(data, "\t");
                    FlxG.log.notice("Saved Character JSON as text within your Clipboard");
                    #end
    
                    FlxG.debugger.visible = true;*/
    
                    saveCharacter();
                }
                
            }
        }
    }

    function saveCharacter()
    {
        var fileDialog = new FileDialog();

        fileDialog.save(Json.stringify(data), null, '$char.json', "Save Character JSON");
    }
}

class ArtificialCharacter extends FlxSprite {
    public var data:CharacterData;

    public function new(character:String) {
        var path:String = Paths.getJSON('characters/$character');
        if (Assets.exists(path))
            data = Json.parse(Assets.getText(path));
        else {
            data = {
                imagePath: "DADDY_DEAREST",
                animations: [
                    {
                        name: "idle",
                        prefix: "Dad idle dance",
                        fps: 24,
                        loop: false,
                        offsets: [0, 0]
                    }
                ]
            }
        }

        super();
    }
}
#end