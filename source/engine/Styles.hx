package engine;

import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import openfl.Assets;

class StyleHandler
{
    public static var curStyle:StyleData;
    public static var styles:Map<String, StyleData> = new Map();
    public static var styleList:Array<String> =[
        'default'
    ];

    public static function init() {
        for (style in styleList) {
            var data:StyleData = Json.parse(Assets.getText(Paths.getJSON('styles/$style')));
            styles.set(style, data);
        }

        curStyle = styles.get('default');
    }

    public static function getImage(path:String):String {
        return Paths.getImage('styles/${curStyle.root}/$path');
    }

    public static function getSparrow(path:String):FlxAtlasFrames {
        return Paths.getSparrow('styles/${curStyle.root}/$path');
    }

    public static function giveMeStrums():FlxAtlasFrames {
        return getSparrow(curStyle.strumImagePath);
    }

    public static function giveMeNotes():FlxAtlasFrames {
        return getSparrow(curStyle.noteImagePath);
    }
}

typedef StyleData =
{
    var root:String;
	var strumImagePath:String;
	var noteImagePath:String;

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
	var ?offsetX:Float;
	var ?offsetY:Float;
}

typedef AnimationData =
{
	var prefix:String;
	var name:String;
	var fps:Int;
	var ?loop:Bool;
	var ?offsetX:Float;
	var ?offsetY:Float;
}