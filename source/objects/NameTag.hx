package objects;

import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.group.FlxSpriteGroup;

class NameTag extends FlxSpriteGroup {
	var description:String;
	var target:FlxObject;

	var backdrop:FlxSprite;

	override function new(object:FlxObject, description:String, ?warning:String) {
		super();

		this.visible = false;
		
		target = object;
		this.description = description;

		var text:FlxText = new FlxText();
		text.setFormat(null, 12, FlxColor.WHITE, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.GRAY);
		text.text = this.description;
		text.updateHitbox();
		
		backdrop = new FlxSprite();
		backdrop.makeGraphic(Math.floor(text.width) + 12, Math.floor(text.height) + 12, FlxColor.BLACK);
		backdrop.x = text.x - (12 / 2);
		backdrop.y = text.y - (12 / 2);
		backdrop.alpha = 0.7;

		add(backdrop);
		add(text);

		if (warning != null) {
			var t:FlxText = new FlxText();
			t.setFormat(null, 8, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.SHADOW, FlxColor.ORANGE);
			t.text = '* $warning';
			t.updateHitbox();

			t.setPosition(backdrop.x, backdrop.y + backdrop.height);

			add(t);
		}

		this.alpha = 0.7;
	}
	
	var checking:Bool = true;
	override public function update(elapsed:Float) {
		this.setPosition(target.x - backdrop.width, target.y - backdrop.height);

		super.update(elapsed);

		if (FlxG.mouse.overlaps(target, camera) && target.alive && target.visible && target.active) {
			this.visible = true;
			FlxG.mouse.cursor.alpha = 0.25;

			checking = true;
		}
		else
			this.visible = false;

		if (checking && !FlxG.mouse.overlaps(target, camera)) {
			checking = false;
			FlxG.mouse.cursor.alpha = 1;
		}
	}

	override function destroy() {
		FlxG.mouse.cursor.alpha = 1;

		super.destroy();
	}

	public static function createTag(object:FlxObject, description:String, ?warning:String):NameTag {
		var tag = new NameTag(object, description, warning);
        return tag;
	}
}