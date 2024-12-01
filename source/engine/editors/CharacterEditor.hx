package engine.editors;

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
import flixel.text.FlxInputText;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxFrame;
import lime.ui.FileDialog;
import flixel.ui.FlxButton;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;

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

    var animName:FlxInputText;
    var animPrefix:FlxInputText;
    var animIndices:FlxInputText;
    var imageText:FlxInputText;

    final helpShit:String = "E, and Q, to select an animation.\n"
        + "W, A, S, and D, to move offsets.\n"
        + "I, J, K, and L, to move camera.\n"
        + "[, and ], to zoom in and out.\n"
        + "X to delete the selected animation.\n"
        + "TAB to toggle \"isPlayer\".\n"
        + "P to randomize the song playing.\n"
        + "R to reload everything.";

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
        offsetText.setPosition(20, 20);
        offsetText.setFormat(null, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.SHADOW, FlxColor.GRAY);
        offsetText.camera = uiCam;
        add(offsetText);
        
        final tabs = [
            {name: "Character", label: "Character"},
            {name: "Animations", label: "Animations"}
        ];
        ui_box = new FlxUITabMenu(null, tabs, true);
        
        ui_box.resize(300, 300);
        ui_box.x = FlxG.width - ui_box.width - 20;
        ui_box.y = 20;
        ui_box.camera = uiCam;

        // Assistant Functions
        final generateCheckBox = function(x:Float, y:Float, name:String, ?callback:FlxUICheckBox->Void, menu:FlxUI, ?startValue:Null<Bool>, ?defValue:Bool = false) {
            var box = new FlxUICheckBox(x, y, null, null, name, 80);

            if (startValue != null)
                box.checked = startValue;
            else
                box.checked = defValue;

            if (callback != null)
                box.callback = () -> { callback(box); };

            menu.add(box);
        };

        // Character Menu
        var character_ui = new FlxUI(null, ui_box);
        character_ui.name = "Character";

        var selectCharacter:FlxUIButton = new FlxUIButton(20, 20, "Load Character", ()->{
            var fileDialog = new FileDialog();

            fileDialog.onOpen.add((res)->{
                data = Json.parse(res);
                char = "unknown"; // doesn't really matter anyway

                if (data.positionOffsets == null)
                    data.positionOffsets = [0, 0];
                if (data.camOffsets == null)
                    data.camOffsets = [0, 0];

                imageText.text = data.imagePath;

                xStepper.value = data.positionOffsets[0];
                yStepper.value = data.positionOffsets[1];

                camXStepper.value = data.camOffsets[0];
                camYStepper.value = data.camOffsets[1];

                curAnimIndex = 0;
                selectedAnimation = data.animations[0];

                reloadCharacter();
            });

            fileDialog.open(null, null, "Character JSON");
        });
        character_ui.add(selectCharacter);

        var saveCharacter:FlxUIButton = new FlxUIButton(120, 20, "Save Character", saveCharacter);
        character_ui.add(saveCharacter);

        var textImageText = new FlxText(20, 50, 100, "Image Path");
        textImageText.setFormat(null, 8, FlxColor.WHITE);
        character_ui.add(textImageText);

        imageText = new FlxInputText(100, 50, 128, data.imagePath);
        imageText.camera = uiCam;
        imageText.onEnter.add((text:String)->{
            var old:String = data.imagePath;

            try {
                data.imagePath = imageText.text;
                reloadCharacter();
            }
            catch (e:Dynamic) {
                trace('Failed to reload character with new image path! ($e).');

                data.imagePath = old;
                reloadCharacter();
            }
        });
        character_ui.add(imageText);

        generateCheckBox(20, 80, "Flip X", (box) -> {
            data.flipX = box.checked;
            reloadCharacter();
        }, character_ui, data.flipX, false);

        generateCheckBox(120, 80, "Antialiasing", (box) -> {
            data.antialiasing = box.checked;
            reloadCharacter();
        }, character_ui, data.antialiasing, true);

        var positionOffsetsText:FlxText = new FlxText(20, 130);
        positionOffsetsText.setFormat(null, 12, FlxColor.WHITE);
        positionOffsetsText.text = "Position Offsets (X, Y)";
        character_ui.add(positionOffsetsText);

        xStepper = new FlxUINumericStepper(20, 150, 5, 0, -4096, 4096, 1);
        if (data.positionOffsets != null)
            xStepper.value = data.positionOffsets[0];
        character_ui.add(xStepper);

        yStepper = new FlxUINumericStepper(120, 150, 5, 0, -4096, 4096, 1);
        if (data.positionOffsets != null)
            yStepper.value = data.positionOffsets[1];
        character_ui.add(yStepper);

        var camOffsetsText:FlxText = new FlxText(20, 200);
        camOffsetsText.setFormat(null, 12, FlxColor.WHITE);
        camOffsetsText.text = "Camera Position Offsets (X, Y)";
        character_ui.add(camOffsetsText);

        camXStepper = new FlxUINumericStepper(20, 220, 5, 0, -4096, 4096, 1);
        if (data.camOffsets != null)
            camXStepper.value = data.camOffsets[0];
        character_ui.add(camXStepper);

        camYStepper = new FlxUINumericStepper(120, 220, 5, 0, -4096, 4096, 1);
        if (data.camOffsets != null)
            camYStepper.value = data.camOffsets[1];
        character_ui.add(camYStepper);

        // Animation Menu
        var animation_ui = new FlxUI(null, ui_box);
        animation_ui.name = "Animations";

        var animNameText:FlxText = new FlxText(20, 20);
        animNameText.text = "Animation Name";
        animation_ui.add(animNameText);

        animName = new FlxInputText(120, 20, 128);
        animName.camera = uiCam;
        animation_ui.add(animName);

        var animPrefixText:FlxText = new FlxText(20, 40);
        animPrefixText.text = "Animation Prefix";
        animation_ui.add(animPrefixText);

        animPrefix = new FlxInputText(120, 40, 128);
        animPrefix.camera = uiCam;
        animation_ui.add(animPrefix);

        var animIndicesText:FlxText = new FlxText(20, 60);
        animIndicesText.text = "Animation Indices";
        animation_ui.add(animIndicesText);

        animIndices = new FlxInputText(120, 60, 128);
        animIndices.camera = uiCam;
        animation_ui.add(animIndices);

        var fpsStepper = new FlxUINumericStepper(20, 80, 1, 24, 1, 60, 0);
        animation_ui.add(fpsStepper);

        var loop:Bool = false;
        generateCheckBox(100, 80, "Loop", (box)->{
            loop = box.checked;
        }, animation_ui, false, false);

        var addAnimButt:FlxUIButton = new FlxUIButton(20, 100, "Add Animation", ()->{
            var frames:Array<Int> = null;

            if (animIndices.text.length > 0) {
                var framesStr = animIndices.text.split(',');
                frames = [];
                for (str in framesStr)
                    frames.push(Std.parseInt(str));
            }

            var anim:AnimationData = {
                name: animName.text,
                prefix: animPrefix.text,
                fps: Std.int(fpsStepper.value),
                offsets: [0, 0],
                indices: frames,
                loop: loop
            }

            data.animations.push(anim);

            animName.text = "";
            animPrefix.text = "";
            animIndices.text = "";

            reloadCharacter();
            updateText();
        });
        animation_ui.add(addAnimButt);

        add(ui_box);

        ui_box.addGroup(character_ui);
        ui_box.addGroup(animation_ui);

        FlxG.camera.focusOn(character.getMidpoint());

        super.create();

        FlxG.sound.music.stop();
        FlxG.mouse.visible = true;

        playRandomInst();
        updateText();
    }

    function reloadCharacter() {
        if (character != null && character.exists)
            character.destroy();

        var position:FlxPoint = new FlxPoint(100, 100);
        if (isPlayer)
            position.set(770, 450);

        character = new Character(position.x, position.y, char, false, data);
        character.debugMode = true;
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

    override public function update(elapsed:Float) {
        if (!FlxG.mouse.overlaps(ui_box, uiCam)) {
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
                FlxG.switchState(new CharacterEditor("unknown", data));
            else if (FlxG.keys.justPressed.TAB) {
                isPlayer = !isPlayer;
                
                updateText();
                reloadCharacter();
                FlxG.camera.focusOn(character.getMidpoint());
            }
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

        if (character.animation.curAnim != null && (character.animation.curAnim.name != selectedAnimation.name || character.animation.curAnim.finished))
            character.playAnim(selectedAnimation.name);

        var addition:Int = 1;
        if (FlxG.keys.pressed.SHIFT)
            addition = 5;

        xStepper.stepSize = yStepper.stepSize = camXStepper.stepSize = camYStepper.stepSize = addition;

        if (FlxG.keys.justPressed.X && data.animations.length > 1) {
            data.animations.remove(data.animations[curAnimIndex]);
            selectedAnimation = data.animations[0];
            curAnimIndex = 0;

            updateText();
        }

        if (!FlxG.mouse.overlaps(ui_box, uiCam)) {
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

                    updateText();
                }
    
                if (FlxG.keys.anyJustPressed([Q, E])) {
                    if (FlxG.keys.pressed.Q && curAnimIndex > 0)
                        --curAnimIndex;
                    else if (FlxG.keys.pressed.E && curAnimIndex < data.animations.length - 1)
                        ++curAnimIndex;
    
                    selectedAnimation = data.animations[curAnimIndex];

                    updateText();
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

    function updateText()
    {
        offsetText.text = 'Offsets: \n';
        for (animation in data.animations) {
            if (animation.offsets == null)
                animation.offsets = [0, 0];

            var sub:String = "";
            if (data.animations[curAnimIndex] == animation)
                sub = '<';

            offsetText.text += '"${animation.name}": [${animation.offsets[0]}, ${animation.offsets[1]}] $sub\n';
        }
        offsetText.text += '\nDisplay Settings: \n"isPlayer": $isPlayer\n\nControls: \n$helpShit';
    }

    function saveCharacter()
    {
        var fileDialog = new FileDialog();

        fileDialog.save(Json.stringify(data, "\t"), null, '$char.json', "Save Character JSON");
    }

    override function destroy() {
        music.stop();
        if (vocals != null)
            vocals.stop();

        super.destroy();
    }
}
#end