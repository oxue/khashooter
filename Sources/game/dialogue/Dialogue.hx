package game.dialogue;

class Dialogue {
	public var phrases:Array<Phrase>;

	public function new(data:Dynamic) {
		phrases = [];
		for (dialogue in cast(data.dialogues, Array<Dynamic>)) {
			for (phrase in cast(dialogue.phrases, Array<Dynamic>)) {
				phrases.push(new Phrase(dialogue.portrait, phrase));
			}
		}
	}
}

class Phrase {
	public var portrait:String;
	public var phrase:String;

	public function new(portrait:String, phrase:String) {
		this.portrait = portrait;
		this.phrase = phrase;
	}
}
