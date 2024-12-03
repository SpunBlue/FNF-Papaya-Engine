package objects;

import engine.Paths;
import openfl.Assets;
import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{	
	public var target:Alphabet;
	var isPlayer:Bool = false;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char);

		/*loadGraphic('assets/images/iconGrid.png', true, 150, 150);

		antialiasing = true;
		animation.add('bf', [0, 1], 0, false, isPlayer);
		animation.add('bf-car', [0, 1], 0, false, isPlayer);
		animation.add('bf-christmas', [0, 1], 0, false, isPlayer);
		animation.add('bf-pixel', [21, 21], 0, false, isPlayer);
		animation.add('spooky', [2, 3], 0, false, isPlayer);
		animation.add('pico', [4, 5], 0, false, isPlayer);
		animation.add('mom', [6, 7], 0, false, isPlayer);
		animation.add('mom-car', [6, 7], 0, false, isPlayer);
		animation.add('tankman', [8, 9], 0, false, isPlayer);
		animation.add('face', [10, 11], 0, false, isPlayer);
		animation.add('dad', [12, 13], 0, false, isPlayer);
		animation.add('senpai', [22, 22], 0, false, isPlayer);
		animation.add('senpai-angry', [22, 22], 0, false, isPlayer);
		animation.add('spirit', [23, 23], 0, false, isPlayer);
		animation.add('bf-old', [14, 15], 0, false, isPlayer);
		animation.add('gf', [16], 0, false, isPlayer);
		animation.add('parents-christmas', [17], 0, false, isPlayer);
		animation.add('monster', [19, 20], 0, false, isPlayer);
		animation.add('monster-christmas', [19, 20], 0, false, isPlayer);
		animation.play(char);
		scrollFactor.set();*/
	}

	override public function update(elapsed)
	{
		if (target != null) {
			setPosition(target.x + target.width, target.y - (this.height / 4));
			this.alpha = target.alpha;
		}
	}

	public function changeIcon(character:String)
	{
		if (Assets.exists(Paths.getImage('icons/$character')))
			loadGraphic(Paths.getImage('icons/$character'), true, 150, 150);
		else
			loadGraphic(Paths.getImage('icons/default'), true, 150, 150);

		antialiasing = true;
		animation.add('$character', [0, 1], 0, false, isPlayer);
		animation.play('$character');
	}
}
