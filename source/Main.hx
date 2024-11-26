package;

import openfl.events.Event;
import flixel.util.FlxSave;
import flixel.FlxG;
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
import lime.system.System;
import lime.app.Application;
import flixel.FlxGame;
import openfl.display.FPS;
import openfl.display.Sprite;

class Main extends Sprite
{
	#if (desktop || mobile)
	public static var gameDirectory:String = "";
	public static var logDirectory:String = "";
	#end

	public function new()
	{
		#if (desktop || mobile)
		var mod:String = Application.current.meta.get("file").toString();

		var date:Date = Date.now();
		var fileName:String = date.getUTCMonth() + "-" + date.getUTCDay() + "-" + date.getUTCFullYear() + " "
		+ date.getUTCHours() + "-" + date.getUTCMinutes() + "-" + date.getUTCSeconds() + ".txt";

		gameDirectory = Path.normalize(System.documentsDirectory + "/Friday Night Funkin/" + mod);
		#if mobile
		gameDirectory = Path.normalize(System.applicationStorageDirectory);
		#end

		logDirectory = Path.normalize(gameDirectory + '/logs/');

		if (!FileSystem.exists(gameDirectory))
			FileSystem.createDirectory(gameDirectory);

		if (!FileSystem.exists(logDirectory))
			FileSystem.createDirectory(logDirectory);
		
		var logPath:String = Path.normalize(gameDirectory + "/logs/" + fileName);

		var currentLog:String = '--- Friday Night Funkin\' Papaya Engine ($mod) ---';
		#end

		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			createThread(() -> {
				var log:String = '${infos.fileName}:${infos.className} [${infos.methodName}]:${infos.lineNumber} : $v';
				Sys.println(log);

				#if (desktop || mobile)
				try {
					currentLog = currentLog + '\n$log';

					File.saveContent(logPath, currentLog);
				}
				catch (e:Dynamic) {
					Sys.println('Failed to save log. ($e)');
				}
				#end
			}, true);
		};

		// Please don't remove this if you're using the Engine for your mod (:
		Application.current.window.title = Application.current.window.title + ' - Papaya Engine';

		super();

		addChild(new FlxGame(0, 0, TitleState));

		#if debug
		addChild(new FPS(10, 3, 0xFFFFFF));
		#end
	}
	
	public function createThread(callback:Void->Void, ?force:Bool = false):Void {
		#if (target.threaded)
		sys.thread.Thread.create(() -> {
			callback();
		});
		#else
		if (force)
			callback();
		#end
	}
}
