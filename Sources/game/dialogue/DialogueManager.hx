package game.dialogue;

import kha.Color;
import refraction.display.ResourceFormat;
import kha.Framebuffer;
import helpers.DebugLogger;
import yaml.Parser;
import yaml.Yaml;
import kha.Assets;
/**
 * assuming this class is correct
 * @author qwerber
 */
class DialogueManager {

	private var rootDir:String;
	private var dialogues:Map<String, Dialogue>;
	private var currentDialogue:String;
	private var currentPhrase:Int;
	private var playing:Bool;

	public function new(_rootDir:String) {
		this.rootDir = _rootDir;
		this.dialogues = new Map<String, Dialogue>();
		currentDialogue = null;
		playing = false;
		currentPhrase = 0;
	}

	public function playDialogue(dialogueName:String):Void {
		currentDialogue = dialogueName;
		currentPhrase = 0;
		playing = true;
		DebugLogger.info("DEBUG", {dia:currentDialogue});
		DebugLogger.info("DEBUG", {play:playing});
	}

	public function render(f:Framebuffer) {
		if (!playing) {
			return;
		}
		var dialogue = dialogues.get(currentDialogue);
		var phrase = dialogue.phrases[currentPhrase];
		

		DebugLogger.info("DEBUG", "drawing dialgoei");
		f.g2.color = Color.Blue;
		f.g2.fillRect(280,280,168,168);
		f.g2.color = Color.White;
		f.g2.drawScaledImage(
			ResourceFormat.images.get(phrase.portrait),
			300,300,
			128,128
		);
		f.g2.color = Color.Blue;
		f.g2.fillRect(448,280,600,168);
		f.g2.color = Color.Black;
		trace(phrase.phrase);
		f.g2.drawString(phrase.phrase, 448, 300);
		
	}

	public function loadDialogue(dialogueName:String):Void {
		Assets.loadBlobFromPath('${rootDir}/${dialogueName}.yaml', (blob) -> {
			dialogues.set(
				dialogueName,
				new Dialogue(Yaml.parse(blob.toString(), Parser.options().useObjects()))
			);

			DebugLogger.info("DEBUG", dialogues);

		});

	}
}
