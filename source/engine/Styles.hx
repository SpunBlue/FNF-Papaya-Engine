package engine;

import objects.NoteSplash.SplashProperties;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.Assets;

/**
 * This isn't a local style handler, this manages the global style of the game.
 */
class StyleHandler
{
    // public static var curStyle:StyleData;
    /**
     * Handles the default style.
     */
    public static var handler:LocalStyle;

    public static var styles:Map<String, StyleData> = new Map();
    public static var styleList:Array<String> = [
        'default'
    ];

    public static function init() {
        styleList = CoolUtil.coolTextFile(Paths.getTxt("visualStyleList"));

        for (style in styleList) {
            var data:StyleData = Json.parse(Assets.getText(Paths.getJSON('styles/$style')));
            styles.set(style, data);
        }

        handler = new LocalStyle(styles.get(styleList[0]));
    }

    public static function getData():StyleData {
        return handler.curStyle;
    }

    public static function getImage(path:String):String {
        return Paths.getImage('styles/${handler.curStyle.root}/$path');
    }

    public static function getSparrow(path:String):FlxAtlasFrames {
        return Paths.getSparrow('styles/${handler.curStyle.root}/$path');
    }

    public static function giveMeStrums():FlxAtlasFrames {
        return getSparrow(handler.curStyle.strumImagePath);
    }

    public static function giveMeNotes():FlxAtlasFrames {
        return getSparrow(handler.curStyle.noteImagePath);
    }
}

/**
 * This is a local style handler, meant for locally defined visual styles.
 */
class LocalStyle {
    public var curStyle:StyleData;

    public function new (style:StyleData) {
        curStyle = style;
    }

    public function setStyle(name:String) {
        curStyle = StyleHandler.styles.get(name);
        if (curStyle == null) {
            curStyle = StyleHandler.getData();
            trace("Could not locate style " + name);
        }
    }

    // I'd make these return from the global style but it likely wouldn't work.
    public function getImage(path:String):String {
        return Paths.getImage('styles/${curStyle.root}/$path');
    }

    public function getSparrow(path:String):FlxAtlasFrames {
        return Paths.getSparrow('styles/${curStyle.root}/$path');
    }

    public function giveMeStrums():FlxAtlasFrames {
        try {
            return getSparrow(curStyle.strumImagePath);
        }
        catch (e:Dynamic) {
            trace('Couldn\'t retrieve strums, pulling from default. ($e).');
            return StyleHandler.giveMeStrums();
        }
    }

    public function giveMeNotes():FlxAtlasFrames {
        try {
            return getSparrow(curStyle.noteImagePath);
        }
        catch (e:Dynamic) {
            trace('Couldn\'t retrieve notes, pulling from default. ($e).');
            return StyleHandler.giveMeNotes();
        }
    }
}

typedef StyleData =
{
    var root:String;
	var strumImagePath:String;
	var noteImagePath:String;
    
    var enableSplashes:Bool;
    var ?splashesImagePath:String;
    var ?splashProperties:SplashProperties;

    var antialiasing:Bool;

	var strumAnimations:Array<StrumShit>;
	var noteAnimations:Array<NoteShit>;

	var numDirectoryPath:String; // checks in `/nums/` by default
	var ratingsDirectoryPath:String; // checks in `/ratings/` by default
	var uiDirectoryPath:String; // checks in `/ui/` by default
}

typedef StrumShit =
{
	var direction:Int;
	var idle:MinimalAnimData;
	var pressed:MinimalAnimData;
	var confirm:MinimalAnimData;
}

typedef NoteShit =
{
	var direction:Int;
	var idle:MinimalAnimData;
	var holding:MinimalAnimData;
	var holdends:MinimalAnimData;
}

typedef MinimalAnimData =
{
	var prefix:String;
	var ?fps:Int;
	var ?offsets:Array<Float>;
}